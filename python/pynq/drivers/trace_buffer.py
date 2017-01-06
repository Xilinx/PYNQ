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

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


import os
import re
import cffi
import json
import csv
import math
from time import sleep
from itertools import zip_longest
import numpy as np
import IPython.core.display
from pynq import PL
from pynq import MMIO
from pynq.drivers import DMA
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import ARDUINO

MAX_SAMPLE_RATE             = 166666667
MAX_NUM_SAMPLES             = 524288
TRACE_CTRL_OFFSET           = 0x00
TRACE_CMP_LSW_OFFSET        = 0x10
TRACE_CMP_MSW_OFFSET        = 0x14
TRACE_LENGTH_OFFSET         = 0x1C
TRACE_SAMPLE_RATE_OFFSET    = 0x24

class Trace_Buffer:
    """Class for the trace buffer, leveraging the sigrok libraries.
    
    This trace buffer class gets the traces from DMA and processes it using 
    the sigrok commands.

    For PMODA and PMODB, pin numbers 0-7 correspond to the pins on the Pmod
    interface. Although PMODA and PMODB are sharing the same trace buffer,
    only one Pmod can be traced at a specific time.

    For ARDUINO, pin numbers 0-5 correspond to A0-A5;
    pin numbers 6-7 correspond to D0-D1;
    pin numbers 8-19 correspond to D2-D13;
    pin numbers 20-21 correspond to SDA and SCL.
    
    Attributes
    ----------
    if_id : int
        The interface ID (PMODA, PMODB, ARDUINO).
    pins : list
        Array of pin numbers, 0-7 for PMODA or PMODB and 0-21 for ARDUINO.
    protocol : str
        The protocol the sigrok decoder are using, for example, I2C.
    trace_csv: str
        Absolute path of the `*.csv` trace that can be opened by text editor.
    trace_sr: str
        Absolute path of the `*.sr` trace file that can be unzipped.
    trace_pd : str
        Absolute path of the `*.pd` decoded file by sigrok decoder.
    probes : list
        The list of probes used for the trace, e.g., ['SCL','SDA'] for I2C.
    dma : DMA
        The DMA object associated with the trace buffer.
    ctrl : MMIO
        The MMIO class used to control the DMA.
    rate: int
        The sample rate of the traces, at most 100M samples per second.
    samples : ndarray
        The np array storing the 64-bit samples.
    ffi: cffi.api.FFI
        The FFI API to the underlying C structure
        
    """
    
    def __init__(self, if_id, pins, protocol, probes=None,
                 trace=None, rate=500000):
        """Return a new trace buffer object. 
        
        Users have to specify the location of the traces, even if no trace 
        has been imported from DMA yet. This method will construct the trace
        from the DMA data.
        
        The maximum sample rate is 100MHz.

        For PMODA and PMODB, pin numbers 0-7 correspond to the pins on the
        Pmod interface. Although PMODA and PMODB are sharing the same trace
        buffer, only one Pmod can be traced at a specific time.

        For ARDUINO, pin numbers 0-5 correspond to A0-A5;
        pin numbers 6-7 correspond to D0-D1;
        pin numbers 8-19 correspond to D2-D13;
        pin numbers 20-21 correspond to SDA and SCL.
        When using the trace buffer, only one out of the above 4 groups can be
        traced in the current implementation.

        The list `probes` depends on the protocol. For instance, the I2C
        protocol requires a list of ['SCL','SDA'].
        
        Parameters
        ----------
        if_id : int
            The interface ID (PMODA, PMODB, ARDUINO).
        pins : list
            List of pin numbers, 0-7 for PMODA or PMODB and 0-21 for ARDUINO.
        protocol : str
            The protocol the sigrok decoder are using, for example, I2C.
        trace: str
            The relative/absolute path of the trace file in `csv`/`sr` format.
        rate : int
            The rate of the samples, at most 100M.
        
        """
        if os.geteuid() != 0:
            raise EnvironmentError('Root permissions required.')
        if not isinstance(protocol, str):
            raise TypeError("Protocol name has to be a string.")
        
        if not isinstance(rate, int):
            raise TypeError("Sample rate has to be an integer.")
        if not 1 <= rate <= 100000000:
            raise ValueError("Sample rate out of range.")
        
        if if_id in [PMODA, PMODB]:
            dma_base, _, _ = PL.ip_dict["SEG_axi_dma_0_Reg"]
            ctrl_base, ctrl_range, _ = PL.ip_dict["SEG_trace_cntrl_0_Reg2"]
        elif if_id in [ARDUINO]:
            dma_base, _, _ = PL.ip_dict["SEG_axi_dma_0_Reg1"]
            ctrl_base, ctrl_range, _ = PL.ip_dict["SEG_trace_cntrl_0_Reg"]
        else:
            raise ValueError("No such IOP for instrumentation.")
        self.if_id = if_id

        if not pins:
            raise ValueError("No pins specified to trace.")
        elif if_id in [PMODA,PMODB]:
            for p in pins:
                if not p in range(8):
                    raise ValueError("Available pin numbers are 0-7.")
            self.pins = np.array([7 - p for p in pins])
        else:
            for p in pins:
                if not p in range(22):
                    raise ValueError("Available pin numbers are 0-21.")
            self.pins = np.array([21 - p for p in pins])

        if not probes:
            self.probes = ['Pin {}'.format(i) for i in pins]
        elif not isinstance(probes, list):
            raise ValueError("Probes have to be a list.")
        else:
            self.probes = probes

        self.dma = DMA(dma_base, direction=1)
        self.ctrl = MMIO(ctrl_base, ctrl_range)
        self.rate = rate
        self.protocol = protocol
        self.ffi = cffi.FFI()
        self.samples = None
        self.trace_pd = ''
        
        if trace:
            if not isinstance(trace, str):
                raise TypeError("Trace path has to be a string.")
            if not os.path.isfile(trace):
                trace_abs = os.getcwd() + '/' + trace
            else:
                trace_abs = trace
            if not os.path.isfile(trace_abs):
                raise ValueError("Specified trace file does not exist.")
            
            _, format = os.path.splitext(trace_abs)
            if format == '.csv':
                self.trace_csv = trace_abs
                self.trace_sr = ''
            elif format == '.sr':
                self.trace_sr = trace_abs
                self.trace_csv = ''
            else:
                raise ValueError("Only supporting csv or sr files.")
        
    def __del__(self):
        """Destructor for trace buffer object.
        
        Returns
        -------
        None

        """
        del self.dma
        
    def start(self, timeout=10):
        """Start the DMA to capture the traces.
        
        If length is not specified, the maximum number of samples will 
        be captured.
        
        Parameters
        ----------
        timeout : int
            The time in number of milliseconds to wait for DMA to be idle.
            
        Return
        ------
        None
        
        """
        # Create buffer
        self.dma.create_buf(MAX_NUM_SAMPLES*8)
        self.dma.transfer(MAX_NUM_SAMPLES*8, direction=1)
        
        # Wait for DMA to be idle
        timer = timeout
        while (self.ctrl.read(0x00) & 0x04)==0:
            sleep(0.001)
            timer -= 1
            if timer==0:
                raise RuntimeError("Timeout when waiting DMA to be idle.")
                
        # Configuration
        self.ctrl.write(TRACE_LENGTH_OFFSET, MAX_NUM_SAMPLES)
        self.ctrl.write(TRACE_SAMPLE_RATE_OFFSET,
                        int(MAX_SAMPLE_RATE / self.rate))
        self.ctrl.write(TRACE_CMP_LSW_OFFSET, 0x00000)
        self.ctrl.write(TRACE_CMP_MSW_OFFSET, 0x00000)
        
        # Start the DMA
        self.ctrl.write(TRACE_CTRL_OFFSET,0x01)
        self.ctrl.write(TRACE_CTRL_OFFSET,0x00)
    
    def stop(self):
        """Stop the DMA after capture is done.
        
        Note
        ----
        There is an internal timeout mechanism in the DMA class.
            
        Return
        ------
        None
        
        """
        # Wait for the DMA
        self.dma.wait()
        
        # Get samples from DMA
        self.samples = np.frombuffer(self.ffi.buffer(
                            self.dma.get_buf(64),MAX_NUM_SAMPLES*8),
                            dtype=np.uint64)
        
    def show(self):
        """Show information about the specified protocol.

        This method will print out useful information about the protocol.

        Return
        ------
        None
        
        """
        if os.system("sigrok-cli --protocol-decoders " + \
                    self.protocol+" --show"):
            raise RuntimeError('Sigrok-cli show failed.')
        
    def csv2sr(self):
        """Translate the `*.csv` file to `*.sr` file.
        
        The translated `*.sr` files can be directly used in PulseView to show 
        the waveform.
        
        Note
        ----
        This method also modifies the input `*.csv` file (the comment header, 
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
        # Copy only the contents; ignore comments
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
        
    def sr2csv(self):
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
        # Copy only the contents; ignore comments
        for i, line in enumerate(in_file):
            if not line.startswith(';'):
                out_file.write(line)
        in_file.close()
        out_file.close()
        os.remove(temp)
        
    def decode(self, decoded_file, options=''):
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
        self.set_metadata()

        if not isinstance(decoded_file, str):
            raise TypeError("File name has to be a string.")
        if not self.probes:
            raise ValueError("Cannot decode without metadata.")
        
        if os.path.isdir(os.path.dirname(decoded_file)):
            decoded_abs = decoded_file
        else:
            decoded_abs = os.getcwd() + '/' + decoded_file
            
        name, _ = os.path.splitext(self.trace_sr)
        temp_file = name + '.temp'
        if os.system('rm -rf ' + temp_file):
            raise RuntimeError("Cannot remove temporary file.")
        self.trace_pd = ''
        if os.system('rm -rf ' + decoded_abs):
            raise RuntimeError("Cannot remove old decoded file.")
            
        pd_annotation = ''
        for i in self.probes:
            if not i=='NC':
                # Ignore pins not connected to device
                pd_annotation += (':'+i.lower()+'='+i)
        command = "sigrok-cli -i " + self.trace_sr + " -P " + \
            self.protocol + options + pd_annotation + (' > ' + temp_file)
        if os.system(command):
            raise RuntimeError('Sigrok-cli decode failed.')
            
        f_decoded = open(decoded_abs, 'w')
        f_temp = open(temp_file, 'r')
        j = 0
        for line in f_temp:
            m = re.search('([0-9]+)-([0-9]+)  (.*)', line)
            if m:
                while j < int(m.group(1)):
                    f_decoded.write('x\n')
                    j += 1
                f_decoded.write(m.group(3) + '\n')
                j += 1
                while j < int(m.group(2)):
                    f_decoded.write('.\n')
                    j += 1

        f_temp.close()
        f_decoded.close()
        self.trace_pd = decoded_abs
        
        if os.system('rm -rf ' + temp_file):
            raise RuntimeError("Cannot remove temporary file.")
        if os.path.getsize(self.trace_pd)==0:
            raise RuntimeError("No transactions and decoded file is empty.")
        
    def set_metadata(self):
        """Set metadata for the trace.
        
        A `*.sr` file directly generated from `*.csv` will not have any 
        metadata. This method helps to set the sample rate, probe names, etc.
        
        Return
        ------
        None
        
        """
        # Convert csv file to sr file, if necessary
        if self.trace_sr == '':
            self.csv2sr()
            
        name, _ = os.path.splitext(self.trace_sr)
        if os.system("rm -rf " + name):
            raise RuntimeError('Directory cannot be deleted.')
        if os.system("mkdir " + name):
            raise RuntimeError('Directory cannot be created.')
        if os.system("unzip -q "+ self.trace_sr + " -d " + name):
            raise RuntimeError('Unzip sr file failed.')
        
        metadata = open(name + '/metadata', 'r')
        temp = open(name + '/temp', 'w')
        pat = "rate=0 Hz"
        subst = "rate=" + str(self.rate) +" Hz"
        j = 0
        for i, line in enumerate(metadata):
            if line.startswith("probe"):
                # Set the probe names
                temp.write("probe"+str(j+1)+"="+self.probes[j]+'\n')
                j += 1
            else:
                # Set the sample rate
                temp.write(line.replace(pat, subst))
        metadata.close()
        temp.close()
        
        if os.system("rm -rf "+ name + '/metadata'):
            raise RuntimeError('Cannot remove metadata folder.')
        if os.system("mv " + name + '/temp ' + name + '/metadata'):
            raise RuntimeError('Cannot rename metadata folder.')
        if os.system("cd "+ name +"; zip -rq " + \
                    self.trace_sr + " * ; cd .."):
            raise RuntimeError('Zip sr file failed.')
        if os.system("rm -rf " + name):
            raise RuntimeError('Cannot remove temporary folder.')
        
    def parse(self, parsed, start_pos, stop_pos):
        """Parse the input data and generate a `*.csv` file.
        
        This method can be used along with the DMA. The input data is assumed
        to be 64-bit. The generated `*.csv` file can be then used as the trace
        file.
        
        Note
        ----
        PMODA and PMODB are sharing the same trace buffer with different sets
        of pins, while ARDUINO has its own trace buffer.
        
        Note
        ----
        The parsed file will be put into the specified path, or in the 
        working directory in case the path does not exist.
        
        Parameters
        ----------
        parsed : str
            Name of the parsed output file which can be opened in text editor.
        start_pos : int
            Starting sample number, no less than 1.
        stop_pos : int
            Stopping sample number, no more than the maximum number of samples.
        
        Return
        ------
        None
        
        """
        if not isinstance(parsed, str):
            raise TypeError("File name has to be an string.")
        if not isinstance(start_pos, int):
            raise TypeError("Start position has to be an integer.")
        if not isinstance(stop_pos, int):
            raise TypeError("Stop position has to be an integer.")
        if not 1 <= start_pos <= stop_pos <= MAX_NUM_SAMPLES:
            raise ValueError("Start or stop position out of range.")
            
        if os.path.isdir(os.path.dirname(parsed)):
            parsed_abs = parsed
        else:
            parsed_abs = os.getcwd() + '/' + parsed
            
        if os.system('rm -rf ' + parsed_abs):
            raise RuntimeError("Cannot remove old parsed file.")

        with open(parsed_abs, 'w') as f:
            for i in range(start_pos, stop_pos):
                if self.if_id == PMODA:
                    sample = np.array(list(
                            np.binary_repr(self.samples[i], width=64))[32:])
                    io_direction = sample[8:16]
                    io_input = sample[16:24]
                    io_output = sample[24:]
                    io_direction = io_direction[self.pins]
                    io_input = io_input[self.pins]
                    io_output = io_output[self.pins]
                elif self.if_id == PMODB:
                    sample = np.array(list(
                            np.binary_repr(self.samples[i], width=64))[:32])
                    io_direction = sample[8:16]
                    io_input = sample[16:24]
                    io_output = sample[24:]
                    io_direction = io_direction[self.pins]
                    io_input = io_input[self.pins]
                    io_output = io_output[self.pins]
                else:
                    sample = np.array(list(
                            np.binary_repr(self.samples[i], width=64)))
                    io_direction = sample[:22]
                    io_input = sample[22:44]
                    io_output = np.append(sample[44:], ['0', '0'])
                    io_direction = io_direction[self.pins]
                    io_input = io_input[self.pins]
                    io_output = io_output[self.pins]

                condition = [io_direction=='0', io_direction=='1']
                list_val = np.select(condition, [io_output, io_input])
                f.write(','.join(list_val) + '\n')
                
        self.trace_csv = parsed_abs
        self.trace_sr = ''
        
    def display(self):
        """Draw digital waveforms in ipython notebook.
        
        It utilises the wavedrom java script library, documentation for which 
        can be found here: https://code.google.com/p/wavedrom/.
        
        Note
        ----
        Only use this method in Jupyter notebook.
        
        Note
        ----
        WaveDrom.js and WaveDromSkin.js are required under the subdirectory js.
        
        Example of the data format to draw waveform:
        
        >>> data = {'signal': [
        
        {'name': 'clk', 'wave': 'p.....|...'},
        
        {'name': 'dat', 'wave': 'x.345x|=.x', 'data': ['D','A','T','A']},
        
        {'name': 'req', 'wave': '0.1..0|1.0'},
        
        {},
        
        {'name': 'ack', 'wave': '1.....|01.'}
        
        ]}
            
        Returns
        -------
        None
        
        """
        # Copy the javascript to the notebook location
        if not (os.path.isfile('./js/WaveDrom.js') and
                os.path.isfile('./js/WaveDromSkin.js')):
            if os.system("cp -rf " + \
                        os.path.dirname(os.path.realpath(__file__)) + \
                        '/js' + ' ./'):
                raise RuntimeError('Cannnot copy wavedrom javascripts.')
        
        # Convert sr file to csv file, if necessary
        if self.trace_csv == '':
            self.sr2csv()
            
        # Read csv trace file
        data_file = open(self.trace_csv, 'r')

        
        # Construct the sample numbers and headers
        head = dict()
        head['text'] = ['tspan', {'class':'info h4'},
            'Protocol decoder: ' + self.protocol + \
            '; Sample rate: ' + str(self.rate) + ' samples/s']
        head['tock'] = ''

        # Setting up the json data
        data = dict()
        if self.trace_pd:
            pd_file = open(self.trace_pd, 'r')
            data['signal'] = [{'name': '', 'wave': '', 'data': list()}
                              for _ in range(len(self.probes)+1)]
            i = 0
            for data_line, pd_line in zip_longest(data_file, pd_file):
                # Adding time line
                if i % 10 == 0:
                    head['tock'] += (str(i) + ' ' * 10)

                # Reading both raw data and decoded files
                csv_data = list(data_line.rstrip().split(','))
                if pd_line is not None:
                    pd_data = pd_line.rstrip()
                else:
                    pd_data = 'x'

                # Adding decoded data
                if str(pd_data) in ['x', '.']:
                    data['signal'][0]['wave'] += str(pd_data)
                else:
                    data['signal'][0]['wave'] += '4'
                    data['signal'][0]['data'].append(str(pd_data))

                # Adding raw data
                if i == 0:
                    ref = csv_data
                    for index, signal_name in enumerate(self.probes):
                        data['signal'][index+1]['name'] = signal_name
                        data['signal'][index+1]['wave'] += str(
                                            csv_data[index])
                else:
                    for index in range(len(self.probes)):
                        if csv_data[index] == ref[index]:
                            data['signal'][index+1]['wave'] += '.'
                        else:
                            ref[index] = csv_data[index]
                            data['signal'][index+1]['wave'] += str(
                                            csv_data[index])
                i += 1

            # Removing NC signal and close file
            for idx,val in enumerate(data['signal']):
                if val['name'] == 'NC':
                    del data['signal'][idx]
            pd_file.close()
        else:
            data['signal'] = [{'name': '', 'wave': '', 'data': list()}
                              for _ in range(len(self.probes))]
            for i, data_line in enumerate(data_file):
                if i % 10 == 0:
                    head['tock'] += (str(i) + ' ' * 10)

                csv_data = list(data_line.rstrip().split(','))
                if i == 0:
                    ref = csv_data
                    for index, signal_name in enumerate(self.probes):
                        data['signal'][index]['name'] = signal_name
                        data['signal'][index]['wave'] += str(csv_data[index])
                else:
                    for index in range(len(self.probes)):
                        if csv_data[index] == ref[index]:
                            data['signal'][index]['wave'] += '.'
                        else:
                            ref[index] = csv_data[index]
                            data['signal'][index]['wave'] += str(
                                csv_data[index])
        data['head'] = head

        # Close data file
        data_file.close()
        
        htmldata = '<script type="WaveDrom">' + json.dumps(data) + '</script>'
        IPython.core.display.display_html(IPython.core.display.HTML(htmldata))
        jsdata = 'WaveDrom.ProcessAll();'
        IPython.core.display.display_javascript(
            IPython.core.display.Javascript(
                data=jsdata,
                lib=['files/js/WaveDrom.js', 'files/js/WaveDromSkin.js']))
    