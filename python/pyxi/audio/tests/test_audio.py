
__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__maintainer__  = "Yun Rock Qu"
__email__       = "yunq@xilinx.com"


import pytest
from pyxi.audio import LineIn, Headphone
from pyxi.test.util import user_answer_yes

flag = user_answer_yes("\nBoth LineIn and Headphone (HPH) jacks connected?")
    
@pytest.mark.run(order=34)  
@pytest.mark.skipif(not flag, reason="need both LineIn and HPH attached")        
def test_LineIn():
    """ Tests whether the __call__() method correctly returns
        The returned value should be a list of two integers.
    """
    linein = LineIn()
    assert type(linein()) is list, 'returned value is not a list'
    assert len(linein())==2, 'returned list does not have 2 elements'
    assert type(linein()[0]) is int, '1st element in the list is not int'
    assert type(linein()[1]) is int, '2nd element in the list is not int'

@pytest.mark.run(order=35)  
@pytest.mark.skipif(not flag, reason="need both LineIn and HPH attached")  
def test_audio_loop():
    """ Tests whether the two objects works properly using their __call__() 
        methods, asking for user confirmation.
    """
    headphone = Headphone()
    linein = LineIn()
    input("\nMake sure LineIn is receiveing audio. Then hit enter...")
    for i in range(100000):
        headphone(linein())
    assert user_answer_yes("Heard audio on the headphone (HPH) port?"),\
        'audio loop is not working'

@pytest.mark.run(order=36)  
@pytest.mark.skipif(not flag, reason="need both LineIn and HPH attached")  
def test_audio_mute():
    """ Tests is_muted() and toggle_mute() methods.
    """ 
    headphone = Headphone()
    is_muted = headphone.controller.is_muted() 
    headphone.controller.toggle_mute()
    assert not is_muted is headphone.controller.is_muted(), \
        'audio is not properly muted'

