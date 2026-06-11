#include "xrfclk.h"
#include <filesystem>
#include <fstream>
#include <stdexcept>
#include <cstring>
#include <cmath>
#include <cctype>
#include <algorithm>

#ifdef DEBUG
#include <iostream>
#endif

namespace fs = std::filesystem;

// Constructor
XRFCLK::XRFCLK() : devices_initialized_(false), tics_dir_("/usr/share/xrfclk") {
    // Discover devices on construction
    findDevices();
}

// Destructor
XRFCLK::~XRFCLK() {
    // No cleanup needed - RAII handles all resource management
}

// Helper function: Read file content as string
std::string XRFCLK::readFile(const fs::path& filepath) {
    std::ifstream file(filepath);
    if (!file) {
        throw std::runtime_error("Failed to open file: " + filepath.string());
    }

    std::string content;
    std::getline(file, content, '\0'); // Read until null terminator
    return content;
}

// Helper function: Read binary file
std::vector<uint8_t> XRFCLK::readBinaryFile(const fs::path& filepath) {
    std::ifstream file(filepath, std::ios::binary);
    if (!file) {
        throw std::runtime_error("Failed to open file: " + filepath.string());
    }

    return std::vector<uint8_t>(
        (std::istreambuf_iterator<char>(file)),
        std::istreambuf_iterator<char>()
    );
}

// Helper function: Get SPI device path
std::string XRFCLK::getSpidevPath(const fs::path& dev) {
    fs::path spidev_dir = dev / "spidev";

    if (!fs::exists(spidev_dir)) {
        throw std::runtime_error("spidev directory not found for device: " + dev.string());
    }

    // Get first entry in spidev directory
    for (const auto& entry : fs::directory_iterator(spidev_dir)) {
        return "/dev/" + entry.path().filename().string();
    }

    throw std::runtime_error("No spidev entry found in: " + spidev_dir.string());
}

// Helper function: Bind SPI device to spidev driver
void XRFCLK::spidevBind(const fs::path& dev) {
    std::string dev_name = dev.filename().string();

    // Write 'spidev' to driver_override
    fs::path driver_override = dev / "driver_override";
    std::ofstream override_file(driver_override);
    if (!override_file) {
        throw std::runtime_error("Failed to open driver_override: " + driver_override.string());
    }
    override_file << "spidev";
    override_file.close();

    // Bind to spidev driver
    fs::path bind_path = "/sys/bus/spi/drivers/spidev/bind";
    std::ofstream bind_file(bind_path);
    if (!bind_file) {
        throw std::runtime_error("Failed to open bind file: " + bind_path.string());
    }
    bind_file << dev_name;
    bind_file.close();
}

