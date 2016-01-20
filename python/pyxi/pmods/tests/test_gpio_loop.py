"""Test module for cable loops"""


__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Yun Rock Qu"
__email__       = "yunq@xilinx.com"


from pyxi.tests import unittest
from pyxi.tests.random import rng
from pyxi.board.utils import delay

from pyxi.pmods import _iop
from pyxi.pmods.gpio import GPIO

class Test_0_Shift(unittest.TestCase):
    """
        TestCase for left/right shifting a bit.
    """
    def test_0_rshift1(self):
        print('\nGenerating tests for right shifting a \"1\"...')
        for i in range(0, 8):
            if i==0:
                data1 = [1,0,0,0,0,0,0,0]
            else:
                data1 = data1[-1:]+data1[:-1]
            data2 = [0,0,0,0,0,0,0,0]
            tx[i].write(data1[i])    
            delay(DelaySec)
            data2[i] = rx[i].read()
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at Pin {}.'.format(data1,data2,i))

    def test_1_rshift0(self):
        print('\nGenerating tests for right shifting a \"0\"...')
        for i in range(0, 8):
            if i==0:
                data1 = [0,1,1,1,1,1,1,1]
            else:
                data1 = data1[-1:]+data1[:-1]
            data2 = [1,1,1,1,1,1,1,1]
            tx[i].write(data1[i])    
            delay(DelaySec)
            data2[i] = rx[i].read()
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at Pin {}.'.format(data1,data2,i)) 
        
    def test_2_lshift1(self):
        print('\nGenerating tests for left shifting a \"1\"...')
        for i in range(0, 8):
            if i==0:
                data1 = [0,0,0,0,0,0,0,1]
            else:
                data1 = data1[1:]+data1[:1]
            data2 = [0,0,0,0,0,0,0,0]
            tx[7-i].write(data1[7-i])    
            delay(DelaySec)
            data2[7-i] = rx[7-i].read()
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at Pin {}.'.format(data1,data2,7-i))
        
    def test_3_lshift0(self):
        print('\nGenerating tests for left shifting a \"0\"...')
        for i in range(0, 8):
            if i==0:
                data1 = [1,1,1,1,1,1,1,0]
            else:
                data1 = data1[1:]+data1[:1]
            data2 = [1,1,1,1,1,1,1,1]
            tx[7-i].write(data1[7-i])    
            delay(DelaySec)
            data2[7-i] = rx[7-i].read()
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at Pin {}.'.format(data1,data2,7-i))

class Test_1_Random(unittest.TestCase):
    """
        TestCase for random data.
    """
    def test_random(self):
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
                data1[j] = rng()%2
                tx[j].write(data1[j])               
                delay(DelaySec) 
                data2[j] = rx[j].read()
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at Pin {}.'.format(data1,data2,j))
               
               
def test_gpio_loop():
    print('Testing PMOD GPIO loop ...')
    if not unittest.request_user_confirmation(
            'Two PMOD interfaces connected by a cable?'):
        raise unittest.SkipTest()
   
    global DelaySec 
    DelaySec = 0.01
    
    TX_PORT = int(input("Type in the PMOD ID of the sender (1 ~ 4): "))
    RX_PORT = int(input("Type in the PMOD ID of the receiver (1 ~ 4): "))
    
    if TX_PORT==RX_PORT:
        print('The sender port cannot be the receiver port.')
        # users should do GPIO internal tests instead in this case
        raise unittest.SkipTest()
    else:
        global tx,rx
        tx = [GPIO(TX_PORT,k,_iop.IOCFG_XGPIO_OUTPUT) for k in range(0, 8)]
        rx = [GPIO(RX_PORT,k,_iop.IOCFG_XGPIO_INPUT) for k in range(0, 8)]
        
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
            for i in range(0, 8):
                rx[i].setCable(_iop.GPIO_CABLE_STRAIGHT)
        else:
            print("Cable unrecognizable.")
            raise unittest.SkipTest()
        
        # starting tests
        unittest.main('pyxi.pmods.tests.test_gpio_loop')
        
        # cleanup active_iops
        from pyxi.pmods._iop import _flush_iops
        _flush_iops()


if __name__ == "__main__":
    test_gpio_loop()
