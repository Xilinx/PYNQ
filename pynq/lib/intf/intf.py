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

import numpy as np
from pynq import MMIO
from pynq import GPIO
from pynq import PL
from pynq import Clocks
from pynq import Xlnk
from pynq import Register
from . import intf_const

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "yunq@xilinx.com"


class _INTF:
    """This class controls the digital interface instances in the system.

    This class servers as the agent to communicate with the interface
    processor in PL. The interface processor has a Microblaze which
    can be reprogrammed to interface with digital IO pins.

    The functions (or types) available for the interface agent include
    Combination Function Generator, Pattern Generator,
    and Finite State Machine.

    Attributes
    ----------
    mb_program : str
        The absolute path of the Microblaze program.
    state : str
        The status (IDLE, RUNNING, or STOPPED) of the interface.
    gpio : GPIO
        The GPIO instance associated with this interface.
    mmio : MMIO
        The MMIO instance associated with this interface.
    clk : Clocks
        The instance to control PL clocks.
    buf_manager : Xlnk
        The Xlnk memory manager used for contiguous memory allocation.
    buffers : dict
        A dictionary of cffi.FFI.CData buffer, each can be accessed similarly
        as arrays.

    """

    def __init__(self, ip_name, addr_base, addr_range, gpio_uix, mb_program):
        """Create a new interface object.

        Parameters
        ----------
        ip_name : str
            The name of the IP corresponding to the interface.
        addr_base : int
            The base address for the MMIO in hex format.
        addr_range : int
            The address range for the MMIO in hex format.
        gpio_uix : int
            The user index of the GPIO, starting from 0.
        mb_program : str
            The Microblaze program loaded for the interface.

        """
        self.ip_name = ip_name
        self.mb_program = intf_const.BIN_LOCATION + mb_program
        self.state = 'IDLE'
        self.addr_base = addr_base
        self.gpio = GPIO(GPIO.get_gpio_pin(gpio_uix), "out")
        self.mmio = MMIO(addr_base, addr_range)
        self.clk = Clocks
        self.buf_manager = Xlnk()
        self.buffers = dict()
        self.armed_builders = {k: False for k in intf_const.CMDS_ARM_BUILDER_LIST}


        self.program()

    def start(self):
        """Start the Microblaze of the current interface.

        This method will update the status of the interface.

        Returns
        -------
        None

        """
        self.state = 'RUNNING'
        self.gpio.write(0)

    def reset(self):
        """Stop the Microblaze of the current interface.

        This method will update the status of the interface.

        Returns
        -------
        None

        """
        self.state = 'STOPPED'
        self.gpio.write(1)

    def program(self):
        """This method programs the Microblaze of the interface.

        This method is called in __init__(); it can also be called after that.
        It uses the attribute "self.mb_program" to program the Microblaze.

        Returns
        -------
        None

        """
        self.reset()
        PL.load_ip_data(self.ip_name, self.mb_program)
        self.start()

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
        for i, j in enumerate(ctrl_parameters):
            self.mmio.write(intf_const.MAILBOX_OFFSET + 4 * i, j)

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
        return [self.mmio.read(intf_const.MAILBOX_OFFSET + i * 4)
                for i in range(num_words)]

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
        self.mmio.write(intf_const.MAILBOX_OFFSET +
                        intf_const.MAILBOX_PY2DIF_CMD_OFFSET, command)
        while not (self.mmio.read(intf_const.MAILBOX_OFFSET +
                                  intf_const.MAILBOX_PY2DIF_CMD_OFFSET) == 0):
            pass

        # Bookkeeping on which builders are armed
        if command in self.armed_builders:
            self.armed_builders[command] = True
        elif command == intf_const.CMD_RUN:
            self.armed_builders = {k: False for k in self.armed_builders}

    def run(self):
        """Run the command.
        
        Send the run command to the Microblaze, and wait for the Microblaze
        to return control.

        """
        self.write_command(intf_const.CMD_RUN)

    def stop(self):
        """Run the command.

        Send the stop command to the Microblaze, and wait for the Microblaze
        to return control.

        """
        self.write_command(intf_const.CMD_STOP)

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

    def get_phy_addr_from_buffer(self, name):
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
        mailbox_addr = self.addr_base + intf_const.MAILBOX_OFFSET
        self.write_command(intf_const.CMD_READ_INTF_SWITCH_CONFIG)
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
        self.write_command(intf_const.CMD_INTF_SWITCH_CONFIG)


def request_intf(if_id=intf_const.ARDUINO, mb_program=intf_const.INTF_MICROBLAZE_BIN):
    """This is the interface to request an I/O Processor.

    It looks for active instances on the same interface ID, and prevents
    users from instantiating different types of interfaces on the same ID.
    Users are notified with an exception if the selected interface is already 
    hooked to another type of interface, to prevent unwanted behavior.

    Two cases:
    1.  No previous interface in the system with the same ID, or users want to
    request another instance with the same program. 
    Do not raises an exception.
    2.  There is A previous interface in the system with the same ID. Users 
    want to request another instance with a different program. 
    Raises an exception.

    Note
    ----
    When an interface is already in the system with the same interface ID, 
    users are in danger of losing the old instances.

    For bitstream `interface.bit`, the interface IDs are
    {1, 2, 3} <=> {PMODA, PMODB, ARDUINO}.
    For different bitstreams, this mapping can be different.

    Parameters
    ----------
    if_id : int
        Interface ID (1, 2, 3) corresponding to (PMODA, PMODB, ARDUINO).
    mb_program : str
        Program to be loaded on the interface controller.

    Returns
    -------
    _INTF
        An _INTF object with the updated Microblaze program.

    Raises
    ------
    ValueError
        When the INTF name or the GPIO name cannot be found in the PL.
    LookupError
        When another INTF is in the system with the same interface ID.

    """
    ip_dict = PL.ip_dict
    gpio_dict = PL.gpio_dict
    dif = f"mb_bram_ctrl_{if_id}"
    rst_pin = f"mb_{if_id}_reset"

    ip = [k for k, _ in ip_dict.items()]
    gpio = [k for k, _ in gpio_dict.items()]

    if dif not in ip:
        raise ValueError("No such IP for INTF {}.".format(if_id))
    if rst_pin not in gpio:
        raise ValueError("No such GPIO pin for INTF {}.".format(if_id))

    addr_base = ip_dict[dif]['phys_addr']
    addr_range = ip_dict[dif]['addr_range']
    ip_state = ip_dict[dif]['state']
    gpio_uix = gpio_dict[rst_pin]['index']

    if (ip_state is None) or \
        (ip_state == (intf_const.BIN_LOCATION + mb_program)):
        # case 1
        return _INTF(dif, addr_base, addr_range, gpio_uix, mb_program)
    else:
        # case 2
        raise LookupError('Another INTF program {} already running. '
                          .format(ip_state))
