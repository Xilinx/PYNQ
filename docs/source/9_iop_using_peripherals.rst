*******************************************************
IO Processors: Using peripherals in your applications
*******************************************************

.. contents:: Table of Contents
   :depth: 2

Pmod IOP driver
=====================

You can find the driver for the Pmod IOP switch here:

:: 
   
   <GitHub Repository>/Pynq-Z1/vivado/ip/pmod_io_switch_1.0/  \
   drivers/pmod_io_switch_v1_0/src/

The ``pmod_io_switch.h`` includes the API for the configuration switch and predefined constants that can be used to connect pins.
   
``pmod.h`` and ``pmod.c`` are also part of the Pmod IO switch driver, and contain an API, addresses, and constant definitions that can be used to write code for an IOP.

This code is automatically compiled into the Board Support Package (BSP). 

To use these files in an IOP application, include the header file(s):
   
.. code-block:: c

   #include "pmod.h"
   #include "pmod_io_switch.h"

Any application that uses the Pmod driver should also call pmod_init() at the beginning of the application. 

From Python all the constants and addresses for the IOP can be found in:

    ``<GitHub Repository>/python/pynq/iop/iop_const.py``
    
   
   
Controlling the Pmod IOP Switch
=================================


There are 8 data pins on a Pmod port, that can be connected to any of 16 internal peripheral pins (8x GPIO, 2x SPI, 4x IIC, 2x Timer). This means the configuration switch for the Pmod has 8 connections to make to the data pins. 

Each pin can be configured by writing a 4 bit value to the corresponding place in the IOP Switch configuration register. the first nibble (4-bits) configures the first pin, the second nible the second pin and so on. 

The following function, part of the provided pmod_io_switch_v1_0 driver (``pmod.h``) can be used to configure the switch from an IOP application. 

.. code-block:: c

   void config_pmod_switch(char pin0, char pin1, char pin2, char pin3, char pin4, \
       char pin5, char pin6, char pin7);

While each parameter is a "char" only the lower 4-bits are used to configure each pin.

Switch mappings used for IOP Switch configuration:

========  ======= 
 Pin      Value  
========  =======
 GPIO_0   0x0  
 GPIO_1   0x1  
 GPIO_2   0x2  
 GPIO_3   0x3  
 GPIO_4   0x4  
 GPIO_5   0x5  
 GPIO_6   0x6  
 GPIO_7   0x7  
 SCL      0x8  
 SDA      0x9  
 SPICLK   0xa  
 MISO     0xb  
 MOSI     0xc  
 SS       0xd  
 PWM      0xe
 TIMER    0xf
========  =======

Example
---------

.. code-block:: c

   config_pmod_switch(SS,MOSI,GPIO_2,SPICLK,GPIO_4,GPIO_5,GPIO_6,GPIO_7);
   
This would connect a SPI interface:

* Pin 0: SS
* Pin 1: MOSI
* Pin 2: GPIO_2
* Pin 3: SPICLK
* Pin 4: GPIO_4
* Pin 5: GPIO_5
* Pin 6: GPIO_6
* Pin 7: GPIO_7

Note that if two or more pins are connected to the same signal, the pins are OR'd together internally. 


.. code-block:: c

   config_pmod_switch(GPIO_1,GPIO_1,GPIO_1,GPIO_1,GPIO_1,GPIO_1,GPIO_1,GPIO_1);
   
This is not recommended and should not be done unintentionally. 

IOP Application Example
==========================


Taking Pmod ALS as an example IOP driver (used to control the PMOD light sensor):

``<GitHub Repository>/Pynq-Z1/sdk/pmod_als/src/pmod_als.c``


First note that the ``pmod.h`` header file is included.

.. code-block:: c

   #include "pmod.h"
   
Some *COMMANDS* are defined. These values can be chosen to be any value. The corresponding Python code will send the appropriate command values to control the IOP application. 

By convention, 0x0 is reserved for no command/idle/acknowledge, and IOP commands can be any non-zero value.

   
.. code-block:: c

   // MAILBOX_WRITE_CMD
   #define READ_SINGLE_VALUE 0x3
   #define READ_AND_LOG      0x7
   // Log constants
   #define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
   #define LOG_ITEM_SIZE sizeof(u32)
   #define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)


The ALS peripheral has as SPI interface. The user defined function get_sample()  calls an SPI function *spi_transfer()*, defined in pmod.h, to read data from the device.  

  
.. code-block:: c

   u32 get_sample(){
      /* 
      ALS data is 8-bit in the middle of 16-bit stream. 
      Two bytes need to be read, and data extracted.
      */
      u8 raw_data[2];
      spi_transfer(SPI_BASEADDR, 2, raw_data, NULL);
      //  return ( ((raw_data[0] & 0xf0) >> 4) + ((raw_data[1] & 0x0f) << 4) );
      return ( ((raw_data[1] & 0xf0) >> 4) + ((raw_data[0] & 0x0f) << 4) );
   }

In ``main()`` notice ``config_pmod_switch()`` is called to initialize the switch with a static configuration. This application does not allow the switch configuration to be modified from Python. This means that if you want to use this code with a different pin configuration, the C code must be modified and recompiled. 
   
