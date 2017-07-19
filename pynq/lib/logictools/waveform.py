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


from copy import deepcopy
import re
import os
import json
import IPython.core.display
from .constants import *


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


PYNQ_JUPYTER_NOTEBOOKS = '/home/xilinx/jupyter_notebooks'


def bitstring_to_wave(bitstring):
    """Function to convert a pattern consisting of `0`, `1` into a sequence
    of `l`, `h`, and dots.

    For example, if the bit string is "010011000111", then the result will be
    "lhl.h.l..h..".

    Returns
    -------
    str
        New wave tokens with valid tokens and dots.

    """
    substitution_map = {'0': 'l', '1': 'h', '.': '.'}

    def insert_dots(match):
        return substitution_map[match.group()[0]] + \
            '.' * (len(match.group()) - 1)

    bit_regex = re.compile(r'[0][0]*|[1][1]*')
    return re.sub(bit_regex, insert_dots, bitstring)


def wave_to_bitstring(wave):
    """Function to convert a pattern consisting of `l`, `h`, and dot to a
    sequence of `0` and `1`.

    Parameters
    ----------
    wave : str
        The input string to convert.

    Returns
    -------
    str
        A bit sequence of 0's and 1's.

    """
    substitution_map = {'l': '0', 'h': '1'}

    def delete_dots(match):
        return substitution_map[match.group()[0]] * len(match.group())

    wave_regex = re.compile(r'[l]\.*|[h]\.*')
    return re.sub(wave_regex, delete_dots, wave)


def bitstring_to_int(bitstring):
    """Function to convert a bit string to integer list.

    For example, if the bit string is '0110', then the integer list will be
    [0,1,1,0].

    Parameters
    ----------
    bitstring : str
        The input string to convert.

    Returns
    -------
    list
        A list of elements, each element being 0 or 1.

    """
    return [int(i, 10) for i in list(bitstring)]


def int_to_sample(bits):
    """Function to convert a bit list into a multi-bit sample.

    Example: [1, 1, 1, 0] will be converted to 7, since the LSB of the 
    sample appears first in the sequence.

    Parameters
    ----------
    bits : list
        A list of bits, each element being 0 or 1.

    Returns
    -------
    int
        A numpy uint32 converted from the bit samples.

    """
    return np.uint32(int("".join(map(str, list(bits[::-1]))), 2))


def _verify_wave_tokens(wave_lane):
    """Validate tokens in a WaveLane string.

    Parameters
    ----------
    wave_lane : str
        A string consisting of the WaveLane tokens.

    Returns
    -------
    Boolean
        True if all the tokens in the WaveLane are valid.

    """
    valid_tokens = {'l', 'h', '.'}
    wave_lane_tokens = list(wave_lane)

    for token in wave_lane_tokens:
        if token not in valid_tokens:
            raise ValueError('Valid tokens are: {}'.format(valid_tokens))


def draw_wavedrom(data):
    """Display the waveform using the Wavedrom package.

    This method requires 2 javascript files to be present. We get the relative
    paths for the 2 files in order to proceed.

    Users can call this method directly to draw any wavedrom data.

    Example usage:

    >>> a = {
        'signal': [
            {'name': 'clk', 'wave': 'p.....|...'},
            {'name': 'dat', 'wave': 'x.345x|=.x', 
                            'data': ['head', 'body', 'tail', 'data']},
            {'name': 'req', 'wave': '0.1..0|1.0'},
            {},
            {'name': 'ack', 'wave': '1.....|01.'}
        ]}
    >>> draw_wavedrom(a)

    """
    wavedrom_js = '/js/WaveDrom.js'
    wavedromskin_js = '/js/WaveDromSkin.js'
    if not os.path.isfile(PYNQ_JUPYTER_NOTEBOOKS + wavedrom_js):
        raise RuntimeError('Cannot locate {}.'.format(wavedrom_js))
    if not os.path.isfile(PYNQ_JUPYTER_NOTEBOOKS + wavedromskin_js):
        raise RuntimeError('Cannot locate {}.'.format(wavedromskin_js))
    current_path = os.getcwd()
    relative_path = os.path.relpath(PYNQ_JUPYTER_NOTEBOOKS, current_path)

    htmldata = '<script type="WaveDrom">' + json.dumps(data) + '</script>'
    IPython.core.display.display_html(IPython.core.display.HTML(htmldata))
    jsdata = 'WaveDrom.ProcessAll();'
    IPython.core.display.display_javascript(
        IPython.core.display.Javascript(
            data=jsdata,
            lib=[relative_path + '/js/WaveDrom.js',
                 relative_path + '/js/WaveDromSkin.js']))


