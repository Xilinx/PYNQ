# Py(thon)xi(linx) Package

Pyxi is a python package developed by Xilinx to support micropython on Xilinx boards, such as Zybo. This package includes the necessary python modules, classes, and functions to control both onboard and offboard devices. A complete set of tests are provided as examples. There are also two hardware overlays included in this package.

Note: The libraries and APIs in the pyxi pacakge are *board-dependent*. The pyxi package in this folder only supports Zybo, while additional changes have to be made to support other boards.

The pyxi package is organized in the following way:

```
					        --------
              	        	| pyxi	|
                	         -------
                  	            |
     -----------------------------------------------------------------
    |	    	 |		       |		     |	           |		  |
 -------	  -------       -------       -------       -------   
| board |    | pmods |     | audio |     | video |     | tests |   __init__.py
 -------	  -------       -------       -------       -------   
    |	    	 |		       |		     |	           |
__init__.py  __init__.py   __init__.py  __init__.py     __init__.py
_gpios.py     _iop.py       _audio.py	 _video.py		random.py
button.py	   adc.py        audio.py	  hdmi.py       testsuite.py
led.py         als.py       -------		   vga.py		unittest.py
switch.py      dac.py      | tests |      -------	
utils.py      devmode.py    -------      | tests | 
 -------       dpot.py         |          -------
| tests |      gpio.py       .....			 |
 -------       led8.py					   .....
    |          oled.py
  .....        tmp2.py
     		   -------
  			  | tests | 
               -------
                  |
     			.....

```
There are 5 subpackages in this package:

1. **board** implements the modules for onboard devices, including LEDs, switches, and push buttons on Zybo. This subpackage is always supported regardless of the hardware overlay on Programmable Logic (PL).

2. **pmods** supports various PMODs to be connected to Zybo. This subpackage is fully supported on the PMOD overlay.

3. **audio** enables audio input and output on Zybo. This subpackage is supported on the audio/video overlay.

4. **video** enables HDMI input and VGA output on Zybo. This subpackage is supported on the audio/video overlay.

5. **tests** consists of necessary Python modules to support assertion tests.


To get more information, check the <a href="https://github.com/Xilinx/XilinxPythonProject/wiki" target="_blank"><b>Wiki</b></a> first. To report an issue, click <a href="https://github.com/Xilinx/XilinxPythonProject/issues" target="_blank"><b>Issues</b></a>.

## Usage
The pyxi package in the `prebuilt` folder is ready-to-use. For example, the following Python code
```python
from pyxi.board import LED
led = LED(3)
led.on()
```
will light on LED 3 (LD3) on Zybo. More information can be found on <a href="https://github.com/Xilinx/XilinxPythonProject/wiki/6.-Libraries-and-APIs" target="_blank"><b>Libraries and APIs</b></a>.
## Building
When the `sdcard` folder is built, the `Makefile` in the main folder will also put the necessary `.bin` files into the `pmod` folder. These `.bin` files are required by the microblazes on PL to drive various offboard devices. Note the `.bin` files are not included in `zybo/py/pyxi/pmods/`, but they will be included in `sdcard/pyxi/pmods/` after users run make to build the project.

The `Makefile` also puts the two overlays (PMOD overlay, and video/audio overlay) into the `sdcard` directory. For more information, check the <a href="https://github.com/Xilinx/XilinxPythonProject/wiki/6.-Libraries-and-APIs" target="_blank"><b>Libraries and APIs</b></a>.

## Tests
To run tests implemented in the pyxi package:
```python
from pyxi.tests import *
run_tests()
```
The test suite will guide users through all the tests. More information can be found on <a href="https://github.com/Xilinx/XilinxPythonProject/wiki/7.-Test" target="_blank"><b>Tests</b></a>.
