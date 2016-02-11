"""Utilities for XPP pytest"""


__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"
        
 
import pytest
import os
    
    
@pytest.mark.run(order=1)
def test_superuser():
    assert os.geteuid()==0, "Need ROOT access in order to run tests" 