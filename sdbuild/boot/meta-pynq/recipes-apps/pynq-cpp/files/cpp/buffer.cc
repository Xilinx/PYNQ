#include "buffer.h"

#define DEBUG

XrtBufferManager::XrtBufferManager(const xrt::device &device_p) : device(device_p) 
{
    device=device_p;
}

xrt::bo XrtBufferManager::allocate_bo(size_t size, bool cacheable)
{
    try
        {
            xrt::bo::flags buffer_flags = xrt::bo::flags::normal; // or cacheable
            if (cacheable)
            {
                buffer_flags = xrt::bo::flags::cacheable; // or cacheable     
            }
            xrt::memory_group memory_grp = 0; // uint32 obtained from kernel agrument?
            xrt::bo buffer = xrt::bo(device, size, buffer_flags, memory_grp);
            return buffer;
        }
        catch (const std::exception &e)
        {
            std::cerr << "Failed to allocate buffer object: " << e.what() << std::endl;
            throw;
        }
}

void XrtBufferManager::free_bo(xrt::bo &bo)
{
    // Properly release the resources held by the buffer object
    bo = xrt::bo();
}

void XrtBufferManager::write_bo(xrt::bo &bo, const uint8_t *data, size_t size)
{
    try
    {
        bo.write(data, size, 0);
    }
    catch (const std::exception &e)
    {
        throw std::runtime_error("Failed to write to buffer object: " + std::string(e.what()));
    }
}

std::vector<uint8_t> XrtBufferManager::read_bo(xrt::bo &bo, size_t size)
{
    std::vector<uint8_t> data(size);
    try
    {
        bo.read(data.data(), size, 0);
    }
    catch (const std::exception &e)
    {
        throw std::runtime_error("Failed to read from buffer object: " + std::string(e.what()));
    }
    return data;
}

xrt::memory_group XrtBufferManager::get_bo_properties(const xrt::bo &bo) const
{
    try
    {
        return bo.get_memory_group();
    }
    catch (const std::exception &e)
    {
        throw std::runtime_error("Failed to get buffer object properties: " + std::string(e.what()));
    }
}

char* XrtBufferManager::map_bo(xrt::bo &bo, bool write)
{
    try
    {
        return static_cast<char *>(bo.map());
    }
    catch (const std::exception &e)
    {
        throw std::runtime_error("Failed to map buffer object: " + std::string(e.what()));
    }
}

void XrtBufferManager::flush_bo(xrt::bo &bo)
{
    try
    {
        bo.sync(xclBOSyncDirection::XCL_BO_SYNC_BO_TO_DEVICE);
    }
    catch (const std::exception &e)
    {
        throw std::runtime_error("Failed to flush buffer object: " + std::string(e.what()));
    }
}

void XrtBufferManager::invalidate_bo(xrt::bo &bo)
{
    try
    {
        bo.sync(xclBOSyncDirection::XCL_BO_SYNC_BO_FROM_DEVICE);
    }
    catch (const std::exception &e)
    {
        throw std::runtime_error("Failed to invalidate buffer object: " + std::string(e.what()));
    }
}

BufferRemote::BufferRemote(const size_t size, const std::string &dtype, XrtBufferManager &xrt_manager, bool cacheable)
    : size_(0), manager_(xrt_manager), freed_(false), cacheable_(false)
{
    cacheable_ = cacheable;
    size_ = size;
    bo_ = manager_.allocate_bo(size_, cacheable_);
    if (!bo_)
    {
        throw std::runtime_error("Failed to allocate buffer object.");
    }
    data_ = reinterpret_cast<uint8_t *>(manager_.map_bo(bo_, true));
    if (!data_)
    {
        throw std::runtime_error("Failed to map buffer object.");
    }
    std::cout << "RemoteBuffer Memory mapped to: " << static_cast<void *>(data_) << std::endl;
    ;
}

BufferRemote::~BufferRemote()
{
    free();
}

uintptr_t BufferRemote::virtual_address() const
{
    return reinterpret_cast<uintptr_t>(data_);
}

uint64_t BufferRemote::physical_address() const
{
    return bo_.address();
}

void BufferRemote::flush()
{
    manager_.flush_bo(bo_);
}

void BufferRemote::invalidate()
{
    manager_.invalidate_bo(bo_);
}

void BufferRemote::sync_to_device()
{
    manager_.write_bo(bo_, data_, size_);
}

void BufferRemote::sync_from_device()
{
    std::vector<uint8_t> temp = manager_.read_bo(bo_, size_);
    std::memcpy(data_, temp.data(), size_);
}

void BufferRemote::free()
{
    if (!freed_)
    {
        manager_.free_bo(bo_);
        data_ = nullptr;
        freed_ = true;
    }
}

bool BufferRemote::cacheable()
{
    return cacheable_;
}


size_t BufferRemote::get_element_size(const std::string &dtype)
{
    static const std::unordered_map<std::string, size_t> dtype_size_map = {
        {"<int8", sizeof(int8_t)},
        {"<uint8", sizeof(uint8_t)},
        {"<int16", sizeof(int16_t)},
        {"<uint16", sizeof(uint16_t)},
        {"<int32", sizeof(int32_t)},
        {"<uint32", sizeof(uint32_t)},
        {"<int64", sizeof(int64_t)},
        {"<uint64", sizeof(uint64_t)},
        {"<float", sizeof(float)},
        {"<double", sizeof(double)},
        {"<i1", sizeof(int8_t)},
        {"<u1", sizeof(uint8_t)},
        {"<i2", sizeof(int16_t)},
        {"<u2", sizeof(uint16_t)},
        {"<i4", sizeof(int32_t)},
        {"<u4", sizeof(uint32_t)},
        {"<i8", sizeof(int64_t)},
        {"<u8", sizeof(uint64_t)},
        {"|int8", sizeof(int8_t)},
        {"|uint8", sizeof(uint8_t)},
        {"|int16", sizeof(int16_t)},
        {"|uint16", sizeof(uint16_t)},
        {"|int32", sizeof(int32_t)},
        {"|uint32", sizeof(uint32_t)},
        {"|int64", sizeof(int64_t)},
        {"|uint64", sizeof(uint64_t)},
        {"|float", sizeof(float)},
        {"|double", sizeof(double)},
        {"|i1", sizeof(int8_t)},
        {"|u1", sizeof(uint8_t)},
        {"|i2", sizeof(int16_t)},
        {"|u2", sizeof(uint16_t)},
        {"|i4", sizeof(int32_t)},
        {"|u4", sizeof(uint32_t)},
        {"|i8", sizeof(int64_t)},
        {"|u8", sizeof(uint64_t)}};

    auto it = dtype_size_map.find(dtype);
    if (it != dtype_size_map.end())
    {
        return it->second;
    }
    else
    {
        throw std::invalid_argument("Unsupported data type: " + dtype);
    }
}
