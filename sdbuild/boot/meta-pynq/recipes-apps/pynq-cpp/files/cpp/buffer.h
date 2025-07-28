// Description: Header file for the buffer manager and remote buffer classes.
#ifndef XRT_BUFFER_MANAGER_H
#define XRT_BUFFER_MANAGER_H

#include <map>
#include <string>
#include <stdexcept>
#include <cstdint>
#include <iostream>
#include <vector>
#include <unordered_map>
#include <numeric>
#include <functional>
#include <cstring>
#include <sys/mman.h>

#include <xrt/xclhal2.h>
#include <xrt/xrt.h>
#include <xrt/xrt_bo.h>
#include <xrt/xrt_device.h>

/**
 * @class XrtBufferManager
 * @brief Manages buffer operations for XRT (Xilinx Runtime) devices.
 *
 * This class provides methods to allocate, free, write, read, map, and manage
 * properties of contiguous memory buffers on XRT devices. It also provides methods for flushing and invalidating
 * the contents of buffers to ensure data consistency between the host and device.
 * Initialise it with the device handle obtained from xrt::device::open() or similar methods. 
 
 * This class is designed to be used by the BufferRemote class, which provides a higher-level interface for managing individual buffers.
 */
class XrtBufferManager
{
private:
    xrt::device device;

public:
/**
 * @brief Constructs a new XrtBufferManager object. 
 * Use this constructor to initialize the buffer manager with a specific XRT device obtained from xrt::device::open() or similar methods.
 * 
 * @param device The handle to the XRT device.
 */
    XrtBufferManager(const xrt::device &device_p);
/**
 * @brief Allocates a buffer object (BO) on the device.
 * 
 * @param size The size of the buffer to allocate in bytes.
 * @param cacheable Indicates if the buffer should have the cacheable flag enabled.
 * @return The handle to the allocated buffer.
 */
    xrt::bo allocate_bo(size_t size, bool cacheable);
/**
 * @brief Frees a previously allocated buffer object (BO).
 * 
 * @param bo The handle to the buffer to free.
 * @param nbytes The size of the buffer.
 * @param virtual_address The virtual address of the buffer.
 */
    void free_bo(xrt::bo &bo);
/**
 * @brief Writes data to a buffer object (BO).
 * 
 * @param bo The handle to the buffer.
 * @param data The data to write to the buffer.
 * @param size The size of the data to write.
 */
    void write_bo(xrt::bo &bo, const uint8_t *data, size_t size);
/**
 * @brief Reads data from a buffer object (BO).
 * 
 * @param bo The handle to the buffer. 
 * @param size The size of the data to read in bytes.
 * @return A vector containing the read data.
 */
    std::vector<uint8_t> read_bo(xrt::bo &bo, size_t size);
/**
 * @brief Maps a buffer object (BO) to the host's address space.
 * 
 * @param bo The handle to the buffer.
 * @param write Indicates if the buffer should be mapped for writing.
 * @return A pointer to the mapped buffer.
 */
    char *map_bo(xrt::bo &bo, bool write = false);
/**
 * @brief Retrieves the memory_group of a buffer object (BO).
 * 
 * @param bo The handle to the buffer.
 * @return The memory_group of the buffer.
 */
    xrt::memory_group get_bo_properties(const xrt::bo &bo) const;

/**
 * @brief Flushes the contents of a buffer object (BO) to the device.
 * 
 * @param bo The handle to the buffer.
 */
    void flush_bo(xrt::bo &bo);

/**
 * @brief Invalidates the contents of a buffer object (BO) in the cache.
 * 
 * @param bo The handle to the buffer.
 */
    void invalidate_bo(xrt::bo &bo);
};


/**
 * @class BufferRemote
 * @brief A class that provides an interface for individual contiguous memory buffers using the XrtBufferManager.
 *
 * This class provides an instance to of contiguous memory buffers, including wrapped functionality for buffer
 * allocation, synchronization, and cache management. 
 * This class is designed to be used with the XrtBufferManager, which manages the underlying buffer operations on the XRT device.
 *
 * @param size A value representing the shape of the buffer in bytes.
 * @param dtype A string representing the data type of the buffer elements.
 * @param xrt_manager A reference to the XrtBufferManager for buffer management.
 * @param cacheable A boolean indicating if the buffer is cacheable.
 */
class BufferRemote
{
public:
    size_t size_;
    uint8_t *data_;
    bool cacheable_;

    /**
     * @brief Constructor for BufferRemote. 
     * This class wraps the XRT buffer management functionality and provides a convenient interface for buffer operations.
     *
     * Create an instance of this class and provide the XrtBufferManager, and a buffer will be allocated on the device. 
     * The data_ member of this instance will point to the memory mapped region of the allocated buffer, allowing for direct access to the buffer data.
     * This class includes some other functions to wrap management of the individual buffers, such as flushing, invalidating, and synchronizing the buffer to/from the device.
     *
     * @param size A value representing the size of the buffer in bytes.
     * @param dtype A string representing the data type of the buffer elements.
     * @param xrt_manager A reference to the XrtBufferManager for buffer management.
     * @param cacheable A boolean indicating if the buffer is cacheable.
     */
    BufferRemote(const size_t size, const std::string &dtype, XrtBufferManager &xrt_manager, bool cacheable);


    /**
     * @brief Destructor for BufferRemote.
     */
    ~BufferRemote();

    /**
     * @brief Get the virtual address of the buffer.
     * @return The virtual address of the buffer.
     */
    uintptr_t virtual_address() const;

    /** 
      * @brief Get the physical address of the buffer.
      * @return The physical address of the buffer.
      */
    uint64_t physical_address() const;

    /**
    * @brief Flush the buffer to ensure data is written to the device.
    */
    void flush();

    /**
      * @brief Invalidate the buffer to ensure data is read from the device.
      */
    void invalidate();

    /**
     * @brief Synchronize the buffer to the device.
     */
    void sync_to_device();

    /**
     * @brief Synchronize the buffer from the device.
     */
    void sync_from_device();

    /**
     * @brief Free the buffer resources.
     */
    void free();

    /**
     * @brief Check if the buffer is cacheable.
     * @return True if the buffer is cacheable, false otherwise.
     */
    bool cacheable();

private:
    std::vector<size_t> shape_;
    size_t element_size_;
    XrtBufferManager &manager_;
    xrt::bo bo_;
    bool freed_;

    /**
      * @brief Get the size of an element based on its data type.
      * @param dtype The data type of the element.
      * @return The size of the element.
      */
    size_t get_element_size(const std::string &dtype);
};

#endif //XRT_BUFFER_MANAGER_H
