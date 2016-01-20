"""Test module for cable loops"""


__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Yun Rock Qu"
__email__       = "yunq@xilinx.com"


from pyxi.tests import unittest
from pyxi.tests.random import rng

from pyxi.pmods import _iop
from pyxi.pmods.gpio import GPIO

class Test_0_Shift(unittest.TestCase):
    """
        TestCase for left/right shifting a bit.
    """
    def test_0_lshift1(self):
        print('\nGenerating tests for left shifting a \"1\"...')
        for i in range(0, 8):
            if i==0:
                data1 = [0,0,0,0,0,0,0,1]
            else:
                data1 = data1[1:]+data1[:1]
            data2 = [0,0,0,0,0,0,0,0]
            
            p1_o[7-i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                    _iop.IOPMM_XGPIO_DATA_OFFSET, data1[7-i])
            p2_o[7-i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                    _iop.IOPMM_XGPIO_DATA_OFFSET, data1[7-i])
            p3_o[7-i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                    _iop.IOPMM_XGPIO_DATA_OFFSET, data1[7-i])
            p4_o[7-i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                    _iop.IOPMM_XGPIO_DATA_OFFSET, data1[7-i])
                                    
            data2[7-i] = p1_i[7-i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 1.'.format(data1,data2))
            data2[7-i] = p2_i[7-i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 2.'.format(data1,data2))
            data2[7-i] = p3_i[7-i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 3.'.format(data1,data2))
            data2[7-i] = p4_i[7-i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 4.'.format(data1,data2))

                
    def test_1_lshift0(self):
        print('\nGenerating tests for left shifting a \"0\"...')
        for i in range(0, 8):
            if i==0:
                data1 = [1,1,1,1,1,1,1,0]
            else:
                data1 = data1[1:]+data1[:1]
            data2 = [1,1,1,1,1,1,1,1]
            
            p1_o[7-i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                    _iop.IOPMM_XGPIO_DATA_OFFSET, data1[7-i])
            p2_o[7-i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                    _iop.IOPMM_XGPIO_DATA_OFFSET, data1[7-i])
            p3_o[7-i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                    _iop.IOPMM_XGPIO_DATA_OFFSET, data1[7-i])
            p4_o[7-i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                    _iop.IOPMM_XGPIO_DATA_OFFSET, data1[7-i])
                                    
            data2[7-i] = p1_i[7-i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 1.'.format(data1,data2))
            data2[7-i] = p2_i[7-i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 2.'.format(data1,data2))
            data2[7-i] = p3_i[7-i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 3.'.format(data1,data2))
            data2[7-i] = p4_i[7-i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 4.'.format(data1,data2))
        
        
    def test_2_rshift1(self):
        print('\nGenerating tests for right shifting a \"1\"...')
        for i in range(0, 8):
            if i==0:
                data1 = [1,0,0,0,0,0,0,0]
            else:
                data1 = data1[-1:]+data1[:-1]
            data2 = [0,0,0,0,0,0,0,0]
            
            p1_o[i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                  _iop.IOPMM_XGPIO_DATA_OFFSET, data1[i])
            p2_o[i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                  _iop.IOPMM_XGPIO_DATA_OFFSET, data1[i])
            p3_o[i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                  _iop.IOPMM_XGPIO_DATA_OFFSET, data1[i])
            p4_o[i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                  _iop.IOPMM_XGPIO_DATA_OFFSET, data1[i])
            
            data2[i] = p1_i[i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                            _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 1.'.format(data1,data2))
            data2[i] = p2_i[i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                            _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 2.'.format(data1,data2))
            data2[i] = p3_i[i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                            _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 3.'.format(data1,data2))
            data2[i] = p4_i[i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                            _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 4.'.format(data1,data2))
        
        
    def test_3_rshift0(self):
        print('\nGenerating tests for right shifting a \"0\"...')
        for i in range(0, 8):
            if i==0:
                data1 = [0,1,1,1,1,1,1,1]
            else:
                data1 = data1[-1:]+data1[:-1]
            data2 = [1,1,1,1,1,1,1,1]
            
            p1_o[i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                  _iop.IOPMM_XGPIO_DATA_OFFSET, data1[i])
            p2_o[i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                  _iop.IOPMM_XGPIO_DATA_OFFSET, data1[i])
            p3_o[i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                  _iop.IOPMM_XGPIO_DATA_OFFSET, data1[i])
            p4_o[i].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                  _iop.IOPMM_XGPIO_DATA_OFFSET, data1[i])
                                  
            data2[i] = p1_i[i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                           _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 1.'.format(data1,data2))
            data2[i] = p2_i[i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                            _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 2.'.format(data1,data2))
            data2[i] = p3_i[i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                            _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(
                data1,data2,
                'Sent {} != received {} at PMOD 3.'.format(data1,data2))
            data2[i] = p4_i[i].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                            _iop.IOPMM_XGPIO_DATA_OFFSET)
            self.assertEqual(data1,data2,
                'Sent {} != received {} at PMOD 4.'.format(data1,data2))

                
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
            data0 = [0,0,0,0,0,0,0,0]
            data1 = [1,1,1,1,1,1,1,1]
            data2 = [1,1,1,1,1,1,1,1]
            data3 = [1,1,1,1,1,1,1,1]
            data4 = [1,1,1,1,1,1,1,1]
            
            for j in range (0, 8):
                data0[j] = rng()%2
                
                p1_o[j].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                      _iop.IOPMM_XGPIO_DATA_OFFSET, data0[j])
                p2_o[j].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                      _iop.IOPMM_XGPIO_DATA_OFFSET, data0[j])
                p3_o[j].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                      _iop.IOPMM_XGPIO_DATA_OFFSET, data0[j])
                p4_o[j].iop.write_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                      _iop.IOPMM_XGPIO_DATA_OFFSET, data0[j])
                                      
                data1[j] = p1_i[j].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
                data2[j] = p2_i[j].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
                data3[j] = p3_i[j].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
                data4[j] = p4_i[j].iop.read_cmd(_iop.IOPMM_GPIO_BASEADDR+
                                                _iop.IOPMM_XGPIO_DATA_OFFSET)
                                                
            self.assertEqual(
                data0,data1,
                'Sent {} != received {} at PMOD 1.'.format(data0,data1))
            self.assertEqual(
                data0,data2,
                'Sent {} != received {} at PMOD 2.'.format(data0,data2))
            self.assertEqual(
                data0,data3,
                'Sent {} != received {} at PMOD 3.'.format(data0,data3))
            self.assertEqual(
                data0,data4,
                'Sent {} != received {} at PMOD 4.'.format(data0,data4)) 
            
            
def test_gpio_internal():
    if not unittest.request_user_confirmation(
            'Testing PMOD GPIO internally?'):
        raise unittest.SkipTest()
        
    global p1_o,p2_o,p3_o,p4_o
    global p1_i,p2_i,p3_i,p4_i
        
    p1_o = [GPIO(1,k,_iop.IOCFG_XGPIO_OUTPUT) for k in range(0, 8)]
    p2_o = [GPIO(2,k,_iop.IOCFG_XGPIO_OUTPUT) for k in range(0, 8)]
    p3_o = [GPIO(3,k,_iop.IOCFG_XGPIO_OUTPUT) for k in range(0, 8)]
    p4_o = [GPIO(4,k,_iop.IOCFG_XGPIO_OUTPUT) for k in range(0, 8)]
    p1_i = [GPIO(1,k,_iop.IOCFG_XGPIO_INPUT) for k in range(0, 8)]
    p2_i = [GPIO(2,k,_iop.IOCFG_XGPIO_INPUT) for k in range(0, 8)]
    p3_i = [GPIO(3,k,_iop.IOCFG_XGPIO_INPUT) for k in range(0, 8)]
    p4_i = [GPIO(4,k,_iop.IOCFG_XGPIO_INPUT) for k in range(0, 8)]
     
    # starting tests
    unittest.main('pyxi.pmods.tests.test_gpio_internal')
       
    # cleanup active_iops
    from pyxi.pmods._iop import _flush_iops
    _flush_iops()


if __name__ == "__main__":
    test_gpio_internal()
