// Copyright (C) 2026 Advanced Micro Devices, Inc.
// SPDX-License-Identifier: BSD-3-Clause

#include "interrupt.h"
#include "mmio.h"
#include <algorithm>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <deque>
#include <filesystem>
#include <fstream>
#include <map>
#include <mutex>
#include <poll.h>
#include <set>
#include <sstream>
#include <thread>
#include <vector>
#include <fcntl.h>
#include <unistd.h>

using remote_device::InterruptRequest;
using remote_device::InterruptResponse;

namespace {
struct Root {
    int fd = -1;
    bool enabled = false;
    explicit Root(unsigned irq) {
        std::ifstream interrupts("/proc/interrupts");
        std::string line, name;
        while (std::getline(interrupts, line)) {
            std::istringstream fields(line);
            std::string field;
            while (fields >> field) {
                if (field.rfind("GIC", 0) != 0)
                    continue;
                unsigned number;
                if (fields >> number && number == irq)
                    while (fields >> field) name = field;
                break;
            }
            if (!name.empty()) break;
        }
        if (!name.empty()) {
            for (const auto &entry : std::filesystem::directory_iterator("/sys/class/uio")) {
                std::ifstream names(entry.path() / "name");
                std::string candidate;
                std::getline(names, candidate);
                if (candidate == name) {
                    const auto path = "/dev/" + entry.path().filename().string();
                    fd = open(path.c_str(), O_RDWR | O_NONBLOCK | O_CLOEXEC);
                    break;
                }
            }
        }
        if (fd < 0)
            throw std::runtime_error("Cannot open UIO for IRQ " + std::to_string(irq));
        enabled = true;
        try { enable(false); }
        catch (...) { close(fd); fd = -1; throw; }
    }
    ~Root() { if (fd >= 0) close(fd); }
    void enable(bool value) {
        if (enabled == value) return;
        uint32_t control = value ? 1 : 0;
        if (write(fd, &control, sizeof(control)) != sizeof(control))
            throw std::runtime_error("Cannot control UIO interrupt");
        enabled = value;
    }
};

struct Controller {
    MMIO mmio;
    uint32_t mask = 0;
    std::string parent;
    Controller(uint64_t address, std::string parent_route)
        : mmio(address, 32), parent(std::move(parent_route)) {
        if (!mmio.contains(0, 32))
            throw std::runtime_error("Cannot map interrupt controller");
        mmio.write(0, 0x08);
        mmio.write(3, 0x1c);
    }
    void enable(uint32_t value) {
        if (mask & ~value) mmio.write(mask & ~value, 0x14);
        if (value & ~mask) mmio.write(value & ~mask, 0x10);
        mask = value;
    }
};

struct Session {
    grpc::ServerContext *context;
    std::mutex mutex;
    std::condition_variable ready;
    std::deque<InterruptResponse> events;
    bool done = false;
    explicit Session(grpc::ServerContext *ctx) : context(ctx) {}
    void send(InterruptResponse::Event event, const InterruptRequest &request,
              const std::string &message = "") {
        InterruptResponse response;
        response.set_event(event);
        response.set_subscription(request.subscription());
        response.set_sequence(request.sequence());
        response.set_message(message);
        std::lock_guard<std::mutex> lock(mutex);
        events.push_back(std::move(response));
        ready.notify_one();
    }
};

std::string key(const InterruptRequest &request, int first = 0) {
    std::string result = std::to_string(request.raw_irq());
    for (int i = request.route_size() - 1; i >= first; --i)
        result += "/" + std::to_string(request.route(i).address()) + ":" +
                  std::to_string(request.route(i).index());
    return result;
}

struct Source {
    std::shared_ptr<Session> owner;
    InterruptRequest request;
    bool armed = false;
};
}

struct InterruptManager::State {
    std::mutex mutex;
    std::string instance;
    uint64_t revision = 0;
    bool suspended = false;
    std::atomic<bool> stopped{false};
    std::map<unsigned, std::shared_ptr<Root>> roots;
    std::map<uint64_t, std::unique_ptr<Controller>> controllers;
    std::map<std::string, Source> sources;
    std::set<std::shared_ptr<Session>> sessions;
    std::thread worker;

    State() {
        std::ifstream uuid("/proc/sys/kernel/random/uuid");
        std::getline(uuid, instance);
        if (instance.empty()) throw std::runtime_error("Cannot create interrupt generation");
        worker = std::thread([this] { run(); });
    }
    ~State() {
        stopped = true;
        worker.join();
        std::lock_guard<std::mutex> lock(mutex);
        reset();
    }
    std::string generation() const { return instance + ":" + std::to_string(revision); }

    void reset() {
        ++revision;
        suspended = true;
        for (auto &session : sessions) session->context->TryCancel();
        sources.clear();
        for (auto &entry : controllers) {
            try { entry.second->enable(0); }
            catch (const std::exception &error) { std::cerr << error.what() << std::endl; }
        }
        for (auto &entry : roots) {
            try { entry.second->enable(false); }
            catch (const std::exception &error) { std::cerr << error.what() << std::endl; }
        }
        controllers.clear();
        roots.clear();
    }