class Waveform:
    """A wrapper class for Wavedrom package and interfacing functions.

    This class wraps the key functions of the Wavedrom package, including
    waveform display, bit pattern converting, csv converting, etc.

    A typical example of the waveform dictionary is:

    >>> loopback_test = {'signal': [

        ['stimulus',

        {'name': 'clk0',  'pin': 'D0', 'wave': 'lh' * 64},

        {'name': 'clk1',  'pin': 'D1', 'wave': 'l.h.' * 32},

        {'name': 'clk2',  'pin': 'D2', 'wave': 'l...h...' * 16},

        {'name': 'clk3',  'pin': 'D3', 'wave': 'l.......h.......' * 8}],

        ['analysis',

        {'name': 'clk15', 'pin': 'D15'},

        {'name': 'clk16', 'pin': 'D16'},

        {'name': 'clk17', 'pin': 'D17'},

        {'name': 'clk18', 'pin': 'D18'},

        {'name': 'clk19', 'pin': 'D19'}]

    ],

    'foot': {'tock': 1},

    'head': {'text': 'Loopback Test'}}

    Attributes
    ----------
    waveform_dict : dict
        The json data stored in the dictionary.
    intf_spec : dict
        The interface specification, e.g., PYNQZ1_DIO_SPECIFICATION.
    stimulus_group_name : str
        Name of the WaveLane group for the stimulus, defaulted to `stimulus`.
    analysis_group_name : str
        Name of the WaveLane group for the analysis, defaulted to `analysis`.
    stimulus_group : list
        A group of lanes, each lane being a dict of name, pin label,and wave.
    analysis_group : list
        A group of lanes, each lane being a dict of name, pin label,and wave.

    """

    def __init__(self, waveform_dict,
                 intf_spec_name='PYNQZ1_DIO_SPECIFICATION',
                 stimulus_group_name=None, analysis_group_name=None):
        """Initializer for this wrapper class.

        Parameters
        ----------
        waveform_dict : dict
            Waveform dictionary in WaveJSON format.
        intf_spec_name : str
            The name of the interface specification.
        stimulus_group_name : str
            Name of the WaveLane group for the stimulus, defaulted to
            `stimulus`.
        analysis_group_name : str
            Name of the WaveLane group for the analysis, defaulted to
            `analysis`.

        """
        self.waveform_dict = deepcopy(waveform_dict)
        self.stimulus_group_name = stimulus_group_name
        self.analysis_group_name = analysis_group_name
        self.intf_spec = eval(intf_spec_name)

        if self.stimulus_group_name is not None:
            self._verify_lanes(stimulus_group_name)
        if self.analysis_group_name is not None:
            self._verify_lanes(analysis_group_name)

    def display(self):
        """Display the waveform using the Wavedrom package.

        This package requires 2 javascript files to be copied locally.

        """
        draw_wavedrom(self.waveform_dict)

    def _get_wavelane_group(self, group_name):
        """Return the WaveLane group if present in waveform_dict.

        Typical group names are `stimulus` and `analysis` by default.
        The returned WaveLane group looks like:
        [{'name': 'dat', 'pin': 'D1', 'wave': 'l...h...lhlh'},
        {'name': 'req', 'pin': 'D2', 'wave': 'lhlhlhlh....'}]

        Parameters
        ----------
        group_name : str
            Name of the WaveLane group.

        Returns
        -------
        list
            A list of lanes, each lane being a dictionary of name, pin label,
            and wave.

        """
        for group in self.waveform_dict['signal']:
            if group and (group[0] == group_name):
                return group[1:]
        return []

    @property
    def stimulus_group(self):
        """Return the stimulus WaveLane group.

        A stimulus group looks like:
        [{'name': 'dat', 'pin': 'D1', 'wave': 'l...h...lhlh'},
        {'name': 'req', 'pin': 'D2', 'wave': 'lhlhlhlh....'}]

        Returns
        -------
        list
            A list of lanes, each lane being a dictionary of name, pin label,
            and wave.

        """
        return self._get_wavelane_group(self.stimulus_group_name)

    @property
    def analysis_group(self):
        """Return the analysis WaveLane group.

        An analysis group looks like:
        [{'name': 'dat', 'pin': 'D1', 'wave': 'l...h...lhlh'},
        {'name': 'req', 'pin': 'D2', 'wave': 'lhlhlhlh....'}]

        Returns
        -------
        list
            A list of lanes, each lane being a dictionary of name, pin label,
            and wave.

        """
        return self._get_wavelane_group(self.analysis_group_name)

    def _get_wavelane_names(self, group_name):
        """Returns all the names of a given group of WaveLanes.

        The returned names are in the same order as in the waveform
        dictionary.

        Parameters
        ----------
        group_name : str
            The name of the group.

        Returns
        -------
        list
            A list of names for all the WaveLanes in that group.

        """
        wavelanes = self._get_wavelane_group(group_name)
        wavelane_names = [wavelane['name'] for wavelane in wavelanes]
        return wavelane_names

    @property
    def stimulus_names(self):
        """Returns all the names of the stimulus WaveLanes.

        The returned names are in the same order as in the waveform
        dictionary.

        Returns
        -------
        list
            A list of names for all the stimulus WaveLanes.

        """
        return self._get_wavelane_names(self.stimulus_group_name)

    @property
    def analysis_names(self):
        """Returns all the names of the analysis WaveLanes.

        The returned names are in the same order as in the waveform
        dictionary.

        Returns
        -------
        list
            A list of names for all the analysis WaveLanes.

        """
        return self._get_wavelane_names(self.analysis_group_name)

    def _get_wavelane_pins(self, group_name):
        """Returns all the pin labels of a given group of WaveLanes.

        The returned pin labels are in the same order as in the waveform
        dictionary.

        Parameters
        ----------
        group_name : str
            The name of the group.

        Returns
        -------
        list
            A list of pin labels for all the WaveLanes of a specified group.

        """
        wavelanes = self._get_wavelane_group(group_name)
        wavelane_pins = [wavelane['pin'] for wavelane in wavelanes]
        return wavelane_pins

    @property
    def stimulus_pins(self):
        """Returns all the pin labels of the stimulus WaveLanes.

        The returned pin labels are in the same order as in the waveform
        dictionary.

        Returns
        -------
        list
            A list of pin labels for all the stimulus WaveLanes.

        """
        return self._get_wavelane_pins(self.stimulus_group_name)

    @property
    def analysis_pins(self):
        """Returns all the pin labels of the analysis WaveLanes.

        The returned pin labels are in the same order as in the waveform
        dictionary.

        Returns
        -------
        list
            A list of pin labels for all the analysis WaveLanes.

        """
        return self._get_wavelane_pins(self.analysis_group_name)

    def _get_wavelane_waves(self, group_name):
        """Returns all the waves for a specific group of WaveLanes.

        The returned waves are in the same order as in the waveform
        dictionary.

        Parameters
        ----------
        group_name : str
            The name of the group.
        Returns
        -------
        list
            A list of waves for all the stimulus WaveLanes.

        """
        wavelanes = self._get_wavelane_group(group_name)
        wavelane_waves = [wavelane['wave'] for wavelane in wavelanes]
        return wavelane_waves

    @property
    def stimulus_waves(self):
        """Returns all the waves of the stimulus WaveLanes.

        The returned waves are in the same order as in the waveform
        dictionary.

        Returns
        -------
        list
            A list of waves for all the stimulus WaveLanes.

        """
        return self._get_wavelane_waves(self.stimulus_group_name)

    @property
    def analysis_waves(self):
        """Returns all the waves of the analysis WaveLanes.

        The returned waves are in the same order as in the waveform
        dictionary.

        Returns
        -------
        list
            A list of waves for all the analysis WaveLanes.

        """
        return self._get_wavelane_waves(self.analysis_group_name)

    def _verify_lanes(self, group_name):
        """Verify the pin labels, names, and tokens for all lanes in the group.

        Typical group names are `stimulus` and `analysis` by default.

        Parameters
        ----------
        group_name: str
            name of lane group whose pin labels will be verified.

        Raises
        ------
        ValueError
            Raises this error when the group name is not valid, or the pin
            label is not valid, or there are duplicated pin labels,
            duplicated lane names, or the wave token is not valid.

        """
        if group_name == self.stimulus_group_name:
            valid_pins = self.intf_spec['traceable_outputs']
        elif group_name == self.analysis_group_name:
            valid_pins = self.intf_spec['traceable_inputs']
        else:
            raise ValueError("Valid group names are {},{}.".format(
                self.stimulus_group_name, self.analysis_group_name))

        lane_group = self._get_wavelane_group(group_name)
        pin_labels = set()
        lane_names = set()
        for lane in lane_group:
            # Verify that each pin label maps to an external pin
            if lane['pin'] not in valid_pins:
                raise ValueError("Pin label {} in Lane {} is invalid."
                                 .format(lane['pin'], lane['name']))

            # Verify the wave tokens
            if 'wave' in lane:
                _verify_wave_tokens(lane['wave'])

            # Add lane names and pin labels
            lane_names.add(lane['name'])
            pin_labels.add(lane['pin'])

        # Verify that each lane has a unique pin label
        if len(pin_labels) < len(lane_group):
            raise ValueError("Duplicate pin labels in group {}."
                             .format(group_name))

        # Verify that each lane has a unique name
        if len(lane_names) < len(lane_group):
            raise ValueError("Duplicate lane names in group {}."
                             .format(group_name))

    def update(self, group_name, wavelane_group):
        """Update waveform dictionary based on the specified WaveLane group.

        A typical use case of this method is that it gets the output returned
        by the analyzer and refreshes the data stored in the dictionary.

        Since the analyzer only knows the pin labels, the data returned from
        the pattern analyzer is usually of format:

        [{'name': '', 'pin': 'D1', 'wave': 'l...h...lhlh'},
        {'name': '', 'pin': 'D2', 'wave': 'lhlhlhlh....'}]

        Note the all the lanes should have the same number of samples.
        Note each lane in the analysis group has its pin number. Based on this
        information, this function only updates the lanes specified.

        Parameters
        ----------
        group_name : str
            The name of the WaveLane group to be updated.
        wavelane_group : list
            The WaveLane group specified for updating.

        """
        pin_to_name = {}
        updated_group = [group_name]
        for group in self.waveform_dict['signal']:
            if group and (group[0] == group_name):
                for wavelane in group[1:]:
                    name, pin = wavelane['name'], wavelane['pin']
                    pin_to_name[pin] = name
                for wavelane in wavelane_group:
                    pin, wave = wavelane['pin'], wavelane['wave']
                    if pin in pin_to_name:
                        updated_dict = {'name': pin_to_name[pin],
                                        'pin': pin,
                                        'wave': wave}
                        updated_group.append(updated_dict)
                break

        for index, group in enumerate(self.waveform_dict['signal']):
            if group and (group[0] == group_name):
                self.waveform_dict['signal'][index] = updated_group

    def append(self, group_name, wavelane_group):
        """Append new data to the existing waveform dictionary.

        A typical use case of this method is that it gets the output returned
        by the analyzer and append new data to the dictionary.

        Since the analyzer only knows the pin labels, the data returned from
        the pattern analyzer is usually of format:

        [{'name': '', 'pin': 'D1', 'wave': 'l...h...lhlh'},
        {'name': '', 'pin': 'D2', 'wave': 'lhlhlhlh....'}]

        Note the all the lanes should have the same number of samples.
        Note each lane in the analysis group has its pin number. Based on this
        information, this function only updates the lanes specified.

        Parameters
        ----------
        group_name : str
            The name of the WaveLane group to be updated.
        wavelane_group : list
            The WaveLane group specified for updating.

        """
        pin_to_name = {}
        pin_to_wave = {}
        updated_group = [group_name]
        for group in self.waveform_dict['signal']:
            if group and (group[0] == group_name):
                for wavelane in group[1:]:
                    name, pin = wavelane['name'], wavelane['pin']
                    if 'wave' in wavelane:
                        pin_to_wave[pin] = wavelane['wave']
                    else:
                        pin_to_wave[pin] = ''
                    pin_to_name[pin] = name
                for wavelane in wavelane_group:
                    pin, wave = wavelane['pin'], wavelane['wave']
                    if pin in pin_to_name:
                        if pin_to_wave[pin]:
                            merged_wave = bitstring_to_wave(
                                wave_to_bitstring(pin_to_wave[pin]) +
                                wave_to_bitstring(wave))
                        else:
                            merged_wave = wave
                        updated_dict = {'name': pin_to_name[pin],
                                        'pin': pin,
                                        'wave': merged_wave}
                        updated_group.append(updated_dict)
                break

        for index, group in enumerate(self.waveform_dict['signal']):
            if group and (group[0] == group_name):
                self.waveform_dict['signal'][index] = updated_group

    def clear_wave(self, group_name):
        """Clear the wave in the existing waveform dictionary.

        This method will clear the wave stored in each wavelane, so that 
        a brand-new waveform dict can be constructed.

        Parameters
        ----------
        group_name : str
            The name of the WaveLane group to be updated.

        """
        for index, group in enumerate(self.waveform_dict['signal']):
            if group and (group[0] == group_name):
                for lane_index, wavelane in enumerate(group):
                    if type(wavelane) is dict and 'wave' in wavelane:
                        self.waveform_dict[
                            'signal'][index][lane_index]['wave'] = ''
