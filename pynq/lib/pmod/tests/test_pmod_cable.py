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
from time import sleep
import pytest
from pynq import Overlay
from pynq.lib.pmod import Pmod_Cable
from pynq.lib.pmod import PMODA
from pynq.lib.pmod import PMODB
from pynq.tests.util import user_answer_yes
from pynq.tests.util import get_interface_id


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    _ = Overlay('base.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTwo Pmod interfaces connected by a cable?")
if flag1:
    send_id = eval(get_interface_id('sender', options=['PMODA', 'PMODB']))
    recv_id = eval(get_interface_id('receiver', options=['PMODA', 'PMODB']))
flag = flag0 and flag1


@pytest.mark.skipif(not flag, 
                    reason="need Pmod cable attached to the base overlay")
def test_pmod_cable():
    """Tests for the Pmod cable.

    The following tests are involved here:

    1. Test the Pmod cable type.

    2. Test for right shifting the bit "1". The sender will send patterns 
    with the bit "1" right shifted each time.

    3. Test for right shifting the bit "0". The sender will send patterns 
    with the bit "0" right shifted each time.

    4. Test for left shifting the bit "1". The sender will send patterns 
    with the bit "1" left shifted each time.

    5. Test for left shifting the bit "0". The sender will send patterns 
    with the bit "0" left shifted each time.

    6. Test software-generated pseudo-random numbers. Random 0/1's are 
    generated at each bit location. 8 bits (1 bit per pin) are sent out 
    in every iteration. This test may take a few seconds to finish.

    Note
    ----
    The cable type can only be 'straight' or 'loopback'.
    Default cable type is straight.
    
    The Pmod IO layout is:
    Upper row: {vdd,gnd,3,2,1,0}.
    Lower row: {vdd,gnd,7,6,5,4}.
    
    """
    ol = Overlay('base.bit')
    print('\nTesting Pmod IO cable...')
    assert not send_id == recv_id, \
        "The sender port cannot be the receiver port."

    tx = [Pmod_Cable(send_id, k, 'out', 'loopback') for k in range(8)]
    rx = [Pmod_Cable(recv_id, k, 'in', 'loopback') for k in range(8)]
    tx[0].write(0)
    tx[3].write(0)
    tx[4].write(1)
    tx[7].write(1)
    
    if [rx[0].read(), rx[3].read(), rx[4].read(), rx[7].read()] == \
            [0, 0, 1, 1]:
        # Using a loop-back cable
        for i in range(8):
            rx[i].set_cable('loopback')
    elif [rx[0].read(), rx[3].read(), rx[4].read(), rx[7].read()] == \
            [1, 1, 0, 0]:
        # Using a straight cable
        for i in range(8):
            rx[i].set_cable('straight')
    else:
        raise AssertionError("Cable unrecognizable.")

    print('Generating tests for right shifting a \"1\"...')
    send_data = [1, 0, 0, 0, 0, 0, 0, 0]
    for i in range(8):
        if i != 0:
            send_data = send_data[-1:]+send_data[:-1]
        recv_data = [0, 0, 0, 0, 0, 0, 0, 0]
        tx[i].write(send_data[i])
        sleep(0.001)
        recv_data[i] = rx[i].read()
        assert send_data == recv_data,\
            'Sent {} != received {} at Pin {}.'.format(send_data, recv_data, i)

    print('Generating tests for right shifting a \"0\"...')
    send_data = [0, 1, 1, 1, 1, 1, 1, 1]
    for i in range(8):
        if i != 0:
            send_data = send_data[-1:]+send_data[:-1]
        recv_data = [1, 1, 1, 1, 1, 1, 1, 1]
        tx[i].write(send_data[i])
        sleep(0.001)
        recv_data[i] = rx[i].read()
        assert send_data == recv_data,\
            'Sent {} != received {} at Pin {}.'.format(send_data, recv_data, i)

    print('Generating tests for left shifting a \"1\"...')
    send_data = [0, 0, 0, 0, 0, 0, 0, 1]
    for i in range(8):
        if i != 0:
            send_data = send_data[1:]+send_data[:1]
        recv_data = [0, 0, 0, 0, 0, 0, 0, 0]
        tx[7-i].write(send_data[7-i])
        sleep(0.001)
        recv_data[7-i] = rx[7-i].read()
        assert send_data == recv_data,\
            'Sent {} != received {} at Pin {}' \
            .format(send_data, recv_data, 7-i)

    print('Generating tests for left shifting a \"0\"...')
    send_data = [1, 1, 1, 1, 1, 1, 1, 0]
    for i in range(8):
        if i != 0:
            send_data = send_data[1:]+send_data[:1]
        recv_data = [1, 1, 1, 1, 1, 1, 1, 1]
        tx[7-i].write(send_data[7-i])
        sleep(0.001)
        recv_data[7-i] = rx[7-i].read()
        assert send_data == recv_data,\
            'Sent {} != received {} at Pin {}' \
            .format(send_data, recv_data, 7-i)

    print('Generating 100 random tests...')
    for _ in range(100):
        send_data = [0, 0, 0, 0, 0, 0, 0, 0]
        recv_data = [1, 1, 1, 1, 1, 1, 1, 1]
        for j in range(8):
            send_data[j] = randint(0, 1)
            tx[j].write(send_data[j])
            sleep(0.001) 
            recv_data[j] = rx[j].read()
        assert send_data == recv_data,\
            'Sent {} != received {}.'.format(send_data, recv_data)

    ol.reset
