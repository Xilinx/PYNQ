#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from . import Grove_ADC




def _int2r(val):
    """Convert the integer value to the light sensor resistance.

    This method should only be used internally.

    Note
    ----
    A smaller returned value indicates a higher brightness. Resistance 
    value ranges from 5.0 (brightest) to 35.0 (darkest).

    Parameters
    ----------
    val : int
        The raw data read from grove ADC.

    Returns
    -------
    float
        The light sensor resistance indicating the light intensity.

    """
    if 0 < val <= 4095:
        r_sensor = (4095.0 - val) * 10 / val
    else:
        raise RuntimeError("Value out of range or device not connected.")
    return float("{0:.2f}".format(r_sensor))


class Grove_Light(Grove_ADC):
    """This class controls the grove light sensor.
    
    This class inherits from the Grove_ADC class. To use this module, grove 
    ADC has to be used as a bridge. The light sensor incorporates a Light 
    Dependent Resistor (LDR) GL5528. Hardware version: v1.1.
    
    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.
    log_running : int
        The state of the log (0: stopped, 1: started).
    log_interval_ms : int
        Time in milliseconds between sampled reads.
    
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove ADC object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on arduino-grove shield.
            
        """
        super().__init__(mb_info, gr_pin)

    def read(self):
        """Read the light sensor resistance in from the light sensor.

        This method overrides the definition in grove ADC.

        Returns
        -------
        float
            The light reading in terms of the sensor resistance.

        """
        val = super().read_raw()
        return _int2r(val)

    def start_log(self):
        """Start recording the light sensor resistance in a log.

        This method will call the start_log_raw() in the parent class.

        Returns
        -------
        None

        """
        super().start_log_raw()

    def get_log(self):
        """Return list of logged light sensor resistances.

        Returns
        -------
        list
            List of valid light sensor resistances.

        """
        r_log = super().get_log_raw()
        return [_int2r(i) for i in r_log]

    def stop_log(self):
        """Stop recording light values in a log.

        This method will call the stop_log_raw() in the parent class.

        Returns
        -------
        None

        """
        super().stop_log_raw()


