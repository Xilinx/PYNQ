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


from random import randint
import pytest
from pynq.pmods.devmode import DevMode
from pynq.pmods import _iop
from pynq.pmods import pmod_const
from pynq import Overlay

global ol
ol = Overlay("pmod.bit")

@pytest.mark.run(order=13)
def test_devmode():
    """Tests whether DevMode returns an _IOP for PMOD 1/2/3/4.
    
    For each PMOD ID, instantiate a DevMode object with various switch 
    configurations. The returned objects should not be None.
    
    """
    ol.flush_ip_dictionary()
    
    for pmod_id in range(1,5):
        assert DevMode(pmod_id, pmod_const.IOP_SWCFG_IIC0_TOPROW) is not None
        assert DevMode(pmod_id, pmod_const.IOP_SWCFG_IIC0_BOTROW) is not None
        assert DevMode(pmod_id, pmod_const.IOP_SWCFG_PMODIOALL) is not None
    
    ol.flush_ip_dictionary()

@pytest.mark.run(order=14)
def test_devmode():
    """Tests whether DevMode write and read work for PMOD 1/2/3/4.
    
    For each PMOD ID, write a command to the mailbox and read another command
    from the mailbox. Test whether the write and the read are successful.
    
    """
    ol.flush_ip_dictionary()
    
    for pmod_id in range(1,5):
        #: Initiate the IOP
        iop = DevMode(pmod_id, pmod_const.IOP_SWCFG_PMODIOALL)
        iop.start()
        assert iop.status()=="RUNNING"
        #: Test whether writing is successful
        data_1 = 0
        iop.write_cmd(pmod_const.IOPMM_PMODIO_BASEADDR+
                        pmod_const.IOPMM_PMODIO_TRI_OFFSET,
                        pmod_const.IOCFG_PMODIO_ALLINPUT)
        iop.load_switch_config()
        iop.write_cmd(pmod_const.IOPMM_PMODIO_BASEADDR + 
                        pmod_const.IOPMM_PMODIO_DATA_OFFSET, data_1)
        #: Test whether reading is successful
        iop.write_cmd(pmod_const.IOPMM_PMODIO_BASEADDR+
                        pmod_const.IOPMM_PMODIO_TRI_OFFSET,
                        pmod_const.IOCFG_PMODIO_ALLOUTPUT)
        iop.load_switch_config()
        data_2 = iop.read_cmd(pmod_const.IOPMM_PMODIO_BASEADDR+
                                pmod_const.IOPMM_PMODIO_DATA_OFFSET)
        #: Stop the IOP after 100 tests
        iop.stop()
        assert iop.status()=="STOPPED"
        
    ol.flush_ip_dictionary()
