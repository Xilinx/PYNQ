#ifndef DEVICE_H
#define DEVICE_H

#include <string>
#include <fstream>
#include <iostream>
#include <utility>
#include <filesystem>
#include <stdexcept>

class Device
{
    /**
     * @class Device
     * @brief Contains functionality for managing the PYNQ device. 
        Interacts with the local filesystem and device drivers.
     */
private:
    std::string binfile_name;                                               ///< Name of the bitstream file
    bool partial;                                                           ///< Indicates if the bitstream is partial
    const std::string FIRMWARE;                                             ///< Directory for bitstream files
    const std::string BS_FPGA_MAN;                                          ///< FPGA manager firmware path
    const std::string BS_FPGA_MAN_FLAGS;                                    ///< FPGA manager flags path

    /**
     * @brief Writes content to a file. 
     * Writes the given content to the specified filepath.
     * @param filename Name of the file.
     * @param content Content to write.
     */
    void write_to_file(const std::string &filename, const std::string &content);

public:
    Device();

    /**
     * @brief Sets the name of the file to be downloaded to the device. This is to be run before the download function. 
     * @param binfile_name Name of the bitstream (.bin) file.
     * @param partial Indicates if the bitstream is partial. Partial Bitstreams are used for dynamic partial reconfiguration and are not yet tested.
     */
    void set_bitstream_attrs(const std::string &binfile_name, bool partial);

    /**
     * @brief Gets attributes for the bitstream file. Use this function to confirm the bitstream file name and partial flag before downloading.
     * @return A pair containing the name of the bitstream file that is stored in the device object, and the partial bitstream flag.
     */
    std::pair<std::string, bool> get_bitstream_attrs() const;

    /**
     * @brief Downloads the bitstream data to the FPGA. Ensure that the file exists in /lib/firmware by using write_to_file(). 
     * 
     * @param binfile_name Name of the bitstream file.
     * @return True if the download is successful, false otherwise. Will return {filename} does not exist if the file is not found in /lib/firmware.
     */
    bool download(std::string binfile_name);
};

#endif // DEVICE_H