// Main device discovery function
void XRFCLK::findDevices() {
    if (devices_initialized_) {
        return;
    }

    lmk_devices_.clear();
    lmx_devices_.clear();

    fs::path spi_devices_path = "/sys/bus/spi/devices";

    if (!fs::exists(spi_devices_path)) {
        throw std::runtime_error("SPI devices path not found: " + spi_devices_path.string());
    }

    // Loop through each SPI device
    for (const auto& dev_entry : fs::directory_iterator(spi_devices_path)) {
        fs::path dev = dev_entry.path();
        fs::path compatible_path = dev / "of_node" / "compatible";

        // Skip if compatible file doesn't exist
        if (!fs::exists(compatible_path)) {
            continue;
        }

        // Read compatible string (e.g., "ti,lmx2594")
        std::string compatible_full = readFile(compatible_path);

        // Strip company name (first 3 chars + comma) to get chip name
        // e.g., "ti,lmx2594" -> "lmx2594"
        if (compatible_full.length() < 4) {
            continue;
        }
        std::string compatible = compatible_full.substr(3);

        // Remove trailing null/newline characters
        compatible.erase(std::remove(compatible.begin(), compatible.end(), '\0'), compatible.end());
        compatible.erase(std::remove(compatible.begin(), compatible.end(), '\n'), compatible.end());

        // Check if it's LMK or LMX device
        if (compatible.substr(0, 3) != "lmk" && compatible.substr(0, 3) != "lmx") {
            continue;
        }

#ifdef DEBUG
        std::cout << "Found device: " << compatible << " at " << dev.string() << std::endl;
#endif

        // Unbind from current driver if necessary
        fs::path driver_path = dev / "driver";
        if (fs::exists(driver_path)) {
            fs::path unbind_path = driver_path / "unbind";
            std::ofstream unbind_file(unbind_path);
            if (unbind_file) {
                unbind_file << dev.filename().string();
                unbind_file.close();
            }
        }

        // Bind to spidev driver
        spidevBind(dev);

        // Add to appropriate device list
        if (compatible.substr(0, 3) == "lmk") {
            LmkDevice lmk_dev;
            lmk_dev.spi_device = getSpidevPath(dev);
            lmk_dev.compatible = compatible;

            // Read num_bytes from device tree
            fs::path num_bytes_path = dev / "of_node" / "num_bytes";
            if (!fs::exists(num_bytes_path)) {
                throw std::runtime_error("Device tree property 'num_bytes' not found for LMK device: " +
                                    compatible + " at " + dev.string() +
                                    ". Check BSP configuration.");
            }

            std::vector<uint8_t> num_bytes_data = readBinaryFile(num_bytes_path);
            if (num_bytes_data.size() < 4) {
                throw std::runtime_error("Device tree property 'num_bytes' is corrupted (size=" +
                                    std::to_string(num_bytes_data.size()) +
                                    ") for LMK device: " + compatible +
                                    ". Expected 4 bytes.");
            }

            // Unpack as big-endian uint32
            lmk_dev.num_bytes = (static_cast<uint32_t>(num_bytes_data[0]) << 24) |
                            (static_cast<uint32_t>(num_bytes_data[1]) << 16) |
                            (static_cast<uint32_t>(num_bytes_data[2]) << 8) |
                                static_cast<uint32_t>(num_bytes_data[3]);

            // Validate the value is sensible (3 or 4)
            if (lmk_dev.num_bytes != 3 && lmk_dev.num_bytes != 4) {
                throw std::runtime_error("Invalid num_bytes value (" +
                                    std::to_string(lmk_dev.num_bytes) +
                                    ") for LMK device: " + compatible +
                                    ". Expected 3 or 4.");
            }

#ifdef DEBUG
            std::cout << "LMK device: " << lmk_dev.spi_device
                     << ", compatible: " << lmk_dev.compatible
                     << ", num_bytes: " << lmk_dev.num_bytes << std::endl;
#endif

            lmk_devices_.push_back(lmk_dev);

        } else { // lmx
            LmxDevice lmx_dev;
            lmx_dev.spi_device = getSpidevPath(dev);
            lmx_dev.compatible = compatible;

#ifdef DEBUG
            std::cout << "LMX device: " << lmx_dev.spi_device
                     << ", compatible: " << lmx_dev.compatible << std::endl;
#endif

            lmx_devices_.push_back(lmx_dev);
        }
    }

    // Validate that devices were found
    if (lmk_devices_.empty()) {
        throw std::runtime_error("SPI path not set. LMK not found on device tree. Issue with BSP.");
    }
    if (lmx_devices_.empty()) {
        throw std::runtime_error("SPI path not set. LMX not found on device tree. Issue with BSP.");
    }

    devices_initialized_ = true;
}

// Get device names for client validation
std::pair<std::string, std::string> XRFCLK::getDeviceNames() {
    if (!devices_initialized_) {
        findDevices();
    }

    // Return first LMK and LMX device names (assuming all LMX devices are same type)
    std::string lmk_name = lmk_devices_.empty() ? "" : lmk_devices_[0].compatible;
    std::string lmx_name = lmx_devices_.empty() ? "" : lmx_devices_[0].compatible;

    return std::make_pair(lmk_name, lmx_name);
}

