Creating a driver or writing code for the IOP
==============================================

IOPs contain a soft [`Xilinx MicroBlaze processor <https://en.wikipedia.org/wiki/MicroBlaze>`_, peripherals (Timer, IIC, SPI, GPIO) a configurable switch and an interface port to a Pmod. An IOP can be used as a flexiblecontroller for different types of peripherals, or code can be off-loaded from the main ARM CPUs to run on the IOP. For peripherals, the intention is that any low-level control, or real-time requirements can be met by the IOP and offloaded from the main processor which is running Pynq. 

The IOP switch can be configured to route signals between the Pmod interface, and the available peripherals. In this way, an IIC, SPI, or custom peripheral can be plugged into the same port using the same Overlay. i.e. to support a different peripheral, there is no need to redesign the FPGA fabric. 

IOPs can also be used standalone to offload some processing from the main processer. The IOPs are running at 100MHz compared to the Dual Core ARM A9 running at 650MHz, which should be taken into account when offloading applications.

Code for the MicroBlaze processor inside the IOP can be written in C or C++. 


Compiling code for the IOP
^^^^^^^^^^^^^^^^^^^^^^^^^^

The Xilinx SDK (Software Development Kit) can be installed on a host computer and used to create a software project to build code for the MicroBlaze. This is the standard way of developing software for a MicroBlaze.

All C code for the IOPs can be found in [the Pynq GitHub repository](https://github.com/Xilinx/Pynq/tree/master/zybo/sdk). 

All code currently available is part of a driver for a peripheral. 

Create SDK Project
------------------

To create a project in SDK, the .hdf hardware definition file for the *OVERLAY* is required. 

In SDK, create a *New Hardware Platfrom Specification* project, and link it to the .hdf file. Then, import the BSP from [`the Pynq GitHub repository <https://github.com/Xilinx/Pynq/tree/master/zybo/sdk>`_. A new Application can then be created.

Run makefile
------------

The SDK projects in the GitHub contain make files. If SDK is installed, the IOP code can be compiled by running make from:

    Pynq\\zybo\\sdk\\

This will built all the projects set in MBBINS at the top of the makefile

Individual projects can be build by navigating to the <project directory>/Debug and running make

Copy existing project
---------------------

Rather than create your own project, you can use an existing project as a starting point for your code.

To do this, copy the project directory and rename it. 

Change the .c file in src/ to your c code. 

The executable that is generated will have the same name as your c code. e.g. if you c code is my_peripheral.c, the generated .elf will be my_peripheral.elf .

You will need to change and references to the old project name to your new project name in <project directory>\\Debug\\makefile and <project directory>\\Debug\\src\\subdir.mk

If you want your project to build as part of the Pynq build, you should also append the bin name of your project to the MBBINS variable at the top of the makefile in

    Pynq\zybo\sdk

Compile on the board
--------------------

You can also write C code, and compile it directly on the Zybo board. The compiler for MicroBlaze is available in xtools in the home area. 

Binary file
-----------

Compiling code results in an .elf executable file. A bin file is required to download to the IOP memory. 

A bin file can be generated from an elf by running:

    mb-objcopy -O binary input_file.elf outputfile.bin

IOP Memory
^^^^^^^^^^

The IOP has a shared memory space with the ARM A9's. This allows an executable to be written from the A9 (the Pynq environment) to the IOP. The IOP can also be reset from Pynq, allowing the IOP to start executing the new program. The shared memory is also used to communicate between the Zynq processors (where Pynq is running) and the IOP.

Memory map
----------

Pynq and the application running on the IOP can write to anywhere in the shared memory space, but it is recommended to follow the convention for communication between the two processors.

* MAILBOX_SIZE   = 0x1000
* MAILBOX_OFFSET = 0x7000
* MAILBOX_PY2IOP_CMD_OFFSET  = 0xffc
* MAILBOX_PY2IOP_ADDR_OFFSET = 0xff8
* MAILBOX_PY2IOP_DATA_OFFSET = 0xf00

i.e. A command will be written from Pynq to the address 0xffc

The IOP must read this location, decode the command and carry out the required operation.

If returning a single value (i.e. .read() ) it should be written to location 0xf00
The Pynq application should read the value back from here. 

There is also a larger data area, which could be used for example, to log data. 

IOP Switch
^^^^^^^^^^

There are 8 data pins on a Pmod port, that can be connected to any of 16 internal signals. 

Switch mappings used for IOP Switch configuration:

* #define GPIO_0 0x0
* #define GPIO_1 0x1
* #define GPIO_2 0x2
* #define GPIO_3 0x3
* #define GPIO_4 0x4
* #define GPIO_5 0x5
* #define GPIO_6 0x6
* #define GPIO_7 0x7
* #define SCL    0x8
* #define SDA    0x9
* #define SPICLK 0xa
* #define MISO   0xb
* #define MOSI   0xc
* #define SS     0xd
* #define BLANK  0xe

If two or more pins are connected to the same signal, the pins are OR'd together. 

Each pin can be configured by writing a 4 bit value to the corresponding place in the IOP Switch configuration register. 

The IOP Switch can be (re)configured by writing a 32 bit value (8x 4 bits) to the IOP Switch configuration register (offset 0x0).

The IOP Address is:

    IOPMM_SWITCHCONFIG_BASEADDR    = 0x44A00000

Pin 0 is the least significant 4 bits, and Pin 7 is the Most significant 4 bits. 

For example, to connect the physical pins GPIO 0-7 to the internal GPIO_0 - GPIO_7, the value 0x01234567 should be written to the IOP Switch configuration register.

Before configuring the switch, it should first be isolated. To do this, write '0' to the MSB of the SWITCH_BASEADDR+0x4 register. To reconnect it, write '1' to the MSB.

e.g.

    Xil_Out32(SWITCH_BASEADDR+0x4,0x00000000); // isolate switch by writing 0 to bit 31

    Xil_Out32(SWITCH_BASEADDR, switchConfigValue); // Set pin configuration

    Xil_Out32(SWITCH_BASEADDR+0x4,0x80000000); // Re-enable Swtch by writing 1 to bit 31
   

For the IOP, the following function, part of the BSP library can be used to configure the switch. 

void configureSwitch(char pin1, char pin2, char pin3, char pin4, char pin5, char pin6, char pin7, char pin8);

From Python all the constants and addresses for the IOP can be found in:

    Pynq\\python\\pmods\\pmod_const.py

For the IOP, all constants and addresses can be found in the pmod.h and pmod.c code included int he BSP:

Pynq\\zybo\\sdk\\standalone_bsp_mb1\\mb_1_microblaze_1\\libsrc\pmodiop_v0_1\\src

pmod.h
^^^^^^^^^^^^^^^^^^^^^
pmod.h contains an API and definitions that can be used to write code for an IOP.

Pynq\\zybo\\sdk\\standalone_bsp_mb1\\mb_1_microblaze_1\\libsrc\pmodiop_v0_1\\src

Selecting which IOP to run the application
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

All IOPs are identical, and while they exist at a different place in the ARM A9 address space, from the IOP perspective, the address space for each IOP is identical.

e.g.The IOPs exist in these locations in the ARM A9 address space:
IOP 1 
IOP 2
IOP 3 
IOP 4

However, for each IOP, the MicroBlaze sees only its own address space. i.e. Timer, IOP Switch, IIC, and SPI have the same addresses in each IOP address space. 

This means, C code written for one IOP can run on any of the other IOPs


Example
^^^^^^^

Examine C Code
--------------

Taking PMOD ALS as an example, first open the pmod.c file:

    Pynq/zybo/sdk/pmodals/src/pmodals.c

Note that the pmod.h header file is included.

Some MAILBOX commands are defined by the user. These values can be chosen to be any value, but must correspond with the Python part of the driver. 

By convention, 0x0 is reserved for no command/idle/acknowledge, and operations for the IOP can start at command 0x1.

Note the user defined function get_sample()

The ALS peripheral has as SPI interface. The SPI API is included in pmod.h and spi_transfer() is called here.

In main() notice configureSwitch() is called to initialize the switch with a static configuration. This means, to use this code with a different pin configuration, the c code must be changed and recompiled. 

Next, the while(1) loop is enter. In this loop the IOP continually checks the MAILBOX_CMD_ADDR for a non-zero command. Once a command is received from Python, the command is decoded, and the functionality is executed. 

Taking the first case, reading a value:

    case READ_SINGLE_VALUE:	  

    MAILBOX_DATA(0) = get_sample();

    MAILBOX_CMD_ADDR = 0x0;

get_sample() is called and a value returned to the first position (0) of the MAILBOX_DATA.

MAILBOX_CMD_ADDR is reset to 0x0 to acknowledge to Python the operation is complete and data is available in the mailbox. 

Examine Python Code
-------------------

Next examine the Python code. 

First the _iop, pmod_const and MMIO are imported. These are all constituents of an IOP.

from . import _iop
from . import pmod_const
from pynq import MMIO

IOP module is imported, along with the MMIO and Overlay

The .bin for the IOP is declared. This is the application executable, and will be loaded into the IOP instruction memory. 

ALS_PROGRAM = "als.bin"

The ALS class is defined:

class ALS(object):

The initialization function for the module requires a pmod id/IOP number.

    def __init__(self, pmod_id):

This will be used to load the application code into the appropriate IOP. The __init__ is called when a module is instantiated. e.g. from Python:

    als = ALS(1)

_iop.request_iop() instantiates an instance of the _iop on the specified pmod_id and loads the .bin file (ALS_PROGRAM) into the instruction memory of the appropriate IOP

    self.iop = _iop.request_iop(pmod_id, ALS_PROGRAM)

MMIO instantiates an MMIO which is used to read and write from the shared memory

    self.mmio = self.iop.mmio

log_interval_ms is a variable used later in the program
    self.log_interval_ms = 1000

iop.start() resets the IOP. After this, the IOP will start running the new application.    

    self.iop.start()

Reading a Value
---------------

The read() function 

    def read(self)

mmio.write() writes a command to the COMMAND area in the shared memory.

        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 3)     

When the IOP is finished, it will write 0x0 to the command area. The code now uses mmio.read() to check if the command is still 3, and if it is, it loops.  
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 3)
            pass
Once the command is no longer 3, i.e. the acknowledge has been received, the result is read from the DATA area of the shared memory MAILBOX_OFFSET. Using mmio.read()

        return self.mmio.read(pmod_const.MAILBOX_OFFSET)

Notice the pmod_const values are used in these function calls. 
