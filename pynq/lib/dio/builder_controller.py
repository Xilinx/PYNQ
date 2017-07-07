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
import numpy as np
from pynq import PL
from pynq import Clocks
from pynq import Xlnk
from pynq import Register
from pynq.lib import PynqMicroblaze
from .constants import *


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "yunq@xilinx.com"


class BuilderController(PynqMicroblaze):
    """This class controls all the builders using a Microblaze instances.

    This class uses the PynqMicroblaze class. It extends 
    PynqMicroblaze with capability to control boolean builders, pattern
    builders, and Finite State Machine (FSM) builders.

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
    intf_spec : dict
        The interface specification, e.g., PYNQZ1_DIO_SPECIFICATION.
    pin_map : dict
        A dictionary of pins available from the interface specification.
    status : dict
        A dictionary keeping track of the builder status.

    """
    __instance = None
    __initialized = False
    __time_stamp = None

    def __new__(cls, mb_info, intf_spec_name):
        """Create a new Microblaze object.

        This method overwrites the default `new()` method so that the same
        instance can be reused by many modules. The internal variable 
        `__instance` is private and used as a singleton.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        intf_spec_name : str
            The name of the interface specification.

        Examples
        --------
        The `mb_info` is a dictionary storing Microblaze information:

        >>> mb_info = {'ip_name': 'mb_bram_ctrl_3',
        'rst_name': 'mb_reset_3', 
        'intr_pin_name': 'iop3/dff_en_reset_0/q', 
        'intr_ack_name': 'mb_3_intr_ack'}

        """
        if cls.__instance is None or cls.__time_stamp != PL.timestamp:
            cls.__instance = PynqMicroblaze.__new__(cls)
            cls.__time_stamp = PL.timestamp
            cls.__initialized = False
        return cls.__instance

    def __init__(self, mb_info, intf_spec_name):
        """Initialize the created Microblaze object.

        This method leverages the initialization method of its parent. It 
        also deals with relative / absolute path of the program.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        intf_spec_name : str
            The name of the interface specification.

        Examples
        --------
        The `mb_info` is a dictionary storing Microblaze information:

        >>> mb_info = {'ip_name': 'mb_bram_ctrl_3',
        'rst_name': 'mb_reset_3', 
        'intr_pin_name': 'iop3/dff_en_reset_0/q', 
        'intr_ack_name': 'mb_3_intr_ack'}

        """
        if not os.path.isabs(INTF_MICROBLAZE_BIN):
            mb_program = os.path.join(BIN_LOCATION, INTF_MICROBLAZE_BIN)
        else:
            mb_program = INTF_MICROBLAZE_BIN

        if not self.__initialized:
            super().__init__(mb_info, mb_program)

            self.clk = Clocks
            self.buf_manager = Xlnk()
            self.buffers = dict()
            self.status = {k: 'RESET'
                           for k in BUILDER_ENGINE_DICT.keys()}
            self.intf_spec = eval(intf_spec_name)
            pin_list = list(
                set(self.intf_spec['traceable_outputs'].keys()) |
                set(self.intf_spec['traceable_inputs'].keys()) |
                set(self.intf_spec['non_traceable_outputs'].keys()) |
                set(self.intf_spec['non_traceable_inputs'].keys()))
            self.pin_map = {k: 'UNUSED' for k in pin_list}
            self.__class__.__initialized = True

    def program(self):
        """This method programs the Microblaze.

        This method is called in `__init__()`; it can also be called after 
        that. It overwrites the `program()` method defined in the parent class.

        """
        super().reset()
        PL.load_ip_data(self.ip_name, self.mb_program)
        if self.interrupt:
            self.interrupt.clear()
        super().run()

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

    def check_status(self):
        """Check the status of all the builders.

        This method will send the command to the Microblaze, and wait for the 
        Microblaze to return the status for all the builder.

        """
        self.write_command(CMD_CHECK_STATUS)
        one_hot_status_list = self.read_results(len(BUILDER_ENGINE_DICT))
        builder_name_list = BUILDER_ENGINE_DICT.keys()
        for builder_name, one_hot_status in zip(builder_name_list,
                                                one_hot_status_list):
            for state_name, state_code in BUILDER_STATE.items():
                if one_hot_status == state_code:
                    self.status[builder_name] = state_name
                    break

    def reset(self, builder_list):
        """Reset the specified builders.

        After reset, the corresponding builders will have to be setup again
        before it can be run or step. During reset, each builder will be 
        stopped first.

        Parameters
        ----------
        builder_list : list
            A list of builders in any state, each being a builder object.

        """
        self.stop(builder_list)
        cmd_reset = CMD_RESET
        for builder in builder_list:
            builder_type = builder.__class__.__name__
            cmd_reset |= BUILDER_ENGINE_DICT[builder_type]
            if builder.analyzer is not None:
                analyzer_type = builder.analyzer.__class__.__name__
                cmd_reset |= BUILDER_ENGINE_DICT[analyzer_type]
        self.write_command(cmd_reset)
        for builder in builder_list:
            builder.reset()
        self.check_status()

    def run(self, builder_list):
        """Send the command `RUN` to the Microblaze.

        Send the command to the Microblaze, and wait for the Microblaze
        to return control.

        Valid builders must be objects of BooleanBuilder, PatternBuilder, 
        FSMBuilder, or TraceAnalyzer.

        Parameters
        ----------
        builder_list : list
            A list of READY builders, each being a builder object.

        """
        cmd_run = CMD_RUN
        for builder in builder_list:
            builder_type = builder.__class__.__name__
            if self.status[builder_type] == 'RESET':
                raise ValueError(
                        f"{builder_type} must be at least READY "
                        f"before RUNNING.")
            else:
                builder.connect()
                cmd_run |= BUILDER_ENGINE_DICT[builder_type]
                if builder.analyzer is not None:
                    analyzer_type = builder.analyzer.__class__.__name__
                    cmd_run |= BUILDER_ENGINE_DICT[analyzer_type]
        self.write_command(cmd_run)
        self.check_status()

    def step(self, builder_list):
        """Send the command `STEP` to the Microblaze.

        Send the command to the Microblaze, and wait for the Microblaze
        to return control.

        Valid builders must be objects of BooleanBuilder, PatternBuilder, 
        FSMBuilder, or TraceAnalyzer.

        Parameters
        ----------
        builder_list : list
            A list of READY builders, each being a builder object.

        """
        cmd_step = CMD_STEP
        for builder in builder_list:
            builder_type = builder.__class__.__name__
            if self.status[builder_type] == 'RESET':
                raise ValueError(
                    f"{builder_type} must be at least READY "
                    f"before RUNNING.")
            else:
                builder.connect()
                cmd_step |= BUILDER_ENGINE_DICT[builder_type]
                if builder.analyzer is not None:
                    analyzer_type = builder.analyzer.__class__.__name__
                    cmd_step |= BUILDER_ENGINE_DICT[analyzer_type]
        self.write_command(cmd_step)
        self.check_status()

    def stop(self, builder_list):
        """Send the command `STOP` to the Microblaze.

        Send the command to the Microblaze, and wait for the Microblaze
        to return control.

        Valid builders must be objects of BooleanBuilder, PatternBuilder, 
        FSMBuilder, or TraceAnalyzer.

        Parameters
        ----------
        builder_list : list
            A list of RUNNING builders, each being a builder object.

        """
        cmd_stop = CMD_STOP
        for builder in builder_list:
            builder_type = builder.__class__.__name__
            cmd_stop |= BUILDER_ENGINE_DICT[builder_type]
            if builder.analyzer is not None:
                analyzer_type = builder.analyzer.__class__.__name__
                cmd_stop |= BUILDER_ENGINE_DICT[analyzer_type]
        self.write_command(cmd_stop)
        for builder in builder_list:
            builder.disconnect()
        self.check_status()

    def __del__(self):
        """Clean up the object when it is no longer used.

        Contiguous memory buffers have to be freed.

        """
        self.reset_buffers()

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
            del (self.buffers[name])

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
        # Read switch config
        self.write_command(CMD_READ_INTF_SWITCH_CONFIG)
        mailbox_addr = self.mmio.base_addr + MAILBOX_OFFSET
        ioswitch_config = [Register(addr)
                           for addr in [mailbox_addr, mailbox_addr + 4]]

        # Modify switch for requested entries
        for ix in ioswitch_pins:
            if ix < 10:
                lsb = ix * 2
                msb = ix * 2 + 1
                ioswitch_config[0][msb:lsb] = ioswitch_select_value
            else:
                lsb = (ix - 10) * 2
                msb = (ix - 10) * 2 + 1
                ioswitch_config[1][msb:lsb] = ioswitch_select_value

        # Write switch config
        self.write_command(CMD_INTF_SWITCH_CONFIG)
