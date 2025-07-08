#ifndef MMIO_H
#define MMIO_H

#include <iostream>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <cstdint>

class MMIO
{
    /**
     * @class MMIO
     * @brief Manages memory-mapped I/O (MMIO) operations. 
     Each instance of this class represents a memory-mapped region for reading and writing data.
     */
private:
    int mem_fd;        ///< File descriptor for memory access
    off_t virt_base;   ///< Base address for virtual memory
    off_t virt_offset; ///< Offset from the base address
    size_t length;        ///< Length of the memory region
    void *mapped_base; ///< Pointer to the mapped memory region

public:
    /**
     * @brief Constructor for MMIO.
     * Initializes memory mapping for the given base address and length.
     * @param base_address Base address for memory mapping.
     * @param length_p Length of the memory region.
     */
    MMIO(off_t base_address, size_t length_p);

    /**
     * @brief Destructor for MMIO.
     * Cleans up memory mapping and file descriptor.
     */
    ~MMIO();

    /**
     * @brief Reads a 32-bit value from the mapped memory.
     * @param offset Offset from the base address.
     * @return 32-bit value read from memory.
     */
    uint32_t read(uint64_t offset);

    /**
     * @brief Writes a 32-bit value to the mapped memory.
     * @param data 32-bit value to write.
     * @param offset Offset from the base address.
     */
    void write(uint32_t data, uint64_t offset);
};

#endif // MMIO_H