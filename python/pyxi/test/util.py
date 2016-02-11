"""Utilities for XPP pytest"""


__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"
        
 
import pytest

def user_answer_yes(text):
    answer = input(text + ' ([yes]/no)>>> ').lower()
    return answer == 'y' or answer == 'yes' or answer == ''
    
def user_answer_no(text):
    answer = input(text + ' (yes/[no])>>> ').lower()
    return answer == 'n' or answer == 'no' or answer == ''
    