
__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"

import os
import sys
import math
from pyxi import MMIO,GPIO,OVERLAY
import mmap

ol = OVERLAY()
ol.add_bitstream('pmod.bit')
#########################
# IOP mailbox constants #
#########################
# bin program size in bytes
MAILBOX_OFFSET = 0x7000
MAILBOX_SIZE   = 0x1000

MAILBOX_PY2IOP_CMDCMD_OFFSET  = 0xffc
MAILBOX_PY2IOP_CMDADDR_OFFSET = 0xff8
MAILBOX_PY2IOP_CMDDATA_OFFSET = 0xf00

# IOP mailbox commands
READ_CMD  = 1
WRITE_CMD = 0

IOP_MMIO_REGSIZE = 0x8000


#########################
# IOP memory map        #
#########################

# IOP Switch Register Map
IOPMM_SWITCHCONFIG_BASEADDR    = int(ol.get_mmio_base('pmod.bit',\
                                    'PMOD_IO_Switch_IP'),16)
IOPMM_SWITCHCONFIG_IO_0_OFFSET = 0
IOPMM_SWITCHCONFIG_IO_1_OFFSET = 4
IOPMM_SWITCHCONFIG_IO_2_OFFSET = 8
IOPMM_SWITCHCONFIG_IO_3_OFFSET = 12
IOPMM_SWITCHCONFIG_IO_4_OFFSET = 16
IOPMM_SWITCHCONFIG_IO_5_OFFSET = 20
IOPMM_SWITCHCONFIG_IO_6_OFFSET = 24
IOPMM_SWITCHCONFIG_IO_7_OFFSET = 28
IOPMM_SWITCHCONFIG_NUMREGS     = 8

# Each PMOD Pin can be tied to XGPIO,SPI,IIC pins... enumerate here
IOP_SWCFG_XGPIO0 = 0
IOP_SWCFG_XGPIO1 = 1
IOP_SWCFG_XGPIO2 = 2
IOP_SWCFG_XGPIO3 = 3
IOP_SWCFG_XGPIO4 = 4
IOP_SWCFG_XGPIO5 = 5
IOP_SWCFG_XGPIO6 = 6
IOP_SWCFG_XGPIO7 = 7

IOP_SWCFG_IIC0_SDA = 0xa
IOP_SWCFG_IIC0_SCL = 0x8

IOP_SWCFG_IIC1_SDA = 0xb
IOP_SWCFG_IIC1_SCL = 0x9

# SWITCH Config - All XGPIOs
IOP_SWCFG_XGPIOALL = [IOP_SWCFG_XGPIO0,IOP_SWCFG_XGPIO1,IOP_SWCFG_XGPIO2, 
                     IOP_SWCFG_XGPIO3,IOP_SWCFG_XGPIO4,IOP_SWCFG_XGPIO5, 
                     IOP_SWCFG_XGPIO6,IOP_SWCFG_XGPIO7]

# SWITCH Config - IIC0, Top Row
IOP_SWCFG_IIC0_TOPROW = [IOP_SWCFG_XGPIO0,IOP_SWCFG_XGPIO1,IOP_SWCFG_IIC0_SCL, 
                         IOP_SWCFG_IIC0_SDA,IOP_SWCFG_XGPIO2,IOP_SWCFG_XGPIO3, 
                         IOP_SWCFG_XGPIO4,IOP_SWCFG_XGPIO5]

# SWITCH Config - IIC0, Bottom Row
IOP_SWCFG_IIC0_BOTTOMROW = [IOP_SWCFG_XGPIO0,IOP_SWCFG_XGPIO1,IOP_SWCFG_XGPIO2, 
                            IOP_SWCFG_XGPIO3,IOP_SWCFG_XGPIO4,IOP_SWCFG_XGPIO5, 
                            IOP_SWCFG_IIC0_SCL,IOP_SWCFG_IIC0_SDA]

