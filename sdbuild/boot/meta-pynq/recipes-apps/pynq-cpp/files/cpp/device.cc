#include "device.h"

#define DEBUG


Device::Device()
    : binfile_name(""), partial(0), FIRMWARE("/lib/firmware/"), BS_FPGA_MAN("/sys/class/fpga_manager/fpga0/firmware"), BS_FPGA_MAN_FLAGS("/sys/class/fpga_manager/fpga0/flags")
{
    namespace fs = std::filesystem;

    // Check if FIRMWARE directory exists, if not create it
    if (!fs::exists(FIRMWARE))
    {
        if (!fs::create_directory(FIRMWARE))
        {
            throw std::runtime_error("Failed to create firmware directory: " + FIRMWARE);
        }
    }

    // Check if FPGA manager directory exists
    std::string fpga_manager_dir = "/sys/class/fpga_manager/fpga0/";
    if (!fs::exists(fpga_manager_dir))
    {
        throw std::runtime_error("FPGA manager directory does not exist: " + fpga_manager_dir);
    }
}

void Device::write_to_file(const std::string &filename, const std::string &content)
{
    std::ofstream file(filename);
    if (file.is_open())
    {
        file << content;
        file.close();
    }
    else
    {
        std::cout << "Error opening the file" << std::endl;
    }
}

void Device::set_bitstream_attrs(const std::string &binfile_name, bool partial)
{
    this->binfile_name = binfile_name;
    this->partial = partial;
#ifdef DEBUG
    std::cout << "set_bitstream_attrs received: " << binfile_name << " " << partial << std::endl;
#endif
}

std::pair<std::string, bool> Device::get_bitstream_attrs() const
{
#ifdef DEBUG
    std::cout << "get_bitstream_attrs returned: " << binfile_name << " " << partial << std::endl;
#endif
    return {binfile_name, partial};
}

bool Device::download(std::string binfile_name)
{
    std::string full_path = FIRMWARE + binfile_name;
    std::ifstream file(full_path);
    if (!file.good())
    {
        std::cerr << binfile_name << " does not exist in /lib/firmware." << std::endl;
        return false;
    }
    file.close();

    write_to_file(BS_FPGA_MAN_FLAGS, "0");
    write_to_file(BS_FPGA_MAN, binfile_name);
    return true;
}