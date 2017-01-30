********************************************
Interrupts
********************************************

.. contents:: Table of Contents
   :depth: 2
	  
Introduction
=========================================
Each IOP has its only interrupt controller allowing its local peripherals to interrupt it. This is the standard `AXI Interrupt Controller (4.1)<https://www.xilinx.com/products/intellectual-property/axi_intc.html>`_ and can be used in an IOP application as it would be used in any MicroBlaze design.

The base overlay also has a interrupt controller connected to the interrupt pin of the Zynq PS. The IOPs can trigger this interrupt controller to singal to the PS and Python that an interrupt in the overlay has occured. 

.. image:: ./images/pynqz1_base_overlay_intc_pin.png
   :align: center

Interrupts in PYNQ can be handled in different ways. One method of handling interrupts is using the *asyncio* Python package. Asyncio was first introduced in Python 3.4 as provisional, and starting in Python 3.6 is considered stable. https://docs.python.org/3.6/whatsnew/3.6.html#asyncio 
This PYNQ release used Python 3.6 and includes the latest asyncio package.

The main advantage of using asyncio over other interrupt handling methods, is that it makes the interrupt handler look like regular Python code. This helps reduce the complexity of managing interrupts using callbacks. 

It should be noted that Python is a productivity langugage rather than a performance language. Any performance critical, or real-time parts of a design should be handled in the PL. An interrupt sent to the PS may have a relatively long latency before it is handled. 


Asyncio
=========

Background terminology
---------------------------

Asyncio consists of the following components:

Event loop
^^^^^^^^^^^^^

An event loop is a loop for scheduling multiple asynchronous functions. When an event loop runs, and the first IO function is reached, the function pauses waiting for its IO to complete. While the function is waiting, the loop continues, executing subsequent functions in the same way. When a function completes its IO, it can resume at the next sceduled point in the event loop.

https://docs.python.org/3/library/asyncio-eventloop.html

.. code-block:: Python
    
    loop = asyncio.get_event_loop()    
    
Futures
^^^^^^^^^^^^^

A future is an object that will have a value in the future. The event loop can wait for a *Future* object to be set to done. i.e. data available.  

    asyncio.ensure_future(async_coroutine(5)),

Coroutines
^^^^^^^^^^^^^

A coroutine is a function that can pause, that can receive values, and can return a series of value periodically. A coroutine is a functions decorated with ``async def`` (Python 3.6).

.. code-block:: Python

    async def function():
        ...
        
Tasks
^^^^^^^^^^^^^

A task is a coroutine wrapped inside a Future. A task runs as long as the event loop runs. 

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


Requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

All blocking calls in event loop should be replaced with coroutines.If you do not do this, when a blocking call is reached, it will block the rest of the loop. 

If you need blocking calls, they should be in seperate threads. 

Compute workloads should be in separate threads/processes. 

Interrupts in PYNQ using asyncio
==================================

Asyncio can be used for managing interrupts. A coroutine can be created to check the status of the interrupt controller, and scheduled in an event loop. Other user functions can be run in the event loop. If an interrupt has been triggered, the next time the "interrupt" coroutine is scheduled, it will service the interrupt. 


The Python *Interrupt* class can be found here:

.. code-block:: console

    pynq\interrupt.py
    
This implements the class to manage the AXI interrupt controller in the PL. It is not necessary to examine this code in detail to use interrupts. 

The IOP class  inherits the main Interrupt class, and implements an asyncio event-like interface to the interrupt subsystem for an IOP. 

The Python code for an IOP application can instantiate the Interrupt class and connect an interrupt pin. 

e.g.

.. code-block:: Python

    def __init__(self)
        self.iop = request_iop(iop_id, IOP_EXECUTABLE)
        self.interrupt = Interrupt('iop1/dff_en_reset_0/q')
        
The IOPs have a GPIO connected to the AXI interrupt controller. The IOP interrupt pin name must be specified to connect the interrupt. 

        
There are two options for running functions from this new IOP wrapper class. The function can be called from an external asyncio event loop, or the function can set up its own event loop and then call its asyncio function from the event loop.

Async function
----------------------

The following code defines an asyncio function. notice the ``async`` and ``await`` keywords are the only additiona code needed to make this function an asyncio coroutine.

.. code-block:: Python

    async def interrupt_handler_async(self, value):
        if self.interrupt is None:
            raise RuntimeError('Interrupts not available in this Overlay')
        while(1):
            await self.interrupt.wait() # Wait for interrupt
            # Do something when an interrupt is received

Function with event loop
---------------------------

The following code sets up an event loop and calls the async function above from the event loop.

.. code-block:: Python
    
    def interrupt_handler(self):   
    
        if self.interrupt is None:
            raise RuntimeError('Interrupts not available in this Overlay')
        loop = asyncio.get_event_loop()
        loop.run_until_complete(asyncio.ensure_future(
            self.interrupt_handler_async()
        ))
        
Interrupt pin mappings
=========================

Interrupts are also available from the GPIO (Pushbuttons, Switches, Video, Tracebuffer Arduino, Tracebuffer Pmods). 

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

The asyncio_buttons.ipynb and iop_interrupts_example.ipynb notebook can be found in the examples directory.
