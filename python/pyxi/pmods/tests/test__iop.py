"""Test module for _iop.py"""


__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


import pytest
from pyxi.pmods._iop import request_iop
from pyxi.pmods._iop import _flush_iops

@pytest.mark.run(order=10)
def test_request_iop_conflicting():
    """TestCase for the IOP class and the request_iop().
    Creates multiple IOP instances on the same fixed ID. Tests whether 
    request_iop() correctly raises a LookupError exception.
    """
    _flush_iops()
    fixed_id = 1
    request_iop(fixed_id,'adc.bin')
    pytest.raises(LookupError, request_iop, fixed_id, 'dac.bin')
    _flush_iops()

@pytest.mark.run(order=11)
def test_request_iop_sameobject():
    """Tests whether case 3 of request_iop() is correctly handled.
    """
    _flush_iops()
    fixed_id = 2
    request_iop(fixed_id)
    exception_raised = False
    try:
        request_iop(fixed_id)
    except LookupError:
        exception_raised = True
    assert not exception_raised, 'request_iop() not working properly'
    _flush_iops()

@pytest.mark.run(order=12)
def test_request_iop_force():
    """Creates multiple IOP instances on the same fixed ID with the *force* 
    flag active. Tests whether request_iop() behaves correctly, silently 
    overwriting the old IOP instance.
    """
    _flush_iops()
    exception_raised = False
    fixed_id = 1
    try:
        request_iop(fixed_id, force=True)
        request_iop(fixed_id, force=True)
    except LookupError:
        exception_raised = True
    assert not exception_raised, 'flag *force* not working properly'
    _flush_iops()
