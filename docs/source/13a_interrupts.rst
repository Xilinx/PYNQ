********************************************
Interrupts
********************************************

.. contents:: Table of Contents
   :depth: 2
	  
Introduction
=========================================
Each IOP has its only interrupt controller allowing its local peripherals to interrupt it. This is the standard MicroBlaze interrupt controller and can be used in the MicroBlaze application as it would be in any other design.

The base overlay also has a interrupt controller connected to the interrupt pin of the Zynq PS. THe IOPs can trigger this interrupt controller to singal to the PS and Python that an interrupt in the overlay has occured. 

.. image:: ./images/pynqz1_base_overlay_intc_pin.png
   :align: center

Interrupts in PYNQ can be handled in different ways. One method of handling interrupts is using the asyncio Python package. Asyncio was first introduced in Python 3.4 as provisional, and starting in Python 3.6 is considered stable. https://docs.python.org/3.6/whatsnew/3.6.html#asyncio 
This PYNQ release used Python 3.6 and includes the latest asyncio package.

The main advantage of using asyncio over other interrupt handling methods, is that it makes the interrupt handler look like regular Python code, and helps reduce the complexity of managing interrupts using callbacks. 

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
    

Asyncio uses Linux selectors.

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

Interrupts using asyncio
==========================

Asyncio can be used for managing interrupts. A coroutine can be created to check the status of the interrupt controller, and scheduled in an event loop alongside other user code. If an interrupt has been triggered, the next time the "interrupt" coroutine is scheduled, it will service the interrupt. 

High performance/real-time code 
------------------------------------

Note that Linux is not a real-time operating system, and Python is not intended as a high performance/low latency language. 

C libraries can be used to replace performance critical Python code. The CFFI may be used for this task. 

The PL can be used for real-time or performance critical operations. 

The IOPs use BRAM local memory which is deterministic and may be suitable for real-time code. Note that the DDR memory accesses will have some variablility and may be less suitable. 

New overlays can also be designed for real-time/performance. 


Interrupt example using asyncio
===================================

An interrupt from the PL is connected to XXX

Code
---------

This depends on user code yielding. This will have a major impact on interrupt latency. 

If user function does not yield from ... sleep() it will be blocking causing very long interrupt latencies. 

Callback, when interrupt triggers, code jumps and breaks execution. 

Example notebook
-----------------

The asyncio_buttons.ipynb notebook can be found in the examples directory. 