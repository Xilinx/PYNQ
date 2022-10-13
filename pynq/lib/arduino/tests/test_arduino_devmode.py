#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from random import randint
import pytest
from pynq import Overlay
from pynq.lib.arduino import Arduino_DevMode
from pynq.lib.arduino import ARDUINO
from pynq.lib.arduino import ARDUINO_SWCFG_DIOALL
from pynq.lib.arduino import ARDUINO_DIO_BASEADDR
from pynq.lib.arduino import ARDUINO_DIO_TRI_OFFSET
from pynq.lib.arduino import ARDUINO_DIO_DATA_OFFSET
from pynq.lib.arduino import ARDUINO_CFG_DIO_ALLOUTPUT
from pynq.lib.arduino import ARDUINO_CFG_DIO_ALLINPUT




try:
    _ = Overlay('interface.bit', download=False)
    flag = True
except IOError:
    flag = False


@pytest.mark.skipif(not flag, reason="need base overlay to run")
def test_arduino_devmode():
    """Tests the Arduino DevMode.

    The first test will instantiate DevMode objects with various switch 
    configurations. The returned objects should not be None.

    The second test write a command to the mailbox and read another command
    from the mailbox. Test whether the write and the read are successful.

    """
    ol = Overlay('base.bit')

    for mb_info in [ARDUINO]:
        assert Arduino_DevMode(mb_info, ARDUINO_SWCFG_DIOALL) is not None
        ol.reset()

        # Initiate the Microblaze
        microblaze = Arduino_DevMode(mb_info, ARDUINO_SWCFG_DIOALL)
        microblaze.start()
        assert microblaze.status() == "RUNNING"

        # Test whether writing is successful
        data = 0
        microblaze.write_cmd(ARDUINO_DIO_BASEADDR + ARDUINO_DIO_TRI_OFFSET,
                             ARDUINO_CFG_DIO_ALLOUTPUT)
        microblaze.write_cmd(ARDUINO_DIO_BASEADDR + ARDUINO_DIO_DATA_OFFSET,
                             data)

        # Test whether reading is successful
        microblaze.write_cmd(ARDUINO_DIO_BASEADDR + ARDUINO_DIO_TRI_OFFSET,
                             ARDUINO_CFG_DIO_ALLINPUT)
        data = microblaze.read_cmd(ARDUINO_DIO_BASEADDR +
                                   ARDUINO_DIO_DATA_OFFSET)
        assert data is not None

        # Stop the Microblaze
        microblaze.stop()
        assert microblaze.status() == "STOPPED"
        ol.reset()

    del ol


