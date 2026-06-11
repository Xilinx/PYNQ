#ifndef XRFCLK_H
#define XRFCLK_H

#include <iostream>
#include <vector>
#include <string>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <stdexcept>
#include <cstring>
#include <algorithm>
#include <mutex>
#include <fcntl.h>
#include <unistd.h>
#include <cerrno>
#include <grpcpp/grpcpp.h>
#include <xrfclk.grpc.pb.h>
#include <xrfclk.pb.h>

// Raised when no on-target TICS file matches the requested chip/frequency, so the
// service can map it to a gRPC NOT_FOUND (the host then reports "frequency not valid").
class TicsNotFound : public std::runtime_error {
public:
    explicit TicsNotFound(const std::string& msg) : std::runtime_error(msg) {}
};

class XRFCLK
{
private:
    // Device structures
    struct LmkDevice {
        std::string spi_device;
        std::string compatible;
        uint32_t num_bytes;
    };
    
    struct LmxDevice {
        std::string spi_device;
        std::string compatible;
    };
    
    // Member variables
    std::vector<LmkDevice> lmk_devices_;
    std::vector<LmxDevice> lmx_devices_;
    bool devices_initialized_;
    std::string tics_dir_;
    
    // Private helper methods
    std::string getSpidevPath(const std::filesystem::path& dev);
    void spidevBind(const std::filesystem::path& dev);
    std::string readFile(const std::filesystem::path& filepath);
    std::vector<uint8_t> readBinaryFile(const std::filesystem::path& filepath);
    void findDevices();

    // On-target TICS lookup/parse: find <tics_dir_>/<CHIP>_<freq>.txt for the given
    // device compatible (case-insensitive) and frequency, and parse its hex registers.
    std::string findTicsFile(const std::string& compatible, double freq);
    std::vector<uint32_t> parseRegFile(const std::filesystem::path& filepath);

public:
    XRFCLK();
    ~XRFCLK();

    // Get device names for client validation
    std::pair<std::string, std::string> getDeviceNames();
    
    void writeLmkRegs(const std::vector<uint32_t>& reg_vals);
    void writeLmxRegs(const std::vector<uint32_t>& reg_vals);

    // Program from the on-target TICS files by frequency (throws TicsNotFound if absent).
    void programLmk(double freq);
    void programLmx(double freq);

    /**
     * @brief Drop the cached device-discovery state.
     *
     * Clears the LMK/LMX device tables and the devices_initialized_ flag so
     * the next call re-walks /sys/bus/spi/devices. The class does not hold
     * any persistent file descriptors (each writeLm*Regs() opens and closes
     * the spidev fd within one call), so no fds need closing here.
     */
    void reset();
};

class XrfclkImpl final : public xrfclk::Xrfclk::Service
{
private:
    XRFCLK xrfclk_instance_;
    std::mutex mu_;

public:
    XrfclkImpl() : xrfclk_instance_() {
        #ifdef DEBUG
        std::cout << "XrfclkImpl initialized - devices discovered" << std::endl;
        #endif
    }

    /**
     * @brief Invalidate the cached clock-device state after a bitstream reload.
     *
     * The PL itself does not own the LMK/LMX SPI devices, but downstream
     * users typically reprogram the clocks after every overlay swap; resetting
     * the cache forces the next call to re-discover the spidev nodes (and
     * re-bind drivers if userspace tore them down between downloads).
     */
    void invalidate();

    grpc::Status find_devices(grpc::ServerContext *context, const xrfclk::FindDevicesRequest *request, xrfclk::FindDevicesResponse *response) override;
    grpc::Status write_lmk_regs(grpc::ServerContext *context, const xrfclk::WriteLmkRegsRequest *request, xrfclk::WriteLmkRegsResponse *response) override;
    grpc::Status write_lmx_regs(grpc::ServerContext *context, const xrfclk::WriteLmxRegsRequest *request, xrfclk::WriteLmxRegsResponse *response) override;
    grpc::Status program_lmk(grpc::ServerContext *context, const xrfclk::ProgramLmkRequest *request, xrfclk::ProgramLmkResponse *response) override;
    grpc::Status program_lmx(grpc::ServerContext *context, const xrfclk::ProgramLmxRequest *request, xrfclk::ProgramLmxResponse *response) override;
};

#endif // XRFCLK_H