    void reconcile() {
        std::map<uint64_t, uint32_t> masks;
        std::set<unsigned> active_roots;
        std::set<uint64_t> used_controllers;
        std::set<unsigned> used_roots;
        for (const auto &entry : sources) {
            const auto &source = entry.second;
            used_roots.insert(source.request.raw_irq());
            for (const auto &route : source.request.route()) {
                used_controllers.insert(route.address());
                if (source.armed) masks[route.address()] |= uint32_t(1) << route.index();
            }
            if (source.armed) active_roots.insert(source.request.raw_irq());
        }
        for (auto it = controllers.begin(); it != controllers.end();) {
            it->second->enable(masks[it->first]);
            if (!used_controllers.count(it->first)) it = controllers.erase(it);
            else ++it;
        }
        for (auto it = roots.begin(); it != roots.end();) {
            it->second->enable(active_roots.count(it->first));
            if (!used_roots.count(it->first)) it = roots.erase(it);
            else ++it;
        }
    }

    void acquire(const std::shared_ptr<Session> &session, const InterruptRequest &request) {
        if (!request.subscription() || request.route_size() > 32)
            throw std::runtime_error("Invalid interrupt subscription or route depth");
        std::set<uint64_t> addresses;
        for (int i = 0; i < request.route_size(); ++i) {
            const auto &route = request.route(i);
            if (route.index() >= 32 || route.address() % 4 ||
                !addresses.insert(route.address()).second)
                throw std::runtime_error("Invalid interrupt controller route");
            auto existing = controllers.find(route.address());
            if (existing != controllers.end() && existing->second->parent != key(request, i + 1))
                throw std::runtime_error("Interrupt controller route conflicts with loaded metadata");
        }
        const auto route_key = key(request);
        for (const auto &entry : sources) {
            if (entry.second.owner == session &&
                entry.second.request.subscription() == request.subscription())
                throw std::runtime_error("Interrupt subscription already exists");
            // A controller output cannot also be owned as a leaf source.
            if (entry.first == route_key || entry.first.rfind(route_key + "/", 0) == 0 ||
                route_key.rfind(entry.first + "/", 0) == 0)
                throw std::runtime_error("Interrupt source is already in use");
        }
        auto root = roots.find(request.raw_irq());
        if (root == roots.end())
            roots.emplace(request.raw_irq(), std::make_shared<Root>(request.raw_irq()));
        for (int i = request.route_size() - 1; i >= 0; --i) {
            const auto &route = request.route(i);
            if (!controllers.count(route.address()))
                controllers.emplace(route.address(),
                    std::make_unique<Controller>(route.address(), key(request, i + 1)));
        }
        sources.emplace(route_key, Source{session, request, false});
    }

    void command(const std::shared_ptr<Session> &session, const InterruptRequest &request) {
        std::lock_guard<std::mutex> lock(mutex);
        if (suspended || request.generation() != generation()) {
            session->context->TryCancel();
            return;
        }
        try {
            if (request.operation() == InterruptRequest::ACQUIRE) {
                acquire(session, request);
                session->send(InterruptResponse::ACQUIRED, request);
                return;
            }
            auto found = sources.end();
            for (auto it = sources.begin(); it != sources.end(); ++it)
                if (it->second.owner == session &&
                    it->second.request.subscription() == request.subscription()) {
                    found = it;
                    break;
                }
            if (found == sources.end()) {
                if (request.operation() == InterruptRequest::RELEASE) {
                    session->send(InterruptResponse::RELEASED, request);
                    return;
                }
                if (request.operation() == InterruptRequest::CANCEL) {
                    session->send(InterruptResponse::CANCELLED, request);
                    return;
                }
                throw std::runtime_error("Unknown interrupt subscription");
            }
            auto &source = found->second;
            switch (request.operation()) {
            case InterruptRequest::ARM:
                if (source.armed) throw std::runtime_error("Interrupt wait already armed");
                source.request.set_sequence(request.sequence());
                source.armed = true;
                reconcile();
                session->send(InterruptResponse::ARMED, request);
                break;
            case InterruptRequest::CANCEL:
                if (source.request.sequence() == request.sequence()) source.armed = false;
                reconcile();
                session->send(InterruptResponse::CANCELLED, request);
                break;
            case InterruptRequest::RELEASE:
                sources.erase(found);
                reconcile();
                session->send(InterruptResponse::RELEASED, request);
                break;
            default:
                throw std::runtime_error("Unknown interrupt operation");
            }
        } catch (const std::exception &error) {
            try { reconcile(); }
            catch (const std::exception &cleanup_error) {
                std::cerr << cleanup_error.what() << std::endl;
                reset();
                return;
            }
            session->send(InterruptResponse::ERROR, request, error.what());
        }
    }

