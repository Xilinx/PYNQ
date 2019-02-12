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
from copy import deepcopy
from math import ceil, log
import numpy as np
from .constants import *
from .logictools_controller import LogicToolsController
from .trace_analyzer import TraceAnalyzer
from .waveform import Waveform


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


def check_pins(fsm_spec, key, intf_spec):
    """Check whether the pins specified are in a valid range.

    This method will raise an exception if `pin` is out of range.

    Parameters
    ----------
    fsm_spec : dict
        The dictionary where the check to be made.
    key : object
        The key to index the dictionary.
    intf_spec : dict
        An interface spec containing the pin map.

    """
    for i in fsm_spec[key]:
        if i[1] not in intf_spec['traceable_io_pins']:
            raise ValueError("{} not in output pin map - "
                             "please check fsm_spec.".format(i[1]))


def check_num_bits(num_bits, label, minimum=0, maximum=32):
    """Check whether the number of bits are still in a valid range.

    This method will raise an exception if `num_bits` is out of range.

    Parameters
    ----------
    num_bits : int
        The number of bits of a specific field.
    label : str
        The label of the field.
    minimum : int
        The minimum number of bits allowed in that field.
    maximum : int
        The maximum number of bits allowed in that field.

    """
    if not minimum <= num_bits <= maximum:
        raise ValueError('{} bits used for {}, out of range: ' +
                         '[{}, {}].'.format(num_bits, label, minimum, maximum))


def check_moore(num_states, num_outputs):
    """Check whether the specified state machine is a moore machine.

    This method will raise an exception if there are more state outputs
    than the number of states.

    Parameters
    ----------
    num_states : int
        The number of bits used for states.
    num_outputs : int
        The number of state outputs.

    """
    if num_states < num_outputs:
        raise ValueError("Specified FSM is not Moore: " +
                         "{} states but {} outputs.".format(
                             num_states, num_outputs))


def check_duplicate(fsm_spec, key):
    """Function to check duplicate entries in a nested dictionary.

    This method will check the entry indexed by key in a dictionary. An
    exception will be raised if there are duplicated entries.

    Parameters
    ----------
    fsm_spec : dict
        The dictionary where the check to be made.
    key : object
        The key to index the dictionary.

    """
    if key == 'inputs' or key == 'outputs':
        name_list = [pair[0] for pair in fsm_spec[key]]
        pin_list = [pair[1] for pair in fsm_spec[key]]
        if len(set(name_list)) < len(name_list):
            raise ValueError('Duplicate names in {}.'.format(key))
        if len(set(pin_list)) < len(pin_list):
            raise ValueError('Duplicate pins in {}.'.format(key))
    else:
        entries = [item for item in fsm_spec[key]]
        if len(set(entries)) < len(entries):
            raise ValueError('Duplicate entries in {}.'.format(key))


def check_pin_conflict(pins1, pins2):
    """Function to check whether there is conflict between input / output pins.

    This method will raise an exception if there are pins specified in both
    inputs and outputs.

    Parameters
    ----------
    pins1 : list
        The list of the first set of pins.
    pins2 : list
        The list of the second set of pins.

    """
    if not set(pins1).isdisjoint(pins2):
        raise ValueError(
            'I/O pin conflicts: {} and {}.'.format(pins1, pins2))


def replace_wildcard(input_list):
    """Method to replace a wildcard `-` in the input values.

    This method will replace the wildcard `-` in the input list; the returned
    two lists have different values on the position of `-`.

    Example: ['0', '-', '1'] => (['0', '0', '1'], ['0', '1', '1'])

    Parameters
    ----------
    input_list : list
        A list of multiple values, possibly with `-` inside.

    Returns
    -------
    list,list
        Two lists differ by the location of `-`.

    """
    if '-' in input_list:
        first_occurrence = input_list.index('-')
        zero_list = input_list[:]
        zero_list[first_occurrence] = '0'
        one_list = input_list[:]
        one_list[first_occurrence] = '1'
        return zero_list, one_list
    else:
        return None, None


def expand_transition(transition, input_list):
    """Add new (partially) expanded state transition.

    Parameters
    ----------
    transition: list
        Specifies a state transition.
    input_list: list
        List of inputs, where each input is a string.

    Returns
    -------
    list
        New (partially) expanded state transition.

    """
    expanded_transition = list()
    expanded_transition.append(''.join(input_list))
    expanded_transition += transition[1:]
    return expanded_transition


