#include "interrupt.h"

#include <iostream>
#include <fstream>
#include <filesystem>
#include <cstring>
#include <sstream>
#include <chrono>
#include <cerrno>
#include <cctype>
#include <sys/epoll.h>
#include <unistd.h>
#include <fcntl.h>

#define DEBUG

namespace
{
    // AXI Interrupt Controller register offsets (per AMD PG099).
    namespace axi_intc
    {
        constexpr uint32_t IPR        = 0x04;  // Interrupt Pending Register
        constexpr uint32_t IER        = 0x08;  // Interrupt Enable Register (full)
        constexpr uint32_t IAR        = 0x0C;  // Interrupt Acknowledge Register
        constexpr uint32_t SIE        = 0x10;  // Set Interrupt Enable (write 1 to enable)
        constexpr uint32_t CIE        = 0x14;  // Clear Interrupt Enable (write 1 to disable)
        constexpr uint32_t MER        = 0x1C;  // Master Enable Register
        constexpr uint32_t MER_ENABLE = 0x3;   // MER value: ME (bit 0) | HIE (bit 1)
        constexpr uint32_t MAX_LINES  = 32;    // AXI INTC supports up to 32 input lines
    }

    // Maximum interval between predicate re-evaluations in wait_for_interrupt.
    constexpr auto WAIT_HEARTBEAT = std::chrono::milliseconds(1000);

    // Sentinel stored in epoll_event.data.u32 to identify the self-pipe wake
    // fd. No real Linux IRQ uses this value.
    constexpr uint32_t SELF_PIPE_SENTINEL = 0xFFFFFFFF;
}

InterruptImpl::InterruptImpl()
{
    epoll_fd_ = epoll_create1(0);
    if (epoll_fd_ < 0)
    {
        std::cerr << "InterruptImpl: failed to create epoll fd: "
                  << std::strerror(errno) << std::endl;
        return;
    }

    int pipe_fds[2] = {-1, -1};
    if (pipe(pipe_fds) < 0)
    {
        std::cerr << "InterruptImpl: failed to create self-pipe: "
                  << std::strerror(errno) << std::endl;
        close(epoll_fd_);
        epoll_fd_ = -1;
        return;
    }
    pipe_read_fd_ = pipe_fds[0];
    pipe_write_fd_ = pipe_fds[1];

    fcntl(pipe_read_fd_, F_SETFL, O_NONBLOCK);

    struct epoll_event ev{};
    ev.events = EPOLLIN;
    ev.data.u32 = SELF_PIPE_SENTINEL;
    epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, pipe_read_fd_, &ev);

    epoll_thread_ = std::thread(&InterruptImpl::epoll_loop, this);
}

InterruptImpl::~InterruptImpl()
{
    // Wake any in-flight waiters before tearing down the dispatch thread.
    invalidate_all_internal();

    shutdown_.store(true);
    wake_epoll();

    if (epoll_thread_.joinable())
    {
        epoll_thread_.join();
    }

    if (pipe_read_fd_ >= 0)  close(pipe_read_fd_);
    if (pipe_write_fd_ >= 0) close(pipe_write_fd_);
    if (epoll_fd_ >= 0)      close(epoll_fd_);
}

void InterruptImpl::wake_epoll()
{
    if (pipe_write_fd_ < 0) return;
    uint8_t val = 1;
    ::write(pipe_write_fd_, &val, 1);
}

std::string InterruptImpl::find_uio_device(uint32_t raw_irq)
{
    // /proc/interrupts row layout (relevant columns only):
    //   <linux_irq>: <cpu0_count> [<cpu_N_count> ...] <chip> <hwirq> <type> <name>
    // We match on the first column (Linux IRQ number, with trailing colon)
    // and capture the last column (driver/device name).
    std::string dev_name;
    {
        std::ifstream proc_int("/proc/interrupts");
        if (!proc_int.is_open()) return "";

        std::string line;
        while (std::getline(proc_int, line))
        {
            std::istringstream iss(line);
            std::vector<std::string> cols;
            for (std::string col; iss >> col; ) cols.push_back(col);
            if (cols.empty()) continue;

            std::string &first = cols.front();
            if (first.empty() || first.back() != ':') continue;
            first.pop_back();

            try
            {
                if (std::stoul(first) == raw_irq)
                {
                    dev_name = cols.back();
                    break;
                }
            }
            catch (...) { /* header row or malformed line */ }
        }
    }
    if (dev_name.empty()) return "";

    try
    {
        for (const auto &entry : std::filesystem::directory_iterator("/sys/class/uio"))
        {
            std::ifstream name_file(entry.path() / "name");
            if (!name_file.is_open()) continue;
            std::string uio_name;
            std::getline(name_file, uio_name);
            while (!uio_name.empty() && std::isspace(static_cast<unsigned char>(uio_name.back())))
                uio_name.pop_back();
            if (uio_name == dev_name)
                return "/dev/" + entry.path().filename().string();
        }
    }
    catch (const std::filesystem::filesystem_error &e)
    {
        std::cerr << "find_uio_device: " << e.what() << std::endl;
    }
    return "";
}

