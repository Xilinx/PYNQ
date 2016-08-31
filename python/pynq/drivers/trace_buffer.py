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
from time import sleep
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
MASK_ALL                    = 0xFFFFFFFFFFFFFFFF

class Trace_Buffer:
    """Class for the trace buffer, leveraging the sigrok libraries.
    
    This trace buffer class gets the traces from DMA and processes it using 
    the sigrok commands.
    
    Note
    ----
    The `sigrok-cli` library has to be installed before using this class.
    
    Attributes
    ----------
    protocol : str
        The protocol the sigrok decoder are using.
    trace_csv: str
        The absolute path of the trace file `*.csv`.
    trace_sr: str
        The absolute path of the trace file `*.sr`, translated from `*.csv`.
    trace_pd : str
        The absolute path of the decoded file by sigrok.
    probes : list
        The list of probes used for the trace.
    dma : DMA
        The DMA object associated with the trace buffer.
    ctrl : MMIO
        The MMIO class used to control the DMA.
    samplerate: int
        The samplerate of the traces.
    data : cffi.FFI.CData
        The pointer to the starting address of the trace data.
        
    """
    
    def __init__(self, if_id, protocol, trace=None, data=None, 
                 samplerate=500000):
        """Return a new trace buffer object. 
        
        Users have to specify the location of the traces, even if no trace 
        has been imported from DMA yet. This method will construct the trace
        from the DMA data.
        
        The maximum sample rate is 100MHz.
        
        Note
        ----
        The probes selected by `mask` does not include any tristate probe.
        
        Parameters
        ----------
        if_id : int
            The interface ID (PMODA, PMODB, ARDUINO).
        protocol : str
            The protocol the sigrok decoder are using.
        trace: str
            The relative/absolute path of the trace file.
        data : cffi.FFI.CData
            The pointer to the starting address of the data.
        samplerate : int
            The rate of the samples.
        
        """
        if os.geteuid() != 0:
            raise EnvironmentError('Root permissions required.')
        if not isinstance(protocol, str):
            raise TypeError("Protocol name has to be a string.")
        
        if data != None:
            if not isinstance(data, cffi.FFI.CData):
                raise TypeError("Data pointer has wrong type.")
        if not isinstance(samplerate, int):
            raise TypeError("Sample rate has to be an integer.")
        if not 1 <= samplerate <= 100000000:
            raise ValueError("Sample rate out of range.")
        
        if if_id in [PMODA, PMODB]:
            dma_base = int(PL.ip_dict["SEG_axi_dma_0_Reg"][0],16)
            ctrl_base = int(PL.ip_dict["SEG_trace_cntrl_0_Reg2"][0],16)
            ctrl_range = int(PL.ip_dict["SEG_trace_cntrl_0_Reg2"][1],16)
        elif if_id in [ARDUINO]:
            dma_base = int(PL.ip_dict["SEG_axi_dma_0_Reg1"][0],16)
            ctrl_base = int(PL.ip_dict["SEG_trace_cntrl_0_Reg"][0],16)
            ctrl_range = int(PL.ip_dict["SEG_trace_cntrl_0_Reg"][1],16)
        else:
            raise ValueError("No such IOP for instrumentation.")
            
        self.dma = DMA(dma_base, direction=1)
        self.ctrl = MMIO(ctrl_base, ctrl_range)
        self.samplerate = samplerate
        self.protocol = protocol
        self.data = data
        self.probes = []
        self.trace_pd = ''
        
        if trace != None: 
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

        Parameters
        ----------
        None
        
        Returns
        -------
        None

        """
        del(self.dma)
        
    def start(self, timeout=10):
        """Start the DMA to capture the traces.
        
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
            if (timer==0):
                raise RuntimeError("Timeout when waiting DMA to be idle.")
                
        # Configuration
        self.ctrl.write(TRACE_LENGTH_OFFSET, MAX_NUM_SAMPLES)
        self.ctrl.write(TRACE_SAMPLE_RATE_OFFSET, \
                        int(MAX_SAMPLE_RATE / self.samplerate))
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
        
        Parameters
        ----------
        None
            
        Return
        ------
        None
        
        """
        # Wait for the DMA
        self.dma.wait()
        
        # Get 64-bit samples from DMA
        self.data = self.dma.get_buf(64)
        
    def show(self):
        """Show information about the specified protocol.
        
        Parameters
        ----------
        None
        
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
        
        Parameters
        ----------
        None
        
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
        It is human readable.
        
        Note
        ----
        This method also removes the redundant header that is generated by 
        sigrok. 
        
        Parameters
        ----------
        None
        
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
            The name of the file recording the outputs.
        options : str
            Additional options to be passed to sigrok-cli.
        
        Return
        ------
        None
        
        """
        if not isinstance(decoded_file, str):
            raise TypeError("File name has to be a string.")
        if self.probes == []:
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
                while (j < int(m.group(1))):
                    f_decoded.write('\n')
                    j += 1
                while (j <= int(m.group(2))):
                    f_decoded.write(m.group(3) + '\n')
                    j += 1
        f_temp.close()
        f_decoded.close()
        self.trace_pd = decoded_abs
        
        if os.system('rm -rf ' + temp_file):
            raise RuntimeError("Cannot remove temporary file.")
        if os.path.getsize(self.trace_pd)==0:
            raise RuntimeError("No transactions and decoded file is empty.")
        
    def set_metadata(self, probes):
        """Set metadata for the trace.
        
        A `*.sr` file directly generated from `*.csv` will not have any 
        metadata. This method helps to set the sample rate, probe names, etc.
        
        The list `probes` depends on the protocol. For instance, the I2C
        protocol requires a list of ['SDA','SCL'].
        
        Parameters
        ----------
        probes : list
            A list of probe names.
        
        Return
        ------
        None
        
        """
        if not isinstance(probes, list):
            raise TypeError("Probes have to be in a list.")
            
        # Convert csv file to sr file, if necessary
        if self.trace_sr == '':
            self.csv2sr()
        self.probes = probes
            
        name, _ = os.path.splitext(self.trace_sr)
        if os.system("rm -rf " + name):
            raise RuntimeError('Directory cannot be deleted.')
        if os.system("mkdir " + name):
            raise RuntimeError('Directory cannot be created.')
        if os.system("unzip -q "+ self.trace_sr + " -d " + name):
            raise RuntimeError('Unzip sr file failed.')
        
        metadata = open(name + '/metadata', 'r')
        temp = open(name + '/temp', 'w')
        pat = "samplerate=0 Hz"
        subst = "samplerate=" + str(self.samplerate) +" Hz"
        j = 0
        for i, line in enumerate(metadata):
            if line.startswith("probe"):
                # Set the probe names
                temp.write("probe"+str(j+1)+"="+probes[j]+'\n')
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
            raise RuntimeError('Cannnot remove temporary folder.')
        
    def parse(self, parsed, start=0, stop=MAX_NUM_SAMPLES, mask=MASK_ALL,
              tri_sel=[], tri_0=[], tri_1=[]):
        """Parse the input data and generate a `*.csv` file.
        
        This method can be used along with the DMA. The input data is assumed
        to be 64-bit. The generated `*.csv` file can be then used as the trace
        file.
        
        To extract certain bits from the 64-bit data, use the parameter
        `mask`. 
        
        Note
        ----
        The probe pins selected by `mask` does not include any tristate probe.
        
        To specify a set of tristate probe pins, e.g., users can set 
        tri_sel = [0x0000000000000004],
        tri_0   = [0x0000000000000010], and
        tri_1   = [0x0000000000000100].
        In this example, the 3rd probe from the LSB is the selection probe; 
        the 5th probe is selected if selection probe is 0, otherwise the 9th
        probe is selected. There can be multiple sets of tristate probe pins.
        
        Note
        ----
        The parsed file will be put into the specified path, or in the 
        working directory in case the path does not exist.
        
        Parameters
        ----------
        parsed : str
            The file name of the parsed output.
        start : int
            The first 64-bit sample of the trace.
        stop : int
            The last 64-bit sample of the trace.
        mask : int
            A 64-bit mask to be applied to the 64-bit samples.
        tri_sel : list
            The list of tristate selection probe pins.
        tri_0 : list
            The list of probe pins selected when the selection probe is 0.
        tri_1 : list
            The list probe pins selected when the selection probe is 1.
        
        Return
        ------
        None
        
        """
        if not isinstance(parsed, str):
            raise TypeError("File name has to be an string.")
        if not isinstance(start, int):
            raise TypeError("Sample number has to be an integer.")
        if not isinstance(stop, int):
            raise TypeError("Sample number has to be an integer.")
        if not 1 <= (stop-start) <= MAX_NUM_SAMPLES:
            raise ValueError("Data length has to be in [1,{}]."\
                            .format(MAX_NUM_SAMPLES))
        if not isinstance(mask, int):
            raise TypeError("Data mask has to be an integer.")
        if not 0<=mask<=MASK_ALL:
            raise ValueError("Data mask out of range.")
        if not isinstance(tri_sel, list):
            raise TypeError("Selection probe pins have to be in a list.")
        if not isinstance(tri_0, list) or not isinstance(tri_1, list):
            raise TypeError("Data probe pins have to be in a list.")
        if not len(tri_sel)==len(tri_0)==len(tri_1):
            raise ValueError("Inconsistent length for tristate lists.")
        for element in tri_sel:
            if not isinstance(element, int) or not 0<element<=MASK_ALL:
                raise TypeError("Selection probe has to be an integer.")
            if not (element & element-1)==0:
                raise ValueError("Selection probe can only have 1-bit set.")
            if not (element & mask)==0:
                raise ValueError("Selection probe has be excluded from mask.")
        for element in tri_0:
            if not isinstance(element, int) or not 0<element<=MASK_ALL:
                raise TypeError("Data probe has to be an integer.")
            if not (element & element-1)==0:
                raise ValueError("Data probe can only have 1-bit set.")
            if not (element & mask)==0:
                raise ValueError("Data probe has be excluded from mask.")
        for element in tri_1:
            if not isinstance(element, int) or not 0<element<=MASK_ALL:
                raise TypeError("Data probe has to be an integer.")
            if not (element & element-1)==0:
                raise ValueError("Data probe can only have 1-bit set.")
            if not (element & mask)==0:
                raise ValueError("Data probe has be excluded from mask.")
            
        if os.path.isdir(os.path.dirname(parsed)):
            parsed_abs = parsed
        else:
            parsed_abs = os.getcwd() + '/' + parsed
            
        if os.system('rm -rf ' + parsed_abs):
            raise RuntimeError("Cannot remove old parsed file.")
        with open(parsed_abs, 'w') as f:
            for i in range(start, stop):
                raw_val = self.data[i] & MASK_ALL
                list_val = []
                for j in range(63,-1,-1):
                    if (mask & 1<<j)>>j:
                        list_val.append(str((raw_val & 1<<j)>>j))
                    else:
                        for selection in tri_sel:
                            idx = tri_sel.index(selection)
                            if (selection & 1<<j)>>j:
                                if ((raw_val & 1<<j)>>j)==0:
                                    log = tri_0[idx].bit_length()-1
                                    list_val.append(
                                        str((raw_val & 1<<log)>>log))
                                else:
                                    log = tri_1[idx].bit_length()-1
                                    list_val.append(
                                        str((raw_val & 1<<log)>>log))
                                
                temp = ','.join(list_val)
                f.write(temp + '\n')
                
        self.trace_csv = parsed_abs
        self.trace_sr = ''
        
    def display(self, start_pos, stop_pos):
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
        
        Parameters
        ----------
        start_pos : int
            The starting sample number (relative to the trace).
        stop_pos : int
            The stopping sample number (relative to the trace).
            
        Returns
        -------
        None
        
        """
        if self.probes == []:
            raise ValueError("Cannot display without metadata.")
        if not isinstance(start_pos, int):
            raise TypeError("Start position has to be an integer.")
        if not 1 <= start_pos <= MAX_NUM_SAMPLES:
            raise ValueError("Start position out of range.")
        if not isinstance(stop_pos, int):
            raise TypeError("Stop position has to be an integer.")
        if not 1 <= stop_pos <= MAX_NUM_SAMPLES:
            raise ValueError("Stop position out of range.")
        
        # Copy the javascript to the notebook location
        if os.system("cp -rf " + \
                    os.path.dirname(os.path.realpath(__file__)) + \
                    '/js' + ' ./'):
            raise RuntimeError('Cannnot copy wavedrom javascripts.')
        
        # Convert sr file to csv file, if necessary
        if self.trace_csv == '':
            self.sr2csv()
            
        # Read csv trace file
        with open(self.trace_csv, 'r') as data_file:
            csv_data = list(csv.reader(data_file))
            
        # Read decoded file
        with open(self.trace_pd, 'r') as pd_file:
            pd_data = list(csv.reader(pd_file))
        
        # Construct the decoded transactions
        data = {}
        data['signal']=[]
        if self.trace_pd != '':
            temp_val = {'name': '', 'wave': '', 'data': []}
            for i in range(start_pos, stop_pos):
                if i==start_pos:
                    ref = pd_data[i]
                    if not ref:
                        temp_val['wave'] += 'x'
                    else:
                        temp_val['wave'] += '4'
                        temp_val['data'].append(''.join(pd_data[i]))
                else:
                    if pd_data[i] == ref:
                        temp_val['wave'] += '.'
                    else:
                        ref = pd_data[i]
                        if not ref:
                            temp_val['wave'] += 'x'
                        else:
                            temp_val['wave'] += '4'
                            temp_val['data'].append(''.join(pd_data[i]))
            data['signal'].append(temp_val)
        
        # Construct the jason format data
        for signal_name in self.probes:
            index = self.probes.index(signal_name)
            temp_val = {'name': signal_name, 'wave': ''}
            for i in range(start_pos, stop_pos):
                if i==start_pos:
                    ref = csv_data[i][index]
                    temp_val['wave'] += str(csv_data[i][index])
                else:
                    if csv_data[i][index] == ref:
                        temp_val['wave'] += '.'
                    else:
                        ref = csv_data[i][index]
                        temp_val['wave'] += str(csv_data[i][index])
            data['signal'].append(temp_val)
            
        # Construct the sample numbers and headers
        head = {}
        head['text'] = ['tspan', {'class':'info h4'}, \
            'Protocol decoder: ' + self.protocol + \
            '; Sample rate: ' + str(self.samplerate) + ' samples/s']
        head['tock'] = ''
        for i in range(start_pos, stop_pos):
            if i%2:
                head['tock'] += ' '
            else:
                head['tock'] += (str(i)+' ')
        data['head'] = head
        
        htmldata = '<script type="WaveDrom">' + json.dumps(data) + '</script>'
        IPython.core.display.display_html(IPython.core.display.HTML(htmldata))
        jsdata = 'WaveDrom.ProcessAll();'
        IPython.core.display.display_javascript(
            IPython.core.display.Javascript(
                data=jsdata, \
                lib=['files/js/WaveDrom.js', 'files/js/WaveDromSkin.js']))
    