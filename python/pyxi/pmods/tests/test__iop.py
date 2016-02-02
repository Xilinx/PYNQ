"""Test module for _iop.py"""


__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest
from pyxi.pmods._iop import request_iop

class TestIOP(unittest.TestCase):
    """TestCase for the IOP class and the request_iop()."""

    def test_0_request_iop_conflicting(self):
        """Creates multiple IOP instances on the same fixed ID. Tests whether 
        request_iop() correctly raises a LookupError exception.
        """
        fixed_id = 1
        request_iop(fixed_id,'adc.bin')
        self.assertRaises(LookupError, request_iop, fixed_id, 'dac.bin')

    def test_1_request_iop_sameobject(self):
        """Tests whether case 3 of request_iop() is correctly handled.
        """
        fixed_id = 2
        request_iop(fixed_id)
        exception_raised = False
        try:
            request_iop(fixed_id)
        except LookupError:
            exception_raised = True
        self.assertFalse(exception_raised)

    def test_2_request_iop_force(self):
        """Creates multiple IOP instances on the same fixed ID with the *force* 
        flag active. Tests whether request_iop() behaves correctly, silently 
        overwriting the old IOP instance.
        """
        exception_raised = False
        fixed_id = 1
        try:
            request_iop(fixed_id, force=True)
            request_iop(fixed_id, force=True)
        except LookupError:
            exception_raised = True
        self.assertFalse(exception_raised)


def test__iop():
    unittest.main(__name__) 
    
    # cleanup active_iops
    from pyxi.pmods._iop import _flush_iops
    _flush_iops()

if __name__ == "__main__":
    test__iop()
