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
from time import sleep
import pytest
from pynq import Overlay
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import Pmod_Cable
from pynq.tests.util import user_answer_yes
from pynq.tests.util import get_pmod_id

flag = user_answer_yes("\nTwo Pmod interfaces connected by a cable?")
if flag:
    global TX_PORT,RX_PORT

    send_id = get_pmod_id('sender')
    if send_id == 'A':
        TX_PORT = PMODA
    elif send_id == 'B':
        TX_PORT = PMODB
    else:
        raise ValueError("Please type in A or B.")

    recv_id = get_pmod_id('receiver')
    if recv_id == 'A':
        RX_PORT = PMODA
    elif recv_id == 'B':
        RX_PORT = PMODB
    else:
        raise ValueError("Please type in A or B.")
    
@pytest.mark.run(order=16) 
@pytest.mark.skipif(not flag, reason="need Pmod cable connected to run")
def test_cable_type():
    """Tests for the Pmod cable type.
    
    Note
    ----
    The cable type can only be 'straight' or 'loopback'.
    Default cable type is straight.
    
    The Pmod IO layout is:
    Upper row: {vdd,gnd,3,2,1,0}.
    Lower row: {vdd,gnd,7,6,5,4}.
    
    """
    print('\nTesting Pmod IO cable...')
    assert not TX_PORT == RX_PORT, \
        "The sender port cannot be the receiver port."
    global tx,rx
    tx = [Pmod_Cable(TX_PORT,k,'out','loopback') for k in range(8)]
    rx = [Pmod_Cable(RX_PORT,k,'in','loopback') for k in range(8)]
    tx[0].write(0)
    tx[3].write(0)
    tx[4].write(1)
    tx[7].write(1)
    
    if [rx[0].read(),rx[3].read(),rx[4].read(),rx[7].read()]==[0,0,1,1]:
        # Using a loop-back cable
        for i in range(8):
            rx[i].set_cable('loopback')
    elif [rx[0].read(),rx[3].read(),rx[4].read(),rx[7].read()]==[1,1,0,0]:
        # Using a straight cable
        for i in range(8):
            rx[i].set_cable('straight')
    else:
        raise AssertionError("Cable unrecognizable.")

@pytest.mark.run(order=17) 
@pytest.mark.skipif(not flag, reason="need Pmod cable connected to run")
def test_rshift1():
    """Test for right shifting the bit "1".
    
    The sender will send patterns with the bit "1" right shifted each time.
    
    """
    print('\nGenerating tests for right shifting a \"1\"...')
    global tx,rx
    
    for i in range(8):
        if i==0:
            data1 = [1,0,0,0,0,0,0,0]
        else:
            data1 = data1[-1:]+data1[:-1]
        data2 = [0,0,0,0,0,0,0,0]
        tx[i].write(data1[i])
        sleep(0.001)
        data2[i] = rx[i].read()
        assert data1==data2,\
            'Sent {} != received {} at Pin {}.'.format(data1,data2,i)

@pytest.mark.run(order=18) 
@pytest.mark.skipif(not flag, reason="need Pmod cable connected to run") 
def test_rshift0():
    """Test for right shifting the bit "0".
    
    The sender will send patterns with the bit "0" right shifted each time.
    
    """
    print('\nGenerating tests for right shifting a \"0\"...')
    global tx,rx
    
    for i in range(8):
        if i==0:
            data1 = [0,1,1,1,1,1,1,1]
        else:
            data1 = data1[-1:]+data1[:-1]
        data2 = [1,1,1,1,1,1,1,1]
        tx[i].write(data1[i])
        sleep(0.001)
        data2[i] = rx[i].read()
        assert data1==data2,\
            'Sent {} != received {} at Pin {}.'.format(data1,data2,i) 

@pytest.mark.run(order=19) 
@pytest.mark.skipif(not flag, reason="need Pmod cable connected to run")
def test_lshift1():
    """Test for left shifting the bit "1".
    
    The sender will send patterns with the bit "1" left shifted each time.
    
    """
    print('\nGenerating tests for left shifting a \"1\"...')
    global tx,rx
    
    for i in range(8):
        if i==0:
            data1 = [0,0,0,0,0,0,0,1]
        else:
            data1 = data1[1:]+data1[:1]
        data2 = [0,0,0,0,0,0,0,0]
        tx[7-i].write(data1[7-i])
        sleep(0.001)
        data2[7-i] = rx[7-i].read()
        assert data1==data2,\
            'Sent {} != received {} at Pin {}.'.format(data1,data2,7-i)

@pytest.mark.run(order=20) 
@pytest.mark.skipif(not flag, reason="need Pmod cable connected to run")
def test_lshift0():
    """Test for left shifting the bit "0".
    
    The sender will send patterns with the bit "0" left shifted each time.
    
    """
    print('\nGenerating tests for left shifting a \"0\"...')
    global tx,rx
    
    for i in range(8):
        if i==0:
            data1 = [1,1,1,1,1,1,1,0]
        else:
            data1 = data1[1:]+data1[:1]
        data2 = [1,1,1,1,1,1,1,1]
        tx[7-i].write(data1[7-i])
        sleep(0.001)
        data2[7-i] = rx[7-i].read()
        assert data1==data2,\
            'Sent {} != received {} at Pin {}.'.format(data1,data2,7-i)

@pytest.mark.run(order=21) 
@pytest.mark.skipif(not flag, reason="need Pmod cable connected to run")
def test_random():
    """Test for random patterns.
    
    Testing software-generated pseudo-random numbers. Random 0/1's are 
    generated at each bit location. 8 bits (1 bit per pin) are sent out 
    in every iteration. This test may take a few seconds to finish.
    
    """
    print('\nGenerating 100 random tests...')
    global tx,rx
    
    for i in range(100):     
        data1=[0,0,0,0,0,0,0,0]
        data2=[1,1,1,1,1,1,1,1]
        for j in range(8):
            data1[j] = randint(0,1)
            tx[j].write(data1[j])
            sleep(0.001) 
            data2[j] = rx[j].read()
        assert data1==data2,\
             'Sent {} != received {} at Pin {}.'.format(data1,data2,j)
    
    del tx,rx
