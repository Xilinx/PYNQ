
__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


import os
import sys
import mmap
import struct


class mmio:
    """This class exposes API to carry MMIO operations."""

    filename = '/dev/mem'

    # Size of a word that will be used for reading/writing
    word = 4
    mask = ~(word - 1)

    def __init__(self, base_addr, length = 1, debug = 0):
        if base_addr < 0 or length < 0: 
            raise AssertionError

        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('root permissions required.')
            exit()

        self._debug = debug

        self.base_addr = base_addr & ~(mmap.PAGESIZE - 1)
        self.base_addr_offset = base_addr - self.base_addr

        stop = base_addr + length * self.word
        if (stop % self.mask):
            stop = (stop + self.word) & ~(self.word - 1)

        self.length = stop - self.base_addr

        self.debug('init with base_addr = {0} and length = {1} on {2}'.
                format(hex(self.base_addr), hex(self.length), self.filename))

        # Open file and mmap
        f = os.open(self.filename, os.O_RDWR | os.O_SYNC)
        self.mem = mmap.mmap(f, self.length, mmap.MAP_SHARED,
                mmap.PROT_READ | mmap.PROT_WRITE,
                offset=self.base_addr)

    def __str__(self):
        return 'MMIO(address, size) = ({0}, {1})'.\
                format(hex(self.base_addr), self.length)


    def read(self, offset = 0, length = 1):
        if offset < 0 or length < 0: 
            raise AssertionError

        if offset + length * self.word > self.length:
            raise MemoryError('Read operation exceeds the MMIO range.')

        # Make reading easier (and faster... won't resolve dot in loops)
        mem = self.mem

        self.debug('reading {0} bytes from offset {1}'.
                   format(length * self.word, hex(offset)))

        # Compensate for the base_address not being what the user requested
        # and then seek to the aligned offset.
        virt_base_addr = self.base_addr_offset & self.mask
        mem.seek(virt_base_addr + offset)

        # Read just one word and return it
        if length == 1:
            return struct.unpack('I', mem.read(self.word))[0]
        else:
            # Read length words of size self.word and return it
            data = []
            for i in range(length):
                data.append(struct.unpack('I', mem.read(self.word))[0])
            return data


    def write(self, data_in, offset = 0):
        try:
            data_length = len(data_in)
        except TypeError:
            data_length = 1 # Just one word
        else:
            if data_length <= 0:
                raise AssertionError            
        finally:
            if offset < 0: 
                raise AssertionError

            if offset + data_length > self.length:
                raise MemoryError('Write operation exceeds MMIO range.')

            self.debug('writing {0} bytes to offset {1}'.
                    format(data_length, hex(offset)))

            # Make reading easier (and faster... won't resolve dot in loops)
            mem = self.mem

            # Compensate for the base_address not being what the user requested
            offset += self.base_addr_offset

            # Check that the operation is going write to an aligned location
            if (offset & ~self.mask): 
                raise AssertionError

            # Seek to the aligned offset
            virt_base_addr = self.base_addr_offset & self.mask
            mem.seek(virt_base_addr + offset)

            # Write just one word
            if data_length == 1:
                mem.write(struct.pack('I', data_in))
            else:
                # Read until the end of our aligned address
                for i in range(0, data_length):
                    self.debug('writing at position = {0}: 0x{1:x}'.
                                format(self.mem.tell(), data_in[i]))
                    # Write one word at a time
                    mem.write(struct.pack('I', data_in[i]))

    def debug_set(self, value):
        self._debug = value

    def debug(self, debug_str):
        if self._debug: print('MMIO Debug: {0}'.format(debug_str))
