__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


import os
import sys
import mmap
import struct

class MMIO:
    """This class exposes API to carry MMIO operations."""

    filename = '/dev/mem'
    word = 4
    mask = ~(word - 1)

    def __init__(self, base_addr, wordlength = 1, debug = 0):
        if base_addr < 0 or wordlength < 0: 
            raise ValueError("Negative offset or negative length")

        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('root permissions required.')
            exit()

        self._debug = debug

        self.base_addr = base_addr & ~(mmap.PAGESIZE - 1)
        self.base_addr_offset = base_addr - self.base_addr

        stop = base_addr + wordlength * self.word
        if (stop % self.mask):
            stop = (stop + self.word) & ~(self.word - 1)

        # wordlength is in words, while self.bytelength is in bytes
        self.bytelength = stop - self.base_addr

        self.debug('init with base_addr = {0} and length = {1} bytes on {2}'.
                format(hex(self.base_addr), hex(self.bytelength), 
                       self.filename))

        # Open file and mmap
        f = os.open(self.filename, os.O_RDWR | os.O_SYNC)
        self.mem = mmap.mmap(f, self.bytelength, mmap.MAP_SHARED,
                mmap.PROT_READ | mmap.PROT_WRITE,
                offset=self.base_addr)

    def __str__(self):
        return 'MMIO(address, size) = ({0}, {1} bytes)'.\
                format(hex(self.base_addr), self.bytelength)


    def read(self, offset = 0, wordlength = 1):
        if offset < 0 or wordlength < 0: 
            raise ValueError("Negative offset or negative length")

        if offset + wordlength * self.word > self.bytelength:
            raise MemoryError('Read operation exceeds the MMIO range')

        # Make reading easier (and faster... won't resolve dot in loops)
        mem = self.mem

        self.debug('reading {0} bytes from offset {1}'.
                   format(wordlength * self.word, hex(offset)))

        # Compensate for the base_address not being what the user requested
        # and then seek to the aligned offset.
        virt_base_addr = self.base_addr_offset & self.mask
        mem.seek(virt_base_addr + offset)

        # Read just one word and return it
        if wordlength == 1:
            return struct.unpack('I', mem.read(self.word))[0]
        else:
            # Read word length of size self.word and return it
            data = []
            for i in range(wordlength):
                data.append(struct.unpack('I', mem.read(self.word))[0])
            return data


    def write(self, offset, data_in):
        try:
            bytelength = len(data_in)
        except TypeError:
            bytelength = 1
        else:
            if bytelength <= 0:
                raise ValueError("Cannot write less than 1 word")        
        finally:
            if offset < 0: 
                raise ValueError("Negative offset")

            if offset + bytelength > self.bytelength:
                raise MemoryError('Write operation exceeds MMIO range.')

            # Make reading easier (and faster... won't resolve dot in loops)
            mem = self.mem

            # Compensate for the base_address
            offset += self.base_addr_offset

            # Check that the operation is going write to an aligned location
            if (offset & ~self.mask): 
                raise MemoryError('Write operation not aligned.')

            # Seek to the aligned offset
            virt_base_addr = self.base_addr_offset & self.mask
            mem.seek(virt_base_addr + offset)

            if bytelength == 1:
                self.debug('writing 4 bytes to offset {0}: {1}'.\
                        format(hex(offset), hex(data_in)))
                mem.write(struct.pack('I', data_in))
            else:
                for i in range(0, bytelength, self.word):
                    buf = int.from_bytes(data_in[i:i+self.word],
                                         byteorder='little')
                    mem.write(struct.pack('I', buf))

    def debug_set(self, value):
        self._debug = value

    def debug(self, debug_str):
        if self._debug: print('MMIO Debug: {0}'.format(debug_str))
