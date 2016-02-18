"""This module exposes API to control an I/O Processor in Development Mode. 
The IOP is in loop waiting for user to send commands to XGPIO, IIC, or 
SPI I/O on a single PMOD.
"""

__author__      = "Graham Schelle, Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.1"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


import time
from . import _iop
from pyxi import MMIO

PROGRAM = "mailbox.bin"

class DevMode(object):
    """Control an I/O Processor running the Developer Mode executable - waiting 
    for Python to send I/O commands to XGPIO, IIC or SPI I/O.

    Arguments
    ----------
    pmod_id (int)           : Id of the PMOD to which the I/O Processor will be 
                              attached to
    switch_config (list)     : I/O Processor switch configuration 
                              ( list of 8 32bit values )

    Attributes
    ----------
    iop                     : I/O Processor instance used by DevMode
    iop_id (int)            : From argument *pmod_id*
    iop_switch_config (list): From argument *switch_config*
    mmio (MMIO)             : Memory-mapped I/O instance needed to read 
                              and write instructions and data.
    program (str)           : Current executable running.
    """

    def __init__(self, pmod_id, switch_config):
        """Return a new instance of a DevMode object. It might raise an 
        exception as the *force* flag is not set when calling request_iop(). 
        Refer to _iop.request_iop() for additional details.
        """
        self.iop = _iop.request_iop(pmod_id, PROGRAM)
        self.iop_switch_config = list(switch_config)
        self.iop_id = pmod_id
        self.mmio = MMIO(_iop.IOP_CONSTANTS[pmod_id]['address'] + 
                         _iop.MAILBOX_OFFSET, _iop.MAILBOX_SIZE>>2) 
        self.program = PROGRAM

    def __repr__(self):
        return "DevMode()"
    
    def __str__(self):
        return """ DeveloperMode instance on PMOD #{id}
                    Executable: {program}
                    Status:     {status}
                    Switch:     {switch}
               """.format(id = str(self.iop_id),
                          program = self.program,
                          status = str(self.get_status()[0]),
                          switch = str(self.iop_switch_config))
     
    def start(self):
        """Enable the I/O Processor:
            1. start I/O Processor
            2. zero out mailbox CMD register
            2. load switch config (if one specified with iopDeveloper class
            3. set status as running
        """
        self.iop.start()
        # Zero-out cmd mailbox
        self.mmio.write(_iop.MAILBOX_PY2IOP_CMDCMD_OFFSET, 0)
        self.load_switch_config()   

    def stop(self):
        """Put the I/O Processor into Reset."""
        self.iop.stop()        

    #######################
    # IOP Config Commands #
    ####################### 
    def load_switch_config(self, config=None):
        """Load the I/O Processor's Switch Configuration 

        Arguments
        ----------
        config (List) : Default:None - Will update switch config first if 
                        supplied ( list of 8 32bit values ). Otherwise, will 
                        configure switch with DevMode.iop_switch_config 

        Raises
        ----------
        TypeError     : If the config argument is not of the correct type.
        """
        if config:
            if len(config) != _iop.IOPMM_SWITCHCONFIG_NUMREGS:
                raise TypeError('User supplied switch config is not a ' +
                        'list of 8 integers. Switch will not be configured.' + 
                        '\nReceived config=' + str(config))
            self.iop_switch_config = config

        # build switch config word 
        sw_config_word = 0
        for ix, cfg in enumerate(self.iop_switch_config): 
            sw_config_word |= (cfg << ix*4)

        #print("SwitchConfig word: " + str(hex(sw_config_word)))

        # disable, configure, enable switch
        self.write_cmd(_iop.IOPMM_SWITCHCONFIG_BASEADDR + 4, 0)
        self.write_cmd(_iop.IOPMM_SWITCHCONFIG_BASEADDR, sw_config_word)
        self.write_cmd(_iop.IOPMM_SWITCHCONFIG_BASEADDR + 7, 0x80, dWidth=1)     


    def get_switch_config(self):
        """Print the I/O Processor's Switch Configuration."""
        sw_config = list()
        for ix, cfg in enumerate(self.iop_switch_config):
            sw_config.append(self.read_cmd(_iop.IOPMM_switch_config_BASEADDR + 
                             ix*4, dWidth=1))
        print(str(sw_config))

    def status(self):
        return self.iop.status()

    ##########################
    # Mailbox RD/WR Commands #
    ##########################        
    def write_cmd(self, address, data, dWidth=4, dLength=1, timeout=20):
        return self._send_cmd(_iop.WRITE_CMD, address, data, dWidth=dWidth, 
                              timeout=timeout)

    def read_cmd(self, address, dWidth=4, dLength=1, timeout=10):        
        return self._send_cmd(_iop.READ_CMD, address, None, dWidth=dWidth, 
                              timeout=timeout)


    def is_cmd_mailbox_idle(self): 
        """Return true if IOP Mailbox Command API idle."""
        mb_cmd_word = self.mmio.read(_iop.MAILBOX_PY2IOP_CMDCMD_OFFSET)
        return (mb_cmd_word & 0x1) == 0

    def is_cmd_valid(self, cmd, address, data, dWidth, dLength, timeout):
        """Check if cmd is valid across all the arguments."""
        return True # TODO: update it to be meaningful, or remove this method

    def get_cmd_word(self, cmd, dWidth, dLength):
        word = 0x1                    # cmd Valid
        word = word | (dWidth-1) << 1 # cmd DataWidth   (4B->3, 2B->1, 1B->0)
        word = word | (cmd) << 3      # cmd type        (RD:1 or WR:0)
        word = word | (dLength) << 8  # cmd BurstLength (dLength->BurstLength)
 
        word = word | (0) << 16       # explicit set to 0
              
        return word


    def _send_cmd(self, cmd, address, data, dWidth=4, dLength=1, timeout=10):
        """Send a command to the I/O Processor via mailbox.

        Arguments
        ----------        
        cmd (int)       : 1 Read IOP Reg | 0 Write IOP Reg
        address (int)   : tied to I/O Processo's memory map (need to write 
                          out the map)
        data (int)      : 32bit value that will be written (set data to 
                          None for Read)
        timeout (int)   : Default:10. Time in milliseconds before function 
                          exits with warning

        Typical usage:
            User should avoid to call this method directly. 
            Use the readRegCmd() or writeRegCmd() calls instead.

        Example:
            >>> _send_cmd(0, 4, None)  # Read address 4.
        """
        self.mmio.write(_iop.MAILBOX_PY2IOP_CMDADDR_OFFSET, address)
        if data != None:
            self.mmio.write(_iop.MAILBOX_PY2IOP_CMDDATA_OFFSET, data)
        
        # Build and Write Command
        cmd_word = self.get_cmd_word(cmd, dWidth, dLength)

        self.mmio.write(_iop.MAILBOX_PY2IOP_CMDCMD_OFFSET, cmd_word)

        # Wait for ACK
        cntdown = timeout
        while not self.is_cmd_mailbox_idle() and cntdown > 0:
            time.sleep(0.001) # wait for 1ms
            cntdown -= 1

        # If did not receive ACK, alert user.
        if cntdown == 0:
            print("DevMode::_send_cmd() - Warning: CMD Not Acknowledged " + 
                  "after " + str(timeout) + "ms (PMOD #" + 
                  str(self.iop_id) + ")")

        # Return data if expected from Read, otherwise return None
        if cmd == _iop.WRITE_CMD: 
            return None
        else:
            # Return Read Data  (Currently only supporting dLength==1)
            return self.mmio.read(_iop.MAILBOX_PY2IOP_CMDDATA_OFFSET) 