void InterruptImpl::epoll_loop()
{
    constexpr int MAX_EVENTS = 16;
    struct epoll_event events[MAX_EVENTS];

    while (!shutdown_.load())
    {
        int nfds = epoll_wait(epoll_fd_, events, MAX_EVENTS, 1000);
        if (nfds < 0)
        {
            if (errno == EINTR) continue;
            std::cerr << "epoll_wait: " << std::strerror(errno) << std::endl;
            break;
        }

        for (int i = 0; i < nfds; i++)
        {
            const uint32_t key = events[i].data.u32;

            // Self-pipe wake: drain and continue
            if (key == SELF_PIPE_SENTINEL)
            {
                uint8_t buf[64];
                while (::read(pipe_read_fd_, buf, sizeof(buf)) > 0) { }
                continue;
            }

            // UIO event: key holds the raw_irq. Look up the UioDevice and
            // read 4 bytes from its fd to acknowledge the kernel-side IRQ.
            std::shared_ptr<UioDevice> uio;
            std::shared_ptr<IntcController> intc;
            {
                std::lock_guard<std::mutex> lock(global_mtx_);
                auto uio_it = uio_devices_.find(key);
                if (uio_it == uio_devices_.end()) continue;
                uio = uio_it->second;
                for (auto &[phys_addr, ctrl] : intc_controllers_)
                {
                    if (ctrl->parent_raw_irq == key)
                    {
                        intc = ctrl;
                        break;
                    }
                }
            }

            if (uio->fd < 0) continue;
            uint32_t val;
            ssize_t n = ::read(uio->fd, &val, sizeof(val));
            if (n != sizeof(val)) continue;

            std::lock_guard<std::mutex> lock(global_mtx_);

            if (intc)
            {
                // Cascaded INTC: read IPR, mask all pending lines, ack, then notify
                std::lock_guard<std::mutex> intc_lock(intc->mtx);
                const uint32_t ipr = intc->mmio->read(axi_intc::IPR);

                uint32_t pending = ipr;
                while (pending != 0)
                {
                    const uint32_t line = __builtin_ctz(pending);
                    intc->mmio->write(1u << line, axi_intc::CIE);
                    pending &= ~(1u << line);
                }
                intc->mmio->write(ipr, axi_intc::IAR);

                for (auto &[id, reg] : registrations_)
                {
                    if (reg->intc.get() == intc.get() && (ipr & (1u << reg->pin_index)))
                    {
                        {
                            std::lock_guard<std::mutex> reg_lock(reg->mtx);
                            reg->fired.store(true);
                        }
                        reg->cv.notify_all();
                    }
                }
            }
            else
            {
                // Direct UIO (no INTC): notify all registrations on this UIO
                for (auto &[id, reg] : registrations_)
                {
                    if (reg->uio && reg->uio->raw_irq == key)
                    {
                        {
                            std::lock_guard<std::mutex> reg_lock(reg->mtx);
                            reg->fired.store(true);
                        }
                        reg->cv.notify_all();
                    }
                }
            }
        }
    }
}