def merge_to_length(a, b, length):
    """Merge 2 lists into a specific length.

    This method will merge 2 lists into a short list, replacing the last few
    items of the first list if necessary.

    For example, a = [1,2,3], b = [4,5,6,7], and length = 6. The result will
    be [1,2,4,5,6,7]. If length = 5, the result will be [1,4,5,6,7]. If length
    is greater or equal to 7, the result will be [1,2,3,4,5,6,7].

    Parameters
    ----------
    a : list
        A list of elements.
    b : list
        Another list of elements.
    length : int
        The length of the result list.

    Returns
    -------
    list
        A merged list of the specified length.

    """
    temp = b[:]
    for index, item in enumerate(a):
        if len(temp) < length:
            temp.insert(index, item)
        else:
            break
    return temp


def get_bram_addr_offsets(num_states, num_input_bits):
    """Get address offsets from given number of states and inputs.

    This method returns the index offset for input bits. For example, if less
    than 32 states are used, then the index offset will be 5. 
    If the number of states used is greater than 32 but less than 64, then 
    the index offset will be 6.

    This method also returns the address offsets for BRAM data. The returned
    list contains 2**`num_input_bits` offsets. The distance between 2 address
    offsets is 2**`index_offset`.

    Parameters
    ----------
    num_states : int
        The number of states in the state machine.
    num_input_bits : int
        The number of inputs in the state machine.

    Returns
    -------
    int, list
        A list of 2**`num_input_bits` offsets.

    """
    if num_states < 32:
        index_offset = 5
    else:
        index_offset = ceil(log(num_states, 2))
    return index_offset, \
        [i * 2 ** index_offset for i in range(2 ** num_input_bits)]