.. code-block:: c

   int main(void)
   {
      int cmd;
      u16 als_data;
      u32 delay;

      pmod_init(0,1);
      config_pmod_switch(SS, GPIO_1, MISO, SPICLK, \
                         GPIO_4, GPIO_5, GPIO_6, GPIO_7);
      // to initialize the device
      get_sample();

      
Next, the ``while(1)`` loop continually checks the ``MAILBOX_CMD_ADDR`` for a non-zero command. Once a command is received from Python, the command is decoded, and executed. 

.. code-block:: c

      // Run application
      while(1){

         // wait and store valid command
         while((MAILBOX_CMD_ADDR & 0x01)==0);
         cmd = MAILBOX_CMD_ADDR;


Taking the first case, reading a single value; ``get_sample()`` is called and a value returned to the first position (0) of the ``MAILBOX_DATA``. 

``MAILBOX_CMD_ADDR`` is reset to zero to acknowledge to the ARM processor that the operation is complete and data is available in the mailbox. 


.. code-block:: c
         
         switch(cmd){
            case READ_SINGLE_VALUE:
            // write out reading, reset mailbox
            MAILBOX_DATA(0) = get_sample();
            MAILBOX_CMD_ADDR = 0x0;
            break;

Remaining code:

 .. code-block:: c           
            
            case READ_AND_LOG:
            // initialize logging variables, reset cmd
            cb_init(&pmod_log, LOG_BASE_ADDRESS, LOG_CAPACITY, LOG_ITEM_SIZE);
            delay = MAILBOX_DATA(1);
            MAILBOX_CMD_ADDR = 0x0; 

               do{
                  als_data = get_sample();
                  cb_push_back(&pmod_log, &als_data);
                  delay_ms(delay);
               } while((MAILBOX_CMD_ADDR & 0x1)== 0);

               break;

            default:
               // reset command
               MAILBOX_CMD_ADDR = 0x0;
               break;
         }
      }
      return(0);
   }



Examining the Python Code
--------------------------

With the IOP Driver written, the Python class can be built that will communicate with that IOP. 
 
``<GitHub Repository>/python/pynq/iop/pmod_als.py``
  
First the MMIO, request_iop, iop_const, PMODA and PMODB are imported. 

.. code-block:: python

   import time
   from pynq import MMIO
   from pynq.iop import request_iop
   from pynq.iop import iop_const
   from pynq.iop import PMODA
   from pynq.iop import PMODB

   ALS_PROGRAM = "pmod_als.bin"

The MicroBlaze binary for the IOP is also declared. This is the application executable, and will be loaded into the IOP instruction memory. 

The ALS class and an initialization method are defined:

.. code-block:: python

   class Pmod_ALS(object):
      def __init__(self, if_id):

The initialization function for the module requires an IOP index. For Grove peripherals and the StickIt connector, the StickIt port number can also be used for initialization.  The ``__init__`` is called when a module is instantiated. e.g. from Python:

.. code-block:: python

    from pynq.pmods import Pmod_ALS
    als = Pmod_ALS(PMODB)

Looking further into the initialization method, the ``_iop.request_iop()`` call instantiates an instance of an IOP on the specified pmod_id and loads the MicroBlaze executable (ALS_PROGRAM) into the instruction memory of the appropriate MicroBlaze.

.. code-block:: python

   self.iop = request_iop(if_id, PMOD_ALS_PROGRAM)

An MMIO class is also instantiated to enable read and write to the shared memory.  

.. code-block:: python

    self.mmio = self.iop.mmio

Finally, the iop.start() call pulls the IOP out of reset. After this, the IOP will be running the als.bin executable.    

.. code-block:: python

    self.iop.start()

Example of Python Class Runtime Methods
-------------------------------------------

The read method in the Pmod_ALS class will simply read an ALS sample and return that value to the caller.  The following steps demonstrate a Python to MicroBlaze read transaction specfic to the ALS class.

.. code-block:: python

    def read(self):

First, the command is written to the MicroBlaze shared memory using mmio.write(). In this case the value 0x3 represents a read command. This value is user defined in the Python code, and must match the value the C program running on the IOP expects for the same function.

.. code-block:: python

    self.mmio.write(iop_const.MAILBOX_OFFSET+
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 3)     

When the IOP is finished, it will write 0x0 to the command area. The Python code now uses mmio.read() to check if the command is still pending (in this case, when the 0x3 value is still present at the ``CMD_OFFSET``).  While the command is pending, the Python class blocks.  

.. code-block:: python

    while (self.mmio.read(iop_const.MAILBOX_OFFSET+
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 3):
        pass
            
Once the command is no longer 0x3, i.e. the acknowledge has been received, the result is read from the ``DATA`` area of the shared memory ``MAILBOX_OFFSET`` using `mmio.read()`.

.. code-block:: python

    return self.mmio.read(iop_const.MAILBOX_OFFSET)

Notice the iop_const values are used in these function calls, values that are predefined in ``iop_const.py``. 
