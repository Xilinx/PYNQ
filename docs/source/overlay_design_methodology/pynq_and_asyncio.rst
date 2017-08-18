.. _pynq-and-asyncio:

PYNQ and Asyncio
================

Interacting with hardware frequently involves waiting for accelerators to
complete or stalling for data. Polling is an inefficient way of waiting for data
especially in a language like python which can only have one executing thread at
once.

The Python `asyncio <https://docs.python.org/3/library/asyncio.html>`_ library
manages multiple IO-bound tasks asynchronously, thereby avoiding any blocking
caused by waiting for responses from slower IO subsystems. Instead, the program
can continue to execute other tasks that are ready to run. When the
previously-busy tasks are ready to resume, they will be executed in turn, and
the cycle is repeated.

In PYNQ real-time tasks are most often implemented using IP blocks in the
Programmable Logic (PL). While such tasks are executing in the PL they can raise
interrupts on the PS CPUs at any time. Python's asyncio library provides an
effective way to manage such events from asynchronous, IO-bound tasks.

The foundation of asyncio in Pynq is the Interrupts class in the
:ref:`pynq-interrupts` which provides an asyncio-style event that can be used
for waiting for interrupts to be raised. The video Library, AXI GPIO and the
PynqMicroblaze drivers are build on top of the interrupt event to provide
coroutines for any functions that might otherwise block.

Asyncio Fundamentals
--------------------

The asyncio concurrency framework relies on coroutines, futures, tasks, and an
event loop. We will introduce these briefly before demonstrating their use with
some introductory examples.

Coroutines
^^^^^^^^^^

Coroutines are a new Python language construct. Coroutines introduce two new
keywords ``await`` and ``async`` the Python syntax. Coroutines are stateful
functions whose execution can be paused. This means that they can yield
execution, while they wait on some task or event to complete. While suspended,
coroutines maintain their state.  They are resumed once the outstanding activity
is resolved.  The await keyword determines the point in the coroutine where
it yields control and from which execution will resume.

Futures
^^^^^^^

A ``future`` is an object that acts as a proxy for a result that is initially
unknown, usually because the action has not yet completed. The futures concept
is essential components in the internals of asyncio: futures encapsulate
pending operations so that they can be put in queues, their state of completion
can be queried, and their results can be retrieved when ready. They are meant to
be instantiated exclusively by the concurrency framework, rather than directly
by the user.

Tasks
^^^^^

Coroutines do not execute directly. Instead, they are wrapped in ``tasks`` and
registered with an asyncio event loop. tasks are a subclass of futures.

Event Loop
^^^^^^^^^^

The event loop is responsible for executing all *ready* tasks, polling the
status of suspended tasks, and scheduling outstanding tasks.

An event loop runs only one task at a time. It relies on cooperative
scheduling.  This means that no task interrupts another, and each task yields
control to the event loop when its execution is blocked. The result is
single-threaded, concurrent code in which the next cycle of the loop does not
start until all the event handlers are executed sequentially.

A simple example is shown below. The example defines an coroutine named
``wake_up`` defined using the new ``async def`` syntax. Function main creates an
asyncio event loop that wraps the wake_up coroutine in a task called called
``wake_up_task`` and registers the task with the event loop. Within the
coroutine, the ``await`` statement marks the point at which execution is
initially suspended, and later resumed. The loop executes the following
schedule:

  1. Starts executing wake_up_task
  2. Suspends wake_up_task and preserves its state
  3. Runs asyncio.sleep runs for 1 to 5 seconds
  4. Resumes wake_up_task from preserved state
  5. Runs to completion using the preserved state

Finally the event loop is closed.  

.. code-block:: Python

    import asyncio
    import random
    import time
    
    # Coroutine
    async def wake_up(delay):
        '''A coroutine that will yield to asyncio.sleep() for a few seconds
           and then resume, having preserved its state while suspended
        '''
        
        start_time = time.time()
        print(f'The time is: {time.strftime("%I:%M:%S")}')
        print(f"Suspending coroutine 'wake_up' at 'await` statement\n")
        await asyncio.sleep(delay)
        print(f"Resuming coroutine 'wake_up' from 'await` statement")
        end_time = time.time()
        sleep_time = end_time - start_time
        print(f"'wake-up' was suspended for precisely: {sleep_time} seconds")
     
    # Event loop 
    if __name__ == '__main__':
        delay = random.randint(1,5)
        my_event_loop = asyncio.get_event_loop()
        try:
            print("Creating task for coroutine 'wake_up'\n")
            wake_up_task = my_event_loop.create_task(wake_up(delay))
            my_event_loop.run_until_complete(wake_up_task)
        except RuntimeError as err:
            print (f'{err}' +
                   ' - restart the Jupyter kernel to re-run the event loop')
        finally:
            my_event_loop.close()


A sample run of the code produces the following output:

.. code-block:: Console

    Creating task for coroutine 'wake_up'
    
    The time is: 11:09:28
    Suspending coroutine 'wake_up' at 'await` statement
    
    Resuming coroutine 'wake_up' from 'await` statement
    'wake-up' was suspended for precisely: 3.0080409049987793 seconds 


