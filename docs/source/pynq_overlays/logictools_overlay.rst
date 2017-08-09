Logictools Overlay
==================

Introduction
---------------------

The *logictools* overlay consists of programmable hardware blocks to connect to
external digital logic circuits. Finite state machines, Boolean logic functions
and digital patterns can be generated from Python. A programmable switch
connects the inputs and outputs from the hardware blocks to external IO
pins. The logictools overlay can also have a trace analyzer to capture data from
the IO interface for analysis and debug.

PYNQ-Z1 Block Diagram
---------------------

.. image:: ../images/logictools_pynqz1.png
   :align: center

The PYNQ-Z1 Logictools overlay includes four main hardware blocks:

* Pattern Generator
* FSM Generator
* Boolean Generator
* Trace Analyzer


Pattern Generator
-----------------

The *Pattern Generator* can be programmed to generate and stream digital
patterns to the IO pins. This can be used as a stimulus to an external circuit.


Finite State Machine (FSM) Generator
------------------------------------
The *FSM Generator* can create a finite state machine from a Python
description. The inputs and outputs and states of the FSM can be connected to
external IO pins.

Boolean Generator
-----------------
The *Boolean Generator* can create independent combinatorial Boolean logic functions. The
external IO pins are used as inputs and outputs to the Boolean functions.

Trace Analyzer
--------------
The *Trace Analyzer* can capture IO signals and stream the data to the PS DRAM
for analysis in the Python environment. The Trace Analyzer can be used
standalone to capture external IO signals, or used in combination with the other
three logictools functions to monitor data to and from the other blocks.
E.g. the trace analyzer can be used with the pattern generator to verify the
data sent to the external pins, or with the FSM to check the input, output or
states to verify or debug a design.


Python API
----------

The API for the logictools generators and trace analyzer can be found in the PYNQ libraries section. 


Rebuilding the Overlay
-----------------------

The project files for the logictools overlay can be found here:

.. code-block:: console

   ``<GitHub Repository>/boards/<board>/logictools``

To rebuild the logictools overlay run *make* in the directory above. 


Logictools IP and  project files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

All source code for the hardware blocks is provided. Each block can also be reused standalone in a custom overlay. 

The source files for the logictools IP can be found in the same location as the other PYNQ IP:

.. code-block:: console

   ``<GitHub Repository>/boards/ip``

   



   
