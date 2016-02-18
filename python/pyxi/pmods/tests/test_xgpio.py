"""Test module for cable loops"""


__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Yun Rock Qu"
__email__       = "yunq@xilinx.com"


import pytest
from random import randint
from time import sleep
from pyxi.pmods import _iop
from pyxi.pmods._iop import _flush_iops
from pyxi.pmods.xgpio import XGPIO
from pyxi.test.util import user_answer_yes

flag = user_answer_yes("\nTwo PMOD interfaces connected by a cable?")
if flag:
    global TX_PORT,RX_PORT
    TX_PORT = int(input("Type in the PMOD ID of the sender (1 ~ 4): "))
    RX_PORT = int(input("Type in the PMOD ID of the receiver (1 ~ 4): "))
    global DelaySec 
    DelaySec = 0.005
                               
@pytest.mark.run(order=27) 
@pytest.mark.skipif(not flag, reason="need PMOD interfaces connected to run")
def test_xgpio_cable():
    print('\nTesting PMOD XGPIO loop ...')
        
    if TX_PORT==RX_PORT:
        raise ValueError("The sender port cannot be the receiver port")
    else:
        global tx,rx
        tx = [XGPIO(TX_PORT,k,_iop.IOCFG_XGPIO_OUTPUT) for k in range(8)]
        rx = [XGPIO(RX_PORT,k,_iop.IOCFG_XGPIO_INPUT) for k in range(8)]
        
        # Identify the cable type: straight / loop-back
        # Upper row: {vdd,gnd,4,5,6,7}
        # Lower row: {vdd,gnd,0,1,2,3}
        # Default cable type is straight
        tx[0].write(0)
        tx[3].write(0)
        tx[4].write(1)
        tx[7].write(1)
        if (rx[0].read()==0 and rx[3].read()==0 and 
            rx[4].read()==1 and rx[7].read()==1):
            print("Using a loop-back cable...")
        elif (rx[0].read()==1 and rx[3].read()==1 and 
            rx[4].read()==0 and rx[7].read()==0):
            print("Using a straight cable...")
            for i in range(8):
                rx[i].setCable(_iop.XGPIO_CABLE_STRAIGHT)
        else:
            raise AssertionError("Cable unrecognizable.")

@pytest.mark.run(order=28) 
@pytest.mark.skipif(not flag, reason="need PMOD interfaces connected to run")
def test_rshift1():
    """
        TestCase for left/right shifting a bit.
    """
    print('\nGenerating tests for right shifting a \"1\"...')
    for i in range(0, 8):
        if i==0:
            data1 = [1,0,0,0,0,0,0,0]
        else:
            data1 = data1[-1:]+data1[:-1]
        data2 = [0,0,0,0,0,0,0,0]
        tx[i].write(data1[i])    
        sleep(DelaySec)
        data2[i] = rx[i].read()
        assert data1==data2,\
            'Sent {} != received {} at Pin {}.'.format(data1,data2,i)

@pytest.mark.run(order=29) 
@pytest.mark.skipif(not flag, reason="need PMOD interfaces connected to run") 
def test_rshift0():
    print('\nGenerating tests for right shifting a \"0\"...')
    for i in range(0, 8):
        if i==0:
            data1 = [0,1,1,1,1,1,1,1]
        else:
            data1 = data1[-1:]+data1[:-1]
        data2 = [1,1,1,1,1,1,1,1]
        tx[i].write(data1[i])    
        sleep(DelaySec)
        data2[i] = rx[i].read()
        assert data1==data2,\
            'Sent {} != received {} at Pin {}.'.format(data1,data2,i) 

@pytest.mark.run(order=30) 
@pytest.mark.skipif(not flag, reason="need PMOD interfaces connected to run")
def test_lshift1():
    print('\nGenerating tests for left shifting a \"1\"...')
    for i in range(0, 8):
        if i==0:
            data1 = [0,0,0,0,0,0,0,1]
        else:
            data1 = data1[1:]+data1[:1]
        data2 = [0,0,0,0,0,0,0,0]
        tx[7-i].write(data1[7-i])    
        sleep(DelaySec)
        data2[7-i] = rx[7-i].read()
        assert data1==data2,\
            'Sent {} != received {} at Pin {}.'.format(data1,data2,7-i)

@pytest.mark.run(order=31) 
@pytest.mark.skipif(not flag, reason="need PMOD interfaces connected to run")
def test_lshift0():
    print('\nGenerating tests for left shifting a \"0\"...')
    for i in range(0, 8):
        if i==0:
            data1 = [1,1,1,1,1,1,1,0]
        else:
            data1 = data1[1:]+data1[:1]
        data2 = [1,1,1,1,1,1,1,1]
        tx[7-i].write(data1[7-i])    
        sleep(DelaySec)
        data2[7-i] = rx[7-i].read()
        assert data1==data2,\
            'Sent {} != received {} at Pin {}.'.format(data1,data2,7-i)

@pytest.mark.run(order=32) 
@pytest.mark.skipif(not flag, reason="need PMOD interfaces connected to run")
def test_random():
    """
        Testing software-generated pseudo-random numbers.
        Random 0/1's are generated at each bit location
        8 bits (pins) are sent out in every iteration
    """
    print('\nGenerating 100 random tests...')
    for i in range(0, 100):     
        data1=[0,0,0,0,0,0,0,0]
        data2=[1,1,1,1,1,1,1,1]
        for j in range (0, 8):
            data1[j] = randint(0,1)
            tx[j].write(data1[j])               
            sleep(DelaySec) 
            data2[j] = rx[j].read()
        assert data1==data2,\
             'Sent {} != received {} at Pin {}.'.format(data1,data2,j)
    _flush_iops()