void XRFCLK::writeLmkRegs(const std::vector<uint32_t>& reg_vals) {
    if (!devices_initialized_) {
        findDevices();
    }

    if (lmk_devices_.empty()) {
        throw std::runtime_error("No LMK devices found");
    }

    // Use the first LMK device (assuming single device)
    const LmkDevice& lmk = lmk_devices_[0];

#ifdef DEBUG
    std::cout << "Writing " << reg_vals.size() << " registers to LMK device: "
              << lmk.spi_device << " with " << lmk.num_bytes << " bytes per register" << std::endl;
    std::cout << "First 5 register values: ";
    for (size_t i = 0; i < std::min(size_t(5), reg_vals.size()); i++) {
        std::cout << "0x" << std::hex << reg_vals[i] << std::dec << " ";
    }
    std::cout << std::endl;
#endif

    // Open SPI device using file descriptor (unbuffered, like Python's buffering=0)
    int fd = open(lmk.spi_device.c_str(), O_WRONLY);
    if (fd < 0) {
        throw std::runtime_error("Failed to open SPI device: " + lmk.spi_device +
                               " (error: " + std::string(strerror(errno)) + ")");
    }

    // Write each register value
    for (uint32_t val : reg_vals) {
        // Pack as big-endian 32-bit value (matches Python's struct.pack('>I', v))
        uint8_t data[4];
        data[0] = (val >> 24) & 0xFF;
        data[1] = (val >> 16) & 0xFF;
        data[2] = (val >> 8) & 0xFF;
        data[3] = val & 0xFF;

        // Write appropriate number of bytes based on device tree
        ssize_t bytes_written;
        if (lmk.num_bytes == 3) {
            // Write last 3 bytes (matches Python's data[1:])
            bytes_written = write(fd, &data[1], 3);
            if (bytes_written != 3) {
                close(fd);
                throw std::runtime_error("Failed to write to SPI device (expected 3 bytes, wrote " +
                                       std::to_string(bytes_written) + ")");
            }
        } else {
            // Write all 4 bytes
            bytes_written = write(fd, data, 4);
            if (bytes_written != 4) {
                close(fd);
                throw std::runtime_error("Failed to write to SPI device (expected 4 bytes, wrote " +
                                       std::to_string(bytes_written) + ")");
            }
        }
    }

    close(fd);

#ifdef DEBUG
    std::cout << "Successfully wrote LMK registers" << std::endl;
#endif
}

// Write LMX registers
void XRFCLK::writeLmxRegs(const std::vector<uint32_t>& reg_vals) {
    if (!devices_initialized_) {
        findDevices();
    }

    if (lmx_devices_.empty()) {
        throw std::runtime_error("No LMX devices found");
    }

    // Write to all LMX devices (typically ADC and DAC clocks)
    for (const LmxDevice& lmx : lmx_devices_) {

#ifdef DEBUG
        std::cout << "Writing " << reg_vals.size() << " registers to LMX device: "
                  << lmx.spi_device << std::endl;
        std::cout << "First 5 register values: ";
        for (size_t i = 0; i < std::min(size_t(5), reg_vals.size()); i++) {
            std::cout << "0x" << std::hex << reg_vals[i] << std::dec << " ";
        }
        std::cout << std::endl;
#endif

        // Open SPI device using file descriptor (unbuffered, like Python's buffering=0)
        int fd = open(lmx.spi_device.c_str(), O_WRONLY);
        if (fd < 0) {
            throw std::runtime_error("Failed to open SPI device: " + lmx.spi_device +
                                   " (error: " + std::string(strerror(errno)) + ")");
        }

        // Program RESET = 1 to reset registers (matches Python's reset = struct.pack('>I', 0x020000))
        uint8_t reset[3] = {0x02, 0x00, 0x00};
        if (write(fd, reset, 3) != 3) {
            close(fd);
            throw std::runtime_error("Failed to write reset command");
        }

        // Program RESET = 0 to remove reset (matches Python's remove_reset = struct.pack('>I', 0))
        uint8_t remove_reset[3] = {0x00, 0x00, 0x00};
        if (write(fd, remove_reset, 3) != 3) {
            close(fd);
            throw std::runtime_error("Failed to write reset removal command");
        }

        // Write each register value (skip first byte, write last 3 bytes)
        for (uint32_t val : reg_vals) {
            // Pack as big-endian 32-bit value (matches Python's struct.pack('>I', v))
            uint8_t data[4];
            data[0] = (val >> 24) & 0xFF;
            data[1] = (val >> 16) & 0xFF;
            data[2] = (val >> 8) & 0xFF;
            data[3] = val & 0xFF;

            // Write last 3 bytes (matches Python's data[1:])
            if (write(fd, &data[1], 3) != 3) {
                close(fd);
                throw std::runtime_error("Failed to write register to SPI device");
            }
        }

        // Program register R0 one additional time with FCAL_EN = 1
        // R0 is at index 112 (last element in 113-element array)
        if (reg_vals.size() > 112) {
            uint32_t r0_val = reg_vals[112];
            uint8_t stable[4];
            stable[0] = (r0_val >> 24) & 0xFF;
            stable[1] = (r0_val >> 16) & 0xFF;
            stable[2] = (r0_val >> 8) & 0xFF;
            stable[3] = r0_val & 0xFF;

            // Write last 3 bytes (matches Python's stable[1:])
            if (write(fd, &stable[1], 3) != 3) {
                close(fd);
                throw std::runtime_error("Failed to write final R0 register");
            }
        }

        close(fd);

#ifdef DEBUG
        std::cout << "Successfully wrote LMX registers to " << lmx.spi_device << std::endl;
#endif
    }
}

