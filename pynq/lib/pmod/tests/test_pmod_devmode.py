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


from random import randint
import pytest
from pynq import Overlay
from pynq.lib.pmod import Pmod_DevMode
from pynq.lib.pmod import PMODA
from pynq.lib.pmod import PMODB
from pynq.lib.pmod import PMOD_SWCFG_IIC0_TOPROW
from pynq.lib.pmod import PMOD_SWCFG_IIC0_BOTROW
from pynq.lib.pmod import PMOD_SWCFG_DIOALL
from pynq.lib.pmod import PMOD_DIO_BASEADDR
from pynq.lib.pmod import PMOD_DIO_TRI_OFFSET
from pynq.lib.pmod import PMOD_DIO_DATA_OFFSET
from pynq.lib.pmod import PMOD_CFG_DIO_ALLOUTPUT
from pynq.lib.pmod import PMOD_CFG_DIO_ALLINPUT


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    _ = Overlay('base.bit', download=False)
    flag = True
except IOError:
    flag = False


@pytest.mark.skipif(not flag, reason="need base overlay to run")
def test_pmod_devmode():
    """Tests the Pmod DevMode.

    The first test will instantiate DevMode objects with various switch 
    configurations. The returned objects should not be None.

    The second test write a command to the mailbox and read another command
    from the mailbox. Test whether the write and the read are successful.

    """
    ol = Overlay('base.bit')

    for mb_info in [PMODA, PMODB]:
        assert Pmod_DevMode(mb_info, PMOD_SWCFG_IIC0_TOPROW) is not None
        assert Pmod_DevMode(mb_info, PMOD_SWCFG_IIC0_BOTROW) is not None
        assert Pmod_DevMode(mb_info, PMOD_SWCFG_DIOALL) is not None
        ol.reset()

        # Initiate the Microblaze
        microblaze = Pmod_DevMode(mb_info, PMOD_SWCFG_DIOALL)
        microblaze.start()
        assert microblaze.status() == "RUNNING"

        # Test whether writing is successful
        data = 0
        microblaze.write_cmd(PMOD_DIO_BASEADDR + PMOD_DIO_TRI_OFFSET, 
                             PMOD_CFG_DIO_ALLOUTPUT)
        microblaze.write_cmd(PMOD_DIO_BASEADDR + PMOD_DIO_DATA_OFFSET, data)

        # Test whether reading is successful
        microblaze.write_cmd(PMOD_DIO_BASEADDR + PMOD_DIO_TRI_OFFSET,
                             PMOD_CFG_DIO_ALLINPUT)
        data = microblaze.read_cmd(PMOD_DIO_BASEADDR + PMOD_DIO_DATA_OFFSET)
        assert data is not None

        # Stop the Microblaze
        microblaze.stop()
        assert microblaze.status() == "STOPPED"
        ol.reset()

    del ol
