"""This module defines constants, functions and objects internally 
used by the PMODs.
"""


__author__      = "Graham Schelle, Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.1"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from pyb import iop


#########################
# IOP mailbox constants #
#########################
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
IOPMM_SWITCHCONFIG_BASEADDR    = 0x44A00000
IOPMM_SWITCHCONFIG_IO_0_OFFSET = 0
IOPMM_SWITCHCONFIG_IO_1_OFFSET = 4
IOPMM_SWITCHCONFIG_IO_2_OFFSET = 8
IOPMM_SWITCHCONFIG_IO_3_OFFSET = 12
IOPMM_SWITCHCONFIG_IO_4_OFFSET = 16
IOPMM_SWITCHCONFIG_IO_5_OFFSET = 20
IOPMM_SWITCHCONFIG_IO_6_OFFSET = 24
IOPMM_SWITCHCONFIG_IO_7_OFFSET = 28
IOPMM_SWITCHCONFIG_NUMREGS     = 8

# Each PMOD Pin can be tied to GPIO,SPI,IIC pins... enumerate here
IOP_SWCFG_GPIO0 = 0
IOP_SWCFG_GPIO1 = 1
IOP_SWCFG_GPIO2 = 2
IOP_SWCFG_GPIO3 = 3
IOP_SWCFG_GPIO4 = 4
IOP_SWCFG_GPIO5 = 5
IOP_SWCFG_GPIO6 = 6
IOP_SWCFG_GPIO7 = 7

IOP_SWCFG_IIC0_SDA = 0xa
IOP_SWCFG_IIC0_SCL = 0x8

IOP_SWCFG_IIC1_SDA = 0xb
IOP_SWCFG_IIC1_SCL = 0x9

# SWITCH Config - All GPIOs
IOP_SWCFG_GPIOALL = [IOP_SWCFG_GPIO0, IOP_SWCFG_GPIO1, IOP_SWCFG_GPIO2, 
                     IOP_SWCFG_GPIO3, IOP_SWCFG_GPIO4, IOP_SWCFG_GPIO5, 
                     IOP_SWCFG_GPIO6, IOP_SWCFG_GPIO7]

# SWITCH Config - IIC0, Top Row
IOP_SWCFG_IIC0_TOPROW = [IOP_SWCFG_GPIO0, IOP_SWCFG_GPIO1, IOP_SWCFG_IIC0_SCL, 
                         IOP_SWCFG_IIC0_SDA, IOP_SWCFG_GPIO2, IOP_SWCFG_GPIO3, 
                         IOP_SWCFG_GPIO4, IOP_SWCFG_GPIO5]

# SWITCH Config - IIC0, Bottom Row
IOP_SWCFG_IIC0_BOTTOMROW = [IOP_SWCFG_GPIO0, IOP_SWCFG_GPIO1, IOP_SWCFG_GPIO2, 
                            IOP_SWCFG_GPIO3, IOP_SWCFG_GPIO4, IOP_SWCFG_GPIO5, 
                            IOP_SWCFG_IIC0_SCL, IOP_SWCFG_IIC0_SDA]

# IIC Register Map
IOPMM_XIIC_0_BASEADDR       = 0x40800000
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
IOPMM_SPI_0_BASEADDR        = 0x44A10000
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

# GPIO Register Map
IOPMM_GPIO_BASEADDR         = 0x40000000
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

# GPIO CABLE TYPE
GPIO_CABLE_STRAIGHT   = 0
GPIO_CABLE_LOOPBACK   = 1

#########################
# IOP handlers          #
#########################

# allow users to specify PMOD by number, we manage various static/dynamic state
iop_constants = {
    1:{
        "address" : 0x40000000,
        "emioPin": 54
    },
    2:{
        "address" : 0x42000000,
        "emioPin": 55
    },
    3:{
        "address" : 0x44000000,
        "emioPin": 56
    },
    4: {
        "address" : 0x46000000,
        "emioPin": 57
    },      
}

_active_iops = {
    1:None,
    2:None,
    3:None,
    4:None  
}
"""Dictionary containing references to active IOP instances."""


