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
__email__       = "xpp_support@xilinx.com"


import os
import cffi

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
        
    """
    
    def __init__(self, protocol, trace, data=None, length=None, mask=None):
        """Return a new trace buffer object. 
        
        Users have to specify the location of the traces, even if no trace 
        has been imported from DMA yet. This method will construct the trace
        from the DMA data.
        
        Parameters
        ----------
        protocol : str
            The protocol the sigrok decoder are using.
        trace: str
            The relative/absolute path of the trace file.
        data : cffi.FFI.CData
            The pointer to the starting address of the data.
        length : int
            The length of the data, in number of 32-bit integers.
        mask : int
            The mask to be applied to the 32-bit data.
        
        """
        if os.geteuid() != 0:
            raise EnvironmentError('Root permissions required.')
        if not isinstance(protocol, str):
            raise TypeError("Protocol name has to be a string.")
        if not isinstance(trace, str):
            raise TypeError("Trace path has to be a string.")
        
        if data != None:
            if not isinstance(data, cffi.FFI.CData):
                raise TypeError("Data pointer has wrong type.")
        if length != None:
            if not isinstance(length, int):
                raise TypeError("Data length has to be an integer.")
            if not 1<=length<=0x100000:
                raise ValueError("Data length has to be in [1,0x100000].")
        if mask != None:
            if not isinstance(mask, int):
                raise TypeError("Data mask has to be an integer.")
            if not 0< mask <=0xFFFFFFFF:
                raise ValueError("Data mask out of range.")
        
        if os.path.isfile(trace) or os.path.isfile(
                os.path.dirname(os.path.realpath(__file__)) + '/' + trace):
            # Trace file exists
            _, format = os.path.splitext(trace)
            if format == '.csv':
                self.trace_csv = os.path.dirname(
                                    os.path.realpath(trace)) + '/' + trace
                self.trace_sr = ''
            elif format == '.sr':
                self.trace_sr = os.path.dirname(
                                    os.path.realpath(trace)) + '/' + trace
                self.trace_csv = ''
            else:
                raise ValueError("Currently only supporting csv or sr files.")
        elif data != None and length != None and mask != None:
            # Trace does not exist, but can be constructed
            self.parse(data, length, mask)
        else:
            # Trace does not exist, and can't be constructed
            raise IOError('Trace {} does not exist or cannot be constructed.'\
                            .format(trace))
                            
        self.protocol = protocol
            
    def show(self):
        """Show information about the specified protocol.
        
        Parameters
        ----------
        None
        
        Return
        ------
        None
        
        """
        os.system("sigrok-cli --protocol-decoders "+self.protocol+" --show")
        
    def _csv2sr(self):
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
        os.system(command)
        
    def _sr2csv(self):
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
        command = "sigrok-cli -i " + self.trace_sr + \
                    " -O csv > " + temp
        os.system(command)
        
        in_file = open(temp, 'r')
        out_file = open(self.trace_csv, 'w')
        # Copy only the contents; ignore comments
        for i, line in enumerate(in_file):
            if not line.startswith(';'):
                out_file.write(line)
        in_file.close()
        out_file.close()
        os.remove(temp)
        
    def decode(self, file_name, samplerate, probes, transactions=None):
        """Decode and record the trace based on the protocol specified.
        
        Example transaction names can be `address-read`, `data-write`, etc. 
        To show all the reads and writes, users can specify:
        transactions = ['address-read','address-write','data-read',
        'data-write'].
        
        `file_name` is only the name, not the path of the output file. The 
        output file will be put into the same folder as the trace file.
        
        `probes` are names associated with all the tracks in PulseView.
        
        Note
        ----
        If `transactions` are left None (by default), this method will return 
        all the raw transactions.
        
        Parameters
        ----------
        file_name : str
            The name of the file recording the outputs.
        samplerate : int
            The rate of the samples.
        probes : list
            A list of probe names.
        transactions : list
            A list of strings specifying the channel names.
        
        Return
        ------
        None
        
        """
        if not isinstance(file_name, str):
            raise TypeError("'file_name' has to be a string.")
        
        self.set_metadata(samplerate, probes)
        command = "sigrok-cli -i " + self.trace_sr + " -P " + self.protocol
        
        # Select transactions, if specified
        if transactions == None:
            pass
        elif not isinstance(transactions, list):
            raise TypeError("'transactions' has to be a list.")
        else:
            channel_list = ':'.join(transactions)
            command += (" -A " + self.protocol + "=" + channel_list)
        
        # Write to output file
        ext = os.path.dirname(os.path.realpath(self.trace_csv)) + \
                    '/' + file_name
        command += ('> ' + ext)
        
        # Execute command
        os.system(command)
        
    def set_metadata(self, samplerate, probes):
        """Set metadata for the trace.
        
        A `*.sr` file directly generated from `*.csv` will not have any 
        metadata. This method helps to set the sample rate, probe names, etc.
        
        Parameters
        ----------
        samplerate : int
            The rate of the samples.
        probes : list
            A list of probe names.
        
        Return
        ------
        None
        
        """
        if not isinstance(samplerate, int):
            raise TypeError("Sample rate has to be an integer.")
        if not isinstance(probes, list):
            raise TypeError("Probes have to be in a list.")
            
        # Convert csv file to sr file, if necessary
        if self.trace_sr == '':
            self._csv2sr()
            
        name, _ = os.path.splitext(self.trace_sr)
        os.system("unzip -q "+ self.trace_sr + " -d " + name)
        
        metadata = open(name + '/metadata', 'r')
        temp = open(name + '/temp', 'w')
        pat = "samplerate=0 Hz"
        subst = "samplerate=" + str(samplerate) +" Hz"
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
        
        os.remove(name + '/metadata')
        os.rename(name + '/temp', name + '/metadata')
        os.system("cd "+ name +"; zip -rq " + self.trace_sr + " * ; cd ..")
        os.system("rm -rf " + name)
        
    def parse(self, data, length, mask=0xFFFFFFFF):
        """Parse the input data and generate a `*.csv` file.
        
        This method can be used along with the DMA. The input data is assumed
        to be 32-bit. The generated `*.csv` file can be then used as the trace
        file.
        
        To extract certain bits from the 32-bit data, use the parameter
        `mask`. The mask always uses the big endian.
        
        Note
        ----
        The parsed data will be stored in the same folder as this file. 
        
        
        Parameters
        ----------
        data : cffi.FFI.CData
            The pointer to the starting address of the data.
        length : int
            The length of the data, in number of 32-bit integers.
        mask : int
            The mask to be applied to the 32-bit data.
        
        Return
        ------
        None
        
        """
        if not isinstance(data, cffi.FFI.CData):
            raise TypeError("Data pointer has wrong type.")
        if not isinstance(length, int):
            raise TypeError("Data length has to be an integer.")
        if not 1<=length<=0x100000:
            raise ValueError("Data length has to be in [1,0x100000]")
        if not isinstance(mask, int):
            raise TypeError("Data mask has to be an integer.")
        if not 0< mask <=0xFFFFFFFF:
            raise ValueError("Data mask out of range.")
            
        parsed = os.path.dirname(os.path.realpath(__file__)) + '/trace.csv'
        with open(parsed, 'w') as f:
            for i in range(0,length):
                raw_val = data[i] & 0xFFFFFFFF
                list_val = []
                for j in range(31,-1,-1):
                    if (mask & 1<<j)>>j:
                        list_val.append(str((raw_val & 1<<j)>>j))
                temp = ','.join(list_val)
                f.write(temp + '\n')
                