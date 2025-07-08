#include "mmio.h"

#define DEBUG

MMIO::MMIO(off_t base_address, size_t length_p)
    : mem_fd(-1), virt_base(0), virt_offset(0), length(0), mapped_base(nullptr)
{
    if (base_address < 0 || length_p < 0)
    {
        std::cerr << "Error: Base address or length cannot be negative." << std::endl;
        return;
    }
    mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (mem_fd == -1)
    {
        std::cerr << "Error: cannot open /dev/mem" << std::endl;
        return;
    }
    virt_base = base_address & ~(4096 - 1);
    virt_offset = base_address - virt_base;
    length = length_p;

    mapped_base = mmap(nullptr, length + virt_offset, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, virt_base);
    if (mapped_base == MAP_FAILED)
    {
        std::cerr << "Error: cannot map memory" << std::endl;
        close(mem_fd);
        mem_fd = -1;
        mapped_base = nullptr;
    }
}

MMIO::~MMIO()
{
    if (mapped_base != nullptr)
    {
        munmap(mapped_base, length + virt_offset);
    }
    if (mem_fd != -1)
    {
        close(mem_fd);
    }
}

uint32_t MMIO::read(uint64_t offset)
{
    int idx = offset >> 2; // data is a uint32 ptr, offset is in bytes so /4
    if (mapped_base == nullptr)
    {
        std::cerr << "Error: memory not mapped" << std::endl;
        return 0;
    }
    uint32_t *ptr = reinterpret_cast<uint32_t *>(static_cast<char *>(mapped_base) + virt_offset);
#ifdef DEBUG
    std::cout << "MMIO Read from " << static_cast<void *>(mapped_base) << " Data: " << ptr[idx] << " Offset: " << offset << std::endl;
#endif
    return ptr[idx];
}

void MMIO::write(uint32_t data, uint64_t offset)
{
    int idx = offset >> 2; // data is a uint32 ptr, offset is in bytes so / 4
    if (mapped_base == nullptr)
    {
        std::cerr << "Error: memory not mapped" << std::endl;
        return;
    }
    uint32_t *ptr = reinterpret_cast<uint32_t *>(static_cast<char *>(mapped_base) + virt_offset);
#ifdef DEBUG
    std::cout << "MMIO Write to " << static_cast<void *>(mapped_base) << " Data: " << data << " Offset: " << offset << std::endl;
#endif
    ptr[idx] = data;
}