// Find <tics_dir_>/<CHIP>_<freq>.txt whose chip matches `compatible`
// (case-insensitive) and whose frequency equals `freq`. Returns "" if none.
std::string XRFCLK::findTicsFile(const std::string& compatible, double freq) {
    if (!fs::exists(tics_dir_) || !fs::is_directory(tics_dir_)) {
        return "";
    }

    for (const auto& entry : fs::directory_iterator(tics_dir_)) {
        if (!entry.is_regular_file()) {
            continue;
        }

        std::string fname = entry.path().filename().string();
        // Expect CHIP_FREQ.txt (e.g. LMK04828_245.76.txt)
        if (fname.size() < 5 || fname.substr(fname.size() - 4) != ".txt") {
            continue;
        }
        std::string stem = fname.substr(0, fname.size() - 4); // CHIP_FREQ

        std::size_t us = stem.find('_');
        if (us == std::string::npos) {
            continue;
        }
        std::string chip = stem.substr(0, us);
        std::string freq_str = stem.substr(us + 1);

        // Compare chip case-insensitively against the device compatible (lowercase).
        std::transform(chip.begin(), chip.end(), chip.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        if (chip != compatible) {
            continue;
        }

        double file_freq;
        try {
            file_freq = std::stod(freq_str);
        } catch (...) {
            continue;
        }
        if (std::fabs(file_freq - freq) < 1e-6) {
            return entry.path().string();
        }
    }

    return "";
}

// Parse hex register values from a TICS file: the first 0x... token on each line
// (matches the host-side parser).
std::vector<uint32_t> XRFCLK::parseRegFile(const fs::path& filepath) {
    std::ifstream file(filepath);
    if (!file) {
        throw std::runtime_error("Failed to open TICS file: " + filepath.string());
    }

    std::vector<uint32_t> regs;
    std::string line;
    while (std::getline(file, line)) {
        std::size_t pos = line.find("0x");
        if (pos == std::string::npos) {
            pos = line.find("0X");
        }
        if (pos == std::string::npos) {
            continue;
        }
        try {
            regs.push_back(static_cast<uint32_t>(std::stoul(line.substr(pos), nullptr, 16)));
        } catch (...) {
            continue;
        }
    }

    if (regs.empty()) {
        throw std::runtime_error("No register values found in TICS file: " + filepath.string());
    }
    return regs;
}

void XRFCLK::programLmk(double freq) {
    if (!devices_initialized_) {
        findDevices();
    }
    if (lmk_devices_.empty()) {
        throw std::runtime_error("No LMK devices found");
    }

    const std::string& compatible = lmk_devices_[0].compatible;
    std::string path = findTicsFile(compatible, freq);
    if (path.empty()) {
        throw TicsNotFound("No on-target TICS file for " + compatible + " at " +
                           std::to_string(freq) + " MHz in " + tics_dir_);
    }

    writeLmkRegs(parseRegFile(path));
}

void XRFCLK::programLmx(double freq) {
    if (!devices_initialized_) {
        findDevices();
    }
    if (lmx_devices_.empty()) {
        throw std::runtime_error("No LMX devices found");
    }

    const std::string& compatible = lmx_devices_[0].compatible;
    std::string path = findTicsFile(compatible, freq);
    if (path.empty()) {
        throw TicsNotFound("No on-target TICS file for " + compatible + " at " +
                           std::to_string(freq) + " MHz in " + tics_dir_);
    }

    writeLmxRegs(parseRegFile(path));
}

void XRFCLK::reset() {
    lmk_devices_.clear();
    lmx_devices_.clear();
    devices_initialized_ = false;
}

void XrfclkImpl::invalidate() {
    std::lock_guard<std::mutex> lk(mu_);
    xrfclk_instance_.reset();
}

grpc::Status XrfclkImpl::find_devices(grpc::ServerContext *context, const xrfclk::FindDevicesRequest *request, xrfclk::FindDevicesResponse *response)
{
    std::lock_guard<std::mutex> lk(mu_);
    #ifdef DEBUG
    std::cout << "Function: find_devices" << std::endl;
    #endif

    try {
        auto device_names = xrfclk_instance_.getDeviceNames();
        response->set_lmk_device(device_names.first);
        response->set_lmx_device(device_names.second);

        #ifdef DEBUG
        std::cout << "Found LMK device: " << device_names.first << std::endl;
        std::cout << "Found LMX device: " << device_names.second << std::endl;
        #endif
    }
    catch (const std::exception &e) {
        std::cerr << "Error finding devices: " << e.what() << std::endl;
        return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
    }

    return grpc::Status::OK;
}

grpc::Status XrfclkImpl::write_lmk_regs(grpc::ServerContext *context, const xrfclk::WriteLmkRegsRequest *request, xrfclk::WriteLmkRegsResponse *response)
{
    std::lock_guard<std::mutex> lk(mu_);
    #ifdef DEBUG
    std::cout << "Function: write_lmk_regs, "
              << "num_regs=" << request->reg_vals_size()
              << std::endl;
    #endif

    try {
        std::vector<uint32_t> reg_vals(request->reg_vals().begin(), request->reg_vals().end());

        xrfclk_instance_.writeLmkRegs(reg_vals);
    }
    catch (const std::exception &e) {
        std::cerr << "Error writing LMK registers: " << e.what() << std::endl;
        return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
    }

    return grpc::Status::OK;
}

grpc::Status XrfclkImpl::write_lmx_regs(grpc::ServerContext *context, const xrfclk::WriteLmxRegsRequest *request, xrfclk::WriteLmxRegsResponse *response)
{
    std::lock_guard<std::mutex> lk(mu_);
    #ifdef DEBUG
    std::cout << "Function: write_lmx_regs, "
              << "num_regs=" << request->reg_vals_size()
              << std::endl;
    #endif

    try {
        std::vector<uint32_t> reg_vals(request->reg_vals().begin(), request->reg_vals().end());

        xrfclk_instance_.writeLmxRegs(reg_vals);
    }
    catch (const std::exception &e) {
        std::cerr << "Error writing LMX registers: " << e.what() << std::endl;
        return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
    }

    return grpc::Status::OK;
}

grpc::Status XrfclkImpl::program_lmk(grpc::ServerContext *context, const xrfclk::ProgramLmkRequest *request, xrfclk::ProgramLmkResponse *response)
{
    std::lock_guard<std::mutex> lk(mu_);
    #ifdef DEBUG
    std::cout << "Function: program_lmk, freq=" << request->freq() << std::endl;
    #endif

    try {
        xrfclk_instance_.programLmk(request->freq());
    }
    catch (const TicsNotFound &e) {
        std::cerr << "LMK TICS not found: " << e.what() << std::endl;
        return grpc::Status(grpc::StatusCode::NOT_FOUND, e.what());
    }
    catch (const std::exception &e) {
        std::cerr << "Error programming LMK: " << e.what() << std::endl;
        return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
    }

    return grpc::Status::OK;
}

grpc::Status XrfclkImpl::program_lmx(grpc::ServerContext *context, const xrfclk::ProgramLmxRequest *request, xrfclk::ProgramLmxResponse *response)
{
    std::lock_guard<std::mutex> lk(mu_);
    #ifdef DEBUG
    std::cout << "Function: program_lmx, freq=" << request->freq() << std::endl;
    #endif

    try {
        xrfclk_instance_.programLmx(request->freq());
    }
    catch (const TicsNotFound &e) {
        std::cerr << "LMX TICS not found: " << e.what() << std::endl;
        return grpc::Status(grpc::StatusCode::NOT_FOUND, e.what());
    }
    catch (const std::exception &e) {
        std::cerr << "Error programming LMX: " << e.what() << std::endl;
        return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
    }

    return grpc::Status::OK;
}