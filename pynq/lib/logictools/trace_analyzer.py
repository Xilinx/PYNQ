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


from collections import OrderedDict
from copy import deepcopy
import re
import subprocess
import numpy as np
from pynq import Clocks
from pynq import Xlnk
from pynq import MMIO
from pynq.lib import DMA
from .constants import *
from .logictools_controller import LogicToolsController
from .waveform import bitstring_to_wave


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


def get_tri_state_pins(io_pin_dict, tri_dict):
    """Function to check tri-state pin specifications.

    Any tri-state pin requires the input/output pin, and the tri-state
    selection pin to be specified. If any one is missing, this method will
    raise an exception.

    Parameters
    ----------
    io_pin_dict : dict
        A dictionary storing the input/output pin mapping.
    tri_dict : dict
        A dictionary storing the tri-state pin mapping.

    Returns
    -------
    list
        A list storing unique tri-state and non tri-state pin names.

    """
    io_pins = list(OrderedDict.fromkeys(io_pin_dict.keys()))
    tri_pins = list(OrderedDict.fromkeys(tri_dict.keys()))
    if set(tri_pins) & set(io_pins) != set(tri_pins):
        raise ValueError("Tri-state pins must specify I/O and tri-state pins.")

    return io_pins


class _MBTraceAnalyzer:
    """Class for the Trace Analyzer controlled by Microblaze.

    A typical use of this class is on the logictools overlay.

    This class can capture digital IO patterns / stimulus on all the pins.
    When a pin is specified as input, the response can be captured.

    On logictools overlay, multiple generators are sharing the same trace
    analyzer.

    Attributes
    ----------
    logictools_controller : LogicToolsController
        The generator controller for this class.
    mb_info : dict
        A dictionary storing Microblaze information, such as the 
        IP name and the reset name.
    intf_spec : dict
        The interface specification, e.g., PYNQZ1_LOGICTOOLS_SPECIFICATION.
    num_analyzer_samples : int
        The number of samples to be analyzed.
    samples : numpy.ndarray
        The raw data samples expressed in numpy array.
    frequency_mhz: float
        The frequency of the trace analyzer, in MHz.

    """
    def __init__(self, mb_info, intf_spec_name):
        """Return a new trace analyzer object.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        intf_spec_name : str/dict
            The name of the interface specification.

        """
        # Book-keep controller-related parameters
        if type(intf_spec_name) is str:
            self.intf_spec = eval(intf_spec_name)
        elif type(intf_spec_name) is dict:
            self.intf_spec = intf_spec_name
        else:
            raise ValueError("Interface specification has to be str or dict.")

        self.mb_info = mb_info
        self.logictools_controller = LogicToolsController(mb_info,
                                                          intf_spec_name)

        # Parameters to be cleared at reset
        self.num_analyzer_samples = 0
        self.samples = None
        self.frequency_mhz = 0

    def __repr__(self):
        """Disambiguation of the object.

        Users can call `repr(object_name)` to display the object information.

        """
        parameter_list = list()
        parameter_list.append('num_analyzer_samples={}'.format(
            self.num_analyzer_samples))
        parameter_list.append('frequency_mhz={}'.format(
            self.frequency_mhz))
        parameter_string = ", ".join(map(str, parameter_list))
        return '{}({})'.format(self.__class__.__name__, parameter_string)

    @property
    def status(self):
        """Return the analyzer's status.

        Returns
        -------
        str
            Indicating the current status of the analyzer; can be 
            'RESET', 'READY', or 'RUNNING'.

        """
        self.logictools_controller.check_status()
        return self.logictools_controller.status[self.__class__.__name__]

    def setup(self, num_analyzer_samples=DEFAULT_NUM_TRACE_SAMPLES,
              frequency_mhz=DEFAULT_CLOCK_FREQUENCY_MHZ,
              fclk_index=1):
        """Configure the trace analyzer.
        
        This method prepares the trace analyzer by sending configuration 
        parameters to the Microblaze.

        Note that the analyzer is always attached to the pins, so there
        is no need to use any method like 'connect()'. In short, once the 
        analyzer has been setup, it is connected as well.

        FCLK1 will be configured during this method.

        Note
        ----
        The first sample captured is a dummy sample (for both pattern 
        generator and FSM generator), therefore we have to allocate a buffer 
        one sample larger.

        Parameters
        ----------
        num_analyzer_samples : int
            The number of samples to be analyzed.
        frequency_mhz: float
            The frequency of the captured samples, in MHz.
        fclk_index : int
            The index of the fclk controlled by clock management object.

        """
        if not 1 <= num_analyzer_samples <= MAX_NUM_TRACE_SAMPLES:
            raise ValueError('Number of samples should be in '
                             '[1, {}]'.format(MAX_NUM_TRACE_SAMPLES))
        self.num_analyzer_samples = num_analyzer_samples

        if not MIN_CLOCK_FREQUENCY_MHZ <= frequency_mhz <= \
                MAX_CLOCK_FREQUENCY_MHZ:
            raise ValueError("Clock frequency out of range "
                             "[{}, {}]".format(MIN_CLOCK_FREQUENCY_MHZ,
                                               MAX_CLOCK_FREQUENCY_MHZ))
        setattr(self.logictools_controller.clk,
                "fclk{}_mhz".format(fclk_index), frequency_mhz)
        self.frequency_mhz = frequency_mhz

        trace_bit_width = self.intf_spec['monitor_width']
        trace_byte_width = round(trace_bit_width / 8)

        if 'trace_buf' in self.logictools_controller.buffers:
            buffer_phy_addr = self.logictools_controller.phy_addr_from_buffer(
                'trace_buf')
        else:
            buffer_phy_addr = self.logictools_controller.allocate_buffer(
                'trace_buf', 1 + self.num_analyzer_samples,
                data_type=BYTE_WIDTH_TO_CTYPE[trace_byte_width])

        self.logictools_controller.write_control([buffer_phy_addr,
                                                 1 + self.num_analyzer_samples,
                                                 0, 0])
        self.logictools_controller.write_command(CMD_CONFIG_TRACE)

        # Update generator status
        self.logictools_controller.check_status()

    def reset(self):
        """Reset the trace analyzer.

        This method will bring the trace analyzer from any state to 
        'RESET' state.

        """
        # Stop the running generator if necessary
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RUNNING':
            self.stop()

        # Clear the parameters
        self.num_analyzer_samples = 0
        self.samples = None
        self.frequency_mhz = 0

        # Send the reset command
        cmd_reset = CMD_RESET | TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_reset)
        self.logictools_controller.check_status()

    def run(self):
        """Start the trace analyzer.

        This method will send the run command to the Microblaze.

        """
        cmd_run = CMD_RUN | TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_run)
        self.logictools_controller.check_status()

    def step(self):
        """Step the trace analyzer.

        This method will send the step command to the Microblaze.

        """
        cmd_step = CMD_STEP | TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_step)
        self.logictools_controller.check_status()

    def stop(self):
        """Stop the trace analyzer.

        This method will send the stop command to the Microblaze.

        """
        cmd_stop = CMD_STOP | TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_stop)
        self.logictools_controller.check_status()

    def __del__(self):
        """Clean up the object when it is no longer used.

        Contiguous memory buffers have to be freed.

        """
        self.logictools_controller.reset_buffers()

    def analyze(self, steps):
        """Analyze the captured pattern.

        This function will process the captured pattern and put the pattern
        into a Wavedrom compatible format.

        Each bit of the 20-bit patterns, from LSB to MSB, corresponds to:
        D0, D1, ..., D18 (A4), D19 (A5), respectively.

        The data output is of format:

        [{'name': '', 'pin': 'D1', 'wave': '1...0.....'},
         {'name': '', 'pin': 'D2', 'wave': '0.1..01.01'}]

        Note the all the lanes should have the same number of samples.

        Note
        ----
        The first sample captured is a dummy sample (for both pattern generator
        and FSM generator), therefore we have to discard the first sample.

        Parameters
        ----------
        steps : int
            Number of samples to analyze, if it is non-zero, it means the 
            generator is working in the `step()` mode.

        Returns
        -------
        list
            A list of dictionaries, each dictionary consisting the pin number,
            and the waveform pattern in string format.

        """
        io_pins = get_tri_state_pins(self.intf_spec['traceable_io_pins'],
                                     self.intf_spec['traceable_tri_states'])
        trace_bit_width = self.intf_spec['monitor_width']
        trace_byte_width = round(trace_bit_width / 8)

        samples = self.logictools_controller.ndarray_from_buffer(
            'trace_buf', (1 + self.num_analyzer_samples) * trace_byte_width,
            dtype=BYTE_WIDTH_TO_NPTYPE[trace_byte_width])

        # Exclude the first dummy sample when not in step()
        data_type = '>i{}'.format(trace_byte_width)
        if steps == 0:
            num_valid_samples = len(samples) - 1
            self.samples = np.zeros(num_valid_samples, dtype=data_type)
            np.copyto(self.samples, samples[1:])
        else:
            num_valid_samples = 1
            self.samples = np.zeros(num_valid_samples, dtype=data_type)
            np.copyto(self.samples, samples[0])
        temp_bytes = np.frombuffer(self.samples, dtype=np.uint8)
        bit_array = np.unpackbits(temp_bytes)
        temp_lanes = bit_array.reshape(
            num_valid_samples,
            self.intf_spec['monitor_width']).T[::-1]

        wavelanes = list()
        for pin_label in io_pins:
            temp_lane = temp_lanes[
                self.intf_spec['traceable_io_pins'][pin_label]]
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = bitstring_to_wave(bitstring)
            wavelanes.append({'name': '', 'pin': pin_label, 'wave': wave})

        return wavelanes


