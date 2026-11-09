#include <iostream>
#include <memory>
#include <string>
#include <fstream>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstdint>
#include <cmath>
#include <vector>
#include <stdexcept>
#include <cstring>
#include <sys/types.h> // For off_t
#include <ctime>
#include <cstdlib>
#include <unordered_map>
#include <grpcpp/ext/proto_server_reflection_plugin.h>
#include <grpcpp/grpcpp.h>
#include <grpcpp/health_check_service_interface.h>
#include <numeric>
#include <limits>
#include <mutex>
#include <sstream>
#include <filesystem>


#include <remote_device.grpc.pb.h>
#include <mmio.grpc.pb.h>
#include <buffer.grpc.pb.h>
#include <gpio.grpc.pb.h>
#ifdef RFSOC
#include <xrfclk.grpc.pb.h>
#include <xrfdc.grpc.pb.h>
#endif

#include "buffer.cc"
#include "mmio.h"
#include "device.h"
#include "gpio.h"
#ifdef RFSOC
#include "xrfclk.h"
#include "xrfdc.h"
#endif

#include <xrt/xrt_bo.h>
#include <xrt/xrt_device.h>

// Namespaces from grpc.pb.h to simplify code
using buffer::AddressRequest;
using buffer::AddressResponse;
using buffer::AllocateRequest;
using buffer::AllocateResponse;
using buffer::BufferReadRequest;
using buffer::BufferReadResponse;
using buffer::BufferWriteRequest;
using buffer::BufferWriteResponse;
using buffer::CacheableRequest;
using buffer::CacheableResponse;
using buffer::FlushRequest;
using buffer::FlushResponse;
using buffer::FreeBufferRequest;
using buffer::FreeBufferResponse;
using buffer::InvalidateRequest;
using buffer::InvalidateResponse;
using buffer::RemoteBuffer;
using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::ServerReader;
using grpc::ServerWriter;
using grpc::Status;
using mmio::GetMmioRequest;
using mmio::GetMmioResponse;
using mmio::Mmio;
using mmio::ReleaseMmioRequest;
using mmio::ReleaseMmioResponse;
using mmio::ReadRequest;
using mmio::ReadResponse;
using mmio::WriteRequest;
using mmio::WriteResponse;
using remote_device::DownloadRequest;
using remote_device::DownloadResponse;
using remote_device::RemoteDevice;
using remote_device::SetBitstreamAttrsRequest;
using remote_device::SetBitstreamAttrsResponse;
using remote_device::SetPlClkRequest;
using remote_device::SetPlClkResponse;
using remote_device::ShutdownRequest;
using remote_device::ShutdownResponse;
using remote_device::CleanupRequest;
using remote_device::CleanupResponse;
using remote_device::ReadFileRequest;
using remote_device::ReadFileResponse;
using remote_device::WriteFileRequest;
using remote_device::WriteFileResponse;
using remote_device::ExistsFileRequest;
using remote_device::ExistsFileResponse;
using gpio::GetGpioRequest;
using gpio::GetGpioResponse;
using gpio::GpioReadRequest;
using gpio::GpioReadResponse;
using gpio::GpioWriteRequest;
using gpio::GpioWriteResponse;
using gpio::GpioUnexportRequest;
using gpio::GpioUnexportResponse;
using gpio::GpioIsExportedRequest;
using gpio::GpioIsExportedResponse;
using gpio::GetGpioBasePathRequest;
using gpio::GetGpioBasePathResponse;
using gpio::GetGpioNPinsRequest;
using gpio::GetGpioNPinsResponse;
using gpio::Gpio;
#ifdef RFSOC
using xrfclk::FindDevicesRequest;
using xrfclk::FindDevicesResponse;
using xrfclk::WriteLmkRegsRequest;
using xrfclk::WriteLmkRegsResponse;
using xrfclk::WriteLmxRegsRequest;
using xrfclk::WriteLmxRegsResponse;
using xrfclk::Xrfclk;
using xrfdc::CfgInitializeRequest;
using xrfdc::CfgInitializeResponse;
using xrfdc::GetIPStatusRequest;
using xrfdc::GetIPStatusResponse;
using xrfdc::TileControlRequest;
using xrfdc::TileControlResponse;
using xrfdc::SetupFIFORequest;
using xrfdc::DynamicPLLConfigRequest;
using xrfdc::GetFabRdVldWordsResponse;
using xrfdc::GetFabWrVldWordsResponse;
using xrfdc::GetDitherResponse;
using xrfdc::GetDecoderModeResponse;
using xrfdc::GetOutputCurrResponse;
using xrfdc::GetInvSincFIRResponse;
using xrfdc::GetDataPathModeResponse;
using xrfdc::GetIMRPassModeResponse;
using xrfdc::GetDACCompModeResponse;
#endif

namespace {

class HandleGenerator
{
private:
    uint64_t next_id_ = 0;
    bool exhausted_ = false;

public:
    bool try_generate(std::string &id_out)
    {
        if (exhausted_)
        {
            return false;
        }

        id_out = std::to_string(next_id_);
        if (next_id_ == std::numeric_limits<uint64_t>::max())
        {
            exhausted_ = true;
        }
        else
        {
            next_id_ += 1;
        }
        return true;
    }
};
grpc::Status handle_not_found_status(
    const std::string &resource,
    const std::string &operation,
    const std::string &id_name,
    const std::string &handle_id)
{
    std::ostringstream message;
    message << resource << " Object not found";
    message << " while handling " << operation << "() for "
            << id_name << "='" << handle_id << "'.";
    return grpc::Status(grpc::StatusCode::NOT_FOUND, message.str());
}

} // namespace

#define DEBUG