grpc::Status InterruptImpl::register_interrupt(
    grpc::ServerContext *context,
    const interrupt::RegisterRequest *request,
    interrupt::RegisterResponse *response)
{
#ifdef DEBUG
    std::cout << "RegisterInterrupt: pin=" << request->pin_name()
              << " raw_irq=" << request->raw_irq()
              << " controller_phys_addr=0x" << std::hex << request->controller_phys_addr() << std::dec
              << " pin_index=" << request->pin_index() << std::endl;
#endif

    if (request->pin_index() >= axi_intc::MAX_LINES)
    {
        response->set_msg("pin_index out of range (max " +
                          std::to_string(axi_intc::MAX_LINES - 1) + ")");
        return grpc::Status(grpc::StatusCode::INVALID_ARGUMENT, response->msg());
    }

    std::lock_guard<std::mutex> lock(global_mtx_);

    // Step 1: get-or-create UioDevice (cached by raw_irq; shared_ptr ref-counted)
    std::shared_ptr<UioDevice> uio;
    auto uio_it = uio_devices_.find(request->raw_irq());
    if (uio_it != uio_devices_.end())
    {
        uio = uio_it->second;
    }
    else
    {
        std::string uio_path = find_uio_device(request->raw_irq());
        if (uio_path.empty())
        {
            response->set_msg("UIO device not found for raw_irq " +
                              std::to_string(request->raw_irq()));
            return grpc::Status(grpc::StatusCode::NOT_FOUND, response->msg());
        }

        int uio_fd = open(uio_path.c_str(), O_RDWR);
        if (uio_fd < 0)
        {
            response->set_msg("Failed to open " + uio_path + ": " +
                              std::strerror(errno));
            return grpc::Status(grpc::StatusCode::INTERNAL, response->msg());
        }

        struct epoll_event ev{};
        ev.events = EPOLLIN;
        ev.data.u32 = request->raw_irq();
        if (epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, uio_fd, &ev) < 0)
        {
            close(uio_fd);
            response->set_msg("Failed to add UIO fd to epoll: " +
                              std::string(std::strerror(errno)));
            return grpc::Status(grpc::StatusCode::INTERNAL, response->msg());
        }

        uio = std::make_shared<UioDevice>();
        uio->fd = uio_fd;
        uio->raw_irq = request->raw_irq();
        uio_devices_[request->raw_irq()] = uio;
    }

    // Step 2: get-or-create IntcController (singleton by phys_addr)
    std::shared_ptr<IntcController> intc;
    if (request->controller_phys_addr() > 0)
    {
        auto intc_it = intc_controllers_.find(request->controller_phys_addr());
        if (intc_it != intc_controllers_.end())
        {
            intc = intc_it->second;
        }
        else
        {
            intc = std::make_shared<IntcController>();
            intc->mmio = std::make_unique<MMIO>(
                static_cast<off_t>(request->controller_phys_addr()), 32);
            intc->phys_addr = request->controller_phys_addr();
            intc->parent_raw_irq = request->raw_irq();

            // Initialize controller once: disable all lines, then enable
            // the master. Per-line enables happen in wait_for_interrupt.
            intc->mmio->write(0, axi_intc::IER);
            intc->mmio->write(axi_intc::MER_ENABLE, axi_intc::MER);

            intc_controllers_[request->controller_phys_addr()] = intc;
        }
    }

    // Step 3: create the registration with shared_ptr copies of uio/intc
    std::string interrupt_id = "irq_" + std::to_string(id_counter_++);
    auto reg = std::make_shared<InterruptRegistration>();
    reg->interrupt_id = interrupt_id;
    reg->pin_name = request->pin_name();
    reg->pin_index = request->pin_index();
    reg->intc = intc;
    reg->uio = uio;

    registrations_[interrupt_id] = std::move(reg);
    wake_epoll();

    response->set_interrupt_id(interrupt_id);
    return grpc::Status::OK;
}

grpc::Status InterruptImpl::wait_for_interrupt(
    grpc::ServerContext *context,
    const interrupt::WaitRequest *request,
    interrupt::WaitResponse *response)
{
#ifdef DEBUG
    std::cout << "WaitForInterrupt: id=" << request->interrupt_id()
              << " timeout_ms=" << request->timeout_ms() << std::endl;
#endif

    // Hold a shared_ptr copy for the wait's duration. release_interrupt and
    // invalidate_all_internal may erase the map entry while we sleep; the
    // local copy keeps the InterruptRegistration alive until we return.
    std::shared_ptr<InterruptRegistration> reg_ptr;
    {
        std::lock_guard<std::mutex> lock(global_mtx_);
        auto it = registrations_.find(request->interrupt_id());
        if (it == registrations_.end())
        {
            response->set_status(interrupt::WaitResponse::ERROR);
            response->set_msg("Unknown interrupt_id: " + request->interrupt_id());
            return grpc::Status::OK;
        }
        reg_ptr = it->second;
    }
    InterruptRegistration *reg = reg_ptr.get();

    // Take reg->mtx BEFORE the invalidated check AND before arming. This
    // serializes with invalidate_all_internal (which also sets invalidated
    // under reg->mtx) and prevents lost wakeups: if the IRQ fires after
    // arming, the epoll thread must wait for us to enter cv.wait_until().
    std::unique_lock<std::mutex> lock(reg->mtx);

    if (reg->invalidated.load())
    {
        response->set_status(interrupt::WaitResponse::ERROR);
        response->set_msg("Interrupt invalidated by Overlay change");
        return grpc::Status(grpc::StatusCode::CANCELLED, "Interrupt invalidated");
    }

    reg->fired.store(false);

    if (reg->intc)
    {
        std::lock_guard<std::mutex> intc_lock(reg->intc->mtx);
        reg->intc->mmio->write(1u << reg->pin_index, axi_intc::SIE);
    }

    if (reg->uio && reg->uio->fd >= 0)
    {
        uint32_t enable = 1;
        ::write(reg->uio->fd, &enable, sizeof(enable));
    }

    auto predicate = [&]()
    {
        return reg->fired.load() || reg->invalidated.load() ||
               reg->released.load() || context->IsCancelled();
    };

    // Heartbeat-bounded wait so cancellation (context->IsCancelled()) is
    // observed even when no IRQ fires. Without this, a dropped client
    // connection would leak this gRPC worker thread.
    using clock = std::chrono::steady_clock;
    const auto deadline = request->timeout_ms() > 0
        ? clock::now() + std::chrono::milliseconds(request->timeout_ms())
        : clock::time_point::max();

    bool wait_result = false;
    while (true)
    {
        if (predicate()) { wait_result = true; break; }
        const auto now = clock::now();
        if (now >= deadline) { wait_result = false; break; }
        const auto wake = (deadline - now < WAIT_HEARTBEAT) ? deadline : now + WAIT_HEARTBEAT;
        reg->cv.wait_until(lock, wake);
    }

    if (reg->invalidated.load())
    {
        response->set_status(interrupt::WaitResponse::ERROR);
        response->set_msg("Interrupt invalidated by Overlay change");
        return grpc::Status(grpc::StatusCode::CANCELLED, "Interrupt invalidated");
    }
    if (reg->released.load())
    {
        response->set_status(interrupt::WaitResponse::ERROR);
        response->set_msg("Interrupt released");
        return grpc::Status(grpc::StatusCode::CANCELLED, "Interrupt released");
    }
    if (context->IsCancelled())
    {
        response->set_status(interrupt::WaitResponse::ERROR);
        response->set_msg("Client cancelled");
        return grpc::Status::CANCELLED;
    }
    if (!wait_result)
    {
        response->set_status(interrupt::WaitResponse::TIMEOUT);
        return grpc::Status::OK;
    }

    reg->fired.store(false);
    response->set_status(interrupt::WaitResponse::FIRED);
    return grpc::Status::OK;
}

