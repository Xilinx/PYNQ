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
    
    def __init__(self, protocol, trace, data=None, length=None, 
                 mask=0xFFFFFFFF, tri_sel=[], tri_0=[], tri_1=[]):
        """Return a new trace buffer object. 
        
        Users have to specify the location of the traces, even if no trace 
        has been imported from DMA yet. This method will construct the trace
        from the DMA data.
        
        Note
        ----
        The probes selected by `mask` does not include any tristate probe.
        
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
        tri_sel : list
            The list of tristate selection probes.
        tri_0 : list
            The list of probes selected when the selection probe is 0.
        tri_1 : list
            The list probes selected when the selection probe is 1.
        
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
        if not isinstance(mask, int):
            raise TypeError("Data mask has to be an integer.")
        if not 0<= mask <=0xFFFFFFFF:
            raise ValueError("Data mask out of range.")
            
        if not isinstance(tri_sel, list):
            raise TypeError("Selection probes has to be in a list.")
        if not isinstance(tri_0, list) or not isinstance(tri_1, list):
            raise TypeError("Data probes has to be in a list.")
        if not len(tri_sel)==len(tri_0)==len(tri_1):
            raise ValueError("Inconsistent length for tristate lists.")
        for element in tri_sel:
            if not isinstance(element, int) or not 0<element<=0xFFFFFFFF:
                raise TypeError("Selection probe has to be an integer.")
            if not (element & element-1)==0:
                raise ValueError("Selection probe can only have 1-bit set.")
            if not (element & mask)==0:
                raise ValueError("Selection probe has be excluded from mask.")
        for element in tri_0:
            if not isinstance(element, int) or not 0<element<=0xFFFFFFFF:
                raise TypeError("Data probe has to be an integer.")
            if not (element & element-1)==0:
                raise ValueError("Data probe can only have 1-bit set.")
            if not (element & mask)==0:
                raise ValueError("Data probe has be excluded from mask.")
        for element in tri_1:
            if not isinstance(element, int) or not 0<element<=0xFFFFFFFF:
                raise TypeError("Data probe has to be an integer.")
            if not (element & element-1)==0:
                raise ValueError("Data probe can only have 1-bit set.")
            if not (element & mask)==0:
                raise ValueError("Data probe has be excluded from mask.")
        
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
            self.parse(trace, data, length, mask, tri_sel, tri_0, tri_1)
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
        
    def decode(self, file_name, transactions=None):
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
        transactions : list
            A list of strings specifying the channel names.
        
        Return
        ------
        None
        
        """
        if not isinstance(file_name, str):
            raise TypeError("'file_name' has to be a string.")
        
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
        if os.system(command):
            raise RuntimeError('Sigrok-cli decode failed.')
        
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
            self.csv2sr()
            
        name, _ = os.path.splitext(self.trace_sr)
        if os.system("mkdir " + name):
            raise RuntimeError('Directory cannot be created.')
        if os.system("unzip -q "+ self.trace_sr + " -d " + name):
            raise RuntimeError('Unzip sr file failed.')
        
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
        
        if os.system("rm -rf "+ name + '/metadata'):
            raise RuntimeError('Cannot remove metadata folder.')
        if os.system("mv " + name + '/temp ' + name + '/metadata'):
            raise RuntimeError('Cannot rename metadata folder.')
        if os.system("cd "+ name +"; zip -rq " + \
                    self.trace_sr + " * ; cd .."):
            raise RuntimeError('Zip sr file failed.')
        if os.system("rm -rf " + name):
            raise RuntimeError('Cannnot remove temporary folder.')
        
    def parse(self, parse_out, data, length, mask=0xFFFFFFFF, 
              tri_sel=[], tri_0=[], tri_1=[]):
        """Parse the input data and generate a `*.csv` file.
        
        This method can be used along with the DMA. The input data is assumed
        to be 32-bit. The generated `*.csv` file can be then used as the trace
        file.
        
        To extract certain bits from the 32-bit data, use the parameter
        `mask`. 
        
        Note
        ----
        The probes selected by `mask` does not include any tristate probe.
        
        To specify a set of tristate probes, e.g., users can set 
        tri_sel = [0x00000004], tri_0 = [0x00000010], tri_1 = [0x00000100].
        In this example, the 3rd probe from the LSB is the selection probe; 
        the 5th probe is selected if selection probe is 0, otherwise the 9th
        probe is selected. There can be multiple sets of tristate probes.
        
        Note
        ----
        The parsed data will be stored in the same folder as this file.
        
        Parameters
        ----------
        parse_out : str
            The file name of the parsed output.
        data : cffi.FFI.CData
            The pointer to the starting address of the data.
        length : int
            The length of the data, in number of 32-bit integers.
        mask : int
            A 32-bit mask to be applied to the 32-bit data.
        tri_sel : list
            The list of tristate selection probes.
        tri_0 : list
            The list of probes selected when the selection probe is 0.
        tri_1 : list
            The list probes selected when the selection probe is 1.
        
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
        if not 0<=mask<=0xFFFFFFFF:
            raise ValueError("Data mask out of range.")
        if not isinstance(tri_sel, list):
            raise TypeError("Selection probes has to be in a list.")
        if not isinstance(tri_0, list) or not isinstance(tri_1, list):
            raise TypeError("Data probes has to be in a list.")
        if not len(tri_sel)==len(tri_0)==len(tri_1):
            raise ValueError("Inconsistent length for tristate lists.")
        for element in tri_sel:
            if not isinstance(element, int) or not 0<element<=0xFFFFFFFF:
                raise TypeError("Selection probe has to be an integer.")
            if not (element & element-1)==0:
                raise ValueError("Selection probe can only have 1-bit set.")
            if not (element & mask)==0:
                raise ValueError("Selection probe has be excluded from mask.")
        for element in tri_0:
            if not isinstance(element, int) or not 0<element<=0xFFFFFFFF:
                raise TypeError("Data probe has to be an integer.")
            if not (element & element-1)==0:
                raise ValueError("Data probe can only have 1-bit set.")
            if not (element & mask)==0:
                raise ValueError("Data probe has be excluded from mask.")
        for element in tri_1:
            if not isinstance(element, int) or not 0<element<=0xFFFFFFFF:
                raise TypeError("Data probe has to be an integer.")
            if not (element & element-1)==0:
                raise ValueError("Data probe can only have 1-bit set.")
            if not (element & mask)==0:
                raise ValueError("Data probe has be excluded from mask.")
            
        parsed = os.path.dirname(os.path.realpath(__file__)) + '/' + parse_out
        if os.system('rm -rf ' + parsed):
            raise RuntimeError("Cannot remove parsed file.")
        with open(parsed, 'w') as f:
            for i in range(0,length):
                raw_val = data[i] & 0xFFFFFFFF
                list_val = []
                for j in range(31,-1,-1):
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
                
        self.trace_csv = parsed
        self.trace_sr = ''