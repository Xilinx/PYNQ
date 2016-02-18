"""This module exposes API to manage XGPIO interfaces."""


__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Yun Rock Qu"
__email__       = "yunq@xilinx.com"


from . import _iop
from .devmode import DevMode

class XGPIO(object):
    """ Return a new instance of a XGPIO object. It might raise an exception 
        as the *force* flag is not set when calling request_iop() in 
        DevMode initialization. 
        Refer to _iop.request_iop() for additional details.
        1.  The parameter 'direction' determines whether the instance is GP
            input or output
            direction = 0 -> output; sending output from onchip to offchip
            direction = 1 -> input; receiving input from offchip to onchip; 
            NOTE: IOCFG_XGPIO_OUTPUT = 0; IOCFG_XGPIO_INPUT  = 1
        2.  The parameter 'cable' decides whether the cable connecting 2 PMODS
            is a "loop-back" or "straight" cable 
            NOTE: XGPIO_CABLE_STRAIGHT = 0; XGPIO_CABLE_LOOPBACK = 1
            The default is a loop-back cable.
    """
    def __init__(self, pmod_id, index, direction): 
        if (pmod_id not in _iop.IOP_CONSTANTS):
            raise ValueError("Valid PMOD IDs are: 1, 2, 3, 4")
        if (index not in _iop.IOP_SWCFG_XGPIOALL):
            raise ValueError("Valid pin indexes are 0 - 7")
        if (direction not in (0,1)):
            raise ValueError("direction can only be 0 (output), or 1 (input)")
        self.iop = DevMode(pmod_id, _iop.IOP_SWCFG_XGPIOALL) 
        self.iop_id = pmod_id
        self.index = index
        self.direction = direction
        self.cable = _iop.XGPIO_CABLE_LOOPBACK
     
        if self.iop.status()[0] != 'RUNNING':
            self.iop.start()
            if (self.direction == _iop.IOCFG_XGPIO_INPUT):
                self.iop.write_cmd(_iop.IOPMM_XGPIO_BASEADDR+
                                   _iop.IOPMM_XGPIO_TRI_OFFSET,
                                   _iop.IOCFG_XGPIO_ALLINPUT)
            else:
                self.iop.write_cmd(_iop.IOPMM_XGPIO_BASEADDR+
                                   _iop.IOPMM_XGPIO_TRI_OFFSET,
                                   _iop.IOCFG_XGPIO_ALLOUTPUT)
                                                                        
        # Set switch to XGPIOALL (mailbox.bin was used previously 
        #                        with non-LED8 PMOD)
        self.iop.load_switch_config()    
    
    def set(self,val):
        if not self.direction is _iop.IOCFG_XGPIO_OUTPUT:
            raise ValueError('XGPIO used as output, while declared as input')
        if not val in (0,1):
            raise ValueError("XGPIO can only write 0 or 1")
        """ Set the value of a single XGPIO pin."""
        if val:
            self.set1()
        else:
            self.set0()

    def set1(self):
        """ Set the value of a single XGPIO pin to 1."""
        currVal = self.iop.read_cmd(_iop.IOPMM_XGPIO_BASEADDR+
                                    _iop.IOPMM_XGPIO_DATA_OFFSET)
        newVal = currVal | (0x1<<self.index)
        self.iop.write_cmd(_iop.IOPMM_XGPIO_BASEADDR + 
                           _iop.IOPMM_XGPIO_DATA_OFFSET, newVal)
     
    def set0(self):
        """Set the value of a single XGPIO pin to 0."""
        currVal = self.iop.read_cmd(_iop.IOPMM_XGPIO_BASEADDR+
                                    _iop.IOPMM_XGPIO_DATA_OFFSET)
        newVal = currVal & (0xff ^ (0x1<<self.index))
        self.iop.write_cmd(_iop.IOPMM_XGPIO_BASEADDR + 
                           _iop.IOPMM_XGPIO_DATA_OFFSET, newVal)
                           
    def setCable(self, cable):
        """ Set the cable type for the PMOD XGPIOs

        Note
        ----------
        Should not be used for receiving a raw value.
        This function should only be used with a "straight" cable.
       
        Arguments
        ----------
        None
        """
        if (cable==_iop.XGPIO_CABLE_STRAIGHT):
            self.cable = _iop.XGPIO_CABLE_STRAIGHT
        elif (cable==_iop.XGPIO_CABLE_LOOPBACK):
            self.cable = _iop.XGPIO_CABLE_LOOPBACK
        else:
            self.cable = _iop.XGPIO_CABLE_LOOPBACK
            print("Cable unrecognizable. Use loopback cable by default.")
    
    def write(self, value): 
        """ Send the value to the offboard XGPIO device

        Note
        ----------
        Only use this function when direction = 0
        
        Arguments
        ----------
        value (int) : The total value of all the pins on the same pmod
        """
        if not value in (0,1):
            raise ValueError("XGPIO can only write 0 or 1")
        if not self.direction is _iop.IOCFG_XGPIO_OUTPUT:
            raise ValueError('XGPIO used as output, while declared as input')
        self.set(value)
        
    def read_raw(self):
        """ Receive the raw value from the offboard XGPIO device

        Note
        ----------
        Should not be used directly. User should rely on read() instead
        Only use this function when direction = 1
        
        Arguments
        ----------
        None
        """
        if not self.direction is _iop.IOCFG_XGPIO_INPUT:
            raise ValueError('XGPIO used as input, while declared as output') 
        return self.iop.read_cmd(_iop.IOPMM_XGPIO_BASEADDR+
                                 _iop.IOPMM_XGPIO_DATA_OFFSET) 

    def read(self):
        """ Receive the value from the offboard XGPIO device

        Note
        ----------
        Should not be used for receiving a raw value.
        For any received raw value, a "straignt" cable (self.cable = 0) flips
        the upper 4 pins and bottom 4 pins:
        {vdd,gnd,0,1,2,3}      <=>      {vdd,gnd,4,5,6,7}
        {vdd,gnd,4,5,6,7}      <=>      {vdd,gnd,0,1,2,3}
        A "loop-back" cable (self.cable = 1) satisfies the following mapping 
        between two PMODS:
        {vdd,gnd,0,1,2,3}      <=>      {vdd,gnd,0,1,2,3}
        {vdd,gnd,4,5,6,7}      <=>      {vdd,gnd,4,5,6,7}
        
        Arguments
        ----------
        None
        """  
        if self.cable==_iop.XGPIO_CABLE_STRAIGHT:
            if (self.index < 4):
                return (self.read_raw() >> (self.index+4)) & 0x1
            else:
                return (self.read_raw() >> (self.index-4)) & 0x1
        else:
                return (self.read_raw() >> (self.index)) & 0x1