Any blocking call in event loop should be replaced with a coroutine. If you do
not do this, when a blocking call is reached, it will block the rest of the
loop.

If you need blocking calls, they should be in separate threads. Compute
workloads should also be in separate threads/processes.


Instances of Asyncio in pynq
----------------------------

Asyncio can be used for managing a variety of potentially blocking operations in
the overlay. A coroutine can be run in an event loop and used to wait for an
interrupt to fire. Other user functions can also be run in the event loop. If an
interrupt is triggered, any coroutines waiting on the corresponding event will
be rescheduled. The responsiveness of the interrupt coroutine will depend on how
frequently the user code yields control in the loop.

GPIO Peripherals
^^^^^^^^^^^^^^^^

User I/O peripherals can trigger interrupts when switches are toggled or buttons
are pressed. Both the :ref:`Button<pynq-lib-button>` and
:ref:`Switch<pynq-lib-switch>` classes have a function ``wait_for_level`` and a
coroutine ``wait_for_level_async`` which block until the corresponding button or
switch has the specified value. This follows a convention throughout the pynq
package that that coroutines have an ``_async`` suffix.

As an example, consider an application where each LED will light up when the
corresponding button is pressed. First a coroutine specifying this functionality
is defined:

.. code-block:: Python

    base = pynq.overlays.base.BaseOverlay('base.bit')

    async def button_to_led(number):
        button = base.buttons[number]
        led = base.leds[number]
        while True:
            await button.wait_for_level_async(1)
            led.on()
            await button.wait_for_level_async(0)
            led.off()

Next add instances of the coroutine to the default event loop

.. code-block:: Python

    tasks = [asyncio.ensure_future(button_to_led(i) for i in range(4)]

Finally, running the event loop will cause the coroutines to be active. This
code runs the event loop until an exception is thrown or the user interrupts the
process.

.. code-block:: Python

    asyncio.get_event_loop().run_forever()


PynqMicroblaze
^^^^^^^^^^^^^^

The :ref:`PynqMicroblaze<pynq-lib-pynqmicroblaze>` class has an ``interrupt``
member variable which acts like an asyncio.Event with a wait() coroutine and a
clear() method. This event is automatically wired to the correct interrupt pin
or set to None if interrupts are not available in the loaded overlay.

For example:

.. code-block:: Python

    def __init__(self)
        self.iop = pynq.lib.PynqMicroblaze(mb_info, IOP_EXECUTABLE)
        if self.iop.interrupt is None:
           warn("Interrupts not available in this Overlay")

There are two options for running functions from this new IOP wrapper class. The
function can be called from an external asyncio event loop (set up elsewhere),
or the function can set up its own event loop and then call its asyncio function
from the event loop.

Async Functions
^^^^^^^^^^^^^^^

pynq offers both an asyncio coroutine and a blocking function call for all
interrupt-driven functions. It is recommended that this should be extended to
any user-provided drivers. The blocking function can be used where there is no
need to work with asyncio, or as a convenience function to run the event
loop until a specified condition. 

The following code defines an asyncio coroutine. Notice the ``async`` and
``await`` keywords are the only additional code needed to make this function an
asyncio coroutine.

.. code-block:: Python

    async def interrupt_handler_async(self, value):
        if self.iop.interrupt is None:
            raise RuntimeError('Interrupts not available in this Overlay')
        while(1):
            await self.iop.interrupt.wait() # Wait for interrupt
            # Do something when an interrupt is received
            self.iop.interrupt.clear()

Event Loops
^^^^^^^^^^^

The following code wraps the asyncio coroutine, adding to the default event loop
and running it until the coroutine completes.

.. code-block:: Python
    
    def interrupt_handler(self):   
    
        if self.iop.interrupt is None:
            raise RuntimeError('Interrupts not available in this Overlay')
        loop = asyncio.get_event_loop()
        loop.run_until_complete(asyncio.ensure_future(
            self.interrupt_handler_async()
        ))

Custom Interrupt Handling
^^^^^^^^^^^^^^^^^^^^^^^^^

The :ref:`Interrupts<pynq-interrupts>` class allows custom interrupt handlers to
be built in Python.

This class abstracts away management of the AXI interrupt controller in the
PL. It is not necessary to examine this code in detail to use interrupts. The
interrupt class takes the pin name of the interrupt line and offers a single
wait_async coroutine and the corresponding wait function that wraps it.  The
interrupt is only enabled in the hardware for as long as a coroutine is waiting
on an *Interrupt* object. The general pattern for using an Interrupt is as
follows:

.. code-block:: Python

    while condition:
        await interrupt.wait()
        # Clear interrupt

This pattern avoids race conditions between the interrupt and the controller and
ensures that an interrupt isn't seen multiple times.

Examples
--------

For more examples, see the AsyncIO Buttons Notebook in the on the Pynq-Z1 in the
following directory:

.. code-block:: console

   <Jupyter Dashboard>/base/board/
