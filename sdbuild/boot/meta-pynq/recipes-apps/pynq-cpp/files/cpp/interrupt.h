#ifndef INTERRUPT_H
#define INTERRUPT_H

#include <string>
#include <memory>
#include <unordered_map>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <thread>
#include <unistd.h>

#include <grpcpp/grpcpp.h>
#include <interrupt.grpc.pb.h>

#include "mmio.h"

class InterruptImpl final : public interrupt::RemoteInterrupt::Service
{
    /**
     * @class InterruptImpl
     * @brief gRPC service for remote FPGA interrupt handling.
     *
     * Hosts a single background epoll thread that waits on all open UIO file
     * descriptors and dispatches IRQ events to per-registration condition
     * variables awaited by gRPC clients. AXI INTC controllers are managed as
     * singletons per physical address and demultiplexed in user space.
     *
     * UioDevice, IntcController, and InterruptRegistration are all shared_ptr
     * managed: each Registration holds shared_ptr copies of the UIO and INTC
     * it references, so concurrent release or bitstream invalidation cannot
     * destroy them out from under a blocked waiter. In-flight waits use a
     * 1-second heartbeat to bound cancellation latency.
     */
public:
    /**
     * @brief Constructor. Creates the epoll instance, self-pipe wake fd,
     * and starts the background dispatch thread.
     */
    InterruptImpl();

    /**
     * @brief Destructor. Wakes any in-flight waiters with an invalidate,
     * joins the epoll thread, and closes all owned file descriptors.
     */
    ~InterruptImpl();

    InterruptImpl(const InterruptImpl &) = delete;
    InterruptImpl &operator=(const InterruptImpl &) = delete;
    InterruptImpl(InterruptImpl &&) = delete;
    InterruptImpl &operator=(InterruptImpl &&) = delete;

    /**
     * @brief Register a new interrupt for a client.
     * @param context gRPC server context.
     * @param request Pin name + Linux raw IRQ + INTC physical address + pin index.
     * @param response interrupt_id on success, msg on failure.
     * @return OK on success; NOT_FOUND, INVALID_ARGUMENT, or INTERNAL on failure.
     */
    grpc::Status register_interrupt(
        grpc::ServerContext *context,
        const interrupt::RegisterRequest *request,
        interrupt::RegisterResponse *response) override;

    /**
     * @brief Block until the registered interrupt fires.
     * Holds shared_ptr copies of the registration, its UIO, and its INTC
     * for the wait's duration so concurrent release/invalidate cannot
     * destroy them.
     * @param context gRPC server context (polled for client cancellation).
     * @param request interrupt_id + optional timeout in milliseconds.
     * @param response Status (FIRED, TIMEOUT, ERROR) and optional message.
     * @return OK if FIRED or TIMEOUT, CANCELLED on invalidation/release/client cancel.
     */
    grpc::Status wait_for_interrupt(
        grpc::ServerContext *context,
        const interrupt::WaitRequest *request,
        interrupt::WaitResponse *response) override;

    /**
     * @brief Release a registration. Wakes any in-flight waiter, then
     * erases the map entry. UIO and INTC are reclaimed automatically when
     * their shared_ptr ref counts drop to one (only the cache map holds).
     * @param context gRPC server context.
     * @param request interrupt_id to release.
     * @param response Optional message.
     * @return Always OK (unknown ids are ignored).
     */
    grpc::Status release_interrupt(
        grpc::ServerContext *context,
        const interrupt::ReleaseRequest *request,
        interrupt::ReleaseResponse *response) override;

    /**
     * @brief Invalidate all registrations after a bitstream reload.
     * Sets invalidated on every registration, notifies waiters, closes
     * UIO fds eagerly, and clears the maps. Waiter-held UioDevices and
     * IntcControllers survive until the waiters return, but their fds are
     * already closed so further IRQ activity is impossible.
     */
    void invalidate_all_internal();

private:
    /**
     * @struct UioDevice
     * @brief RAII handle to one /dev/uioN. The destructor closes the fd.
     * Lifetime managed by shared_ptr; the uio_devices_ map and every
     * referring InterruptRegistration each hold a copy.
     */
    struct UioDevice
    {
        int fd = -1;
        uint32_t raw_irq = 0;
        ~UioDevice() { if (fd >= 0) close(fd); }
    };

    /**
     * @struct IntcController
     * @brief Singleton AXI INTC controller wrapper, shared_ptr managed.
     * One instance per controller physical address; cached in the
     * intc_controllers_ map and referenced by every InterruptRegistration
     * that uses it. parent_raw_irq is the Linux IRQ of the UIO this INTC
     * is cascaded behind; used by epoll_loop for dispatch.
     */
    struct IntcController
    {
        std::unique_ptr<MMIO> mmio;
        uint64_t phys_addr = 0;
        std::mutex mtx;
        uint32_t parent_raw_irq = 0;
    };

    /**
     * @struct InterruptRegistration
     * @brief One client's interest in a specific interrupt pin.
     * Owned via shared_ptr in registrations_; each in-flight waiter holds
     * its own shared_ptr copy. Holds shared_ptrs to its UIO and INTC so
     * concurrent release/invalidate cannot destroy them while a wait is
     * in flight. intc is nullptr for direct-UIO (PS GIC) pins.
     */
    struct InterruptRegistration
    {
        std::string interrupt_id;
        std::string pin_name;
        uint32_t pin_index = 0;
        std::shared_ptr<IntcController> intc;
        std::shared_ptr<UioDevice> uio;
        std::mutex mtx;
        std::condition_variable cv;
        std::atomic<bool> fired{false};
        std::atomic<bool> invalidated{false};
        std::atomic<bool> released{false};
    };

    /**
     * @brief Map a raw Linux IRQ to a UIO device path.
     * @param raw_irq The Linux virtual IRQ number to look up.
     * @return Path to the UIO device, or empty string if not found.
     */
    std::string find_uio_device(uint32_t raw_irq);

    /**
     * @brief Background thread entry. Waits on the epoll set and
     * dispatches IRQ events to registered waiters via condition variables.
     */
    void epoll_loop();

    /**
     * @brief Wake the epoll loop by writing one byte to the self-pipe.
     */
    void wake_epoll();

    // Maps keyed by, respectively: controller phys_addr, raw IRQ,
    // and interrupt_id. All three and id_counter_ are protected by
    // global_mtx_.
    std::unordered_map<uint64_t, std::shared_ptr<IntcController>> intc_controllers_;
    std::unordered_map<uint32_t, std::shared_ptr<UioDevice>> uio_devices_;
    std::unordered_map<std::string, std::shared_ptr<InterruptRegistration>> registrations_;
    std::mutex global_mtx_;

    int epoll_fd_ = -1;
    int pipe_read_fd_ = -1;
    int pipe_write_fd_ = -1;
    std::thread epoll_thread_;
    std::atomic<bool> shutdown_{false};
    uint64_t id_counter_ = 0;
};

#endif // INTERRUPT_H
