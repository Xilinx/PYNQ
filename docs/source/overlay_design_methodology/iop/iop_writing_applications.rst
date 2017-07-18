
IO Processors: Writing applications
=======================================

.. contents:: Table of Contents
   :depth: 2

Introduction
--------------------

The previous section described the software architecture and the software build process. This section will cover how to write the IOP application and also the corresponding Python interface. 

The section assumes that the hardware platform and the BSPs have already been generated as detailed in the previous section. 

IOP header files and libraries
---------------------------------

A library is provided for the IOPs which includes an API for local peripherals (IIC, SPI, Timer, Uart, GPIO), the configurable switch, links to the peripheral addresses, and mappings for the mailbox used in the existing IOP peripheral applications provided with Pynq. This library can be used to write custom IOP applications. 

The only IP that is specific to each IOP is the configurable switch. There is a ``pmod_io_switch`` and an ``arduino_io_switch``. The header files for the IOPs are associated with the corresponding configurable switch, and can be found here

:: 
   
   <GitHub Repository>/boards/<board name>/vivado/ip/pmod_io_switch_1.0/  \
   drivers/pmod_io_switch_v1_0/src/pmod.h
      <GitHub Repository>/boards/<board name>/vivado/ip/arduino_io_switch_1.0/  \
   drivers/arduino_io_switch_v1_0/src/arduino.h

The corresponding C code, ``pmod.c`` and ``arduino.c`` can also be found in this directory. 
 
Configurable switch header files
-----------------------------------

There is a separate header file that corresponds to each configurable switch. These files include the API for the configuration switch and predefined constants that can be used to connect to the physical interface on the board. 

Pmod Configurable Switch header
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can find the header file for the Pmod IOP switch here:

:: 
   
   <GitHub Repository>/boards/<board name>/vivado/ip/pmod_io_switch_1.0/  \
   drivers/pmod_io_switch_v1_0/src/pmod_io_switch.h

This code is automatically compiled into the Board Support Package (BSP). 


Arduino
^^^^^^^^^^^^^^^^^^^^^^^

The corresponding files for the Arduino IOP switch can be found here:

:: 
   
   <GitHub Repository>/boards/<board name>/vivado/ip/arduino_io_switch_1.0/  \
   drivers/arduino_io_switch_1.0/src/arduino_io_switch.h


Files to include
^^^^^^^^^^^^^^^^^^^^^^^

To use these files in an IOP application, include the header file(s):


For a Pmod IOP:

.. code-block:: c

   #include "pmod.h"
   #include "pmod_io_switch.h"

or for an Arduino IOP:

.. code-block:: c

   #include "arduino.h"
   #include "arduino_io_switch.h"

Pmod applications should call ``pmod_init()`` at the beginning of the application, and Arduino applications, ``arduino_init()``. This will initialize all the IOP peripherals in the subsystem.  

   
Controlling the Pmod IOP Switch
-----------------------------------

The IOP switch needs to be configured by the IOP application before any peripherals can be used. This can be done statically from within the application, or the application can allow Python to write a switch configuration to shared memory, which can be used to configure the switch. This functionality must be implemented by the user, but existing IOP applications can be used as a guide. For example, the ``arduino_lcd18`` IOP project shows and example of reading the switch configuration from the mailbox, and using this to configure the switch. 

There are 8 data pins on a Pmod port, that can be connected to any of 16 internal peripheral pins (8x GPIO, 2x SPI, 4x IIC, 2x Timer). This means the configuration switch for the Pmod has 8 connections to make to the data pins. 

Each pin can be configured by writing a 4 bit value to the corresponding place in the IOP Switch configuration register. The first nibble (4-bits) configures the first pin, the second nibble the second pin and so on. 

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
^^^^^^^^

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

Controlling the Arduino IOP Switch
-------------------------------------

Switch mappings used for IO switch configuration:

===  ======  =====   =========  ======  ======  ================  ========  ====  =============
                                                                                               