    void dispatch(unsigned irq, Root &root) {
        uint32_t count;
        if (read(root.fd, &count, sizeof(count)) != sizeof(count)) return;
        root.enabled = false;
        std::map<uint64_t, uint32_t> pending;
        std::map<uint64_t, int> depths;
        for (auto &entry : sources) {
            auto &source = entry.second;
            if (!source.armed || source.request.raw_irq() != irq) continue;
            bool fired = true;
            int depth = source.request.route_size();
            for (const auto &route : source.request.route()) {
                depths[route.address()] = depth--;
                auto it = pending.find(route.address());
                if (it == pending.end())
                    it = pending.emplace(route.address(), controllers.at(route.address())->mmio.read(0x04)).first;
                if (!(it->second & (uint32_t(1) << route.index()))) fired = false;
            }
            if (!fired) continue;
            source.armed = false;
            // Disable the source before waking its driver to clear peripheral status.
            for (const auto &route : source.request.route()) {
                auto &controller = *controllers.at(route.address());
                controller.enable(controller.mask & ~(uint32_t(1) << route.index()));
            }
            source.owner->send(InterruptResponse::FIRED, source.request);
        }
        // A masked child can leave a captured interrupt in its parent.
        std::vector<std::pair<int, uint64_t>> acknowledgement;
        for (const auto &entry : depths) acknowledgement.emplace_back(entry.second, entry.first);
        std::sort(acknowledgement.rbegin(), acknowledgement.rend());
        for (const auto &entry : acknowledgement)
            if (pending[entry.second])
                controllers.at(entry.second)->mmio.write(pending[entry.second], 0x0c);
        reconcile();
    }

    void run() {
        while (!stopped) {
            std::vector<std::pair<unsigned, std::shared_ptr<Root>>> snapshot;
            std::vector<pollfd> descriptors;
            uint64_t version;
            {
                std::lock_guard<std::mutex> lock(mutex);
                version = revision;
                for (const auto &entry : roots) {
                    snapshot.push_back(entry);
                    descriptors.push_back({entry.second->fd, POLLIN, 0});
                }
            }
            const int result = poll(descriptors.data(), descriptors.size(), 20);
            if (result <= 0) continue;
            std::lock_guard<std::mutex> lock(mutex);
            if (version != revision) continue;
            try {
                for (size_t i = 0; i < descriptors.size(); ++i) {
                    auto root = roots.find(snapshot[i].first);
                    if (root == roots.end() || root->second != snapshot[i].second) continue;
                    if (descriptors[i].revents & (POLLERR | POLLHUP | POLLNVAL))
                        throw std::runtime_error("UIO interrupt device disconnected");
                    if (descriptors[i].revents & POLLIN) dispatch(root->first, *root->second);
                }
            } catch (const std::exception &) {
                reset();
            }
        }
    }
};

InterruptManager::InterruptManager() : state_(std::make_unique<State>()) {}
InterruptManager::~InterruptManager() = default;

std::string InterruptManager::generation() {
    std::lock_guard<std::mutex> lock(state_->mutex);
    if (state_->suspended) return "";
    return state_->generation();
}

std::string InterruptManager::invalidate() {
    std::lock_guard<std::mutex> lock(state_->mutex);
    state_->reset();
    return state_->generation();
}

bool InterruptManager::resume(const std::string &generation) {
    std::lock_guard<std::mutex> lock(state_->mutex);
    if (generation != state_->generation()) return false;
    state_->suspended = false;
    return true;
}

grpc::Status InterruptManager::serve(grpc::ServerContext *context,
    grpc::ServerReaderWriter<InterruptResponse, InterruptRequest> *stream) {
    auto session = std::make_shared<Session>(context);
    {
        std::lock_guard<std::mutex> lock(state_->mutex);
        state_->sessions.insert(session);
    }
    std::thread writer([&] {
        std::unique_lock<std::mutex> lock(session->mutex);
        while (!session->done) {
            session->ready.wait_for(lock, std::chrono::milliseconds(100), [&] {
                return session->done || !session->events.empty();
            });
            if (context->IsCancelled()) break;
            while (!session->events.empty() && !session->done) {
                auto response = std::move(session->events.front());
                session->events.pop_front();
                lock.unlock();
                const bool written = stream->Write(response);
                lock.lock();
                if (!written) { context->TryCancel(); return; }
            }
        }
    });
    InterruptRequest request;
    while (stream->Read(&request)) state_->command(session, request);
    {
        std::lock_guard<std::mutex> lock(state_->mutex);
        for (auto it = state_->sources.begin(); it != state_->sources.end();)
            if (it->second.owner == session) it = state_->sources.erase(it);
            else ++it;
        try { state_->reconcile(); }
        catch (const std::exception &error) {
            std::cerr << error.what() << std::endl;
            state_->reset();
        }
        state_->sessions.erase(session);
    }
    {
        std::lock_guard<std::mutex> lock(session->mutex);
        session->done = true;
        session->ready.notify_one();
    }
    writer.join();
    return grpc::Status::OK;
}
