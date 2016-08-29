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


from random import randint
import pytest
from pynq import Overlay
from pynq.iop import iop
from pynq.iop import iop_const
from pynq.iop import DevMode

global ol
ol = Overlay("base.bit")

@pytest.mark.run(order=14)
def test_devmode():
    """Tests whether DevMode returns an _IOP for Pmod 1 and 2.
    
    For each Pmod ID, instantiate a DevMode object with various switch 
    configurations. The returned objects should not be None.
    
    """
    for iop_id in range(1,3):
        assert DevMode(iop_id, iop_const.PMOD_SWCFG_IIC0_TOPROW) is not None
        assert DevMode(iop_id, iop_const.PMOD_SWCFG_IIC0_BOTROW) is not None
        assert DevMode(iop_id, iop_const.PMOD_SWCFG_DIOALL) is not None
    
    ol.reset()

@pytest.mark.run(order=15)
def test_devmode():
    """Tests whether DevMode write and read work for Pmod 1 and 2.
    
    For each Pmod ID, write a command to the mailbox and read another command
    from the mailbox. Test whether the write and the read are successful.
    
    """
    for iop_id in range(1,3):
        # Initiate the IOP
        iop = DevMode(iop_id, iop_const.PMOD_SWCFG_DIOALL)
        iop.start()
        assert iop.status()=="RUNNING"
        # Test whether writing is successful
        data = 0
        iop.write_cmd(iop_const.PMOD_DIO_BASEADDR + \
                      iop_const.PMOD_DIO_TRI_OFFSET,
                      iop_const.PMOD_CFG_DIO_ALLINPUT)
        iop.write_cmd(iop_const.PMOD_DIO_BASEADDR + \
                      iop_const.PMOD_DIO_DATA_OFFSET, data)
        # Test whether reading is successful
        iop.write_cmd(iop_const.PMOD_DIO_BASEADDR + \
                      iop_const.PMOD_DIO_TRI_OFFSET,
                      iop_const.PMOD_CFG_DIO_ALLOUTPUT)
        data = iop.read_cmd(iop_const.PMOD_DIO_BASEADDR + \
                            iop_const.PMOD_DIO_DATA_OFFSET)
        # Stop the IOP
        iop.stop()
        assert iop.status()=="STOPPED"
        
    ol.reset()
