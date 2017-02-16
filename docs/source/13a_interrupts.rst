********************************************
Interrupts
********************************************

.. contents:: Table of Contents
   :depth: 2
	  
Introduction
=========================================
Each IOP has its only interrupt controller. This allows IOP peripherals (IIC, SPI, GPIO, Uart, Timers) to interrupt the MicroBlaze processor inside the IOP. The IOP uses the `AXI Interrupt Controller <https://www.xilinx.com/products/intellectual-property/axi_intc.html>`_. It can be used in an IOP application in the same way as any other MicroBlaze application to manage this local interrupts.

The base overlay also has a interrupt controller connected to the interrupt pin of the Zynq PS. The overlay interrupt controller can be triggered by the MicroBlaze inside an IOP to signal to the PS and Python that an interrupt has occurred in the overlay. 

.. image:: ./images/pynqz1_base_overlay_intc_pin.png
   :align: center

Interrupts in PYNQ can be handled in different ways. The *asyncio* Python package is one method of handling interrupts. Asyncio was first introduced in Python 3.4 as provisional, and starting in Python 3.6 is considered stable. `Python 3.6 documentation on asyncio <https://docs.python.org/3.6/whatsnew/3.6.html#asyncio>`_. 


This PYNQ release used Python 3.6 and includes the latest asyncio package.

The main advantage of using asyncio over other interrupt handling methods, is that it makes the interrupt handler look similar to regular Python code. This helps reduce the complexity of managing interrupts using callbacks. 

It should be noted that Python is a productivity language rather than a performance language. Any performance critical, or real-time parts of a design should be handled in the PL. An interrupt sent to the PS may have a relatively long latency before it is handled. 


Asyncio
=========

Background terminology
---------------------------

Asyncio includes the following components:

Event loop
^^^^^^^^^^^^^

An event loop is a loop for scheduling multiple asynchronous functions. When an event loop runs, and the first IO function is reached, the function pauses waiting for its IO to complete. While the function is waiting, the loop continues, executing subsequent functions in the same way. When a function completes its IO, it can resume at the next scheduled point in the event loop.


.. code-block:: Python
    
    loop = asyncio.get_event_loop()    
    
https://docs.python.org/3/library/asyncio-eventloop.html

Futures
^^^^^^^^^^^^^

A future is an object that will have a value in the future. The event loop can wait for a *Future* object to be set to done. i.e. data available.  

.. code-block:: Python

    asyncio.ensure_future(async_coroutine(5)),

https://docs.python.org/3/library/asyncio-task.html#future

Coroutines
^^^^^^^^^^^^^

A coroutine is a function that can pause, that can receive values, and can return a series of value periodically. A coroutine is a functions decorated with ``async def`` (Python 3.6).

.. code-block:: Python

    async def function():
        ...
        

https://docs.python.org/3/library/asyncio-task.html#coroutines

Tasks
^^^^^^^^^^^^^

A task is a coroutine wrapped inside a Future. A task runs as long as the event loop runs. 

.. code-block:: Python

   asyncio.ensure_future(async_coroutine())

https://docs.python.org/3/library/asyncio-task.html#task

await
^^^^^^^^^^^^^

The ``await`` expression is used to obtain a result from a coroutine 

.. code-block:: Python

    async def asyncio_function(db):
        data = await read()
        ...


Example
-------------------------

An event loop registers a task object. The loop will schedule and run the task. 
Callbacks can be added to the task to notify when a future has a result. 

When the coroutine in a task *awaits* it is paused. When it has a value, it resumes. When it returns, the task completes, and the future gets a value. Any associated callback is run. 


.. code-block:: Python


   async def async_coroutine(max):
      for i in range (1,max):
         await asyncio.sleep(1)
         print(i)
       
      print("Done")

   loop = asyncio.get_event_loop()    
   tasks = [
      asyncio.ensure_future(async_coroutine(5)),
      asyncio.ensure_future(async_coroutine(20)),
      asyncio.ensure_future(async_coroutine(10)),
      asyncio.ensure_future(async_coroutine(1))]
   loop.run_until_complete(asyncio.gather(*tasks))
   loop.close()


Asyncio requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

All blocking calls in event loop should be replaced with coroutines. If you do not do this, when a blocking call is reached, it will block the rest of the loop. 

If you need blocking calls, they should be in separate threads. 

Compute workloads should be in separate threads/processes. 

Interrupts in PYNQ using asyncio
==================================

Asyncio can be used for managing interrupt events from the overlay. A coroutine can be run in an event loop and used to check the status of the interrupt controller in the overlay, and handle any event. Other user functions can also be run in the event loop. If an interrupt is triggered, the next time the "interrupt" coroutine is scheduled, it will service the interrupt. The responsiveness of the interrupt coroutine will depend on how frequently the user code yields control in the loop. 

Interrupts in the Base Overlay
------------------------------