class FSMGenerator:
    """Class for Finite State Machine generator.

    This class enables users to specify a Finite State Machine (FSM). Users
    have to provide a FSM in the following format.

    fsm_spec = {'inputs': [('reset','D0'), ('direction','D1')],\n
    'outputs': [('alpha','D3'), ('beta','D4'), ('gamma','D5')],\n
    'states': ('S0', 'S1', 'S2', 'S3', 'S4', 'S5'),\n
    'transitions': [['00', 'S0', 'S1', '000'],\n
                    ['01', 'S0', 'S5', '000'],\n
                    ['00', 'S1', 'S2', '001'],\n
                    ['01', 'S1', 'S0', '001'],\n
                    ['00', 'S2', 'S3', '010'],\n
                    ['01', 'S2', 'S1', '010'],\n
                    ['00', 'S3', 'S4', '011'],\n
                    ['01', 'S3', 'S2', '011'],\n
                    ['00', 'S4', 'S5', '100'],\n
                    ['01', 'S4', 'S3', '100'],\n
                    ['00', 'S5', 'S0', '101'],\n
                    ['01', 'S5', 'S4', '101'],\n
                    ['1-', '*',  'S0', '']]}

    The current implementation assumes Moore machine, so the output is decided
    by the current state. Hence, if a wildcard `*` is specified for the
    current state, users can just set the output to be empty.

    Attributes
    ----------
    logictools_controller : LogicToolsController
        The generator controller for this class.
    intf_spec : dict
        The interface specification, e.g., PYNQZ1_LOGICTOOLS_SPECIFICATION.
    fsm_spec : dict
        The FSM specification, with inputs (list), outputs (list),
        states (list), and transitions (list).
    num_input_bits : int
        The number of input bits / pins.
    num_outputs : int
        The number of possible FSM outputs specified by users.
    num_output_bits : int
        The number of bits used for the FSM outputs.
    num_states : int
        The number of FSM states specified by users.
    num_state_bits : int
        The number of bits used for the FSM states.
    state_names : list
        List of state names specified by the users.
    transitions : int
        Transition list with all the wildcards replaced properly.
    input_pins : list
        List of input pins on Arduino header.
    output_pins : list
        List of output pins on Arduino header.
    use_state_bits : bool
        Flag indicating whether the state bits are shown on output pins.
    analyzer : TraceAnalyzer
        Analyzer to analyze the raw capture from the pins.
    num_analyzer_samples : int
        The number of analyzer samples to capture.
    frequency_mhz: float
        The frequency of the running FSM / captured samples, in MHz.
    waveform : Waveform
        The Waveform object used for Wavedrom display.

    """

    def __init__(self, mb_info,
                 intf_spec_name='PYNQZ1_LOGICTOOLS_SPECIFICATION'):
        """Initialize the FSM generator class.

        If `use_state_bits` is set to True, the state bits will be shown as
        outputs. The last few outputs may get replaced by state bits,
        regardless of the specification users provide. For example, if 3
        bits are required for state codes (e.g. a state code 110), and the
        last 3 outputs from `fsm_spec` are: ('alpha','D2'), ('beta','D4'),
        and ('gamma','D19'), then pin `D2`, `D4`, and `D19` will show the
        state code (continuing the example above, `D2` = 1, `D4` = 1,
        `D19` = 0). Other outputs remain consistent with users' specification.

        The waveform instance will not get populated until the `fsm_spec` is
        parsed.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        intf_spec_name : str/dict
            The name of the interface specification.

        """
        # Book-keep controller-related parameters
        self.logictools_controller = LogicToolsController(mb_info,
                                                          intf_spec_name)
        if type(intf_spec_name) is str:
            self.intf_spec = eval(intf_spec_name)
        elif type(intf_spec_name) is dict:
            self.intf_spec = intf_spec_name
        else:
            raise ValueError("Interface specification has to be str or dict.")
        self._mb_info = mb_info

        # Parameters to be cleared at reset
        self.fsm_spec = dict()
        self.num_input_bits = 0
        self.num_outputs = 0
        self.num_output_bits = 0
        self.num_states = 0
        self.num_state_bits = 0
        self.state_names = list()
        self.transitions = list()
        self.input_pins = list()
        self.output_pins = list()
        self.use_state_bits = False
        self.waveform = None
        self.frequency_mhz = 0
        self._state_names2codes = dict()
        self._state_names2outputs = dict()
        self._expanded_transitions = list()
        self._encoded_transitions = list()
        self._bram_data = np.zeros(2 ** FSM_BRAM_ADDR_WIDTH, dtype=np.uint32)

        # Trace analyzer will be attached by default
        self.analyzer = None
        self.num_analyzer_samples = 0
        self.trace()

    def __repr__(self):
        """Disambiguation of the object.

        Users can call `repr(object_name)` to display the object information.

        """
        parameter_list = list()
        parameter_list.append('num_analyzer_samples={}'.format(
            self.num_analyzer_samples))
        parameter_list.append('frequency_mhz={}'.format(
            self.frequency_mhz))
        parameter_list.append('use_state_bits={}'.format(
            self.use_state_bits))
        parameter_string = ", ".join(map(str, parameter_list))
        return '{}({})'.format(self.__class__.__name__, parameter_string)

    @property
    def status(self):
        """Return the generator's status.

        Returns
        -------
        str
            Indicating the current status of the generator; can be 
            'RESET', 'READY', or 'RUNNING'.

        """
        self.logictools_controller.check_status()
        return self.logictools_controller.status[self.__class__.__name__]

    def trace(self, use_analyzer=True,
              num_analyzer_samples=DEFAULT_NUM_TRACE_SAMPLES):
        """Configure the trace analyzer.

        By default, the trace analyzer is always on, unless users explicitly
        disable it.

        Parameters
        ----------
        use_analyzer : bool
            Whether to use the analyzer to capture the trace.
        num_analyzer_samples : int
            The number of analyzer samples to capture.

        """
        if use_analyzer:
            self.analyzer = TraceAnalyzer(self._mb_info,
                                          intf_spec_name=self.intf_spec)
            self.num_analyzer_samples = num_analyzer_samples
        else:
            if self.analyzer is not None:
                self.analyzer.__del__()
            self.analyzer = None
            self.num_analyzer_samples = 0

    def _parse_fsm_spec(self, fsm_spec_in, use_state_bits):
        """Parse a given FSM specification.

        If `use_state_bits` is set to True, this method will modify the
        given transition table; the last few outputs may get altered if
        there are not enough pins for both state bits and output bits.
        In that case, the last few output bits will reflect the current
        state code.

        After calling this method, the `self.fsm_spec` dictionary will be 
        modified if `use_state_bits` is set to True. 

        Parameters
        ----------
        fsm_spec_in : dict
            The FSM specification, with inputs (list), outputs (list),
            states (list), and transitions (list).
        use_state_bits : bool
            Whether to check the state bits in the final output pins.

        """
        fsm_spec = deepcopy(fsm_spec_in)
        self.use_state_bits = use_state_bits

        # The key 'inputs', 'outputs', and 'states' are mandatory
        for key in ['inputs', 'outputs', 'states']:
            check_duplicate(fsm_spec, key)

        self.num_input_bits = len(fsm_spec['inputs'])
        self.num_outputs = len(set([i[3] for i in fsm_spec['transitions']
                                    if i[3]]))
        self.num_output_bits = len(fsm_spec['outputs'])
        self.num_states = len(fsm_spec['states'])
        self.num_state_bits = int(ceil(log(self.num_states, 2)))
        self.input_pins = [i[1] for i in fsm_spec['inputs']]
        self.output_pins = [i[1] for i in fsm_spec['outputs']]

        check_num_bits(self.num_input_bits, 'inputs',
                       FSM_MIN_INPUT_BITS, FSM_MAX_INPUT_BITS)
        check_num_bits(self.num_output_bits, 'outputs',
                       FSM_MIN_OUTPUT_BITS, FSM_MAX_OUTPUT_BITS)
        check_num_bits(self.num_state_bits, 'states',
                       FSM_MIN_STATE_BITS, FSM_MAX_STATE_BITS)
        check_num_bits(self.num_input_bits + self.num_state_bits,
                       'states and inputs',
                       FSM_MIN_INPUT_BITS + FSM_MIN_STATE_BITS,
                       FSM_MAX_STATE_INPUT_BITS)
        check_moore(self.num_states, self.num_outputs)
        check_pins(fsm_spec, 'inputs', self.intf_spec)
        check_pins(fsm_spec, 'outputs', self.intf_spec)

        self.state_names = fsm_spec['states']
        self._state_names2codes = {
            state_name: format(i, '0{}b'.format(self.num_state_bits))
            for i, state_name in enumerate(fsm_spec['states'])}

        if self.use_state_bits:
            # Update outputs
            state_pins = list()
            total_pins_used = self.input_pins[:] + self.output_pins[:]
            num_pins_altered = 0
            for bit in range(self.num_state_bits):
                output_bit_name = 'state_bit' + str(bit)
                found_pin = False
                for pin in self.intf_spec['traceable_io_pins']:
                    if pin not in total_pins_used:
                        state_pins = [(output_bit_name, pin)] + state_pins
                        total_pins_used.append(pin)
                        found_pin = True
                        break
                if not found_pin:
                    num_pins_altered += 1
                    temp_tuple = fsm_spec['outputs'][-num_pins_altered]
                    fsm_spec['outputs'][-num_pins_altered] = (output_bit_name,
                                                              temp_tuple[1])
            fsm_spec['outputs'] += state_pins

            # Update transitions
            for index, row in enumerate(fsm_spec['transitions']):
                _, current_state, _, old_output = row
                if old_output:
                    current_state_code = self._state_names2codes[current_state]
                    new_output = ''.join(merge_to_length(
                        list(old_output),
                        list(current_state_code),
                        20 - self.num_input_bits))
                    fsm_spec['transitions'][index][-1] = new_output

            # Update all the attributes related to outputs and transitions
            self.num_outputs = len(set([i[3] for i in fsm_spec['transitions']
                                        if i[3]]))
            self.num_output_bits = len(fsm_spec['outputs'])

        self._state_names2outputs = {
            state_name: row[3] for row in fsm_spec['transitions']
            for state_name in fsm_spec['states'] if state_name == row[1]}
        self.transitions, self._expanded_transitions = \
            self._expand_all_transitions(fsm_spec['transitions'])
        self._encoded_transitions = [[i[0],
                                      self._state_names2codes[i[1]],
                                      self._state_names2codes[i[2]],
                                      i[3]]
                                     for i in self._expanded_transitions]
        self.input_pins = [i[1] for i in fsm_spec['inputs']]
        self.output_pins = [i[1] for i in fsm_spec['outputs']]

        # Check whether input and output pins are disjoint
        check_pin_conflict(self.input_pins, self.output_pins)

        # Check used pins on the controller
        for i in self.input_pins + self.output_pins:
            if self.logictools_controller.pin_map[i] != 'UNUSED':
                raise ValueError(
                    "Pin conflict: {} already in use.".format(
                        self.logictools_controller.pin_map[i]))

        # Reserve pins only if there are no conflicts for any pin
        for i in self.output_pins:
            self.logictools_controller.pin_map[i] = 'OUTPUT'
        for i in self.input_pins:
            self.logictools_controller.pin_map[i] = 'INPUT'

        # Finally update all dictionaries
        self.fsm_spec = fsm_spec

    def _expand_all_transitions(self, transitions):
        """Expand all the state transitions, resolving wildcards.

        This method will resolve all the wildcards in inputs and states.
        For example: [['1-', '*', 'S0', '']] will be converted to
        [['10', 'S1', 'S0', ''],['11', 'S1', 'S0', '']], ...].

        This method is called internally during setup of this class.

        Parameters
        ----------
        transitions: list
            List of lists, where each inner list specifies a state transition.

        Returns
        -------
        list,list
            First list has all the state wildcards '*' expanded; second list
            has the state wildcards '*' and input wildcards '-' both
            expanded.

        """
        # Expand the states first
        transitions_copy1 = deepcopy(transitions)
        for index, row in enumerate(transitions_copy1):
            if row[1] == '*':
                for state_name in self.state_names:
                    if row[2] != state_name:
                        new_row = deepcopy(transitions_copy1[index])
                        new_row[1] = state_name
                        new_row[3] = self._state_names2outputs[state_name]
                        transitions_copy1.append(new_row)
        transitions_copy1 = [row for row in transitions_copy1
                             if '*' not in row[1]]

        # Expand the input values
        transitions_copy2 = deepcopy(transitions_copy1)
        for index, row in enumerate(transitions_copy2):
            input_list = list(row[0])
            if len(input_list) != self.num_input_bits:
                raise ValueError('{} input bits required '
                                 'for each transition.'.format(
                                    self.num_input_bits))
            wildcard = '-'
            if wildcard in input_list:
                zero_list, one_list = replace_wildcard(input_list)
                if zero_list:
                    new_row = deepcopy(transitions_copy2[index])
                    transitions_copy2.append(expand_transition(new_row,
                                                               zero_list))
                    transitions_copy2.append(expand_transition(new_row,
                                                               one_list))
        expanded_transitions = list()
        for row in transitions_copy2:
            if '-' not in row[0] and row not in expanded_transitions:
                expanded_transitions.append(row)
        return transitions_copy1, expanded_transitions

    def _prepare_bram_data(self):
        """Prepare the data to be loaded into the BRAM.

        This method prepares the data to be loaded into BRAM: it first loads
        the data into main memory as a numpy array, with all the values set
        to be default; then based on the transactions specified, it updates
        the memory with proper values.

        After this method is called, users can manually check the memory
        content to verify the memory is loaded with correct values.

        The dummy state is used to compensate the erroneous sample at the 
        beginning of the trace. The last BRAM address is reserved for this
        state. The content of the address is 0, meaning that all outputs
        will be 0, and this dummy state will always go to the first state
        of the FSM.

        For the memory content to be loaded, it has the following format:
        Bits 31 - 13 : used for outputs.
        Bits 12 - 9  : used for inputs.
        Bits 8 - 5   : used for inputs or states.
        Bits 4 - 0   : used for states.

        Returns
        -------
        int
            The BRAM address where the FSM should get started.

        """
        _, addr_offsets = get_bram_addr_offsets(self.num_states,
                                                self.num_input_bits)
        # Load default values into BRAM data
        for input_value, offset_addr in enumerate(addr_offsets):
            for state_name in self.state_names:
                output_value = int(''.join(list(
                    self._state_names2outputs[state_name])[::-1]), 2)
                next_state_code = current_state_code = \
                    int(self._state_names2codes[state_name], 2)
                self._bram_data[offset_addr + current_state_code] = \
                    (output_value << FSM_MAX_STATE_INPUT_BITS) + \
                    next_state_code

        # Prepare the dummy state where the FSM actually starts
        self._bram_data[FSM_DUMMY_STATE_BRAM_ADDRESS] = 0

        # Update BRAM data based on state transitions
        for input_value, offset_addr in enumerate(addr_offsets):
            for transition in self._encoded_transitions:
                if input_value == int(transition[0], 2):
                    current_state_code, next_state_code, output_value = \
                        int(transition[1], 2),\
                        int(transition[2], 2),\
                        int(''.join(list(transition[3])[::-1]), 2)
                    self._bram_data[offset_addr + current_state_code] = \
                        (output_value << FSM_MAX_STATE_INPUT_BITS) + \
                        next_state_code

    def setup(self, fsm_spec, use_state_bits=False,
              frequency_mhz=DEFAULT_CLOCK_FREQUENCY_MHZ):
        """Configure the programmable FSM generator.

        This method will configure the FSM based on supplied configuration 
        specification. Users can send the samples to PatternAnalyzer for 
        additional analysis. 

        Parameters
        ----------
        fsm_spec : dict
            The FSM specification, with inputs (list), outputs (list),
            states (list), and transitions (list).
        use_state_bits : bool
            Whether to check the state bits in the final output pins.
        frequency_mhz: float
            The frequency of the FSM and captured samples, in MHz.

        """
        if not MIN_CLOCK_FREQUENCY_MHZ <= frequency_mhz <= \
                MAX_CLOCK_FREQUENCY_MHZ:
            raise ValueError("Clock frequency out of range "
                             "[{}, {}]".format(MIN_CLOCK_FREQUENCY_MHZ,
                                               MAX_CLOCK_FREQUENCY_MHZ))

        # Parse the FSM specification
        self._parse_fsm_spec(fsm_spec, use_state_bits)

        # Load BRAM data into the main memory
        self._prepare_bram_data()
        bram_data_addr = self.logictools_controller.allocate_buffer(
            'bram_data_buf', 2 ** FSM_BRAM_ADDR_WIDTH,
            data_type='unsigned int')

        for index, data in enumerate(self._bram_data):
            self.logictools_controller.buffers['bram_data_buf'][index] = data

        # Setup configurations
        config = list()
        index_offset, _ = get_bram_addr_offsets(self.num_states,
                                                self.num_input_bits)

        # Configuration for bit 8,7,6,5 (slvreg 0)
        config_shared_pins = 0x1f1f1f1f
        shared_input_bits = min(self.num_input_bits,
                                FSM_MAX_STATE_BITS - index_offset)
        for i in range(shared_input_bits):
            config_shared_pins = \
                ((config_shared_pins << 8) +
                 (0x80 + self.intf_spec['traceable_io_pins'][
                     self.input_pins[i - shared_input_bits]])) & 0xffffffff
        for _ in range(5, index_offset):
            config_shared_pins = \
                ((config_shared_pins << 8) + 0x1f) & 0xffffffff
        config.append(config_shared_pins)

        # Configuration for bit 12,11,10,9 (slvreg 1)
        config_input_pins = 0x1f1f1f1f
        if self.num_input_bits > shared_input_bits:
            dedicated_input_bits = self.num_input_bits - shared_input_bits
            for i in range(dedicated_input_bits):
                config_input_pins = \
                    ((config_input_pins << 8) +
                     (0x80 + self.intf_spec['traceable_io_pins'][
                         self.input_pins[i]])) & 0xffffffff
        config.append(config_input_pins)

        # Configuration for bit 31 - 13 (slvreg 6,5,4,3,2)
        fully_used_reg, remaining_pins = divmod(self.num_output_bits, 4)
        assigned_output_pins = 0
        for _ in range(fully_used_reg):
            config_output_pins = 0x0
            for i in range(3, -1, -1):
                config_output_pins = \
                    ((config_output_pins << 8) +
                     self.intf_spec['traceable_io_pins'][
                         self.output_pins[i + assigned_output_pins]]) & \
                    0xffffffff
            assigned_output_pins += 4
            config.append(config_output_pins)

        for j in range(fully_used_reg, 5):
            config_output_pins = 0x0
            if j == fully_used_reg:
                for i in range(remaining_pins - 1, -1, -1):
                    config_output_pins = \
                        ((config_output_pins << 8) +
                         self.intf_spec['traceable_io_pins'][
                             self.output_pins[i + assigned_output_pins]]) & \
                        0xffffffff
                assigned_output_pins += remaining_pins
            config.append(config_output_pins)

        # Configuration for direction mask
        direction_mask = 0xfffff
        for pin in range(20):
            for pin_label in self.output_pins:
                if self.intf_spec['traceable_io_pins'][pin_label] == pin:
                    direction_mask &= (~(1 << pin))
        config.append(direction_mask)

        # Send BRAM data address
        config.append(bram_data_addr)

        # Send the dummy state address where FSM should start
        config.append(FSM_DUMMY_STATE_BRAM_ADDRESS)

        # Wait for the Microblaze processor to return control
        self.logictools_controller.write_control(config)
        self.logictools_controller.write_command(CMD_CONFIG_FSM)

        # Configure the waveform object
        waveform_dict = {'signal': [
            ['analysis']],
            'head': {'text': 'Finite State Machine'}}
        for name, pin in (self.fsm_spec['inputs'] + self.fsm_spec['outputs']):
            waveform_dict['signal'][0].append({'name': name, 'pin': pin})
        self.waveform = Waveform(waveform_dict, analysis_group_name='analysis')

        # Configure the trace analyzer and frequency
        if self.analyzer is not None:
            self.analyzer.setup(self.num_analyzer_samples,
                                frequency_mhz)
        else:
            self.logictools_controller.clk.fclk1_mhz = frequency_mhz
        self.frequency_mhz = frequency_mhz

        # Free the BRAM buffer
        self.logictools_controller.free_buffer('bram_data_buf')

        # Update generator status
        self.logictools_controller.check_status()
        self.logictools_controller.steps = 0

    def reset(self):
        """Reset the FSM generator.

        This method will bring the generator from any state to 
        'RESET' state.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RUNNING':
            self.stop()

        for i in self.output_pins + self.input_pins:
            self.logictools_controller.pin_map[i] = 'UNUSED'

        self.fsm_spec.clear()
        self.num_input_bits = 0
        self.num_outputs = 0
        self.num_output_bits = 0
        self.num_states = 0
        self.num_state_bits = 0
        self.state_names.clear()
        self.transitions.clear()
        self.input_pins.clear()
        self.output_pins.clear()
        self.use_state_bits = False
        self.waveform = None
        self.frequency_mhz = 0
        self._state_names2codes.clear()
        self._state_names2outputs.clear()
        self._expanded_transitions.clear()
        self._encoded_transitions.clear()
        self._bram_data = np.zeros(2 ** FSM_BRAM_ADDR_WIDTH, dtype=np.uint32)

        cmd_reset = CMD_RESET | FSM_ENGINE_BIT
        if self.analyzer is not None:
            cmd_reset |= TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_reset)
        self.logictools_controller.check_status()

    def connect(self):
        """Method to configure the IO switch.

        Usually this method should only be used internally. Users only need
        to use `run()` method.

        """
        # Gather which pins are being used
        ioswitch_pins = [self.intf_spec['traceable_io_pins'][ins[1]]
                         for ins in self.fsm_spec['inputs']]
        ioswitch_pins.extend([self.intf_spec['traceable_io_pins'][outs[1]]
                              for outs in self.fsm_spec['outputs']])

        # Send list to Microblaze processor for handling
        self.logictools_controller.config_ioswitch(ioswitch_pins,
                                                   IOSWITCH_FSM_SELECT)

    def disconnect(self):
        """Method to disconnect the IO switch.

        Usually this method should only be used internally. Users only need
        to use `stop()` method.

        """
        # Gather which pins are being used
        ioswitch_pins = [self.intf_spec['traceable_io_pins'][ins[1]]
                         for ins in self.fsm_spec['inputs']]
        ioswitch_pins.extend([self.intf_spec['traceable_io_pins'][outs[1]]
                              for outs in self.fsm_spec['outputs']])

        # Send list to Microblaze processor for handling
        self.logictools_controller.config_ioswitch(ioswitch_pins,
                                                   IOSWITCH_DISCONNECT)

    def run(self):
        """Run the FSM generator.

        The method will first collects the pins used and sends the list to 
        Microblaze for handling. Then it will start to run the FSM 
        generator.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RESET':
            raise ValueError(
                "Generator must be at least READY before RUNNING.")
        self.connect()
        self.logictools_controller.steps = 0

        cmd_run = CMD_RUN | FSM_ENGINE_BIT
        if self.analyzer is not None:
            cmd_run |= TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_run)
        self.logictools_controller.check_status()
        self.analyze()

    def step(self):
        """Step the FSM generator.

        The method will first collects the pins used and sends the list to 
        Microblaze for handling. Then it will start to step the FSM 
        generator.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RESET':
            raise ValueError(
                "Generator must be at least READY before RUNNING.")

        if self.logictools_controller.steps == 0:
            self.connect()
            cmd_step = CMD_STEP | FSM_ENGINE_BIT
            if self.analyzer is not None:
                cmd_step |= TRACE_ENGINE_BIT
            self.logictools_controller.write_command(cmd_step)
        self.logictools_controller.steps += 1

        cmd_step = CMD_STEP | FSM_ENGINE_BIT
        if self.analyzer is not None:
            cmd_step |= TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_step)
        self.logictools_controller.check_status()
        self.analyze()

    def analyze(self):
        """Update the captured samples.

        This method updates the captured samples from the trace analyzer.
        It is required after each step() / run().

        """
        if self.analyzer is not None:
            analysis_group = self.analyzer.analyze(
                self.logictools_controller.steps)
            if self.logictools_controller.steps:
                self.waveform.append('analysis', analysis_group)
            else:
                self.waveform.update('analysis', analysis_group)

    def stop(self):
        """Stop the FSM generator.

        This command will stop the pattern generated from FSM.

        """
        cmd_stop = CMD_STOP | FSM_ENGINE_BIT
        if self.analyzer is not None:
            cmd_stop |= TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_stop)
        self.disconnect()
        self.logictools_controller.check_status()
        self.clear_wave()
        self.logictools_controller.steps = 0

    def clear_wave(self):
        """Clear the waveform object so new patterns can be accepted.

        This function is required after each `stop()`.

        """
        if self.waveform:
            self.waveform.clear_wave('analysis')

    def show_state_diagram(self, file_name='fsm_spec.png', save_png=False):
        """Display the state machine in Jupyter notebook.

        This method uses the installed package `pygraphviz`. References:
        http://pygraphviz.github.io/documentation/latest/pygraphviz.pdf

        A PNG file of the state machine will also be saved into the current
        working directory.

        Parameters
        ----------
        file_name : str
            The name / path of the picture for the FSM diagram.
        save_png : bool
            Whether to save the PNG showing the state diagram.

        """
        import pygraphviz as pgv
        from IPython.display import Image, display

        if self.logictools_controller.status[
                self.__class__.__name__] == 'RESET':
            raise ValueError(
                "Generator must be setup before showing state diagram.")

        with open('fsm_spec.dot', 'w') as f:
            f.write("digraph {\n" +
                    "    graph [fontsize=10 splines=true overlap=false]\n" +
                    "    edge  [fontsize=10 fontname=\"helvetica\"]\n" +
                    "    node  [fontsize=10 fontname=\"helvetica\"" +
                    " nodesep=2.0]\n" +
                    "    ratio=auto\n")
            for i in self._state_names2outputs:
                f.write(('    \"' + i + ' &#8260; ' +
                         self._state_names2outputs[i]) + '\"\n')
            for row in self.transitions:
                f.write(
                    '    \"' + row[1] + ' &#8260; ' +
                    self._state_names2outputs[row[1]] + '\" -> \"' +
                    row[2] + ' &#8260; ' +
                    self._state_names2outputs[row[2]] + "\" [label=\"" +
                    row[0] + "\" arrowhead = \"vee\"]\n")
            f.write("}")

        graph = pgv.AGraph('fsm_spec.dot')
        graph.layout(prog='dot')
        graph.draw(file_name)
        display(Image(filename=file_name))
        os.remove("fsm_spec.dot")

        if not save_png:
            os.remove(file_name)

    def show_waveform(self):
        """Display the waveform.
        
        This method requires the waveform class to be present. Also, 
        javascripts will be copied into the current directory.

        """
        if self.analyzer is None:
            raise ValueError("Trace disabled, please enable and rerun.")

        if 0 < self.logictools_controller.steps < 3:
            for key in self.waveform.waveform_dict:
                for annotation in ['tick', 'tock']:
                    if annotation in self.waveform.waveform_dict[key]:
                        del self.waveform.waveform_dict[key][annotation]
        else:
            self.waveform.waveform_dict['foot'] = {'tock': 1}
        self.waveform.display()

    def __del__(self):
        """Delete the instance.

        Need to reset the buffers used in this instance.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] != 'RESET':
            self.reset()
            self.logictools_controller.check_status()
        if self.analyzer:
            self.analyzer.__del__()