class _PSTraceAnalyzer:
    """Class for the Trace Analyzer controlled by PS.

    A typical use of this class is on the base overlay.

    This class can capture digital IO patterns / stimulus on all the pins.
    There can by multiple such instances on the defined overlay.

    Attributes
    ----------
    trace_control : MMIO
        The trace controller associated with the analyzer.
    dma : DMA
        The PS controlled DMA object associated with the analyzer.
    intf_spec : dict
        The interface specification, e.g., PYNQZ1_PMODA_SPECIFICATION.
    num_analyzer_samples : int
        The number of samples to be analyzed.
    samples : numpy.ndarray
        The raw data samples expressed in numpy array.
    frequency_mhz: float
        The frequency of the trace analyzer, in MHz.
    clk : Clocks
        The clock management unit for the trace analyzer.
    xlnk : Xlnk
        The Xlnk object to control contiguous memory.

    """
    def __init__(self, ip_info, intf_spec_name):
        """Return a new PS controlled trace analyzer object. 

        The maximum sample rate is 100MHz. Usually the sample rate is set
        to no larger than 10MHz in order for the signals to be captured
        on pins / wires.

        For Pmod header, pin numbers 0-7 correspond to the pins on the
        Pmod interface.

        For Arduino header, pin numbers 0-13 correspond to D0-D13;
        pin numbers 14-19 correspond to A0-A5;
        pin numbers 20-21 correspond to SDA and SCL.

        Parameters
        ----------
        ip_info : dict
            The dictionary containing the IP associated with the analyzer.
        intf_spec_name : str/dict
            The name of the interface specification.

        """
        if type(intf_spec_name) is str:
            self.intf_spec = eval(intf_spec_name)
        elif type(intf_spec_name) is dict:
            self.intf_spec = intf_spec_name
        else:
            raise ValueError("Interface specification has to be str or dict.")

        trace_cntrl_info = ip_info['trace_cntrl_{}_0'.format(
            self.intf_spec['monitor_width'])]
        trace_dma_info = ip_info['axi_dma_0']
        self.trace_control = MMIO(trace_cntrl_info['phys_addr'],
                                  trace_cntrl_info['addr_range'])
        self.dma = DMA(trace_dma_info)
        self.num_analyzer_samples = 0
        self.samples = None
        self._cma_array = None
        self.frequency_mhz = 0
        self.clk = Clocks
        self.xlnk = Xlnk()
        self._status = 'RESET'

    def __repr__(self):
        """Disambiguation of the object.

        Users can call `repr(object_name)` to display the object information.

        """
        parameter_list = list()
        parameter_list.append('num_analyzer_samples={}'.format(
            self.num_analyzer_samples))
        parameter_list.append('frequency_mhz={}'.format(
            self.frequency_mhz))
        parameter_string = ", ".join(map(str, parameter_list))
        return '{}({})'.format(self.__class__.__name__, parameter_string)

    @property
    def status(self):
        """Return the analyzer's status.

        Returns
        -------
        str
            Indicating the current status of the analyzer; can be 
            'RESET', 'READY', or 'RUNNING'.

        """
        return self._status

    def setup(self, num_analyzer_samples=DEFAULT_NUM_TRACE_SAMPLES,
              frequency_mhz=DEFAULT_CLOCK_FREQUENCY_MHZ,
              fclk_index=3):
        """Configure the trace analyzer.

        This method prepares the trace analyzer by sending configuration 
        parameters to the Microblaze.

        Note that the analyzer is always attached to the pins, so there
        is no need to use any method like 'connect()'. In short, once the 
        analyzer has been setup, it is connected as well.

        FCLK3 will be configured during this method.

        Note
        ----
        The first sample captured is a dummy sample (for both pattern 
        generator and FSM generator), therefore we have to allocate a buffer 
        one sample larger.

        Parameters
        ----------
        num_analyzer_samples : int
            The number of samples to be analyzed.
        frequency_mhz: float
            The frequency of the captured samples, in MHz.
        fclk_index : int
            The index of the fclk controlled by clock management object.

        """
        if not 1 <= num_analyzer_samples <= MAX_NUM_TRACE_SAMPLES:
            raise ValueError('Number of samples should be in '
                             '[1, {}]'.format(MAX_NUM_TRACE_SAMPLES))
        self.num_analyzer_samples = num_analyzer_samples

        if not MIN_CLOCK_FREQUENCY_MHZ <= frequency_mhz <= \
                MAX_CLOCK_FREQUENCY_MHZ:
            raise ValueError("Clock frequency out of range "
                             "[{}, {}]".format(MIN_CLOCK_FREQUENCY_MHZ,
                                               MAX_CLOCK_FREQUENCY_MHZ))
        setattr(self.clk,
                "fclk{}_mhz".format(fclk_index), frequency_mhz)
        self.frequency_mhz = frequency_mhz

        trace_byte_width = round(self.intf_spec['monitor_width'] / 8)
        self._cma_array = self.xlnk.cma_array(
            [1, self.num_analyzer_samples],
            dtype=BYTE_WIDTH_TO_NPTYPE[trace_byte_width])
        self._status = 'READY'

    def reset(self):
        """Reset the trace analyzer.

        This method will bring the trace analyzer from any state to 
        'RESET' state.

        """
        if self._status == 'RUNNING':
            self.stop()

        self.samples = None
        self.num_analyzer_samples = 0
        self.frequency_mhz = 0
        if self._cma_array is not None:
            self._cma_array.close()
        self._status = 'RESET'

    def run(self):
        """Start the DMA to capture the traces.

        Return
        ------
        None

        """
        self.dma.recvchannel.transfer(self._cma_array)
        if self.intf_spec['monitor_width'] == 32:
            self.trace_control.write(TRACE_CNTRL_32_LENGTH, 
                                     self.num_analyzer_samples)
            self.trace_control.write(TRACE_CNTRL_32_DATA_COMPARE, 0)
            self.trace_control.write(TRACE_CNTRL_32_ADDR_AP_CTRL, 1)
            self.trace_control.write(TRACE_CNTRL_32_ADDR_AP_CTRL, 0)
        else:
            self.trace_control.write(TRACE_CNTRL_64_LENGTH, 
                                     self.num_analyzer_samples)
            self.trace_control.write(TRACE_CNTRL_64_DATA_COMPARE_MSW, 0)
            self.trace_control.write(TRACE_CNTRL_64_DATA_COMPARE_LSW, 0)
            self.trace_control.write(TRACE_CNTRL_64_ADDR_AP_CTRL, 1)
            self.trace_control.write(TRACE_CNTRL_64_ADDR_AP_CTRL, 0)

        self._status = 'RUNNING'

    def stop(self):
        """Stop the DMA after capture is done.

        Return
        ------
        None

        """
        self.dma.recvchannel.wait()
        self._status = 'READY'

    def __del__(self):
        """Destructor for trace buffer object.

        Returns
        -------
        None

        """
        if self._cma_array is not None:
            self._cma_array.close()

    def analyze(self, steps):
        """Analyze the captured pattern.

        This function will process the captured pattern and put the pattern
        into a Wavedrom compatible format.

        The data output is of format:

        [{'name': '', 'pin': 'D1', 'wave': '1...0.....'},
         {'name': '', 'pin': 'D2', 'wave': '0.1..01.01'}]

        Note the all the lanes should have the same number of samples.
        All the pins are assumed to be tri-stated and traceable.

        Currently only no `step()` method is supported for PS controlled 
        trace analyzer.

        Parameters
        ----------
        steps : int
            Number of samples to analyze. A value 0 means to analyze all the
            valid samples.

        Returns
        -------
        list
            A list of dictionaries, each dictionary consisting the pin number,
            and the waveform pattern in string format.

        """
        io_pins = get_tri_state_pins(self.intf_spec['traceable_io_pins'],
                                     self.intf_spec['traceable_tri_states'])

        if steps == 0:
            num_valid_samples = self.num_analyzer_samples
        else:
            num_valid_samples = steps

        trace_byte_width = round(self.intf_spec['monitor_width'] / 8)
        data_type = '>i{}'.format(trace_byte_width)
        self.samples = np.zeros(num_valid_samples, dtype=data_type)
        np.copyto(self.samples, self._cma_array)
        temp_bytes = np.frombuffer(self.samples, dtype=np.uint8)
        bit_array = np.unpackbits(temp_bytes)
        temp_lanes = bit_array.reshape(
            num_valid_samples,
            self.intf_spec['monitor_width']).T[::-1]

        wavelanes = list()
        for pin_label in io_pins:
            temp_lane = temp_lanes[
                self.intf_spec['traceable_io_pins'][pin_label]]
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = bitstring_to_wave(bitstring)
            wavelanes.append({'name': '', 'pin': pin_label, 'wave': wave})

        return wavelanes


