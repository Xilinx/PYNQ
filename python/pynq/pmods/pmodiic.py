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


from pynq.pmods import pmod_const
from pynq.pmods.devmode import DevMode

class PMODIIC(object):
    """This class controls the PMOD IIC pins.
    
    Note
    ----
    The index of the PMOD pins:
    upper row, from left to right: {vdd,gnd,3,2,1,0}.
    lower row, from left to right: {vdd,gnd,7,6,5,4}.
    
    Attributes
    ----------
    iop : _IOP
        The _IOP object returned from the DevMode.
    scl_pin : int
        The SCL pin number.
    sda_pin : int
        The SDA pin number.
    iic_addr : int
        The IIC device address.
    
    """
    def __init__(self, pmod_id, scl_pin, sda_pin, iic_addr, 
                 overlay_name='pmod.bit'): 
        """Return a new instance of a PMODIIC object.
    
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA).
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
        scl_pin : int
            The SCL pin number.
        sda_pin : int
            The SDA pin number.
        iic_addr : int
            The IIC device address.
        overlay_name : str
            The name of the overlay for IOP.
            
        """
        if (scl_pin not in range(8)):
            raise ValueError("Valid SCL pin numbers are 0 - 7.")
        if (sda_pin not in range(8)):
            raise ValueError("Valid SDA pin numbers are 0 - 7.")
        
        switchconfig = []
        for i in range(8):
            if i == sda_pin:
                switchconfig.append(pmod_const.IOP_SWCFG_IIC0_SDA)
            elif i == scl_pin:
                switchconfig.append(pmod_const.IOP_SWCFG_IIC0_SCL)
            else:
                switchconfig.append(pmod_const.IOP_SWCFG_PMODIO0)
        
        self.iop = DevMode(pmod_id, switchconfig, overlay_name)
        self.iop.start()
        self.iop.load_switch_config()
        
        self.iic_addr = iic_addr
        self._iic_enable()
        
    def _iic_enable(self):
        """This method enables the IIC drivers.
        
        The correct sequence to enable the drivers is:
        1. Disale the IIC core.
        2. Set the Rx FIFO depth to maximum.
        3. Reset the IIC core and flush the Tx FIFO.
        4. Enable the IIC core.
        
        Note
        ----
        This function is only required during initialization.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        #: Disale the IIC core
        self.iop.write_cmd(pmod_const.IOPMM_XIIC_0_BASEADDR + \
                            pmod_const.IOPMM_XIIC_CR_REG_OFFSET, 0x00)
        #: Set the Rx FIFO depth to maximum
        self.iop.write_cmd(pmod_const.IOPMM_XIIC_0_BASEADDR + \
                            pmod_const.IOPMM_XIIC_RFD_REG_OFFSET, 0x0F)
        #: Reset the IIC core and flush the Tx FIFO
        self.iop.write_cmd(pmod_const.IOPMM_XIIC_0_BASEADDR + \
                            pmod_const.IOPMM_XIIC_CR_REG_OFFSET, 0x02)
        #: Enable the IIC core
        self.iop.write_cmd(pmod_const.IOPMM_XIIC_0_BASEADDR + \
                            pmod_const.IOPMM_XIIC_CR_REG_OFFSET, 0x01)
        
    def send(self,iic_words):
        """This method sends the command or data to the driver.
        
        Parameters
        ----------
        iic_words : list
            A list of 32-bit words to be sent to the driver.
            
        Returns
        -------
        None
        
        Raises
        ------
        RuntimeError
            Timeout when waiting for the FIFO to be empty.
            
        """
        #: Transmit 7-bit address and Write bit (with START)
        self.iop.write_cmd(pmod_const.IOPMM_XIIC_0_BASEADDR + \
                            pmod_const.IOPMM_XIIC_DTR_REG_OFFSET, 
                            0x100 | (self.iic_addr << 1))
        
        #: Iteratively write into Tx FIFO, wait for it to be empty
        sr_addr = pmod_const.IOPMM_XIIC_0_BASEADDR + \
                    pmod_const.IOPMM_XIIC_SR_REG_OFFSET
        for tx_cnt in range(len(iic_words)):
            timeout = 100
            if (tx_cnt == len(iic_words) - 1):
                tx_word = (0x200 | iic_words[tx_cnt])
            else:
                tx_word = iic_words[tx_cnt]
            
            self.iop.write_cmd(pmod_const.IOPMM_XIIC_0_BASEADDR + \
                                pmod_const.IOPMM_XIIC_DTR_REG_OFFSET, 
                                tx_word)
            while ((timeout > 0) and \
                        ((self.iop.read_cmd(sr_addr) & 0x80) == 0x00)):
                timeout -= 1
            if (timeout==0):
                raise RuntimeError("Timeout when writing IIC.")
                