# IIC Register Map
IOPMM_XIIC_0_BASEADDR       = int(ol.get_mmio_base('pmod.bit','iic'),16)
IOPMM_XIIC_DGIER_OFFSET     = 0x1C
IOPMM_XIIC_IISR_OFFSET      = 0x20
IOPMM_XIIC_IIER_OFFSET      = 0x28
IOPMM_XIIC_RESETR_OFFSET    = 0x40
IOPMM_XIIC_CR_REG_OFFSET    = 0x100
IOPMM_XIIC_SR_REG_OFFSET    = 0x104
IOPMM_XIIC_DTR_REG_OFFSET   = 0x108
IOPMM_XIIC_DRR_REG_OFFSET   = 0x10C
IOPMM_XIIC_ADR_REG_OFFSET   = 0x110
IOPMM_XIIC_TFO_REG_OFFSET   = 0x114
IOPMM_XIIC_RFO_REG_OFFSET   = 0x118
IOPMM_XIIC_TBA_REG_OFFSET   = 0x11C
IOPMM_XIIC_RFD_REG_OFFSET   = 0x120
IOPMM_XIIC_GPO_REG_OFFSET   = 0x124

# SPI Register Map
IOPMM_SPI_0_BASEADDR        = int(ol.get_mmio_base('pmod.bit','spi'),16)
IOPMM_XSP_DGIER_OFFSET      = 0x1C
IOPMM_XSP_IISR_OFFSET       = 0x20
IOPMM_XSP_IIER_OFFSET       = 0x28
IOPMM_XSP_SRR_OFFSET        = 0x40
IOPMM_XSP_CR_OFFSET         = 0x60
IOPMM_XSP_SR_OFFSET         = 0x64
IOPMM_XSP_DTR_OFFSET        = 0x68
IOPMM_XSP_DRR_OFFSET        = 0x6C
IOPMM_XSP_SSR_OFFSET        = 0x70
IOPMM_XSP_TFO_OFFSET        = 0x74
IOPMM_XSP_RFO_OFFSET        = 0x78

# XGPIO Register Map
IOPMM_XGPIO_BASEADDR        = int(ol.get_mmio_base('pmod.bit','gpio'),16)
IOPMM_XGPIO_DATA_OFFSET     = 0x0
IOPMM_XGPIO_TRI_OFFSET      = 0x4
IOPMM_XGPIO_DATA2_OFFSET    = 0x8
IOPMM_XGPIO_TRI2_OFFSET     = 0xC
IOPMM_XGPIO_GIE_OFFSET      = 0x11C
IOPMM_XGPIO_ISR_OFFSET      = 0x120
IOPMM_XGPIO_IER_OFFSET      = 0x128

IOCFG_XGPIO_OUTPUT = 0
IOCFG_XGPIO_INPUT  = 1

IOCFG_XGPIO_ALLOUTPUT = 0x0
IOCFG_XGPIO_ALLINPUT  = 0xff

# XGPIO CABLE TYPE
XGPIO_CABLE_STRAIGHT   = 0
XGPIO_CABLE_LOOPBACK   = 1

#########################
# IOP handlers          #
#########################
IOP_CONSTANTS = {
    1:{
        "address" : int(ol.get_mmio_base('pmod.bit','axi_bram_ctrl_1'),16),
        "emioPin": ol.get_gpio_base() + 54
    },
    2:{
        "address" : int(ol.get_mmio_base('pmod.bit','axi_bram_ctrl_2'),16),
        "emioPin": ol.get_gpio_base() + 55
    },
    3:{
        "address" : int(ol.get_mmio_base('pmod.bit','axi_bram_ctrl_3'),16),
        "emioPin": ol.get_gpio_base() + 56
    },
    4: {
        "address" : int(ol.get_mmio_base('pmod.bit','axi_bram_ctrl_4'),16),
        "emioPin": ol.get_gpio_base() + 57
    },      
}

IOP_INSTANCES = {
    1:None,
    2:None,
    3:None,
    4:None  
}

bin_location = '/home/xpp/src/pyxi/python/pyxi/pmods/'