grpc::Status InterruptImpl::release_interrupt(
    grpc::ServerContext *context,
    const interrupt::ReleaseRequest *request,
    interrupt::ReleaseResponse *response)
{
#ifdef DEBUG
    std::cout << "ReleaseInterrupt: id=" << request->interrupt_id() << std::endl;
#endif

    std::lock_guard<std::mutex> lock(global_mtx_);
    auto it = registrations_.find(request->interrupt_id());
    if (it == registrations_.end())
    {
        response->set_msg("Unknown interrupt_id");
        return grpc::Status::OK;
    }

    // Local shared_ptr; keeps the Registration alive through this function.
    auto reg = it->second;

    // Wake any in-flight waiter. The shared_ptr they hold (via
    // wait_for_interrupt) keeps the Registration alive until they return.
    {
        std::lock_guard<std::mutex> reg_lock(reg->mtx);
        reg->released.store(true);
    }
    reg->cv.notify_all();

    registrations_.erase(it);

    // Drop our local ref so the use_count check below sees the true
    // remaining reference count (map + any waiters of OTHER registrations
    // sharing this UIO/INTC).
    reg.reset();

    // Reclaim any cached UIO/INTC that no registration references anymore.
    // use_count == 1 means only the cache map holds it; erasing drops the
    // last ref and runs the destructor (which closes the UIO fd).
    for (auto uio_it = uio_devices_.begin(); uio_it != uio_devices_.end(); )
    {
        if (uio_it->second.use_count() == 1)
            uio_it = uio_devices_.erase(uio_it);
        else
            ++uio_it;
    }
    for (auto intc_it = intc_controllers_.begin(); intc_it != intc_controllers_.end(); )
    {
        if (intc_it->second.use_count() == 1)
            intc_it = intc_controllers_.erase(intc_it);
        else
            ++intc_it;
    }

    wake_epoll();
    return grpc::Status::OK;
}

void InterruptImpl::invalidate_all_internal()
{
#ifdef DEBUG
    std::cout << "InterruptImpl: invalidate_all_internal()" << std::endl;
#endif

    std::lock_guard<std::mutex> lock(global_mtx_);

    for (auto &[id, reg] : registrations_)
    {
        {
            std::lock_guard<std::mutex> reg_lock(reg->mtx);
            reg->invalidated.store(true);
        }
        reg->cv.notify_all();
    }

    // Eagerly close UIO fds and mark them -1. Waiter-held UioDevices
    // survive past the map clear via shared_ptr, but their fds are now
    // inert so no further IRQ activity is possible. The UioDevice
    // destructor's check (fd >= 0) prevents a double-close.
    for (auto &[irq, uio] : uio_devices_)
    {
        if (uio->fd >= 0)
        {
            close(uio->fd);
            uio->fd = -1;
        }
    }

    uio_devices_.clear();
    intc_controllers_.clear();
    registrations_.clear();

    wake_epoll();
}
