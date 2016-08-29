************
Verification
************


.. contents:: Table of Contents
   :depth: 2
 
This section documents the test infrastructure supplied with the `pynq` package. It is organized as follows:

* *Running Tests* : describes how to run the pytest.
* *Writing Tests* : explains how a user can write their own tests.
* *Miscellaneous* : covers additional information relating to tests. 


Running Tests
=============


The *pynq* package provides tests for most python modules.

To run all the tests together, we can directly run pytest in the Linux terminal. All the tests will be automatically collected in the current directory and all of its child directories.

.. code-block:: console

   cd /usr/local/lib/python3.4/dist-packages/pynq
   py.test –vsrw

For a complete list of pytest options, please refer to `Usage and Invocations - Pytest <https://pytest.org/latest/usage.html>`_. 

Collection Phase
----------------
During this phase, the pytest will collect all the test modules in the current directory and all of its child directories. The users will be asked if a PMOD is connected, and to which port it is connected. 

For example:

.. code-block:: console

   Is LED8 attached to the board? ([yes]/no)>>> yes
   Type in the PMOD ID of the LED8 (1 ~ 4):

For the answer to the first question, "yes", "YES", "Yes", "y", and "Y" are acceptable; the same applies for a "no" as an answer. Users can also directly press enter; this is equivalent to giving the "yes" answer.

For the answer to the second question, since we are using the PMOD overlay, 1, 2, 3, and 4 are all acceptable answers, since there are only 4 IO processors in "pmod.bit".

If we answer "no" to the first question, the corresponding tests will be skipped during the testing phase.

Testing Phase
-------------
The test suite will guide the users through all the tests implemented in the pynq package. As part of the tests, the user will be prompted for confirmation the tests have passed, for example:

.. code-block:: console

   test_led0 ...
   Onboard LED 0 on? ([yes]/no)>>>

Again, "yes", "YES", "Yes", "y", and "Y" are acceptable; the same applies for a "no" as an answer. Users can also directly press enter; this is equivalent to giving the "yes" answer.

At the end of the testing phase, a summary will be given to show users how many tests are passed / skipped / failed.

Writing Tests
=============
This section follows the guide available on `Usages and Examples - Pytest <https://pytest.org/latest/example/>`_. The users can write a test class with assertions on inputs and outputs to deliver automatic testing. The names of the test modules *must* start with `test_`; all the methods for tests in any test module *must* begin with `test_` as well. One reason to enforce this is to ensure the tests will be collected properly. More information can be found on `Full pytest documentation <https://pytest.org/latest/contents.html>`_.

Step 1
------
First of all, the pytest package has to be imported:

.. code-block:: python

   import pytest
   
Step 2
------
Then users can specify decorators right above the methods. For example, users can specify (1) the order of this test in the entire pytest process, and (2) the condition to skip the corresponding test. More decorators can be found on `Marking test functions with attributes - Pytest <https://pytest.org/latest/mark.html>`_.

.. code-block:: python

   @pytest.mark.run(order=25) 
   @pytest.mark.skipif(not flag, reason="need both ADC and DAC attached")

Step 3
------
Right below the decorators, users can write some assertions/tests. Below is an example taken from `test_dac_adc.py`:

.. code-block:: python

   @pytest.mark.run(order=25) 
   @pytest.mark.skipif(not flag, reason="need both ADC and DAC attached")
   def test_loop_single():
   """Test for writing a single value via the loop.
   
   First check whether read() correctly returns a string. Then ask the users 
   to write a voltage on the DAC, read from the ADC, and compares the two 
   voltages.
   
   Note
   ----
   Users can use a straight cable (instead of wires) to do this test.
   For the 6-pin DAC PMOD, it has to be plugged into the upper row of the PMOD
   interface.
   
   """
   global dac,adc
   dac = PMOD_DAC(dac_id)
   adc = PMOD_ADC(adc_id)
    
   value = float(input("\nInsert a voltage in the range of [0.00, 2.00]: "))
   assert value<=2.00, 'Input voltage should not be higher than 2.00V.'
   assert value>=0.00, 'Input voltage should not be lower than 0.00V.'
   dac.write(value)
   assert abs(value-float(adc.read()))<0.06, 'Read value != write value.'

Note the `assert` statements specify the desired condition, and raise exceptions whenever that condition is not met. A customized exception message can be attached at the end of the `assert` methods, as shown above in the example.

Miscellaneous Test Setup
========================

ADC Jumper
----------

In our tests and demos, we have used a PMOD ADC. In order to make it work properly with the testing environment, users have to set a small jumper on the PMOD ADC as following. This setting will allow the ADC to use the correct reference voltage.
 
.. image:: ./images/adc_jumper.jpeg
   :width: 200

Cable Type
----------

Two types of cables can be used with the tests in the pynq package, a "straight" cable, and a "loopback" cable:

.. image:: ./images/cable_type.jpeg
   :width: 400
 
*  *Straight cable* (upper one in the image): The internal wires between the two ends are straight. This cable is intended for use as an extension cable.
*  *Loopback cable* (lower one in the image, with red ribbon): The internal wires are twisted. This cable is intended for testing.

There are marks on the connectors at each end of the cable to indicate the orientation and wiring of the cable. 

.. note::  

   Since users must avoid shorting the VCC and GND, it is good practice to align the pins with the dot marks to VCC of the PMOD interfaces. A connection shorting the sources is strictly prohibited.
   
.. note::  
   For testing, there is only one connection type (mapping) allowed for each cable type. Otherwise VCC and GND could be shorted, damaging the board.
