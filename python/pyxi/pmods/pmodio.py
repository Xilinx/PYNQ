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


from . import pmod_const
from .devmode import DevMode

class PMODIO(object):
    """This class controls the PMOD IO pins as inputs or outputs.
    
    Note
    ----
    The parameter 'direction' determines whether the instance is input /output.
    direction = 0 -> output; sending output from onchip to offchip.
    direction = 1 -> input; receiving input from offchip to onchip. 
    When 2 PMODs are connected using a cable, the parameter 'cable' decides 
    whether the cable is a "loop-back" or "straight" cable.
    The default is a straight cable.
    
    Attributes
    ----------
    iop : _IOP
        The _IOP object returned from the DevMode.
    index : int
        The index of the pin in a PMOD, from 0 to 7.
    direction : int
        Input (1) or output (0).
    cable : int
        Straight cable (0) or loop-back cable (1).
    
    """
    def __init__(self, pmod_id, index, direction): 
        """Return a new instance of a PMOD IO object. 
        
        When we call request_iop() in DevMode, an exception might be raised if 
        the *force* flag is not set. Please refer to _iop.request_iop() for 
        additional details.
    
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA).
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
        index: int
            The index of the pin in a PMOD, from 0 to 7.
        direction : int
            Input (1) or output (0).
            
        """
        if (index not in range(8)):
            raise ValueError("Valid pin indexes are 0 - 7.")
        if (direction not in (0,1)):
            raise ValueError("direction can only be 0 (output), or 1 (input).")
        self.iop = DevMode(pmod_id, pmod_const.IOP_SWCFG_PMODIOALL)
        self.index = index
        self.direction = direction
        self.cable = pmod_const.PMODIO_CABLE_STRAIGHT
        
        self.iop.start()
        if (self.direction == pmod_const.IOCFG_PMODIO_INPUT):
            self.iop.write_cmd(pmod_const.IOPMM_PMODIO_BASEADDR+
                                pmod_const.IOPMM_PMODIO_TRI_OFFSET,
                                pmod_const.IOCFG_PMODIO_ALLINPUT)
        else:
            self.iop.write_cmd(pmod_const.IOPMM_PMODIO_BASEADDR+
                                pmod_const.IOPMM_PMODIO_TRI_OFFSET,
                                pmod_const.IOCFG_PMODIO_ALLOUTPUT)
                                                                        
        self.iop.load_switch_config()
                           
    def setCable(self, cable):
        """Set the cable type for the PMOD IOs.

        Note
        ----------
        The default cable type is "straight". Only straight cable or loop-back
        cable can be recognized.
       
        Parameters
        ----------
        cable : int
            Straight cable (0) or loop-back cable (1).
            
        Returns
        -------
        None
        
        """
        if (cable==pmod_const.PMODIO_CABLE_STRAIGHT):
            self.cable = pmod_const.PMODIO_CABLE_STRAIGHT
        elif (cable==pmod_const.PMODIO_CABLE_LOOPBACK):
            self.cable = pmod_const.PMODIO_CABLE_LOOPBACK
        else:
            raise ValueError("Cable unrecognizable.")
    
    def write(self, value): 
        """Send the value to the offboard PMOD IO device.

        Note
        ----------
        Only use this function when direction = 0.
        
        Parameters
        ----------
        value : int
            The value to be written to the PMOD IO device.
            
        """
        if not value in (0,1):
            raise ValueError("PMOD IO can only write 0 or 1.")
        if not self.direction is pmod_const.IOCFG_PMODIO_OUTPUT:
            raise ValueError('PMOD IO used as output, but declared as input.')

        if value:
            #: Set the value of a single PMOD IO pin to 1.
            currVal = self.iop.read_cmd(pmod_const.IOPMM_PMODIO_BASEADDR+
                                        pmod_const.IOPMM_PMODIO_DATA_OFFSET)
            newVal = currVal | (0x1<<self.index)
            self.iop.write_cmd(pmod_const.IOPMM_PMODIO_BASEADDR + 
                                pmod_const.IOPMM_PMODIO_DATA_OFFSET, newVal)
        else:
            #: Set the value of a single PMOD IO pin to 0.
            currVal = self.iop.read_cmd(pmod_const.IOPMM_PMODIO_BASEADDR+
                                        pmod_const.IOPMM_PMODIO_DATA_OFFSET)
            newVal = currVal & (0xff ^ (0x1<<self.index))
            self.iop.write_cmd(pmod_const.IOPMM_PMODIO_BASEADDR + 
                                pmod_const.IOPMM_PMODIO_DATA_OFFSET, newVal)

    def read(self):
        """Receive the value from the offboard PMOD IO device.

        Note
        ----
        When two PMODs are connected, for any received raw value, 
        a "straignt" cable (self.cable = 0) flips the upper 4 pins and 
        the bottom 4 pins:
        {vdd,gnd,0,1,2,3}      <=>      {vdd,gnd,4,5,6,7}
        {vdd,gnd,4,5,6,7}      <=>      {vdd,gnd,0,1,2,3}
        A "loop-back" cable (self.cable = 1) satisfies the following mapping 
        between two PMODs:
        {vdd,gnd,0,1,2,3}      <=>      {vdd,gnd,0,1,2,3}
        {vdd,gnd,4,5,6,7}      <=>      {vdd,gnd,4,5,6,7}
        Also, only use this function when direction = 1.
        
        Parameters
        ---------
        None
        
        Returns
        -------
        int
            The data (0 or 1) on the specified PMOD IO pin.
        
        """  
        if not self.direction is pmod_const.IOCFG_PMODIO_INPUT:
            raise ValueError('PMOD IO used as input, but declared as output.') 
        raw_value = self.iop.read_cmd(pmod_const.IOPMM_PMODIO_BASEADDR+
                                        pmod_const.IOPMM_PMODIO_DATA_OFFSET) 
                                 
        if self.cable==pmod_const.PMODIO_CABLE_STRAIGHT:
            if (self.index < 4):
                return (raw_value >> (self.index+4)) & 0x1
            else:
                return (raw_value >> (self.index-4)) & 0x1
        else:
                return (raw_value >> (self.index)) & 0x1