class TraceAnalyzer:
    """Class for trace analyzer.

    This class can capture digital IO patterns / stimulus on monitored pins.

    This class can wrap one out of the two classes:
    (1) the Microblaze controlled trace analyzer, or (2) the PS controlled 
    trace analyzer.

    To use the PS controlled trace analyzer, users can set the `ip_info` to 
    a dictionary containing the corresponding IP name; for example:

    >>> ip_info = {'trace_cntrl':'trace_analyzer_pmoda/trace_cntrl_0',
        'trace_dma': 'trace_analyzer_pmoda/axi_dma_0'}

    Otherwise the Microblaze controlled trace analyzer will be used.
    By default, the Microblaze controlled version will be used, and the 
    interface specification name will be set to 
    `PYNQZ1_LOGICTOOLS_SPECIFICATION`.

    Most of the methods implemented inside this class assume the protocol 
    is known, so the pattern can be decoded and added to the annotation
    of the waveforms.

    In case the protocol is unknown, users should refrain from using these 
    methods.

    Two files are maintained by this class: the `csv` file, which is human
    readable; and the `sr` file, which is sigrok readable.

    """
    def __init__(self, ip_info,
                 intf_spec_name='PYNQZ1_LOGICTOOLS_SPECIFICATION'):
        """Initialize the trace analyzer.

        Note all the file paths are empty but will be set later. 
        Two files are maintained by this class: the `csv` file, which is human
        readable; and the `sr` file, which is sigrok readable. In addition to
        those two files, the `pd` file records the decoded transactions using
        sigrok.

        """
        if not ('ip_name' in ip_info and 'rst_name' in ip_info):
            self._trace_analyzer = _PSTraceAnalyzer(ip_info,
                                                    intf_spec_name)
        else:
            self._trace_analyzer = _MBTraceAnalyzer(ip_info,
                                                    intf_spec_name)
        self.protocol = None
        self.trace_csv = ''
        self.trace_sr = ''
        self.trace_pd = ''
        self.trace_txt = ''
        self.probes = OrderedDict({})
        self.intf_spec = self._trace_analyzer.intf_spec
        self.frequency_mhz = self._trace_analyzer.frequency_mhz
        self.samples = self._trace_analyzer.samples

        self.num_analyzer_samples = self._trace_analyzer.num_analyzer_samples
        self.num_decoded_samples = 0

    def __repr__(self):
        """Disambiguation of the object.

        Users can call `repr(object_name)` to display the object information.

        """
        return self.__repr__()

    @property
    def status(self):
        """Return the analyzer's status.

        Returns
        -------
        str
            Indicating the current status of the analyzer; can be 
            'RESET', 'READY', or 'RUNNING'.

        """
        return self._trace_analyzer.status

    def setup(self, num_analyzer_samples=DEFAULT_NUM_TRACE_SAMPLES,
              frequency_mhz=DEFAULT_CLOCK_FREQUENCY_MHZ,
              fclk_index=None):
        """Configure the trace analyzer.

        The wrapper method for configuring the PS or Microblaze controlled
        trace analyzer.

        Users need to provide the `fclk_index` explicitly, otherwise the driver
        will just use the default clock. For MB-controlled trace analyzer,
        the default `fclk_index` is 1; for PS-controlled trace analyzer,
        the default `fclk_index` is 3.

        Parameters
        ----------
        num_analyzer_samples : int
            The number of samples to be analyzed.
        frequency_mhz: float
            The frequency of the captured samples, in MHz.
        fclk_index : int
            The index of the fclk controlled by clock management object.

        """
        if fclk_index is None:
                self._trace_analyzer.setup(num_analyzer_samples, frequency_mhz)
        else:
                self._trace_analyzer.setup(num_analyzer_samples, frequency_mhz,
                                           fclk_index)
        self.frequency_mhz = self._trace_analyzer.frequency_mhz
        self.samples = self._trace_analyzer.samples
        self.num_analyzer_samples = self._trace_analyzer.num_analyzer_samples

    def reset(self):
        """Reset the trace analyzer.

        This method will bring the trace analyzer from any state to 
        'RESET' state.

        At the same time, all the trace files stored previously will be 
        removed.

        """
        self._trace_analyzer.reset()
        self.intf_spec = self._trace_analyzer.intf_spec
        self.frequency_mhz = self._trace_analyzer.frequency_mhz
        self.samples = self._trace_analyzer.samples

        self.num_analyzer_samples = self._trace_analyzer.num_analyzer_samples
        self.num_decoded_samples = 0

        if os.system('rm -rf ' + self.trace_csv):
            raise RuntimeError("Cannot remove trace csv file.")
        if os.system('rm -rf ' + self.trace_sr):
            raise RuntimeError("Cannot remove trace sr file.")
        if os.system('rm -rf ' + self.trace_pd):
            raise RuntimeError("Cannot remove trace pd file.")
        if os.system('rm -rf ' + self.trace_txt):
            raise RuntimeError("Cannot remove trace txt file.")

    def run(self):
        """Start the trace capture.

        Return
        ------
        None

        """
        self._trace_analyzer.run()

    def stop(self):
        """Stop the DMA after capture is done.

        Return
        ------
        None

        """
        self._trace_analyzer.stop()

    def step(self):
        """Step the trace analyzer.

        This method is only supported in the Microblaze controlled trace
        analyzer. An exception will be raised if users want to call this
        method in PS controlled trace analyzer.

        """
        self._trace_analyzer.step()

    def __del__(self):
        """Destructor for trace analyzer object.

        Returns
        -------
        None

        """
        self._trace_analyzer.__del__()

    def analyze(self, steps=0):
        """Analyze the captured pattern.

        This function will process the captured pattern and put the pattern
        into a Wavedrom compatible format.

        The data output is of format:

        [{'name': '', 'pin': 'D1', 'wave': '1...0.....'},
         {'name': '', 'pin': 'D2', 'wave': '0.1..01.01'}]

        Note the all the lanes should have the same number of samples.
        All the pins are assumed to be tri-stated and traceable.

        Currently only no `step()` method is supported for PS controlled 
        trace analyzer.

        Parameters
        ----------
        steps : int
            Number of samples to analyze. A value 0 means to analyze all the
            valid samples.

        Returns
        -------
        list
            A list of dictionaries, each dictionary consisting the pin number,
            and the waveform pattern in string format.

        """
        wavelanes = self._trace_analyzer.analyze(steps)
        self.samples = self._trace_analyzer.samples
        return wavelanes

    def set_protocol(self, protocol, probes):
        """Set the protocol and probes for the decoder.

        This method is usually called at beginning of the analyzer. To learn
        from that specific protocol, users can call `show_protocol` to learn
        useful information about that protocol.

        Currently only `i2c` and `spi` are supported.

        This method also sets the probe names for the decoder.

        The dictionary `probes` depends on the protocol. For instance, the I2C
        protocol requires the keys 'SCL' and 'SDA'. An example can be:

        >>>probes = {'SCL': 'D2', 'SDA': 'D3'}

        To avoid memory error for decoding, users can add `NC` as non-used
        pins to the probes.

        Parameters
        ----------
        protocol : str
            The name of the protocol.
        probes : dict
            A dictionary keeping the probe names and pin number.

        """
        self.protocol = protocol

        if not isinstance(probes, dict):
            raise ValueError("Probes have to be a dictionary.")
        else:
            self.probes = OrderedDict(probes)

    def show_protocol(self):
        """Show information about the specified protocol.

        This method will print out useful information about the protocol.

        Return
        ------
        None

        """
        if self.protocol is None:
            raise ValueError("Must set protocol before showing information.")

        result = subprocess.run(["sigrok-cli", "--protocol-decoders",
                                 self.protocol, "--show"],
                                stdout=subprocess.PIPE,
                                universal_newlines=True)
        print(result.stdout)

    def _csv_to_sr(self):
        """Translate the `*.csv` file to `*.sr` file.

        The translated `*.sr` files can be directly used in PulseView to show 
        the waveform.

        Note
        ----
        This method also modifies the input `*.csv` file (the comments, 
        usually 3 lines, will be removed).

        Return
        ------
        None

        """
        name, _ = os.path.splitext(self.trace_csv)
        self.trace_sr = name + ".sr"
        temp = name + ".temp"

        if os.system("rm -rf " + self.trace_sr):
            raise RuntimeError('Trace sr file cannot be deleted.')

        in_file = open(self.trace_csv, 'r')
        out_file = open(temp, 'w')

        for i, line in enumerate(in_file):
            if not line.startswith(';'):
                out_file.write(line)
        in_file.close()
        out_file.close()
        os.remove(self.trace_csv)
        os.rename(temp, self.trace_csv)

        command = "sigrok-cli -i " + self.trace_csv + \
                  " -I csv -o " + self.trace_sr
        if os.system(command):
            raise RuntimeError('Sigrok-cli csv to sr failed.')

    def _sr_to_csv(self):
        """Translate the `*.sr` file to `*.csv` file.

        The translated `*.csv` files can be used for interactive plotting. 
        `*.csv` file is human readable, and can be opened using text editor.

        Note
        ----
        This method also removes the redundant header that is generated by 
        sigrok.

        Return
        ------
        None

        """
        name, _ = os.path.splitext(self.trace_sr)
        self.trace_csv = name + ".csv"
        temp = name + ".temp"

        if os.system("rm -rf " + self.trace_csv):
            raise RuntimeError('Trace csv file cannot be deleted.')

        command = "sigrok-cli -i " + self.trace_sr + \
                  " -O csv > " + temp
        if os.system(command):
            raise RuntimeError('Sigrok-cli sr to csv failed.')

        in_file = open(temp, 'r')
        out_file = open(self.trace_csv, 'w')

        for i, line in enumerate(in_file):
            if not line.startswith(';'):
                out_file.write(line)
        in_file.close()
        out_file.close()
        os.remove(temp)

    def decode(self, trace_csv, start_pos, stop_pos,
               decoded_file, options=''):
        """Parse CSV file, add metadata, and use sigrok to decode transactions.

        Internally, this method is calling `save_csv()`, `set_metadata()`,
        and `sigrok_decode()` methods.

        Parameters
        ----------
        trace_csv : str
            Name of the output file (`*.csv`) which can be opened in 
            text editor.
        start_pos : int
            Starting sample number, no less than 1.
        stop_pos : int
            Stopping sample number, no more than the maximum number of samples.
        decoded_file : str
            Name of the output file, which can be opened in text editor.
        options : str
            Additional options to be passed to sigrok-cli.

        Return
        ------
        None
        
        """
        wave_lanes = self._save_csv(trace_csv, start_pos, stop_pos)
        self._set_metadata()
        self._sigrok_decode(decoded_file, options)
        annotation_lane = self._get_annotation()
        return wave_lanes + [{}] + annotation_lane

    def _save_csv(self, trace_csv, start_pos, stop_pos):
        """Parse the input data and generate a `*.csv` file.

        This method can be used along with the DMA. The input data is assumed
        to be 64-bit or 32-bit. The generated `*.csv` file can be then used
        as the trace file.

        This method also returns the wavelanes based on the given positions.
        The data output has a similar format as `analyze()`:

        [{'name': '', 'pin': 'D1', 'wave': '1...0.....'},
         {'name': '', 'pin': 'D2', 'wave': '0.1..01.01'}]

        Note
        ----
        The `trace_csv` file will be put into the specified path, or in the 
        working directory in case the path does not exist.

        Parameters
        ----------
        trace_csv : str
            Name of the output file (`*.csv`) which can be opened in 
            text editor.
        start_pos : int
            Starting sample number, no less than 1.
        stop_pos : int
            Stopping sample number, no more than the maximum number of samples.

        Returns
        -------
        list
            A list of dictionaries, each dictionary consisting the pin number,
            and the waveform pattern in string format.

        """
        if not self.probes:
            raise ValueError("Must set probes before parsing samples.")

        if not 1 <= start_pos <= stop_pos <= MAX_NUM_TRACE_SAMPLES:
            raise ValueError("Start or stop position out of range "
                             "[1, {}].".format(MAX_NUM_TRACE_SAMPLES))

        if os.path.isdir(os.path.dirname(trace_csv)):
            trace_csv_abs = trace_csv
        else:
            trace_csv_abs = os.getcwd() + '/' + trace_csv

        if os.system('rm -rf ' + trace_csv_abs):
            raise RuntimeError("Cannot remove old trace_csv file.")

        _ = get_tri_state_pins(self.intf_spec['traceable_io_pins'],
                               self.intf_spec['traceable_tri_states'])
        self.num_decoded_samples = stop_pos - start_pos
        temp_bytes = np.frombuffer(self.samples[start_pos:stop_pos],
                                   dtype=np.uint8)
        bit_array = np.unpackbits(temp_bytes)
        temp_lanes = bit_array.reshape(
            self.num_decoded_samples,
            self.intf_spec['monitor_width']).T[::-1]

        wavelanes = list()
        temp_samples = None
        for index, pin_name in enumerate(self.probes.keys()):
            pin_label = self.probes[pin_name]
            temp_lane = temp_lanes[
                self.intf_spec['traceable_io_pins'][pin_label]]
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = bitstring_to_wave(bitstring)
            wavelanes.append({'name': pin_name,
                              'pin': pin_label,
                              'wave': wave})

            temp_sample = temp_lane.reshape(-1, 1)
            if index == 0:
                temp_samples = deepcopy(temp_sample)
            else:
                temp_samples = np.concatenate((temp_samples, temp_sample),
                                              axis=1)

        np.savetxt(trace_csv_abs, temp_samples, fmt='%d', delimiter=',')
        self.trace_csv = trace_csv_abs
        self.trace_sr = ''

        return wavelanes

    def _set_metadata(self):
        """Set metadata for the trace.

        A `*.sr` file directly generated from `*.csv` will not have any 
        metadata. This method helps to set the sample rate, probe names, etc.

        Return
        ------
        None

        """
        if self.trace_sr == '':
            self._csv_to_sr()

        dir_name, _ = os.path.splitext(self.trace_sr)
        if os.system("rm -rf " + dir_name):
            raise RuntimeError('Directory cannot be deleted.')
        if os.system("mkdir " + dir_name):
            raise RuntimeError('Directory cannot be created.')
        if os.system("unzip -q " + self.trace_sr + " -d " + dir_name):
            raise RuntimeError('Unzip sr file failed.')

        metadata = open(dir_name + '/metadata', 'r')
        temp = open(dir_name + '/temp', 'w')
        pat = "rate=0 Hz"
        rate = self.frequency_mhz * 1e6
        subst = "rate=" + str(rate) + " Hz"
        j = 0
        probe_list = list(self.probes.keys())
        for line in metadata:
            if line.startswith("probe"):
                temp.write("probe" + str(j + 1) + "=" +
                           str(probe_list[j]) + '\n')
                j += 1
            else:
                temp.write(line.replace(pat, subst))
        metadata.close()
        temp.close()

        if os.system("rm -rf " + dir_name + '/metadata'):
            raise RuntimeError('Cannot remove metadata folder.')
        if os.system("mv " + dir_name + '/temp ' + dir_name + '/metadata'):
            raise RuntimeError('Cannot rename metadata folder.')
        if os.system("cd " + dir_name + "; zip -rq " +
                     self.trace_sr + " * ; cd .."):
            raise RuntimeError('Zip sr file failed.')
        if os.system("rm -rf " + dir_name):
            raise RuntimeError('Cannot remove temporary folder.')

    def _sigrok_decode(self, decoded_file, options=''):
        """Decode and record the trace based on the protocol specified.

        The `decoded_file` contains the name of the output file.

        The `option` specifies additional options to be passed to sigrok-cli.
        For example, users can use option=':wordsize=9:cpol=1:cpha=0' to add 
        these options for the SPI decoder.

        The decoder will also ignore the pin collected but not required for 
        decoding.

        Note
        ----
        The output file will have `*.pd` extension.

        Note
        ----
        The decoded file will be put into the specified path, or in the 
        working directory in case the path does not exist.

        Parameters
        ----------
        decoded_file : str
            Name of the output file, which can be opened in text editor.
        options : str
            Additional options to be passed to sigrok-cli.

        Return
        ------
        None

        """
        if os.path.isdir(os.path.dirname(decoded_file)):
            decoded_abs = decoded_file
        else:
            decoded_abs = os.getcwd() + '/' + decoded_file

        dir_name, _ = os.path.splitext(self.trace_sr)
        txt_file = dir_name + '.txt'
        if os.system('rm -rf ' + txt_file):
            raise RuntimeError("Cannot remove temporary txt file.")
        if os.system('rm -rf ' + decoded_abs):
            raise RuntimeError("Cannot remove old decoded file.")

        self.trace_pd = ''
        pd_annotation = ''
        for i in list(self.probes.keys()):
            if i != 'NC':
                pd_annotation += (':' + i.lower() + '=' + i)
        command = "sigrok-cli -i " + self.trace_sr + " -P " + \
                  self.protocol + options + pd_annotation + (' > ' + txt_file)
        if os.system(command):
            raise RuntimeError('Sigrok-cli decode failed.')

        f_decoded = open(decoded_abs, 'w')
        f_temp = open(txt_file, 'r')
        j = 0
        for line in f_temp:
            m = re.search('([0-9]+)-([0-9]+)( +)(.*)', line)
            if m:
                while j < int(m.group(1)):
                    f_decoded.write('x\n')
                    j += 1
                f_decoded.write(m.group(4) + '\n')
                j += 1
                while j < int(m.group(2)):
                    f_decoded.write('.\n')
                    j += 1
        for i in range(j, self.num_decoded_samples):
            f_decoded.write('x\n')

        f_temp.close()
        f_decoded.close()
        self.trace_pd = decoded_abs
        self.trace_txt = txt_file

        if os.path.getsize(self.trace_pd) == 0:
            raise RuntimeError("No transactions and decoded file is empty.")

    def _get_annotation(self):
        """Get the decoded transactions as annotation to the wavelanes.

        The sigrok decoded transactions can be added into the wavelanes
        so that the decoded transactions can also be shown in the waveform.

        The returned annotation has the following format:
        [{name: '', 
          wave: 'x.444x4.x', 
          data: ['read', 'write', 'read', 'data']}]

        Returns
        -------
        list
            A list containing one dictionary, having the same format as 
            wavelane.

        """
        if self.trace_pd == '':
            raise ValueError("Must have decoded trace before annotating.")

        pd_file = open(self.trace_pd, 'r')
        annotation_lane = [{'name': '', 'wave': '', 'data': list()}]
        i = 0
        for pd_line in pd_file:
            if pd_line is not None:
                pd_data = pd_line.rstrip()
            else:
                pd_data = 'x'

            if str(pd_data) in ['x', '.']:
                annotation_lane[0]['wave'] += str(pd_data)
            else:
                annotation_lane[0]['wave'] += '4'
                annotation_lane[0]['data'].append(str(pd_data))
            i += 1
        pd_file.close()

        return annotation_lane

    def get_transactions(self):
        """List all the transactions captured.

        The transaction list will only be non-empty after users have run
        `decode()` method. An exception will be raised if the transaction
        is empty, or the text file cannot be found.

        Returns
        -------
        list
            A list of dictionaries. Each bus event is a dictionary:
            [{'command': str, 'begin': int, 'end': int}]
        """
        transactions = list()
        if not self.trace_txt:
            raise ValueError("Trace has to be decoded first.")

        zero_based_correction = 1
        with open(self.trace_txt, 'r') as f:
            i = 1
            for line in f:
                m = re.search('(?P<begin>[0-9]+)-(?P<end>[0-9]+)' +
                              '(?P<whitespace> +)(?P<command>.*)', line)
                if m:
                    cmd = dict()
                    cmd['command'] = m.group('command')
                    cmd['begin'] = int(m.group('begin'))+zero_based_correction
                    cmd['end'] = int(m.group('end'))+zero_based_correction
                    transactions.append(cmd)
                i += 1

        return transactions
