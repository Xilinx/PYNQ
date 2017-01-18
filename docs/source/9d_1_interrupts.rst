********************************************
Interrupts
********************************************

.. contents:: Table of Contents
   :depth: 2
	  
Introduction
=========================================
Each IOP has its only interrupt controller allowing its local peripherals to interrupt it. This is the standard MicroBlaze interrupt controller and can be used in the MicroBlaze application as it would be in any other design.

The base overlay also has a central interrupt controller connected to the PS. THe IOPs can trigger the central interrupt controller. 

Interrupts in PYNQ can be handled in different ways. One method of handling interrupts is using asyncio. Asyncio was introduced in Python 3.4 as provisional, and starting in Python 3.6 is considered stable. https://docs.python.org/3.6/whatsnew/3.6.html#asyncio This PYNQ release used Python 3.6.

The main advantage os using asyncio is that it makes the interrupt handler look liek regular code, and helps reduce the complexity of managing interrupts using callbacks. 


Asyncio
--------------

Background terminology
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

asyncio uses Linux selectors.

Asyncio consists of the following components:

* Event loop

Multiple asynchronous functions can be scheduled and managed inside in an event loop. When the event loop runs, and the first IO function is reached, the function pauses waiting for its IO to complete. While the function is waiting, the loop continues, executing subsequent functions in the same way. When a function completes its IO, it can resume at the next sceduled point in the event loop.

https://docs.python.org/3/library/asyncio-eventloop.html


* Futures

A future is an object that will have a value in the future. The event loop can wait for a *Future* object to be set to done. i.e. data available.  

*  Coroutines. 

A coroutine is a function that can pause, that can receive values, and can return a series of value periodically. A coroutine is a functions decorated with ``async def`` (Python 3.6).

* await

The ``await`` expression is used to obtain a result from a coroutine 

async def asyncio_function(db):
    data = await read()
    ...

* Tasks

A task is a coroutine wrapped inside a Future. A task runs as long as the event loop runs. 

Putting it together
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

An event loop registers a task object. The loop will schedule and run the task. 
Callbacks can be added to the task to notify when a future has a result. 

When the coroutine in a task *awaits* it is paused. When it has a value, it resumes. When it returns, the task completes, and the future gets a value. Any associated callback is run. 

Example
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

All blocking calls in event loop should be replaced with coroutines

Compute workloads should be in separate thread/process

Use separate threads for blocking calls

Interrupts using asyncio
==========================

Asyncio can be used for managing interrupts. An coroutine can be created to check the status of the interrupt controller. 
The coroutine can be scheduled in an event loop alongside other user code. When an interrupt is triggered, the coroutine resumes and handles the interrupt. 

Interrupt example using asyncio
===================================

An interrupt from the PL is connected to XXX

Code
^^^^^^^^^^^

This depends on user code yielding. This will massively impact interrupt latency. 

If user function does not yield from ... sleep() it will be blocking. 


Callback, when interrupt triggers, code jumps and breaks execution. No need to yield