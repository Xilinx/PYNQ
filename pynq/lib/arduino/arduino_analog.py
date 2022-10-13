#   Copyright (c) 2016-2020, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import numpy as np
from . import Arduino
from . import MAILBOX_OFFSET
from . import ARDUINO_NUM_ANALOG_PINS




ARDUINO_ANALOG_PROGRAM = "arduino_analog.bin"
ARDUINO_ANALOG_LOG_START = MAILBOX_OFFSET+16
ARDUINO_MAX_SAMPLES = 1018
CONFIG_IOP_SWITCH = 0x1
GET_RAW_DATA = 0x3
READ_AND_LOG_RAW = 0x7
RESET_ANALOG = 0xB
V_Conv = 3.33 / 65536


class Arduino_Analog(object):
    """This class controls the Arduino Analog. 
    
    XADC is an internal analog controller in the hardware. This class
    provides API to do analog reads from IOP.
    
    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.
    log_running : int
        The state of the log (0: stopped, 1: started).
    log_interval_ms : int
        Time in milliseconds between samples on the same channel.
    gr_pin : list
        A group of pins on arduino-grove shield.
    num_channels : int
        The number of channels sampled.

    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Arduino_Analog object. 
        
        Note
        ----
        The parameter `gr_pin` is a list of analog pins enabled.
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on arduino-grove shield.
            
        """
        for pin in gr_pin:
            if pin not in range(ARDUINO_NUM_ANALOG_PINS):
                raise ValueError("Analog pin number can only be 0 - {}."
                                 .format(ARDUINO_NUM_ANALOG_PINS-1))

        self.microblaze = Arduino(mb_info, ARDUINO_ANALOG_PROGRAM)
        self.log_interval_ms = 1000
        self.log_running = 0
        self.gr_pin = gr_pin
        self.num_channels = len(gr_pin)
        # Calculate the offset address of the end of the log
        self._samples_channel = ARDUINO_MAX_SAMPLES // self.num_channels
        self._log_end = ARDUINO_ANALOG_LOG_START + 4 * self.num_channels * \
                        self._samples_channel


        # Enable all the analog pins
        data = [0 for _ in range(ARDUINO_NUM_ANALOG_PINS)]
        self.microblaze.write_mailbox(0, data)
        
        # Write configuration and wait for ACK
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def read(self,  out_format = 'voltage'):
        """Read the shared mailbox memory with the adc raw value
         from the analog peripheral.

        Parameters
        ----------
        out_format : str
            Selects the return type, either 'raw' or 'voltage'
        
        Returns
        -------
        list
            Either the 'raw' values or 'voltage' depending on out_format
        
        """
        if out_format not in ['raw', 'voltage']:
            raise ValueError("out_format can only be 'raw' or 'voltage'")
            
        data_channels = 0
        for channel in self.gr_pin:
            data_channels |= (0x1 << channel)
        cmd = (data_channels << 8) + GET_RAW_DATA
        self.microblaze.write_blocking_command(cmd)

        reading = np.asarray(\
            self.microblaze.read_mailbox(0, self.num_channels))
        
        if out_format == 'raw':
            return reading
        else:
            return reading * V_Conv
        
    def set_log_interval_ms(self, log_interval_ms):
        """Set the length of the log for the analog peripheral.
        
        This method can set the time interval between two samples, so that 
        users can read out multiple values in a single log. 
        
        Parameters
        ----------
        log_interval_ms : int
            The time between two samples in milliseconds, for logging only.
            
        Returns
        -------
        None
        
        """
        if not isinstance(log_interval_ms, int):
            raise ValueError("Time between samples should be integer.")
        elif log_interval_ms < 0:
            raise ValueError("Time between samples should be no less than 0.")
        
        self.log_interval_ms = log_interval_ms
        self.microblaze.write_mailbox(4, log_interval_ms)

    def start_log(self):
        """Start recording multiple analog samples (raw) values in a log.
        
        This method will first call set_log_interval_ms() before writing to
        the MMIO.
            
        Returns
        -------
        None
        
        """
        self.log_running = 1
        self.set_log_interval_ms(self.log_interval_ms)

        data_channels = 0
        for channel in self.gr_pin:
            data_channels |= (0x1 << channel)
        cmd = (data_channels << 8) + READ_AND_LOG_RAW
        self.microblaze.write_non_blocking_command(cmd)

    def stop_log(self):
        """Stop recording the raw values in the log.
        
        Simply write 0xC to the MMIO to stop the log.
            
        Returns
        -------
        None
        
        """
        if self.log_running == 1:
            self.microblaze.write_non_blocking_command(RESET_ANALOG)
            self.log_running = 0
        else:
            raise RuntimeError("No analog log running.")
            
    def get_log(self, out_format = 'voltage'):
        """Return list of logged raw samples.

        Parameters
        ----------
        out_format : str
            Selects the return type, either 'raw' or 'voltage'

        Returns
        -------
        Numpy Array
            Numpy array of valid samples from the analog device, 
            either 'raw' or 'voltage'
        
        """
        # Stop logging
        self.stop_log()

        if out_format not in ['raw', 'voltage']:
            raise ValueError("out_format can only be 'raw' or 'voltage'")

        # Prep iterators and results list
        [head_ptr, tail_ptr] = self.microblaze.read_mailbox(0x8, 2)
        readings = []
        for _ in range(self.num_channels):
            readings.append([])

        # Sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr, tail_ptr, 4*self.num_channels):
                raw = np.atleast_1d(self.microblaze.read(i, self.num_channels))
                for j in range(self.num_channels):
                    readings[j].append(raw[j])
        else:
            for i in range(head_ptr, self._log_end, 4*self.num_channels):
                raw = np.atleast_1d(self.microblaze.read(i, self.num_channels))
                for j in range(self.num_channels):
                    readings[j].append(raw[j])

            for i in range(ARDUINO_ANALOG_LOG_START, tail_ptr,
                           4*self.num_channels):
                raw = np.atleast_1d(self.microblaze.read(i, self.num_channels))
                for j in range(self.num_channels):
                    readings[j].append(raw[j])
        
        readings_arr = np.asarray(readings)
        
        if out_format == 'raw':
            return readings_arr
        else:
            return readings_arr * V_Conv

        
    def reset(self):
        """Resets the system monitor for analog devices.
            
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(RESET_ANALOG)

    def read_raw(self):
        """Read the analog raw value from the analog peripheral.
        
        Returns
        -------
        list
            The raw values from the analog device.
        
        """        
        return self.read('raw')

    def get_log_raw(self):
        """Return list of logged raw samples.
            
        Returns
        -------
        list
            List of valid raw samples from the analog device.
        
        """        
        return self.get_log('raw')

    def stop_log_raw(self):
        """Stop recording the raw values in the log.
        
        Simply write 0xC to the MMIO to stop the log.
            
        Returns
        -------
        None
        
        """        
        self.stop_log()

    def start_log_raw(self):
        """Start recording raw data in a log.
        
        This method will first call set_log_interval_ms() before writing to
        the MMIO.
            
        Returns
        -------
        None
        
        """        
        self.start_log()


