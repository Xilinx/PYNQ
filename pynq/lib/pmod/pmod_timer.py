#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from pynq import Clocks
from . import Pmod



PMOD_TIMER_PROGRAM = "pmod_timer.bin"
CONFIG_IOP_SWITCH = 0x1
STOP_TIMER = 0x3
GENERATE_FOREVER = 0x5
GENERATE_N_TIMES = 0x7
EVENT_OCCURED = 0x9
COUNT_EVENTS = 0xB
MEASURE_PERIOD = 0xD


class Pmod_Timer(object):
    """This class uses the timer's capture and generation capabilities.

    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    clk_period_ns : int
        The clock period of the IOP in ns.

    """

    def __init__(self, mb_info, index):
        """Return a new instance of an Pmod_Timer object.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        index : int
            The specific pin that runs timer.

        """
        self.microblaze = Pmod(mb_info, PMOD_TIMER_PROGRAM)
        self.clk_period_ns = int(1000 / Clocks.fclk0_mhz)

        # Write PWM pin config
        self.microblaze.write_mailbox(0, index)

        # Write configuration and wait for ACK
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def stop(self):
        """This method stops the timer.

        Returns
        -------
        None

        """
        self.microblaze.write_blocking_command(STOP_TIMER)

    def generate_pulse(self, period, times=0):
        """Generate pulses every (period) clocks for a number of times.

        The default is to generate pulses every (period) IOP clocks forever
        until stopped. The pulse width is equal to the IOP clock period.

        Parameters
        ----------
        period : int
            The period of the generated signals.
        times : int
            The number of times for which the pulses are generated.

        Returns
        -------
        None

        """
        if times == 0:
            # Generate pulses forever
            if period not in range(3, 4294967296):
                raise ValueError("Valid period is between 3 and 4294967296.")
            self.microblaze.write_mailbox(0, period)
            self.microblaze.write_blocking_command(GENERATE_FOREVER)
        elif 1 <= times < 255:
            # Generate pulses for a certain times
            if period not in range(3, 16777217):
                raise ValueError("Valid period is between 3 and 16777217.")
            self.microblaze.write_mailbox(0, ((period - 2) << 8) | times)
            self.microblaze.write_blocking_command(GENERATE_N_TIMES)
        else:
            raise ValueError("Valid number of times is between 1 and 255.")

    def event_detected(self, period):
        """Detect a rising edge or high-level in (period) clocks.

        Parameters
        ----------
        period : int
            The period of the generated signals.

        Returns
        -------
        int
            1 if any event is detected, and 0 if no event is detected.

        """
        if period not in range(52, 4294967296):
            raise ValueError("Valid period is between 52 and 4294967296.")
        self.microblaze.write_mailbox(0, period - 2)
        self.microblaze.write_blocking_command(EVENT_OCCURED)
        detected = self.microblaze.read_mailbox(0)
        return detected

    def event_count(self, period):
        """Count the number of rising edges detected in (period) clocks.

        Parameters
        ----------
        period : int
            The period of the generated signals.

        Returns
        -------
        int
            The number of events detected.

        """
        if period not in range(52, 4294967297):
            raise ValueError("Valid period is between 52 and 4294967297.")
        self.microblaze.write_mailbox(0, period - 2)
        self.microblaze.write_blocking_command(COUNT_EVENTS)
        count = self.microblaze.read_mailbox(0)
        return count

    def get_period_ns(self):
        """Measure the period between two successive rising edges.

        Returns
        -------
        int
            Measured period in ns.

        """
        self.microblaze.write_blocking_command(MEASURE_PERIOD)
        count = self.microblaze.read_mailbox(0)
        return count * self.clk_period_ns


