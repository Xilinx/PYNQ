"""This is a pseudo-random number generator.

Usage
----------
1.  This file uses the pyboard embedded functions. Further information can be 
found at: https://micropython.org/doc/module/pyb/ 
2.  pyb.millis() returns the number of milliseconds since the board was last 
reset. Note that this may return a negative number. 
This allows you to always do: 
    start = pyb.millis() ...
    do some operation... 
    elapsed = pyb.millis() - start
As long as the time of your operation is less than 24 days, you'll always get 
the right answer and not have to worry about whether pyb.millis() wraps around.
3.  Using pyb.millis() as the seed, the function rng() returns a number between
0 ~ 8388593. Since the seed is based on the elapsed time, the returned number 
is pseudo-random.
4.  To generate a pseudo-random integer number between 0 ~ X, do: rng()%X
5.  The function rand() returns a pseudo-random fraction number between 0 ~ 1.
"""

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__ 	= "Yun Rock Qu"
__email__ 		= "yunq@xilinx.com"
import pyb

rand_seed = pyb.millis()
def rng():
    """ Return a pseudo-random number between 0 to 8388593 """ 
    global rand_seed
    # for these choice of numbers, see P L'Ecuyer, 
    # "Tables of linear congruential generators of different sizes and 
    #  good lattice structure"
    rand_seed = (rand_seed * 653276) % 8388593
    return rand_seed
    
def rand():
    return rng()/8388593