class _IOP:
    """Class controls the number of active IOP instances in the system."""

    def __init__(self, iop_id, program='mailbox.bin'):
        self.pmod_id = iop_id
        self.program = program
        self.state = 'IDLE'
        self.gpio = GPIO(IOP_CONSTANTS[self.pmod_id]['emioPin'],'out')
        
        # reset microblaze
        self.stop()

        try:
            bitf = open(bin_location + self.program, 'rb')
        except IOError:
            print('cannot open', bin_location + self.program)

        size = (math.ceil(os.fstat(bitf.fileno()).st_size/ \
                mmap.PAGESIZE))*(mmap.PAGESIZE>>2)
        self.mmio = MMIO(IOP_CONSTANTS[self.pmod_id]['address'],size)
        
        try:
            bitbuf = bitf.read(4)
            counter = 0
            while bitbuf:
                self.mmio.write(counter,bitbuf)
                counter += 4
                bitbuf = bitf.read(4)
        except IOError:
            print('cannot read', bin_location + self.program)
            print('or write MMIO', IOP_CONSTANTS[self.pmod_id]['address'])
        finally:
            bitf.close()
        
        # microblaze out of reset
        self.start()
        
    def start(self):
        self.state = 'RUNNING';
        self.gpio.write(0)
        
    def stop(self):
        self.state = 'STOPPED'
        self.gpio.write(1)
        
    def update(self, program):
        self.program = program
        self.stop()

        try:
            bitf = open(bin_location + self.program, 'rb')
        except IOError:
            print('cannot open', bin_location + self.program)

        size = (math.ceil(os.fstat(bitf.fileno()).st_size/ \
                mmap.PAGESIZE))*(mmap.PAGESIZE>>2)
        self.mmio = MMIO(IOP_CONSTANTS[self.pmod_id]['address'],size)
        
        try:
            bitbuf = bitf.read(4)
            counter = 0
            while bitbuf:
                self.mmio.write(counter,bitbuf)
                counter += 4
                bitbuf = bitf.read(4)
        except IOError:
            print('cannot read', bin_location + self.program)
            print('or write MMIO', IOP_CONSTANTS[self.pmod_id]['address'])
        finally:
            bitf.close()
        
        self.start()
         
    def status(self):
        str = 'Microblaze program %s at address 0x%x %s' % (self.program,
              IOP_CONSTANTS[self.pmod_id]['address'], self.state)
        return str

def request_iop(pmod_id, program='mailbox.bin', force=False):
    """This is the interface to request an I/O Processor. 
    It looks for active instances on the same PMOD ID, and prevents users from 
    instantiating different types of IOPs on the same PMOD.

    Users are notified with an exception if the selected PMOD is already 
    hooked to another type of IOP, to prevent unwanted behavior.
    This can be overridden by setting the *force* flag.

    Arguments
    ----------
    pmod_id (int)    : ID of the PMOD/IOP
    program (string) : program to be loaded on the IOP. 
                       no program is loaded if not specified
    force (Boolean)  : flag whether the function will force IOP instantiation.

    Raises
    ----------
    LookupError      : Another IOP type in the system with the same ID, 
                       and the *force* flag is not set.
    """

    """ Three cases:
    1. No previous IOP in the system with the same ID
    2. There is A previous IOP in the system with the same ID. 
       Users want to request another instance with the same program. 
       Update the program only: do not raises an exception.
    3. force == False. There is A previous IOP in the system with the same ID. 
       Users want to request another instance with a different program. 
       Raises an exception.           
    """
    if IOP_INSTANCES[pmod_id] is None:
        # case 1
        new_iop = _IOP(pmod_id, program)
        IOP_INSTANCES[pmod_id] = new_iop
        return new_iop
    else:
        if (force or program is IOP_INSTANCES[pmod_id].program):
        # case 2
            IOP_INSTANCES[pmod_id].update(program)
        else:
        # case 3
            raise LookupError('Another I/O Processor type with the same ' +  
                              'ID is already in the system. The *force* ' + 
                              'flag can be set to overwrite the old ' + 
                              'instance, but that is not advised as hot ' + 
                              'swapping is currently not supported.')   
        return IOP_INSTANCES[pmod_id]

def _flush_iops():
    """This function should be used with caution.
    It flushes the _IOP_INSTANCES dictionary.
    """    
    for key in IOP_INSTANCES:
        IOP_INSTANCES[key] = None