Pin  A/D IO  A_INT   Interrupt  UART    PWM     Timer             SPI       IIC   Input-Capture  
                                                                                         
===  ======  =====   =========  ======  ======  ================  ========  ====  =============
A0   A_GPIO  A_INT                                                                             
A1   A_GPIO  A_INT                                                                             
A2   A_GPIO  A_INT                                                                             
A3   A_GPIO  A_INT                                                                             
A4   A_GPIO  A_INT                                                          IIC                
A5   A_GPIO  A_INT                                                          IIC                
D0   D_GPIO          D_INT      D_UART                                                         
D1   D_GPIO          D_INT      D_UART                                                         
D2   D_GPIO          D_INT                                                                     
D3   D_GPIO          D_INT              D_PWM0  D_TIMER Timer0                    IC Timer0  
D4   D_GPIO          D_INT                      D_TIMER Timer0_6                             
D5   D_GPIO          D_INT              D_PWM1  D_TIMER Timer1                    IC Timer1  
D6   D_GPIO          D_INT              D_PWM2  D_TIMER Timer2                    IC Timer2  
D7   D_GPIO          D_INT                                                                     
D8   D_GPIO          D_INT                      D_TIMER Timer1_7                  Input Capture
D9   D_GPIO          D_INT              D_PWM3  D_TIMER Timer3                    IC Timer3  
D10  D_GPIO          D_INT              D_PWM4  D_TIMER Timer4    D_SS            IC Timer4  
D11  D_GPIO          D_INT              D_PWM5  D_TIMER Timer5    D_MOSI          IC Timer5  
D12  D_GPIO          D_INT                                        D_MISO                       
D13  D_GPIO          D_INT                                        D_SPICLK                     
                                                                                               
===  ======  =====   =========  ======  ======  ================  ========  ====  =============

For example, to connect the UART to D0 and D1, write D_UART to the configuration register for D0 and D1. 

.. code-block:: c

    config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, A_GPIO, A_GPIO, A_GPIO,
                  D_UART, D_UART, D_GPIO, D_GPIO, D_GPIO,
                  D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                  D_GPIO, D_GPIO, D_GPIO, D_GPIO);

   
IOP Application Example
---------------------------


Taking Pmod ALS as an example IOP driver (used to control the PMOD light sensor):

``<GitHub Repository>/boards/<board name>/sdk/pmod_als/src/pmod_als.c``


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
^^^^^^^^^^^^^^^^^^^^^^^^^^^

With the IOP Driver written, the Python class can be built that will communicate with that IOP. 
 
``<GitHub Repository>/pynq/lib/pmod/pmod_als.py``
  
First the Pmod package is imported: 

.. code-block:: python

   from . import Pmod

   PMOD_ALS_PROGRAM = "pmod_als.bin"

The MicroBlaze binary file for the IOP is defined. This is the application executable, and will be loaded into the IOP instruction memory. 

The ALS class and an initialization method are defined:

.. code-block:: python

   class Pmod_ALS(object):
   
      def __init__(self, mb_info):

The initialization function for the module requires an IOP index. For Grove peripherals and the StickIt connector, the StickIt port number can also be used for initialization.  The ``__init__`` is called when a module is instantiated. e.g. from Python:

.. code-block:: python

    from pynq.lib.pmod import Pmod_ALS
    als = Pmod_ALS(0)

This will create a *Pmod_ALS* instance, and and load the MicroBlaze executable (PMOD_ALS_PROGRAM) into the instruction memory of the specified IOP.

In the initialization method, an instance of the ``microblaze`` class is created. This class contains 

An MMIO class is also instantiated to enable read and write to the shared memory.  

.. code-block:: python

    self.mmio = self.iop.mmio

Finally, the iop.start() call pulls the IOP out of reset. After this, the IOP will be running the als.bin executable.    

.. code-block:: python

    self.iop.start()

Example of Python Class Runtime Methods
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The read method in the Pmod_ALS class will simply read an ALS sample and return that value to the caller.  The following steps demonstrate a Python to MicroBlaze read transaction specific to the ALS class.

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