The I/O peripherals in the base overlay will trigger interrupts when switches are toggled or buttons are pressed. Both the *Button* and *Switch* classes have a function ``wait_for_level`` and a coroutine ``wait_for_level_async`` which block until the corresponding button or switch has the specified value. This follows a convention throughout the PYNQ python API that that coroutines have an ``_async`` suffix.

As an example, consider an application where each LED will light up when the corresponding button is pressed. First a coroutine specifying this functionality is defined:

.. code-block:: Python

    async def button_to_led(number):
        button = pynq.board.Button(number)
        led = pynq.board.LED(number)
        while True:
            await button.wait_for_level_async(1)
            led.on()
            await button.wait_for_level_async(0)
            led.off()

Next add instances of the coroutine to the default event loop

.. code-block:: Python

    tasks = [asyncio.ensure_future(button_to_led(i) for i in range(4)]

Finally, running the event loop will cause the coroutines to be active. This code runs the event loop until an exception is thrown or the user interrupts the process.

.. code-block:: Python

    asyncio.get_event_loop().run_forever()


IOP and Interrupts
------------------------------

The IOP class has an ``interrupt`` member variable which acts like an *asyncio.Event* with a ``wait`` coroutine and a ``clear`` method. This event is automatically wired to the correct interrupt pin or set to ``None`` if interrupts are not available in the loaded overlay. 

e.g.

.. code-block:: Python

    def __init__(self)
        self.iop = request_iop(iop_id, IOP_EXECUTABLE)
        if self.iop.interrupt is None:
           warn("Interrupts not available in this Overlay")

There are two options for running functions from this new IOP wrapper class. The function can be called from an external asyncio event loop (set up elsewhere), or the function can set up its own event loop and then call its asyncio function from the event loop.

Async function
----------------------

By convention, the PYNQ python API offers both an asyncio coroutine and a blocking function call for all interrupt-driven functions. It is recommended that this should be extended to any user-provided IOP drivers. The blocking function can be used where there is no need to work with asyncio, or as a convenience function to run the event loop until a specified condition. The coroutine is given the ``_async`` suffix to avoid breaking backwards compatibility when updating existing functions.

The following code defines an asyncio coroutine. Notice the ``async`` and ``await`` keywords are the only additional code needed to make this function an asyncio coroutine.

.. code-block:: Python

    async def interrupt_handler_async(self, value):
        if self.iop.interrupt is None:
            raise RuntimeError('Interrupts not available in this Overlay')
        while(1):
            await self.iop.interrupt.wait() # Wait for interrupt
            # Do something when an interrupt is received
            self.iop.interrupt.clear()

Function with event loop
---------------------------

The following code wraps the asyncio coroutine, adding to the default event loop and running it until the coroutine completes.

.. code-block:: Python
    
    def interrupt_handler(self):   
    
        if self.interrupt is None:
            raise RuntimeError('Interrupts not available in this Overlay')
        loop = asyncio.get_event_loop()
        loop.run_until_complete(asyncio.ensure_future(
            self.interrupt_handler_async()
        ))

Custom interrupt handling
---------------------------

The Python *Interrupt* class can be found here:

.. code-block:: console

    <GitHub Repository>\pynq\interrupt.py

This class abstracts away management of the AXI interrupt controller in the PL. It is not necessary to examine this code in detail to use interrupts. The interrupt class takes the pin name of the interrupt line and offers a single ``wait`` coroutine. The interrupt is only enabled in the hardware for as long as a coroutine is waiting on an *Interrupt* object. The general pattern for using an Interrupt is as follows:

.. code-block:: Python

    while condition:
        await interrupt.wait()
        # Clear interrupt

This pattern avoids race conditions between the interrupt and the controller and ensures that an interrupt isn't seen multiple times.

Interrupt pin mappings
=========================

Interrupts are also available from the GPIO (Pushbuttons, Switches, Video, Trace buffer Arduino, Trace buffer Pmods). 

=============== ========== =====================================
Name             IOP ID     Pin
=============== ========== =====================================
PMODA            1          iop1/dff_en_reset_0/q
PMODB            2          iop2/dff_en_reset_0/q
ARDUINO          3          iop3/dff_en_reset_0/q
Buttons                     btns_gpio/ip2intc_irpt
Switches                    swsleds_gpio/ip2intc_irpt
Video                       video/dout
Trace(Pmod)                 tracepmods_arduino/s2mm_introut
Trace(Arduino)              tracebuffer_arduino/s2mm_introut
=============== ========== =====================================


Interrupt examples using asyncio
===================================

Example notebooks
-----------------

The `asyncio_buttons.ipynb <https://github.com/Xilinx/PYNQ/blob/master/Pynq-Z1/notebooks/examples/asyncio_buttons.ipynb>`_ notebook can be found in the examples directory. The Arduino LCD IOP driver provides an example of using the IOP interrupts.
