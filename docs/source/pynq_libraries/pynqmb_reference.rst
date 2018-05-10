Microblaze Library
==================

The PYNQ Microblaze library is the primary way of interacting with
Microblaze subsystems. It consists of a set of wrapper drivers for I/O
controllers and is optimised for the situation where these are connected
to a PYNQ I/O switch.

This document describes all of the C functions and types provided by the
API - see the Python/C interoperability guide for more details on how
this API translates into Python.

General Principles
------------------

This library provides GPIO, I2C, SPI, PWM/Timer and UART functionality.
All of these libraries follow the same design. Each defines a type which
represents a handle to the device. ``*_open`` functions are used in
situations where there is an I/O switch in the design and takes a set of
pins to connect the device to. The number of pins depends on the
protocol. ``*_open_device`` opens a specific device and can be passed
either the base address of the controller or the index as defined by the
BSP. ``*_close`` is used to release a handle.

GPIO Devices
------------

GPIO devices allow for one or multiple pins to be read and written
directly. All of these functions are in ``gpio.h``

``gpio`` type
~~~~~~~~~~~~~~~~

A handle to one or more pins which can be set simultaneously.

``gpio gpio_open(int pin)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Returns a new handle to a GPIO device for a specific pin on the I/O
switch. This function can only be called if there is an I/O switch in
the design.

``gpio gpio_open_device(unsigned int device)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Returns a handle to an AXI GPIO controller based either on the base
address or device index. The handle will allow for all pins on channel 1
to be set simultaneously.

``gpio gpio_configure(gpio parent, int low, int hi, int channel)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Returns a new handle tied to the specified pins of the controller. This
function does not change the configuration of the parent handle.

``void gpio_set_direction(gpio device, int direction)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Sets the direction of all pins tied to the specified handle. The
direction can either be ``GPIO_IN`` or ``GPIO_OUT``.

``void gpio_write(gpio device, unsigned int value)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Sets the value of the output pins represented by the handle. If the
handle represents multiple pins then the least significant bit refers to
the lowest index pin. Writing to pins configured as input has no effect.

``unsigned int gpio_read(gpio device)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Reads the value of input pins represented by the handle, If the handle
represents multiple pins then the least significant bit refers to the
lowest index pin. Read from pins configured as output results in 0 being
returned.

``void gpio_close(gpio_device)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Returns the specified pins to high-impedance output and closes the
device.

I2C Devices
-----------

The I2C driver is designed for master operation only and provides
interfaces to read and write from a slave device. All of these functions
are in ``i2c.h``.

``i2c`` type
~~~~~~~~~~~~

Represents an I2C master. It is possible for multiple handles to
reference the same master device.

``i2c i2c_open(int sda, int scl)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Open an I2C device attached to an I/O switch configured to use the
specified pins. Calling this function will disconnect any previously
assigned pins and return them to a high-impedance state.

``i2c i2c_open_device(unsigned int device)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Open an I2C master by base address or ID

``void i2c_read(i2c dev_id, unsigned int slave_address, unsigned char* buffer, unsigned int length)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Issue a read command to the specified slave. ``buffer`` is an array
allocated by the caller of at least length ``length``.

``void i2c_write(i2c dev_id, unsigned int slave_address, unsigned char* buffer, unsigned int length)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Issue a write command to the specified slave.

``void i2c_close(i2c dev_id)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Close the I2C device.

SPI Devices
-----------

SPI operates on a synchronous transfer of data so rather than read and
write, only a ``transfer`` function is provided. These functions are all
provided by ``spi.h``.

``spi`` type
~~~~~~~~~~~~

Handle to a SPI master.

``spi spi_open(unsigned int spiclk, unsigned int miso, unsigned int mosi, unsigned int ss)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Opens a SPI master on the specified pins. If a pin is not needed for a
device, ``-1`` can be passed in to leave it unconnected.

``spi spi_open_device(unsigned int device)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Opens a SPI master by base address or device ID.

``spi spi_configure(spi dev_id, unsigned int clk_phase, unsigned int clk_polarity)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Configures the SPI master with the specified clock phase and polarity.
These settings are global to all handles to a SPI master.

``void spi_transfer(spi dev_id, const char* write_data, char* read_data, unsigned int length);``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Transfer bytes to and from the SPI slave. Both ``write_data`` and
``write_data`` should be allocated by the caller and NULL. Buffers
should be at least of length ``length``.

``void spi_close(spi dev_id)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Closes a SPI master

Timer Devices
-------------

Timer devices serve two purposes. They can either be used to output PWM
signals or as program timers for inserting accurate delays. It is not
possible to use these functions simultaneously and attempting to ``delay``
while PWM is in operation will result in undefined behavior. All of these
functions are in ``timer.h``.

``timer`` type
~~~~~~~~~~~~~~

Handle to an AXI timer

``timer timer_open(unsigned int pin)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Open an AXI timer attached to the specified pin

``timer timer_open_device(unsigned int device)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Open an AXI timer by address or device ID

``void timer_delay(timer dev_id, unsigned int cycles)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Delay the program by a specified number of cycles

``void timer_pwm_generate(timer dev_id, unsigned int period, unsigned int pulse)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Generate a PWM signal using the specified timer

``void timer_pwm_stop(timer dev_id)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Stop the PWM output

``void timer_close(timer dev_id)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Close the specified timer

``void delay_us(unsigned int us)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Delay the program by a number of microseconds using the default delay
timer (timer index 0).

``void delay_ms(unsigned int ms)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Delay the program by a number of milliseconds using the default delay
timer (timer index 0).

UART Devices
------------

This device driver controls a UART master.

``uart type``
~~~~~~~~~~~~~

Handle to a UART master device.

``uart uart_open(unsigned int tx, unsigned int rx)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Open a UART device on the specified pins

``uart uart_open_device(unsigned int device)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Open a UART device by base address or index

``void uart_read(uart dev_id, char* read_data, unsigned int length)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Read a fixed length of data from the UART

``void uart_write(uart dev_id, char* write_data, unsigned int length)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write a block of data to the UART.

``void uart_close(uart dev_id)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Close the handle.
