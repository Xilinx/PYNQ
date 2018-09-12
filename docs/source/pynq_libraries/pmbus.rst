.. _pynq-libraries-pmbus:

PMBus
=====

PYNQ provides access to voltage and current sensors provided on many boards
using PMBus or other protocols supported by the Linux kernel. PYNQ uses the
libsensors API (https://github.com/lm-sensors/lm-sensors) to provide access to
monitoring sensors.

``pynq.pmbus`` API
------------------

All sensors can be found using the ``pynq.get_rails()`` function which returns a
dictionary mapping the name of the voltage rail to a ``Rail`` class. Each ``Rail``
has members for the ``voltage``, ``current`` and ``power`` sensors, the current
reading of which can be obtained from the ``value`` attribute.

The ``DataRecorder``
--------------------

The other aspect of the PMBus library is the ``DataRecorder`` class which
provides a simple way to record the values of one or more sensors during a
test. A ``DataRecorder`` is constructed with the sensors to be monitored and will
ultimately produce a pandas ``DataFrame`` as the result. The
``record(sample_interval)`` function begins the recording with the sample rate
specified as the interval in seconds. The ``stop()`` function ends the recording.
If the ``record`` function is used in a ``with`` block the ``stop`` will be called
automatically at the end of the block ensuring that the monitoring thread is
always terminated even in the presence of exceptions. Each sample in the result
is indexed by a timestamp and contains a session identifier in addition to the
values. This identifier starts at ``0`` and is incremented each time that
``record`` is called on a recorder or when the ``mark()`` function is called. This
identifier is designed to allow different parts or runs of a test to be
differentiated in further analysis.

Example
-------

.. code-block:: Python

    from pynq import get_rails, DataRecorder

    rails = get_rails()
    recorder = DataRecorder(rails['12V'].power)

    with recorder.record(0.2): # Sample every 200 ms
        # Perform the first part of the test
        recorder.mark()
        # Perform the second part of the test

    results = recorder.frame

Board Support
-------------

For full support on a board a custom configuration file is required for
libsensors to identify which voltage rails are attached to which sensors which
should be copied to ``/etc/sensors.d``. The PYNQ repository contains a
configuration for the ZCU104 board. For details on the format of this file see
both the ZCU104 configuration in ``boards/ZCU104/packages/sensorconf``
directory and the lm-sensors documentation at the link in the introduction.