def request_iop(req_obj, pmod_id, program=None, force=False):
    """This is the interface to request an I/O Processor. 
    It will lookup for active instances on the same PMOD ID, and prevent 
    the user from instantiating different types of IOPs on the same ID.
    The pyb.iop instance is returned, an exception is raised if errors occur.

    User will be notified with an exception if the selected PMOD is already 
    hooked to another type of IOP, to prevent unwanted behavior.
    This can be explicitly overridden setting the *force* flag.

    Arguments
    ----------
    req_obj (Object) : Just a reference to the object which is requesting 
                       the new IOP instance
    pmod_id (int)    : ID of the PMOD's IOP
    program (string) : Specify which program has to be loaded on the IOP. 
                       Can be left unspecified, and in this case 
                       no program will be loaded
    force (Boolean)  : Default:False. Flag indicating if the function 
                       will force IOP instantiation.

    Raises
    ----------
    LookupError      : If there is a another IOP type in the system with 
                       the same ID, and the user does not set the *force* flag.
    """

    # We can basically incur in three different cases 
    # (one of which is somehow a corner case):
    # 1. No previous IOP in the system with the same ID
    # 2. There is a previous IOP in the system with the same ID. Raises an 
    #    exception or update the previous IOP if *force" is set to True
    # 3. (Corner case) Although there is a previous IOP in the system with 
    #    the same ID, the object requesting the new instance is of the same 
    #    type as of the previous one. In this case, the IOP will be silently 
    #    updated and no exception will be raised even if *force* is not set. 
    if _active_iops[pmod_id] != None:
        if type(_active_iops[pmod_id].current_reference) is not type(req_obj):
            # case 2        
            if not force:
                raise LookupError('Another I/O Processor type with the same ' +  
                                  'ID is already in the system. The *force* ' + 
                                  'flag can be set to overwrite the old ' + 
                                  'instance, but that is not advised as hot ' + 
                                  'swapping is currently not supported.')
            _active_iops[pmod_id].current_reference = req_obj
        # Common to 2 and 3. If program is not set, there is nothing to update. 
        if program != None and \
                program != _active_iops[pmod_id].iop.status()[1]: 
            _active_iops[pmod_id].iop.update(program)        
        return _active_iops[pmod_id].iop    
    else: 
        # case 3        
        new_iop = IOP(req_obj, pmod_id, program)
        _active_iops[pmod_id] = new_iop
        return new_iop.iop

def _flush_iops():
    """This function is intended for internal use only and should be used with
    caution.
    It flushes the _active_iops dictionary.
    """    
    for key in _active_iops:
        del _active_iops[key]
        _active_iops[key] = None    


# NOTE ABOUT THIS CLASS: It would have made a lot of sense to make this IOP 
#   class an extension of pyb.iop. However, inheritance from pyb.iop does 
#   not work properly. Although make_new() is good for performance, it is 
#   not Python compliant. pyb.iop does not have __new__ and __init__ at all,
#   so __init__ overriding is simply not possible (see commented code).
#
#   REF: https://github.com/micropython/micropython/issues/606
#   The current, not so elegant workaround is to have a pyb.iop instance 
#   as an attribute of this class.
class IOP(object):
    """This class extends pyb.iop functionalities to control the number of 
    active IOP instances in the system.

    The only difference is that it contains a reference to the object instance 
    (current_reference) which is using the IOP.
    Refer to pyb.iop for additional details.
    """

    def __init__(self, current_reference, iop_id, program=None):
        #if program != None:
        #   super().__init__(iop_constants[iop_id]['address'], 
        #                    iop_constants[iop_id]['emioPin'], program)
        #else:
        #   super().__init__(iop_constants[iop_id]['address'], 
        #                    iop_constants[iop_id]['emioPin'])
        self.current_reference = current_reference

        if program != None:
            self.iop = iop(iop_constants[iop_id]['address'], 
                           iop_constants[iop_id]['emioPin'], program)
        else:
            self.iop = iop(iop_constants[iop_id]['address'], 
                           iop_constants[iop_id]['emioPin'])