/**
 * @class BufferImpl
 * @brief Implements the gRPC service for managing remote buffers.
 *
 * Buffer operations and cleanup are serialized so cleanup cannot destroy a
 * buffer while an in-flight RPC is using it.
 */
class BufferImpl final : public RemoteBuffer::Service
{
private:
    xrt::device device;
    XrtBufferManager manager;
    std::unordered_map<std::string, std::unique_ptr<BufferRemote>> buffers_;
    HandleGenerator handle_generator_;
    std::mutex mutex_;

public:
    std::string device_name = "";
    // Constructor with member initialization list
    BufferImpl()
        : device(open_device("0")), // Initialize device using open_device method
          manager(device)           // Initialize manager with the created device
    {
        device_name = device.get_info<xrt::info::device::name>();
        std::cout << "device name: " << device_name << "\n";
    }

    /**
     * @brief Release every buffer owned by the service.
     * @return Number of buffers released.
     */
    std::size_t clearBuffers()
    {
        std::lock_guard<std::mutex> lock(mutex_);
        std::size_t released = buffers_.size();
        buffers_.clear();
        return released;
    }

    Status bufferNotFoundStatus(const std::string &buffer_id, const std::string &operation)
    {
        return handle_not_found_status(
            "Buffer",
            operation,
            "buffer_id",
            buffer_id
        );
    }

private:
    // Helper method to open the device
    xrt::device open_device(std::string index)
    {
        try
        {
            xrt::device device(index); // Attempt to open the device at the given index
            return device;
        }
        catch (const std::exception &e)
        {
            std::cerr << "Failed to open device: " << e.what() << std::endl;
            throw; // Re-throw to handle the exception further up
        }
    }
    /**
     * @brief Handles allocation requests from the client.
     *
     * This function processes an allocation request by creating a new BufferRemote object
     * and storing it in the buffers_ map with a unique identifier. The identifier is then
     * sent back to the client in the response.
     *
     * @param context The server context for the RPC call.
     * @param request The allocation request containing the size, data type, and cacheable flag.
     * @param response The response to be sent back to the client, containing the buffer ID and status.
     * @return grpc::Status indicating the success or failure of the RPC call.
     */
    Status allocate(ServerContext *context, const AllocateRequest *request, AllocateResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        #ifdef DEBUG
        std::cout << "Allocate Request Received: "
                  << "size=" << static_cast<size_t>(request->size()) << ", "
                  << "dtype=" << request->dtype() << ", "
                  << "cacheable=" << (request->cacheable() ? "true" : "false")
                  << std::endl;
        #endif
        try
        {
            auto buffer = std::make_unique<BufferRemote>(static_cast<size_t>(request->size()), request->dtype(), manager, request->cacheable());
            std::string buffer_id;
            if (!handle_generator_.try_generate(buffer_id))
            {
                return grpc::Status(
                    grpc::StatusCode::RESOURCE_EXHAUSTED,
                    "Buffer ID space exhausted."
                );
            }
            buffers_[buffer_id] = std::move(buffer);
            response->set_buffer_id(buffer_id);
        }
        catch (const std::exception &e)
        {
            std::cerr << "Allocation failed: " << e.what() << std::endl;
        }
        return grpc::Status::OK;
    }
    /**
     * @brief Handles the write operation for the remote server.
     *
     * This function processes a stream of BufferWriteRequest messages from the client,
     * writes the data to the appropriate buffer, and sends a BufferWriteResponse back to the client.
     *
     * @param context The server context for the RPC call.
     * @param reader A ServerReader to read the stream of BufferWriteRequest messages.
     * @param response A BufferWriteResponse to send the status and message back to the client.
     * @return grpc::Status The status of the RPC call.
     *
     * The function performs the following steps:
     * 1. Reads the BufferWriteRequest messages from the client.
     * 2. On the first request, it retrieves the buffer associated with the buffer_id.
     * 3. Writes the data from each request to the buffer.
     * 4. Checks for buffer overflow and handles errors appropriately.
     * 5. Sends a response back to the client indicating success or failure.
     *
     * @note If DEBUG is defined, the function will print debug information to the console.
     */
    Status write(ServerContext *context, ServerReader<BufferWriteRequest> *reader, BufferWriteResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        #ifdef DEBUG
        std::cout << "Write Request Received" << std::endl;
        #endif
        BufferWriteRequest request;
        bool start = true;
        uint8_t* currentPtr = nullptr;
        size_t offset=0;
        size_t bufferSize=0;
        while (reader->Read(&request))
        {
            // Run once for first request.
            if (start)
            {
                // std::cout << "In start" << std::endl;
                start = false;
                // Use the buffer id to get the buffer this stream request associates with once.
                auto it = buffers_.find(request.buffer_id());
                if (it == buffers_.end())
                {
                    Status status = bufferNotFoundStatus(request.buffer_id(), "write");
                    std::cerr << status.error_message() << std::endl;
                    return status;
                }

                auto buffer = it->second.get();
                // Once you have the buffer object, find the start_ptr
                currentPtr = buffer->data_;
                bufferSize = buffer->size_;
#ifdef DEBUG
                std::cout << "StartPtr: " << static_cast<void *>(currentPtr) << std::endl;
                std::cout << "Size: " << bufferSize << std::endl;
                std::cout << "Offset: " << offset << std::endl;
#endif
            }
            // Run every time, including first.

            const uint8_t *data = reinterpret_cast<const uint8_t *>(request.data().data());
            size_t dataSize = request.data().size();
            // Calculate new offset
            offset += dataSize;
#ifdef DEBUG
            std::cout << "Current Ptr: " << static_cast<void *>(currentPtr) << " Size: " << dataSize << " Offset: " << offset << std::endl;
#endif
            if (offset > bufferSize) // If  current offset + dataSize would go over buffer size, error and dont write.
            {
                std::cerr << "Buffer overflow: Attempt to write beyond buffer size." << std::endl;
                response->set_msg("Buffer overflow.");
                return Status::OK; // Could change to truncate data to fit in buffer using dataSize = bufferSize - offset; before memcpy
            };
            std::memcpy(currentPtr, data, dataSize);
            currentPtr += dataSize;
        }
        return grpc::Status::OK;
    }
    /**
     * @brief Handles a read request from the client to read data from a buffer.
     *
     * This function processes a read request by locating the specified buffer and 
     * streaming its contents back to the client in chunks. If the buffer is not found, 
     * it returns a NOT_FOUND status. If the client disconnects during the write process, 
     * it returns an ABORTED status.
     *
     * @param context The server context for the request.
     * @param request The request containing the buffer ID to read from.
     * @param writer The server writer used to stream the buffer data back to the client.
     * @return grpc::Status The status of the read operation.
     */
    Status read(ServerContext *context, const BufferReadRequest *request, ServerWriter<BufferReadResponse> *writer) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
#ifdef DEBUG
        std::cout << "Read Request Received: " << std::endl;
#endif

