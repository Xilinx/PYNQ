#   Copyright (c) 2016, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import os
import math
import numpy as np
from pynq import PL
from pynq import Clocks
from pynq import Xlnk
from pynq import Register
from . import MAILBOX_OFFSET
from . import MAILBOX_PY2DIF_CMD_OFFSET
from . import BIN_LOCATION
from . import CMD_RUN
from . import CMD_STOP
from . import CMD_READ_INTF_SWITCH_CONFIG


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "yunq@xilinx.com"


class Intf(PynqMicroblaze):
    """This class controls the Intf Microblaze instances in the system.

    This class inherits from the PynqMicroblaze class. It extends 
    PynqMicroblaze with capability to control boolean generators, pattern
    generators, and Finite State Machine (FSM) generators.

    Attributes
    ----------
    ip_name : str
        The name of the IP corresponding to the Microblaze.
    rst_name : str
        The name of the reset pin for the Microblaze.
    mb_program : str
        The absolute path of the Microblaze program.
    state : str
        The status (IDLE, RUNNING, or STOPPED) of the Microblaze.
    reset : GPIO
        The reset pin associated with the Microblaze.
    mmio : MMIO
        The MMIO instance associated with the Microblaze.
    interrupt : Event
        An asyncio.Event-like class for waiting on and clearing interrupts.
    clk : Clocks
        The instance to control PL clocks.
    buf_manager : Xlnk
        The Xlnk memory manager used for contiguous memory allocation.
    buffers : dict
        A dictionary of cffi.FFI.CData buffer, each can be accessed similarly
        as arrays.

    """

    def __init__(self, mb_info, mb_program):
        """Create a new Microblaze object.

        This method leverages the initialization method of its parent. It 
        also deals with relative / absolute path of the program.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        mb_program : str
            The Microblaze program loaded for the processor.

        Examples
        --------
        The `mb_info` is a dictionary storing Microblaze information:

        >>> mb_info = {'ip_name': 'mb_bram_ctrl_3',
        'rst_name': 'mb_reset_3', 
        'intr_pin_name': 'iop3/dff_en_reset_0/q', 
        'intr_ack_name': 'mb_3_intr_ack'}

        """
        if not os.path.isabs(mb_program):
            mb_program = os.path.join(BIN_LOCATION, mb_program)

        super().__init__(mb_info, mb_program)
        self.clk = Clocks
        self.buf_manager = Xlnk()
        self.buffers = dict()

    def write_control(self, ctrl_parameters):
        """This method writes control parameters to the Microblaze.

        Parameters
        ----------
        ctrl_parameters : list
            A list of control parameters, each being an int.

        Returns
        -------
        None

        """
        self.write(MAILBOX_OFFSET, ctrl_parameters)

    def read_results(self, num_words):
        """This method reads results from the Microblaze.

        Parameters
        ----------
        num_words : int
            Number of 32b words to read from Microblaze mailbox.

        Returns
        -------
        list
            list of results read from mailbox

        """
        return self.read(MAILBOX_OFFSET, num_words)

    def write_command(self, command):
        """This method writes the commands to the Microblaze.

        The program waits in the loop until the command is cleared by the
        Microblaze.

        Parameters
        ----------
        command : int
            The command to write to the Microblaze.

        Returns
        -------
        None

        """
        self.write(MAILBOX_OFFSET + MAILBOX_PY2DIF_CMD_OFFSET, command)
        while self.read(MAILBOX_OFFSET + MAILBOX_PY2DIF_CMD_OFFSET) != 0:
            pass

    def start(self):
        """Send the command `RUN` to the Microblaze.
        
        Send the command to the Microblaze, and wait for the Microblaze
        to return control.

        """
        self.write_command(CMD_RUN)

    def stop(self):
        """Send the command `STOP` to the Microblaze.

        Send the command to the Microblaze, and wait for the Microblaze
        to return control.

        """
        self.write_command(CMD_STOP)

    def allocate_buffer(self, name, num_samples, data_type="unsigned int"):
        """This method allocates the source or the destination buffers.

        Usually, the source buffer stores 32-bit samples, while the
        destination buffer stores 64-bit samples.

        Note that the numpy array has to be deep-copied before users can
        free the buffer.

        Parameters
        ----------
        name : str
            The name of the string, used for indexing the buffers.
        num_samples : int
            The number of samples that needs to be generated or captured.
        data_type : str
            The type of the data.

        Returns
        -------
        int
            The address of the source or destination buffer.

        """
        buf = self.buf_manager.cma_alloc(num_samples,
                                         data_type=data_type)
        self.buffers[name] = buf
        return self.buf_manager.cma_get_phy_addr(buf)

    def ndarray_from_buffer(self, name, num_bytes, dtype=np.uint32):
        """This method returns a numpy array from the buffer.

        If not data type is specified, the returned numpy array will have
        data type as `numpy.uint32`.

        The numpy array is copied. Hence even if the underlying buffer is
        freed, the returned numpy array is still usable.

        Parameters
        ----------
        name : str
            The name of the buffer where the numpy array can be constructed.
        num_bytes : int
            The length of the buffer, in bytes.
        dtype : str
            Data type of the numpy array.

        Returns
        -------
        numpy.ndarray
            The numpy array constructed from the buffer.

        """
        if name not in self.buffers:
            raise ValueError(f"No such buffer {name} allocated previously.")
        buffer = self.buffers[name]
        buf_temp = self.buf_manager.cma_get_buffer(buffer,
                                                   num_bytes)
        return np.frombuffer(buf_temp, dtype=dtype).copy()

    def free_buffer(self, name):
        """This method frees the buffer.

        Note that the numpy array built on top of the buffer should be
        deep-copied before users can free the buffer.

        Parameters
        ----------
        name : str
            The name of the buffer to be freed.

        """
        if name in self.buffers:
            self.buf_manager.cma_free(self.buffers[name])
            del(self.buffers[name])
        else:
            raise ValueError(f"No such buffer {name} allocated previously.")

    def phy_addr_from_buffer(self, name):
        """Get the physical address from the buffer.

        The method takes the name of the buffer as input, and returns the 
        physical address.
        
        Parameters
        ----------
        name : str
            The name of the buffer.
        
        Returns
        -------
        int
            The physical address of the buffer.

        """
        if name not in self.buffers:
            raise ValueError(f"No such buffer {name} allocated previously.")
        return self.buf_manager.cma_get_phy_addr(self.buffers[name])

    def reset_buffers(self):
        """This method resets all the buffers.

        Note that the numpy array built on top of the buffer should be
        deep-copied before users can free the buffer.

        """
        if self.buffers:
            for name in self.buffers:
                self.buf_manager.cma_free(self.buffers[name])
        self.buffers = dict()

    def config_ioswitch(self, ioswitch_pins, ioswitch_select_value):
        """Configure the IO switch.

        This method configures the IO switch based on the input parameters.

        Parameters
        ----------
        ioswitch_pins : list
            List of pins to be configured.
        ioswitch_select_value : int
            Function selection parameter.
        
        """
        # read switch config
        self.write_command(CMD_READ_INTF_SWITCH_CONFIG)
        mailbox_addr = self.mmio.base_addr + MAILBOX_OFFSET
        ioswitch_config = [Register(addr)
                           for addr in [mailbox_addr, mailbox_addr + 4]]

        # modify switch for requested entries
        for ix in ioswitch_pins:
            if ix < 10:
                lsb = ix * 2
                msb = ix * 2 + 1
                ioswitch_config[0][msb:lsb] = ioswitch_select_value
            else:
                lsb = (ix - 10) * 2
                msb = (ix - 10) * 2 + 1
                ioswitch_config[1][msb:lsb] = ioswitch_select_value

        # write switch config
        self.write_command(CMD_INTF_SWITCH_CONFIG)
