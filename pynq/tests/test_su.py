#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import os
import pytest




@pytest.mark.run(order=1)
def test_superuser():
    """Test whether the user have the root privilege.
    
    Note
    ----
    To pass all of the pytests, need the root access.
    
    """
    assert os.geteuid() == 0, "Need ROOT access in order to run tests."