        auto it = buffers_.find(request->buffer_id());
        if (it == buffers_.end())
        {
            Status status = bufferNotFoundStatus(request->buffer_id(), "read");
            std::cerr << status.error_message() << std::endl;
            return status;
        }

        auto buffer = it->second.get();
        uint8_t *currentPtr = buffer->data_; // Get the buffer start pointer
                                             // Create a BufferReadResponse and send the data in chunks

        // For optimal performance, chunk sizes between 16KiB and 64KiB are often recommended2.
        // This range balances efficiency and reliability, ensuring smooth streaming without overwhelming the system.
        size_t chunkSize = 1024 * 1024; // Define the size of each chunk to send = 4MB
        size_t readSize = buffer->size_;
#ifdef DEBUG
        std::cout << "StartPtr: " << static_cast<void *>(currentPtr) << std::endl;
        std::cout << "Size: " << readSize << std::endl;
#endif
        BufferReadResponse response;
        while (readSize > 0)
        {
            size_t currentChunkSize = std::min(chunkSize, readSize); // Determine the size of the current chunk
#ifdef DEBUG
            std::cout << "CurrentPtr: " << static_cast<void *>(currentPtr) << std::endl;
            std::cout << "Read Size: " << readSize << std::endl;
#endif
            // Read back data from the mapped buffer
            response.set_data(reinterpret_cast<const char *>(currentPtr), currentChunkSize);
            // Send the current chunk back to the client
            if (!writer->Write(response))
            {
                // If writing fails (e.g., client disconnects), return with an error
                std::cerr << "Failed to write data to client." << std::endl;
                return grpc::Status(grpc::StatusCode::ABORTED, "Failed to write data to client.");
            }

            // Move the pointer forward and reduce the remaining read size
            currentPtr += currentChunkSize;
            readSize -= currentChunkSize;
        }
#ifdef DEBUG
        std::cout << "Read Size Final: " << readSize << std::endl;
#endif
        // When readSize = 0 it will exit loop and exit stream
        return grpc::Status::OK;
    }


    /**
     * @brief Handles the request to free a buffer.
     *
     * This function processes a request to free a buffer identified by its buffer ID.
     * It searches for the buffer in the internal map and removes it if found.
     * If the buffer is not found, the request succeeds because there is no
     * resource to release.
     * 
     * @param context The server context for the request.
     * @param request The request containing the buffer ID to be freed.
     * @param response The response indicating the status of the operation.
     * @return grpc::Status The status of the operation.
     */
    Status  freebuffer(ServerContext *context, const FreeBufferRequest *request, FreeBufferResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
#ifdef DEBUG
        std::cout << "Freebuffer Request Received: " << request->buffer_id() << std::endl;
#endif
        auto it = buffers_.find(request->buffer_id());
        if (it == buffers_.end())
        {
            return grpc::Status::OK;
        }
        else
        {

            buffers_.erase(it); // Remove from map and auto call destructor for object as it is a unique_ptr type
#ifdef DEBUG
            it = buffers_.find(request->buffer_id()); // Check that buffer is free'd successfully by searching for it.
            if (it == buffers_.end())
            {
                std::cout << "Buffer Successfuly Freed: " << request->buffer_id() << std::endl;
            }
#endif
        }
        return grpc::Status::OK;
    }

    /**
     * @brief Handles a flush request from the client.
     *
     * This function processes a flush request by locating the buffer
     * specified by the buffer_id in the request. If the buffer is found,
     * it performs a flush operation on the buffer and sets the response
     * status to 1. If the buffer is not found, it returns a NOT_FOUND
     * gRPC status.
     *
     * @param context The server context for the request.
     * @param request The flush request containing the buffer_id.
     * @param response The response to be sent back to the client.
     * @return grpc::Status indicating the success or failure of the operation.
     */
    Status flush(ServerContext *context, const FlushRequest *request, FlushResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
#ifdef DEBUG
        std::cout << "Flush Request Received: " << request->buffer_id() << std::endl;
#endif
        // Find the buffer based on the buffer_id in the request
        auto it = buffers_.find(request->buffer_id());
        if (it == buffers_.end())
        {
            Status status = bufferNotFoundStatus(request->buffer_id(), "flush");
            std::cerr << status.error_message() << std::endl;
            return status;
        }
        auto buffer = it->second.get();
        buffer->flush();
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the invalidate request from the client.
     *
     * This function processes an invalidate request, which includes finding the buffer
     * based on the buffer_id provided in the request. If the buffer is found, it is invalidated,
     * and the response status is set to 1. If the buffer is not found, an error status is returned.
     *
     * @param context The server context for the request.
     * @param request The invalidate request containing the buffer_id.
     * @param response The response to be sent back to the client.
     * @return grpc::Status indicating the success or failure of the operation.
     */
    Status invalidate(ServerContext *context, const InvalidateRequest *request, InvalidateResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
#ifdef DEBUG
        std::cout << "Invalidate Request Received: " << request->buffer_id() << std::endl;
#endif
        // Find the buffer based on the buffer_id in the request
        auto it = buffers_.find(request->buffer_id());
        if (it == buffers_.end())
        {
            Status status = bufferNotFoundStatus(request->buffer_id(), "invalidate");
            std::cerr << status.error_message() << std::endl;
            return status;
        }
        auto buffer = it->second.get();
        buffer->invalidate();
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the request to get the physical address of a buffer.
     *
     * This function processes a request to retrieve the physical address of a buffer
     * identified by its buffer ID. It searches for the buffer in the internal map
     * and, if found, retrieves its physical address and sets it in the response.
     * If the buffer is not found, it returns a NOT_FOUND status.
     *
     * @param context The server context for the request.
     * @param request The request containing the buffer ID.
     * @param response The response containing the physical address and status.
     * @return grpc::Status The status of the request processing.
     */
    Status physical_address(ServerContext *context, const AddressRequest *request, AddressResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
#ifdef DEBUG
        std::cout << "Physical_address Request Received: " << request->buffer_id() << std::endl;
#endif
        // Find the buffer based on the buffer_id in the request
        auto it = buffers_.find(request->buffer_id());
        if (it == buffers_.end())
        {
            Status status = bufferNotFoundStatus(request->buffer_id(), "physical_address");
            std::cerr << status.error_message() << std::endl;
            return status;
        }
        auto buffer = it->second.get();
        uint64_t paddr = buffer->physical_address();
#ifdef DEBUG
        std::cout << "Physical Address found: " << paddr << std::endl;
#endif
        response->set_address(paddr);
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the virtual address request from the client.
     *
     * This function processes a request to retrieve the virtual address of a buffer
     * identified by its buffer ID. It searches for the buffer in the internal map
     * and, if found, retrieves its virtual address and sends it back in the response.
     * If the buffer is not found, it returns a NOT_FOUND status.
     *
     * @param context The server context for the request.
     * @param request The request containing the buffer ID.
     * @param response The response containing the virtual address and status.
     * @return grpc::Status The status of the request processing.
     */
    Status virtual_address(ServerContext *context, const AddressRequest *request, AddressResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
#ifdef DEBUG
        std::cout << "Virtual_address Request Received: " << request->buffer_id() << std::endl;
#endif
        // Find the buffer based on the buffer_id in the request
        auto it = buffers_.find(request->buffer_id());
        if (it == buffers_.end())
        {
            Status status = bufferNotFoundStatus(request->buffer_id(), "virtual_address");
            std::cerr << status.error_message() << std::endl;
            return status;
        }
        auto buffer = it->second.get();
        uint64_t vaddr = buffer->virtual_address();
#ifdef DEBUG
        std::cout << "Virtual Address found: " << vaddr << std::endl;
#endif
        response->set_address(vaddr);
        return grpc::Status::OK;
    }

    /**
     * @brief Handles a cacheable request to determine if a buffer is cacheable.
     *
     * This function processes a cacheable request by looking up the buffer
     * specified by the buffer_id in the request. If the buffer is found, it
     * checks whether the buffer is cacheable and sets the response accordingly.
     * If the buffer is not found, it returns a NOT_FOUND status.
     *
     * @param context The server context for the request.
     * @param request The cacheable request containing the buffer_id.
     * @param response The response to be populated with the cacheable status and result status.
     * @return grpc::Status OK if the buffer is found and processed, NOT_FOUND if the buffer is not found.
     */
    Status cacheable(ServerContext *context, const CacheableRequest *request, CacheableResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
#ifdef DEBUG
        std::cout << "Cacheable Request Received: " << std::endl;
#endif
        // Find the buffer based on the buffer_id in the request
        auto it = buffers_.find(request->buffer_id());
        if (it == buffers_.end())
        {
            Status status = bufferNotFoundStatus(request->buffer_id(), "cacheable");
            std::cerr << status.error_message() << std::endl;
            return status;
        }
        auto buffer = it->second.get();
        bool cacheable = buffer->cacheable();
        response->set_cacheable(cacheable);
        return grpc::Status::OK;
    }
};

class MMIOImpl final : public Mmio::Service
{
    /**
     * @class MMIOImpl
     * @brief Implements the gRPC service for managing MMIO objects.
     *
     * MMIO operations and cleanup are serialized so cleanup cannot destroy a
     * mapping while an in-flight RPC is using it.
     */
private:
    std::unordered_map<std::string, std::unique_ptr<MMIO>> mmios_; ///< Map to store MMIO objects
    HandleGenerator handle_generator_;
    std::mutex mutex_;

public:
    /**
     * @brief Adds a new MMIO object.
     * Creates and stores a new MMIO object with the given base address, length, and identifier.
     * @param base_addr Base address for memory mapping.
     * @param length Length of the memory region.
     * @param mmio_id Identifier for the MMIO object.
     */
    void addMMIO(uint64_t base_addr, uint64_t length, std::string mmio_id)
    {
        mmios_[mmio_id] = std::make_unique<MMIO>(base_addr, length);
    }

    bool releaseMMIO(const std::string &mmio_id)
    {
        return mmios_.erase(mmio_id) > 0;
    }

    /**
     * @brief Release every MMIO mapping owned by the service.
     * @return Number of mappings released.
     */
    std::size_t clearMMIOs()
    {
        std::lock_guard<std::mutex> lock(mutex_);
        std::size_t released = mmios_.size();
        mmios_.clear();
        return released;
    }

    Status mmioNotFoundStatus(const std::string &mmio_id, const std::string &operation)
    {
        return handle_not_found_status(
            "MMIO",
            operation,
            "mmio_id",
            mmio_id
        );
    }

    /**
     * @brief Finds an MMIO object by its ID.
     * Searches the internal map for an MMIO object with the given identifier.
     * @param mmio_id Identifier for the MMIO object.
     * @return Pointer to the MMIO object, or nullptr if not found.
     */
    MMIO *findMMIO(const std::string &mmio_id)
    {
        auto it = mmios_.find(mmio_id);
        if (it != mmios_.end())
        {
            return it->second.get();
        }
        return nullptr;
    }

    /**
     * @brief Handles the GetMmio gRPC request.
     * Creates a new MMIO object based on the request parameters and returns its identifier.
     * @param context Server context for the request.
     * @param request GetMmioRequest message.
     * @param response GetMmioResponse message.
     * @return gRPC status.
     */
    Status get_mmio(ServerContext *context, const GetMmioRequest *request, GetMmioResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        #ifdef DEBUG
        std::cout << "Function: get_mmio, "
                  << "base_addr=" << request->base_addr() << ", "
                  << "length=" << request->length()
                  << std::endl;
        #endif
        std::string mmio_id;
        if (!handle_generator_.try_generate(mmio_id))
        {
            return grpc::Status(
                grpc::StatusCode::RESOURCE_EXHAUSTED,
                "MMIO ID space exhausted."
            );
        }
        addMMIO(request->base_addr(), request->length(), mmio_id);
        response->set_mmio_id(mmio_id);
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the ReleaseMmio gRPC request.
     * Releases a server-side MMIO object by identifier. If the ID is not
     * present, the request succeeds so object cleanup can follow global cleanup.
     * @param context Server context for the request.
     * @param request ReleaseMmioRequest message.
     * @param response ReleaseMmioResponse message.
     * @return gRPC status.
     */
    Status release_mmio(ServerContext *context, const ReleaseMmioRequest *request, ReleaseMmioResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        bool released = releaseMMIO(request->mmio_id());
#ifdef DEBUG
        std::cout << "Function: release_mmio, "
                  << "mmio_id=" << request->mmio_id() << ", "
                  << "released=" << (released ? "true" : "false")
                  << std::endl;
#endif
        response->set_status(true);
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the Read gRPC request.
     * Reads data from the specified MMIO object and returns it in the response.
     * @param context Server context for the request.
     * @param request ReadRequest message.
     * @param response ReadResponse message.
     * @return gRPC status.
     */
    Status read(ServerContext *context, const ReadRequest *request, ReadResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        MMIO *mmio = findMMIO(request->mmio_id());
        if (!mmio)
        {
            Status status = mmioNotFoundStatus(request->mmio_id(), "read");
            std::cerr << status.error_message() << std::endl;
            return status;
        }
        uint32_t data = mmio->read(request->offset());
        #ifdef DEBUG
        std::cout << "Function: read, "
                  << "mmio_id=" << request->mmio_id() << ", "
                  << "offset=" << request->offset()
                  << "Data=" << data
                  << std::endl;
        #endif
        response->set_data(data);
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the Write gRPC request.
     * Writes data to the specified MMIO object based on the request parameters.
     * @param context Server context for the request.
     * @param request WriteRequest message.
     * @param response WriteResponse message.
     * @return gRPC status.
     */
    Status write(ServerContext *context, const WriteRequest *request, WriteResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        #ifdef DEBUG
        std::cout << "Function: write, "
                  << "mmio_id=" << request->mmio_id() << ", "
                  << "offset=" << request->offset() << ", "
                  << "data=" << *reinterpret_cast<const uint32_t *>(request->data().data())
                  << std::dec
                  << std::endl;
        #endif
        MMIO *mmio = findMMIO(request->mmio_id());
        if (!mmio)
        {
            Status status = mmioNotFoundStatus(request->mmio_id(), "write");
            std::cerr << status.error_message() << std::endl;
            return status;
        }
        uint32_t value;
        std::memcpy(&value, request->data().data(), sizeof(value));
        mmio->write(value, request->offset());
        return grpc::Status::OK;
    }
};

class GPIOImpl final : public Gpio::Service
{
    /**
     * @class GPIOImpl
     * @brief Implements the gRPC service for managing GPIO objects.
     *
     * GPIO operations and cleanup are serialized so cleanup cannot destroy a
     * GPIO object while an in-flight RPC is using it.
     */
private:
    std::unordered_map<std::string, std::unique_ptr<GPIO>> gpios_; ///< Map to store GPIO objects
    HandleGenerator handle_generator_;
    std::mutex mutex_;

public:
    /**
     * @brief Adds a new GPIO object.
     * Creates and stores a new GPIO object with the given index, direction and identifier.
     * @param index Index of the GPIO.
     * @param direction Direction of the GPIO.
     * @param gpio_id Identifier for the GPIO object.
     */
    void addGPIO(uint32_t index, std::string direction, std::string gpio_id)
    {
        gpios_[gpio_id] = std::make_unique<GPIO>(index, direction);
    }

    /**
     * @brief Release every GPIO object owned by the service.
     * @return Number of GPIO objects released.
     */
    std::size_t clearGPIOs()
    {
        std::lock_guard<std::mutex> lock(mutex_);
        std::size_t released = gpios_.size();
        gpios_.clear();
        return released;
    }

    Status gpioNotFoundStatus(const std::string &gpio_id, const std::string &operation)
    {
        return handle_not_found_status(
            "GPIO",
            operation,
            "gpio_id",
            gpio_id
        );
    }

    /**
     * @brief Finds a GPIO object by its ID.
     * Searches the internal map for a GPIO object with the given identifier.
     * @param gpio_id Identifier for the GPIO object.
     * @return Pointer to the GPIO object, or nullptr if not found.
     */
    GPIO *findGPIO(const std::string &gpio_id)
    {
        auto it = gpios_.find(gpio_id);
        if (it != gpios_.end())
        {
            return it->second.get();
        }
        return nullptr;
    }

    /**
     * @brief Handles the GetGpio gRPC request.
     * Creates a new GPIO object based on the request parameters and returns its identifier.
     * @param context Server context for the request.
     * @param request GetGpioRequest message.
     * @param response GetGpioResponse message.
     * @return gRPC status. 
     */
    Status get_gpio(ServerContext *context, const GetGpioRequest *request, GetGpioResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        #ifdef DEBUG
        std::cout << "Function: get_gpio, "
                  << "index=" << request->index() << ", "
                  << "direction=" << request->direction()
                  << std::endl;
        #endif
        std::string gpio_id;
        if (!handle_generator_.try_generate(gpio_id))
        {
            return grpc::Status(
                grpc::StatusCode::RESOURCE_EXHAUSTED,
                "GPIO ID space exhausted."
            );
        }
        addGPIO(request->index(), request->direction(), gpio_id);
        response->set_gpio_id(gpio_id);
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the Read gRPC request.
     * Reads data from the specified GPIO object and returns it in the response.
     * @param context Server context for the request.
     * @param request GpioReadRequest message.
     * @param response GpioReadResponse message.
     * @return gRPC status.
     */
    Status read(ServerContext *context, const GpioReadRequest *request, GpioReadResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        GPIO *gpio = findGPIO(request->gpio_id());
        if (!gpio)
        {
            Status status = gpioNotFoundStatus(request->gpio_id(), "read");
            std::cerr << status.error_message() << std::endl;
            return status;
        }
        uint32_t data = gpio->read();
        #ifdef DEBUG
        std::cout << "Function: read, "
                  << "gpio_id=" << request->gpio_id() << ", "
                  << "Data=" << data
                  << std::endl;
        #endif
        response->set_value(data);
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the Write gRPC request.
     * Writes the value (0,1) to the specified GPIO object based on the request parameters.
     * @param context Server context for the request.
     * @param request GpioWriteRequest message.
     * @param response GpioWriteResponse message.
     * @return gRPC status.
     */
    Status write(ServerContext *context, const GpioWriteRequest *request, GpioWriteResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        #ifdef DEBUG
        std::cout << "Function: write, "
                  << "gpio_id=" << request->gpio_id() << ", "
                  << "data=" << request->value()
                  << std::dec
                  << std::endl;
        #endif
        GPIO *gpio = findGPIO(request->gpio_id());
        if (!gpio)
        {
            Status status = gpioNotFoundStatus(request->gpio_id(), "write");
            std::cerr << status.error_message() << std::endl;
            return status;
        }
        gpio->write(request->value());
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the Unexport gRPC request.
     * Releases the specified GPIO object based on the request parameters.
     * If the ID is not present, the request succeeds so object cleanup can
     * follow global cleanup.
     * @param context Server context for the request.
     * @param request GpioUnexportRequest message.
     * @param response GpioUnexportResponse message.
     * @return gRPC status.
     */
    Status unexport(ServerContext *context, const GpioUnexportRequest *request, GpioUnexportResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        #ifdef DEBUG
        std::cout << "Function: unexport, "
                  << "gpio_id=" << request->gpio_id()
                  << std::dec
                  << std::endl;
        #endif
        GPIO *gpio = findGPIO(request->gpio_id());
        if (!gpio)
        {
            return grpc::Status::OK;
        }
        // Erasing the owning pointer invokes GPIO::~GPIO(), which unexports it.
        gpios_.erase(request->gpio_id());
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the IsExported gRPC request.
     * Checks if the specified GPIO object is exported based on the request parameters.
     * @param context Server context for the request.
     * @param request GpioIsExportedRequest message.
     * @param response GpioIsExportedResponse message.
     * @return gRPC status.
     */
    Status is_exported(ServerContext *context, const GpioIsExportedRequest *request, GpioIsExportedResponse *response) override
    {
        std::lock_guard<std::mutex> lock(mutex_);
        #ifdef DEBUG
        std::cout << "Function: is_exported, "
                  << "gpio_id=" << request->gpio_id()
                  << std::dec
                  << std::endl;
        #endif
        GPIO *gpio = findGPIO(request->gpio_id());
        response->set_is_exported(gpio != nullptr && gpio->is_exported());
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the GetGpioBasePath gRPC request.
     * Retrieves the base path of the specified GPIO object based on the request parameters.
     * @param context Server context for the request.
     * @param request GetGpioBasePathRequest message.
     * @param response GetGpioBasePathResponse message.
     * @return gRPC status.
     */
    Status get_gpio_base_path(ServerContext *context, const GetGpioBasePathRequest *request, GetGpioBasePathResponse *response) override
    {
        #ifdef DEBUG
        std::cout << "Function: get_gpio_base_path, "
                    << "target_label=" << request->target_label()
                    << std::dec
                    << std::endl;
        #endif

        std::string base_path;
        if (request->has_target_label()) {
            base_path = ::get_gpio_base_path(request->target_label());
        } else {
            base_path = ::get_gpio_base_path();
        }
        response->set_base_path(base_path);
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the GetGpioNPins gRPC request.
     * Retrieves the number of pins of the specified GPIO object based on the request parameters.
     * @param context Server context for the request.
     * @param request GetGpioNPinsRequest message.
     * @param response GetGpioNPinsResponse message.
     * @return gRPC status.
     */
    Status get_gpio_npins(ServerContext *context, const GetGpioNPinsRequest *request, GetGpioNPinsResponse *response) override
    {
        #ifdef DEBUG
        std::cout << "Function: get_gpio_npins, "
                    << "target_label=" << request->target_label()
                    << std::dec
                    << std::endl;
        #endif

        uint32_t npins;
        if (request->has_target_label()) {
            npins = ::get_gpio_npins(request->target_label());
        } else {
            npins = ::get_gpio_npins();
        }
        response->set_npins(npins);
        return grpc::Status::OK;
    }
};


class RemoteDeviceImpl final : public RemoteDevice::Service
{
    /**
     * @class RemoteDeviceImpl
     * @brief Implements the gRPC service for managing remote devices.
     */
private:
    const std::string FIRMWARE = "/lib/firmware/";                               ///< Directory for bitstream files
    Device remote_device_;
    BufferImpl* buffer_service_ = nullptr; ///< Cleared when a client starts a new overlay/session.
    MMIOImpl* mmio_service_ = nullptr;     ///< Cleared when a client starts a new overlay/session.
    GPIOImpl* gpio_service_ = nullptr;     ///< Cleared when a client starts a new overlay/session.
#ifdef RFSOC
    XrfdcImpl* xrfdc_service_ = nullptr;   ///< Notified on bitstream download so it can drop its stale RFDC mapping.
    XrfclkImpl* xrfclk_service_ = nullptr; ///< Notified on bitstream download so it can drop its cached clock-device state.
#endif

public:
    std::string device_name = "";
    /**
     * @brief Constructor for RemoteDeviceImpl.
     * Checks if the /lib/firmware/ directory exists and creates it if it does not.
     */
    RemoteDeviceImpl()
    {
        if (!std::filesystem::exists(FIRMWARE))
        {
            std::filesystem::create_directories(FIRMWARE);
            std::cout << "Created directory: " << FIRMWARE << std::endl;
        }
    }

    /**
     * @brief Register resource-owning service impls for cleanup requests.
     *
     * These pointers are non-owning; the services live in RunServer's stack
     * frame for the lifetime of the gRPC server.
     */
    void set_resource_services(BufferImpl* buffer, MMIOImpl* mmio, GPIOImpl* gpio)
    {
        buffer_service_ = buffer;
        mmio_service_ = mmio;
        gpio_service_ = gpio;
    }

#ifdef RFSOC
    /**
     * @brief Register the xrfdc/xrfclk service impls so download() can invalidate
     * their cached state after the PL is reprogrammed. Both pointers are non-owning;
     * the services outlive this object (they live in RunServer's stack frame).
     */
    void set_rfsoc_services(XrfdcImpl* xrfdc, XrfclkImpl* xrfclk)
    {
        xrfdc_service_ = xrfdc;
        xrfclk_service_ = xrfclk;
    }
#endif

    /**
     * @brief Handles the SetBitstreamAttrs gRPC request.
     * Sets attributes for the bitstream file based on the request parameters.
     * @param context Server context for the request.
     * @param request SetBitstreamAttrsRequest message. request Contains std::string binfile_name, bool partial
     * @param response SetBitstreamAttrsResponse message. Contains bool status
     * @return gRPC status.
     */
    Status set_bitstream_attrs(ServerContext *context, const SetBitstreamAttrsRequest *request, SetBitstreamAttrsResponse *response) override
    {
        remote_device_.set_bitstream_attrs(request->binfile_name(), request->partial());
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the Download gRPC request.
     * Receives bitstream data in 1MB chunks and writes it to the FIRMWARE path (/lib/firmware) using binfile_name set using SetBitstreamAttrs.
     * @param context Server context for the request.
     * @param reader ServerReader for DownloadRequest messages. Processes stream of requests containing std::string buffer
     * @param reply DownloadResponse message. Contains bool status
     * @return gRPC status.
     */
    Status download(ServerContext *context, ServerReader<DownloadRequest> *reader, DownloadResponse *reply) override
    {
        std::ofstream file(FIRMWARE + remote_device_.get_bitstream_attrs().first);
        DownloadRequest request;
        int chunk_count = 0;
        while (reader->Read(&request))
        {
            chunk_count++;
            file << request.buffer();
        }
        file.close();
        remote_device_.download(remote_device_.get_bitstream_attrs().first);

#ifdef RFSOC
        // The PL has been reprogrammed, so any cached RFDC/clock state on the
        // server now points at the old overlay. Tell the dependent services to
        // drop it; the client is expected to re-run xrfdc.CfgInitialize and
        // xrfclk programming against the new bitstream.
        if (xrfdc_service_) {
            xrfdc_service_->invalidate();
        }
        if (xrfclk_service_) {
            xrfclk_service_->invalidate();
        }
#endif

        return grpc::Status::OK;
    }

    /**
     * @brief Handles the Cleanup gRPC request.
     *
     * Clears server-side resource handles that may have been orphaned by a
     * host Python kernel restart or by stale overlay objects. Each resource
     * service waits for its in-flight operations before destroying objects.
     *
     * @param context Server context for the request.
     * @param request Empty cleanup request.
     * @param response Cleanup completion status.
     * @return gRPC status.
     */
    Status cleanup(ServerContext *context, const CleanupRequest *request, CleanupResponse *response) override
    {
        uint64_t buffers_freed = 0;
        uint64_t mmios_freed = 0;
        uint64_t gpios_freed = 0;

        if (buffer_service_)
        {
            buffers_freed = buffer_service_->clearBuffers();
        }
        if (mmio_service_)
        {
            mmios_freed = mmio_service_->clearMMIOs();
        }
        if (gpio_service_)
        {
            gpios_freed = gpio_service_->clearGPIOs();
        }

#ifdef DEBUG
        std::cout << "Cleanup Request Received: "
                  << "buffers_freed=" << buffers_freed << ", "
                  << "mmios_freed=" << mmios_freed << ", "
                  << "gpios_freed=" << gpios_freed
                  << std::endl;
#endif

        response->set_status(true);
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the ExistsFile gRPC request.
     * Checks if the specified file exists.
     * @param context Server context for the request.
     * @param request ExistsFileRequest message containing the file path.
     * @param reply ExistsFileResponse message containing the existence status.
     * @return gRPC status.
     */
    Status existsfile(ServerContext *context, const ExistsFileRequest *request, ExistsFileResponse *reply) override
    {
        #ifdef DEBUG
        std::cout << "ExistsFile Request Received: " << request->file_path() << std::endl;
        #endif
        reply->set_exists(std::filesystem::exists(request->file_path()));
        return grpc::Status::OK;
    }

    /**
     * @brief Handles the ReadFile gRPC request.
     * Reads the file specified by file_path and streams its content back to the client.
     * @param context Server context for the request.
     * @param request ReadFileRequest message containing the file path.
     * @param writer ServerWriter for ReadFileResponse messages. Streams the file content back to the client.
     * @return gRPC status.
     */
    Status readfile(ServerContext *context, const ReadFileRequest *request, ServerWriter<ReadFileResponse> *writer) override
    {
        #ifdef DEBUG
        std::cout << "ReadFile Request Received: " << request->file_path() << std::endl;
        #endif
        if (request->file_path() == "xrt_device")
        {
            ReadFileResponse response;
            response.set_data(device_name);
            writer->Write(response);
            return grpc::Status::OK;
        }

        std::ifstream file(request->file_path(), std::ios::binary);
        if (!file.is_open())
        {
            return grpc::Status(grpc::StatusCode::NOT_FOUND, "File not found");
        }

        ReadFileResponse response;
        char buffer[1024];
        while (file.read(buffer, sizeof(buffer)) || file.gcount() > 0)
        {
            response.set_data(buffer, file.gcount());
            writer->Write(response);
        }
        file.close();
        return grpc::Status::OK;
    }
    /**
     * @brief Handles the WriteFile gRPC request.
     * Receives file data in chunks and writes it to the specified file path.
     * @param context Server context for the request.
     * @param reader ServerReader for WriteFileRequest messages. Processes stream of requests containing file path and data.
     * @param reply WriteFileResponse message.
     * @return gRPC status.
     */
    Status writefile(ServerContext *context, ServerReader<WriteFileRequest> *reader, WriteFileResponse *reply) override
    {
        #ifdef DEBUG
        std::cout << "WriteFile Request Received" << std::endl;
        #endif
        WriteFileRequest request;
        if (!reader->Read(&request))
        {
            return grpc::Status(grpc::StatusCode::INVALID_ARGUMENT, "No file path provided");
        }

        std::ofstream file(request.file_path(), std::ios::binary);
        if (!file.is_open())
        {
            return grpc::Status(grpc::StatusCode::INTERNAL, "Failed to open file for writing");
        }

        do
        {
            file.write(request.data().data(), request.data().size());
        } while (reader->Read(&request));

        file.close();
        return grpc::Status::OK;
    }
};

/**
 * @brief Runs the gRPC server.
 * Sets up and starts the gRPC server on the specified port.
 * @param port Port number for the server.
 */
void RunServer(uint16_t port)
{
    // Server runs locally on port assigned via absl::flag.
    std::string server_address = "0.0.0.0:" + std::to_string(port);
    RemoteDeviceImpl remote_device_service; // Create remote_device rpc handler
    MMIOImpl mmio_service;                  // Create MMIO rpc handler
    BufferImpl buffer_service;              // Create Buffer rpc handler
    GPIOImpl gpio_service;                  // Create Gpio rpc handler
    remote_device_service.set_resource_services(&buffer_service, &mmio_service, &gpio_service);
#ifdef RFSOC
    XrfclkImpl xrfclk_service;              // Create Xrfclk rpc handler
    XrfdcImpl xrfdc_service;                // Create Xrfdc rpc handler
    remote_device_service.set_rfsoc_services(&xrfdc_service, &xrfclk_service);
#endif
    remote_device_service.device_name = buffer_service.device_name;

    grpc::EnableDefaultHealthCheckService(true);
    grpc::reflection::InitProtoReflectionServerBuilderPlugin();
    ServerBuilder builder;
    builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
    builder.RegisterService(&remote_device_service); // Add to RPC running server.
    builder.RegisterService(&mmio_service);
    builder.RegisterService(&buffer_service);
    builder.RegisterService(&gpio_service);
#ifdef RFSOC
    builder.RegisterService(&xrfclk_service);
    builder.RegisterService(&xrfdc_service);
#endif

    std::unique_ptr<Server> server(builder.BuildAndStart());
    std::cout << "Server listening on " << server_address << std::endl;
    // Wait for the server to shutdown. Note that some other thread must be
    // responsible for shutting down the server for this call to ever return.
    server->Wait();
}

int main(int argc, char **argv)
{
    RunServer(7967);
    return 0;
}
