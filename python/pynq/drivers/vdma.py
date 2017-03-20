__author__ = "Giuseppe Natale, Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"

from pynq import PL
from pynq import MMIO
from pynq.drivers.framebuffer import FrameBuffer



#Bit Masks
BITMASK_CR_RUN_STOP    = 0x00000001 # Start/stop DMA channel
BITMASK_CR_TAIL_EN     = 0x00000002 # Tail ptr enable or Park
BITMASK_CR_RESET       = 0x00000004 # Reset channel
BITMASK_CR_SYNC_EN     = 0x00000008 # Gen-lock enable
BITMASK_CR_FRMCNT_EN   = 0x00000010 # Frame count enable
BITMASK_CR_FSYNC_SRC   = 0x00000060 # Fsync Source Select
BITMASK_CR_GENLCK_SRC  = 0x00000080 # Genlock Source Select
BITMASK_CR_RD_PTR      = 0x00000F00 # Read pointer number
BITMASK_CR_GENLCK_RPT  = 0x00008000 # GenLock Repeat
BITMASK_CR_FRM_CNT     = 0x00FF0000 # Number of frames before IRQ

BIT_CR_RUN_STOP        = 0
BIT_CR_CIRCULAR_PARKED = 1
BIT_CR_RESET           = 2
BIT_CR_FRMCNT_EN       = 4
BIT_CR_FRMCNT_INT_EN   = 12

#Version
BITMASK_VERSION_MAJOR  = 0xF0000000
BITMASK_VERSION_MINOR  = 0x0FF00000
BITMASK_VERSION_REV    = 0x000F0000

#Status Reset
BITMASK_SR_HALTED       = 0x00000001  # DMA channel halted
BITMASK_SR_IDLE         = 0x00000002  # DMA channel idle
BITMASK_SR_ERR_INTERNAL = 0x00000010  # Datamover internal err
BITMASK_SR_ERR_SLAVE    = 0x00000020  # Datamover slave err
BITMASK_SR_ERR_DECODE   = 0x00000040  # Datamover decode err
BITMASK_SR_ERR_FSZ_LESS = 0x00000080  # FSize Less Mismatch err
BITMASK_SR_ERR_LSZ_LESS = 0x00000100  # LSize Less Mismatch err
BITMASK_SR_ERR_SG_SLV   = 0x00000200  # SG slave err
BITMASK_SR_ERR_SG_DEC   = 0x00000400  # SG decode err
BITMASK_SR_ERR_FSZ_MORE = 0x00000800  # FSize More Mismatch err
BITMASK_SR_ERR_ALL      = 0x00000FF0  # All errors

BIT_SR_HALTED           = 0
BIT_SR_IDLE             = 1

#Stride
BITMASK_STRIDE          = 0x0000FFFF

#Park Pointer Bitmasks
BITMASK_WIP_WR_FRM_PTR  = 0x1F000000
BITMASK_WIP_RD_FRM_PTR  = 0x001F0000
BITMASK_WR_FRM_PTR      = 0x00001F00
BITMASK_RD_FRM_PTR      = 0x0000001F

#Registers (Without Offset)
REG_MM2S_CR              = 0x00
REG_MM2S_SR              = 0x04
REG_MM2S_REG_INDEX       = 0x14 #page select for frame ptr addr (0:1-16, 1:17:32)
REG_PARK_PTR_REG         = 0x28
REG_VDMA_VERSION         = 0x2C
REG_S2MM_CR              = 0x30
REG_S2MM_SR              = 0x34
REG_S2MM_VDMA_IRQ_MASK   = 0x3C
REG_S2MM_REG_INDEX       = 0x44
REG_MM2S_VSIZE           = 0x50
REG_MM2S_HSIZE           = 0x54
REG_MM2S_FRMDLY_STRIDE   = 0x58
REG_MM2S_START_ADDR      = 0x5C
REG_S2MM_VSIZE           = 0xA0
REG_S2MM_HSIZE           = 0xA4
REG_S2MM_FRMDLY_STRIDE   = 0xA8
REG_S2MM_START_ADDR      = 0xAC

#Default Configuration Dictionary
'''
The VDMA is configured by Vivado and those configuration
values should be in a dictionary like the following, ideally there
would be a script that would read the .tcl file to discover
the cores parameters and populate this configuration dict
with accurate values.
'''
DEFAULT_VDMA_CONFIG_DICT = {
    'NUM_FSTORES'              : 3,     #Number of frames to use
    'INCLUDE_MM2S'             : 1,
    'INCLUDE_MM2S_DRE'         : 0,     #Data Re-Alignment Engine
    'M_AXI_MM2S_DATA_WIDTH'    : 32,
    'INCLUDE_S2MM'             : 1,
    'INCLUDE_S2MM_DRE'         : 0,     #Data Re-Alignment Engine
    'M_AXI_S2MM_DATA_WIDTH'    : 32,
    'INCLUDE_SG'               : 0,
    'ENABLE_VIDPRMTR_READS'    : 1,
    'USE_FSYNC'                : 1,
    'FLUSH_ON_FSYNC'           : 1,
    'MM2S_LINEBUFFER_DEPTH'    : 4096,
    'S2MM_LINEBUFFER_DEPTH'    : 4096,
    'MM2S_GENLOCK_MODE'        : 0,
    'S2MM_GENLOCK_MODE'        : 0,
    'INCLUDE_INTERNAL_GENLOCK' : 1,
    'S2MM_SOF_ENABLE'          : 1,
    'M_AXIS_MM2S_TDATA_WIDTH'  : 24,
    'S_AXIS_S2MM_TDATA_WIDTH'  : 24,
    'ENABLE_DEBUG_INFO_1'      : 0,
    'ENABLE_DEBUG_INFO_5'      : 0,
    'ENABLE_DEBUG_INFO_6'      : 1,
    'ENABLE_DEBUG_INFO_7'      : 1,
    'ENABLE_DEBUG_INFO_9'      : 0,
    'ENABLE_DEBUG_INFO_13'     : 0,
    'ENABLE_DEBUG_INFO_14'     : 1,
    'ENABLE_DEBUG_INFO_15'     : 1,
    'ENABLE_DEBUG_ALL'         : 0,
    'ADDR_WIDTH'               : 32,
}

class VDMAException(Exception):
    """
    Errors associated with VDMA including:
        - Attempting to access MM2S or S2MM
        when not enabled
        - Setting incorrect address widths
    """
    pass

class VDMA(object):
    """ Video DMA core manager

    The VDMA core can be configured as an egress (memory -> stream)
    an ingress(stream -> memory) or both. In order to use the core it must
    be setup in the following way


    IMPORTANT:

    There is a 'start_engine' and 'stop_engine' function that performs
    most of the following functions within it, The following is here if
    the user would like to take advantage of other features not available
    in the 'start_engine' function


    WARNING:

    Note about starting engines: If you are sending data that will
    exit one VDMA and enter another it is important to start the
    'ingress' VDMA (from stream to memory) before the 'egress' VDMA
    (memory to stream)

    Egress Configuration:

    1. Set the size of the images to read or write using the following
        functions
        (TODO: for incomming stream, auto configure the size)

        set_image_size(<width>, <height>)

    2. Configure the core to output a fixed number of frames or continuous
        frames.

        Fixed:
            enable_egress_continuous(False)
            set_egress_frame_count(<Number of Frames to output>)
            [Optionally: Set an interrupt when the fixed number frames
                were outputted]
            enable_egress_interrupt_on_frame_count(True)

        Continuous:
            enable_egress_continuous(True)
            <Depending on if you want a parked or circular output>
            <Parked>
            set_egress_parked_frame()
            <Circular>
            set_egress_circular_frame()

    3. Enable VDMA
        enable_egress(True)


    If the VDMA was set for a fixed number of frames the VDMA will
    automatically disable the engine. Users can check the state of the engine
    with the function
        is_egress_enabled()


    Ingress Configuration

    1. Set the size of the images to read or write using the following
        functions
        (TODO: for incomming stream, auto configure the size)

        set_image_size(<width>, <height>)

    2. Configure the core to input a fixed number of frames or continuous
        capture frames.

        Fixed:
            enable_ingress_continuous(False)
            set_ingress_frame_count(<Number of Frames to output>)
            [Optionally: Set an interrupt when the fixed number frames
                were captured]
            enable_ingress_interrupt_on_frame_count(True)

        Continuous:
            enable_ingress_continuous(True)
            <Depending on if you want a parked or circular input>
            <Parked>
            set_ingress_parked_frame()
            <Circular>
            set_ingress_circular_frame()

    3. Enable VDMA
        enable_ingress(True)

    """
    def __init__(self, name, vdma_config_dict = DEFAULT_VDMA_CONFIG_DICT, debug = False):
        """Returns a new VDMA object.

        Parameters
        ----------
        vdma_config_dict : dict
            A dictionary describing the VDMA configuration.
        debug : boolean
            Output Debug Messages
        """
        self.debug = debug
        if name not in PL.ip_dict:
            raise LookupError("No such AXI Stream IP in the overlay.")
        self.mmio = MMIO(PL.ip_dict[name][0], PL.ip_dict[name][1])
        self._set_config_dict(vdma_config_dict)
        self.frames = []
        self.width = 0
        self.height = 0

    #Ingress/Egress Independent Functions
    def _set_config_dict(self, config_dict):
        #Sets up the configuration dictionary
        self.config_dict = config_dict
        if (self.config_dict['ADDR_WIDTH'] % 8):
            raise VDMAException("Illegal address width: %d, must be a \
                                 minimum of 32 and a multiple of 8"   \
                                 % self.config_dict["ADDR_WIDTH"])

    def get_version(self):
        """Returns a tuple describing the version of the VDMA core

        Parameters
        ----------
        None

        Returns
        -------
        tuple
            major version
            minor version
            revision
        """
        major_version = self.mmio.read_register_bitmask(REG_VDMA_VERSION, BITMASK_VERSION_MAJOR)
        minor_version = self.mmio.read_register_bitmask(REG_VDMA_VERSION, BITMASK_VERSION_MINOR)
        revision = self.mmio.read_register_bitmask(REG_VDMA_VERSION, BITMASK_VERSION_REV)
        return (major_version, minor_version, revision)

    def get_max_number_of_frames(self):
        """Returns the maximum number of frames the core can hold

        Parameters
        ----------
        None

        Returns
        -------
        int
            the number of frames the VDMA can store
        """
        return self.config_dict['NUM_FSTORES']

    def set_image_size(self, width, height, color_depth=3):
        """Sets the image size

        Parameters
        ----------
        width: int
            width of the image
        height: int
            height of the image
        color_depth : int
            The number of bytes per pixel (usually 3 for RGB)

        Returns
        -------
        None
        """
        self.width = width
        self.height = height
        self.color_depth = color_depth
        self.frames = []
        for i in range(self.get_max_number_of_frames()):
            self.frames.append(FrameBuffer(self.width, self.height, self.color_depth))

        if self.debug:
            for i in range(self.get_max_number_of_frames()):
                addr = self.frames[i].get_phy_address()
                print ("Frame Address: 0x%08X" % addr)

    def get_frame(self, index):
        """Returns the framebuffer at the specified index

        Parameters
        ----------
        index: int
            the index of the frame to get

        Returns
        -------
        The Framebuffer object
        """
        if len(self.frames) == 0:
            raise VDMAException("No Frames, 'set_image_size' must be called before frames are available")

        if index >= self.get_max_number_of_frames():
            raise VDMAException("%d is not a valid index, %d frames available" % (index, self.get_max_number_of_frames()))

        return self.frames[index]

    #Egress Functions
    def enable_egress(self, enable):
        """Enable the egress channel

        Note
        ----
        This is misleading, this does not actually start a transaction, instead
        the mechanism that usually starts a transaction is writing to the
        vertical size

        Parameters
        ----------
        enable: boolean
            True: Start channel
            False: Stop channel

        Returns
        -------
        Nothing
        """
        if not self.config_dict['INCLUDE_MM2S']:
            raise VDMAException("MM2S Is not Enabled")

        self.mmio.enable_register_bit(REG_MM2S_CR, BIT_CR_RUN_STOP, enable)

    def start_egress_engine(self, continuous=False, parked=True, num_frames=1,
                            frame_index=0, interrupt=False):

        """Start Egress Engine

        Note
        ----
        This is a simple way to use the VDMA Egress, it will configure the egress
        VDMA and start it

        Parameters
        ----------
        continuous: boolean
            True: Continuously send out frames
            False: Send out a fixed number of frames
        parked: boolean
            True: If continuous, send out the same frame over and over again
            False: if continuous, send out the sequence of frames circulating
                through all the frames
        num_frames: int
            If continuous is False then send the specified number of frames
            out
        frame_index: start sending frames specified at the index
        interrupt: when the transaction is finished sending a fixed
            number of frames raise the interrupt

        Returns
        -------
        None
        """
        self.reset_egress()
        while (self.is_egress_reset_in_progress()):
            continue
        #Configure the control register
        self.enable_egress_continuous(continuous)
        if parked:
            self.set_egress_parked_frame()
        else:
            self.set_egress_circular_frame()

        self.set_egress_frame_count(num_frames)
        #If we need an interrupt when we sent off the correct number of frames
        self.enable_egress_interrupt_on_frame_count(interrupt)

        #Enable the channel (This seems like it should be the last thing done)
        self.enable_egress(True)
        if self.debug: print ("MM2S Control Register: 0x%08X" % self.mmio.read(REG_MM2S_CR))

        #Connect all the physical addresses of the frames to their indexes
        for i in range(self.get_max_number_of_frames()):
            self.set_egress_frame_mem_address(self.frames[i].get_phy_address(), i)
            #self.set_egress_frame_mem_address(self.frames[i].get_address(), i)

        #Set the frame index to start on
        self.set_egress_frame_index(frame_index)

        self.set_egress_width(self.width * self.color_depth)
        #This should kick it off
        self.set_egress_height(self.height)
        #XXX:self.enable_egress(True)

    def stop_egress_engine(self):
        """stops the egress engine

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        self.enable_egress(False)

    def is_egress_enabled(self):
        """returns true if the egress engine is enabled

        Parameters
        ----------
        None

        Returns
        -------
        boolean
            True: Egress Engine is enabled
            False: Egress Engine is not enabled
        """
        return not self.mmio.is_register_bit_set(REG_MM2S_SR, BIT_SR_HALTED)

    def get_egress_error(self):
        """Returns a bitmask of the egress error shifted over to 0

        Note
        ----
        Bits:
            0: Internal Error
            1: Slave Error
            2: Decode Error
            3: Fsize less Mismatch
            4: LSize less Mismatch
            5: Scatter Gather slave error
            6: Scatter Gather decode error
            7: FSize More Mismatch

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        return self.mmio.read_register_bitmask(REG_MM2S_SR, BITMASK_SR_ERR_ALL)

    def reset_egress(self):
        """Resets the Egress Engine

        Note
        ----
        Self Clearing

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        self.mmio.set_register_bit(REG_MM2S_CR, BIT_CR_RESET)

    def is_egress_reset_in_progress(self):
        """Returns true if egress engine is in reset

        Parameters
        ----------
        None

        Returns
        -------
        boolean
            True: reset is in progress
            False: reset is not in progress
        """
        return self.mmio.is_register_bit_set(REG_MM2S_CR, BIT_CR_RESET)

    def set_egress_parked_frame(self):
        """ Configures the egress engine to use a parked frame
        when continuously sending frames

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        self.mmio.clear_register_bit(REG_MM2S_CR, BIT_CR_CIRCULAR_PARKED)

    def set_egress_circular_frame(self):
        """Configure the egress engine to cycle through all frames
        when continuously sending frames

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        self.mmio.set_register_bit(REG_MM2S_CR, BIT_CR_CIRCULAR_PARKED)

    def enable_egress_continuous(self, enable):
        ''' Enable continuously sending frames

        Note
        ----

        If enabled write a continuous stream of frames, this works with the
        following two functions:
            - set_egress_parked_frame(): send the same frame pointed to by index
                over and over again
            - set_egress_circular_frame()
                send all the images within the circular buffer continuously

        If false, set the number of frames to write using
            - set_egress_frame_count

        Parameters
        ----------
        enable: boolean
            True: Continuously send frames
            False: Send a fixed number of frames

        Returns
        -------
        None
        '''
        self.mmio.enable_register_bit(REG_MM2S_CR, BIT_CR_FRMCNT_EN, not enable)

    def set_egress_frame_count(self, frame_count = 1):
        ''' Set the number of frames to send when sending a fixed number

        Note
        ----
        This will only send a certain number of frames, after the number of
        frames are sent then the engine will halt itself. This is the opposite
        of 'set_continuous' which constantly sends frames

        When the number of frames are sent the engine will shut 'halt'

        Parameters
        ----------
        frame_count: int
            Number of frames to send

        Returns
        -------
        None
        '''
        self.mmio.write_register_bitmask(REG_MM2S_CR, BITMASK_CR_FRM_CNT,
            frame_count)

    def enable_egress_interrupt_on_frame_count(self, enable):
        """Enable interrupt when egress engine sends all frames

        Parameters
        ----------
        enable: boolean
            True: Enable Interrupt
            False: Disable Interrupt

        Returns
        -------
        None
        """
        self.mmio.enable_register_bit(REG_MM2S_CR, BIT_CR_FRMCNT_INT_EN, enable)

    def set_egress_width(self, width):
        """Sets the width of the egress frame

        Note
        ----
        This value should include the color depth value
        so if a frame is 720 pixels accross and there are 3 bytes per pixel (RGB)
        then the width should be 720 * 3

        The stride should be at least the size of the width or the engine will
        error out

        Parmaeters
        ----------
        width: int
            Number of bytes within one row of data

        Returns
        -------
        None
        """
        self.mmio.write(REG_MM2S_HSIZE, width)
        self.set_egress_stride(width)

    def set_egress_height(self, height):
        """Set the height of the egress frame

        Note
        ----
        This function is usually the last to be called when updating the register
        values and will start off either the egress engine or the ingress engine

        Parameters
        ----------
        height: int
            Number of rows of an image

        Returns
        -------
        None
        """
        self.mmio.write(REG_MM2S_VSIZE, height)

    def set_egress_stride(self, stride):
        """Sets the stride of the image

        Note
        ----
        The stride must be equal or longer than the width of the image

        Parameters
        ----------
        stride: int
            The physical width of where the image is stored, this can be longer
            than the width of the image, this is usually used to align memory rows

        Returns
        -------
        None
        """
        self.mmio.write_register_bitmask(REG_MM2S_FRMDLY_STRIDE, BITMASK_STRIDE,
            stride)

    def get_current_egress_frame_index(self):
        """ Returns the current frame index

        Parameters
        ----------
        None

        Returns
        -------
        int
            index of the frame the egress engine is working on
        """
        return self.mmio.read_register_bitmask(REG_PARK_PTR_REG, BITMASK_RD_FRM_PTR)

    def set_egress_frame_mem_address(self, address, index):
        """ Sets the physical address of the frame associated with the index

        Note
        ----
        The FPGA must read image data from the memory, this memory is within
        the kernel space and can be accessed by the FPGA

        Parameters
        ----------
        address: int
            physical address of the buffer in kernel memory
        index: int
            Which index the egress engine will associate with the frame

        Returns
        -------
        None
        """
        multiplier = self.config_dict['ADDR_WIDTH'] / 8
        pos = 0
        if self.debug: print("Entered set_egress_frame_mem_address with index: %d" % index)
        while (pos < multiplier):
            if (((pos * multiplier) / 8) >= 16):
                self.mmio.write(REG_MM2S_REG_INDEX, 1)
            else:
                self.mmio.write(REG_MM2S_REG_INDEX, 0)
            if self.debug: print ("Writing: 0x%08X:0x%08X" % (int(REG_MM2S_START_ADDR + (index * multiplier) + pos), (address & 0xFFFFFFFF)))
            self.mmio.write(int(REG_MM2S_START_ADDR + (index * multiplier) + pos), \
                (address & 0xFFFFFFFF))
            address = address >> 32
            pos += 4

    def set_egress_frame_index(self, index):
        """ Tell the egress engine which frame index to use when sending data

        Note
        ----
        When configuring the egress frame engine to send data out this function
        will specify which framebuffer to send out.

        Parameters
        ----------
        index: int
            the index of the framebuffer to use

        Returns
        -------
        None
        """
        multiplier = self.config_dict['ADDR_WIDTH'] / 8
        index =int( multiplier * index)
        self.mmio.write_register_bitmask(REG_PARK_PTR_REG, BITMASK_RD_FRM_PTR, index)

    def get_current_frame_index(self):
        """Returns the current frame index

        Parameters
        ----------
        None

        Returns
        -------
        int
            The current index of the framebuffer
        """
        return self.mmio.get_register_bitmask(REG_PARK_PTR_REG, BITMASK_RD_FRM_PTR)

    def get_wip_egress_frame(self):
        """Gets the frame that the egress engine is currently working on

        Parameters
        ----------
        None

        Returns
        -------
        int
            The frame the egress engine is currently working on
        """
        return self.mmio.read_register_bitmask(REG_MM2S_SR, BITMASK_CR_FRM_CNT)

    def get_egress_control(self):
        """ Debug: Returns the control register
        """
        return self.mmio.read(REG_MM2S_CR)

    def get_egress_status(self):
        """ Debug: Returns the current status register
        """
        return self.mmio.read(REG_MM2S_SR)

    def dump_egress_registers(self):
        """ Debug: Dumps all the register
        """
        print ("")
        print ("Egress Registers:")
        print ("  Control     [%02X]: 0x%08X" % (REG_MM2S_CR, self.mmio.read(REG_MM2S_CR)))
        print ("  Status      [%02X]: 0x%08X" % (REG_MM2S_SR, self.mmio.read(REG_MM2S_SR)))
        print ("  Reg Index   [%02X]: 0x%08X" % (REG_MM2S_REG_INDEX, self.mmio.read(REG_MM2S_REG_INDEX)))
        print ("  Park Pointer[%02X]: 0x%08X" % (REG_PARK_PTR_REG, self.mmio.read(REG_PARK_PTR_REG)))
        print ("  VSize       [%02X]: 0x%08X" % (REG_MM2S_VSIZE, self.mmio.read(REG_MM2S_VSIZE)))
        print ("  HSize       [%02X]: 0x%08X" % (REG_MM2S_HSIZE, self.mmio.read(REG_MM2S_HSIZE)))
        print ("  Dly/Stride  [%02X]: 0x%08X" % (REG_MM2S_FRMDLY_STRIDE, self.mmio.read(REG_MM2S_FRMDLY_STRIDE)))
        print ("  Frame Memory Map")
        for i in range (self.get_max_number_of_frames()):
            print ("    %d[%02X]: 0x%08X" % (i, REG_MM2S_START_ADDR + (i * 4), self.mmio.read(REG_MM2S_START_ADDR + (i * 4))))
        print ("")

    #Ingress Functions
    def enable_ingress(self, enable):
        """Enable the ingress channel

        Note
        ----
        This is misleading, this does not actually start a transaction, instead
        the mechanism that usually starts a transaction is writing to the
        vertical size

        Parameters
        ----------
        enable: boolean
            True: Start channel
            False: Stop channel

        Returns
        -------
        Nothing
        """
        if not self.config_dict['INCLUDE_S2MM']:
            raise VDMAException("S2MM Is not Enabled")
        self.mmio.enable_register_bit(REG_S2MM_CR, BIT_CR_RUN_STOP, enable)

    def start_ingress_engine(self, continuous=False, parked=True, num_frames=1,
                             frame_index=0, interrupt=False):
        """Start Egress Engine

        Note
        ----
        This is a simple way to use the VDMA Ingress, it will configure the
        ingress VDMA and start it

        Parameters
        ----------
        continuous: boolean
            True: Continuously receive frames
            False: Receive a fixed number of frames
        parked: boolean
            True: If continuous, receive the same frame over and over again
            False: if continuous, receive the sequence of frames circulating
                through all the frames
        num_frames: int
            If continuous is False then receive the specified number of frames
            out
        frame_index: start receiving frames specified at the index
        interrupt: when the transaction is finished receiving a fixed
            number of frames raise the interrupt

        Returns
        -------
        None
        """

        self.reset_ingress()
        while (self.is_ingress_reset_in_progress()):
            continue
        #Configure the control register
        self.enable_ingress_continuous(continuous)
        if parked:
            self.set_ingress_parked_frame()
        else:
            self.set_ingress_circular_frame()

        self.set_ingress_frame_count(num_frames)
        #if we need an interrupt when we read the correct number of frames
        self.enable_ingress_interrupt_on_frame_count(interrupt)

        #Enable the channel (This seems like it should be the last thing done)
        self.enable_ingress(True)
        if self.debug: print ("S2MM Control Register: 0x%08X" % self.mmio.read(REG_S2MM_CR))

        #Connect all of the physical address of the frames to their indexes
        for i in range(self.get_max_number_of_frames()):
            self.set_ingress_frame_mem_address(self.frames[i].get_phy_address(), i)
            #self.set_ingress_frame_mem_address(self.frames[i].get_address(), i)

        #Set the frame index to start on
        self.set_ingress_frame_index(frame_index)

        self.set_ingress_width(self.width * self.color_depth)
        self.set_ingress_height(self.height)
        #XXX:self.enable_ingress(True)

    def stop_ingress_engine(self):
        """stops the ingress engine

        Parameters
        ----------
        None

        Returns
        -------
        None
        """

        self.enable_ingress(False)

    def is_ingress_enabled(self):
        """returns true if the ingress engine is enabled

        Parameters
        ----------
        None

        Returns
        -------
        boolean
            True: Ingress Engine is enabled
            False: Ingress Engine is not enabled
        """

        return not self.mmio.is_register_bit_set(REG_S2MM_SR, BIT_SR_HALTED)

    def get_ingress_error(self):
        """Returns a bitmask of the ingress error shifted over to 0

        Note
        ----
        Bits:
            0: Internal Error
            1: Slave Error
            2: Decode Error
            3: Fsize less Mismatch
            4: LSize less Mismatch
            5: Scatter Gather slave error
            6: Scatter Gather decode error
            7: FSize More Mismatch

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        return self.mmio.read_register_bitmask(REG_S2MM_SR, BITMASK_SR_ERR_ALL)

    def reset_ingress(self):
        """Resets the Ingress Engine

        Note
        ----
        Self Clearing

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        self.mmio.set_register_bit(REG_S2MM_CR, BIT_CR_RESET)

    def is_ingress_reset_in_progress(self):
        """Returns true if ingress engine is in reset

        Parameters
        ----------
        None

        Returns
        -------
        boolean
            True: reset is in progress
            False: reset is not in progress
        """

        return self.mmio.is_register_bit_set(REG_S2MM_CR, BIT_CR_RESET)

    def enable_ingress_continuous(self, enable):
        ''' Enable continuously receiving frames


        Note
        ----

        If enabled read a continous stream of frames, this works
        with the following two functions:
            - set_ingress_parked_frame(): the incomming data will
                continuously write to the same index over and over
                again
            - set_ingress_circular_frame(): the incomming data will
                write to all the frames sequentally and then
                write the beginning frame again

        if false, set the number of frames to write using
            - set_ingress_frame_count
        After the specified number of frames have been read the
        ingress engine will shut off

        Parameters
        ----------
        enable: boolean
            True: continuously receive frames
            False: Receive a fixed number of frames

        Returns
        -------
        None
        '''
        self.mmio.enable_register_bit(REG_S2MM_CR, BIT_CR_FRMCNT_EN, not enable)

    def set_ingress_frame_count(self, frame_count = 1):
        ''' Set the number of frames to receive

        Note
        ----
        This will only receive a certain number of frames, after the number of
        frames are received then the engine will halt itself. This is the opposite
        of 'set_continuous' which constantly sends frames

        When the number of frames are received the engine will shut 'halt'

        Parameters
        ----------
        frame_count: int
            Number of frames to read

        Returns
        -------
        None
        '''
        self.mmio.write_register_bitmask(REG_S2MM_CR, BITMASK_CR_FRM_CNT,
            frame_count)

    def set_ingress_parked_frame(self):
        """ Configures the ingress engine to use a parked frame
        when continuously receiving frames

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        self.mmio.clear_register_bit(REG_S2MM_CR, BIT_CR_CIRCULAR_PARKED)

    def set_ingress_circular_frame(self):
        """Configure the ingress engine to cycle through all frames
        when continuously receiving frames

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        self.mmio.set_register_bit(REG_S2MM_CR, BIT_CR_CIRCULAR_PARKED)

    def enable_ingress_interrupt_on_frame_count(self, enable):
        """Enable interrupt when ingress engine receives all frames

        Parameters
        ----------
        enable: boolean
            True: Enable Interrupt
            False: Disable Interrupt

        Returns
        -------
        None
        """
        self.mmio.enable_register_bit(REG_S2MM_CR, BIT_CR_FRMCNT_INT_EN, enable)

    def set_ingress_width(self, width):
        """Sets the width of the ingress frame

        Note
        ----
        This value should include the color depth value
        so if a frame is 720 pixels accross and there are 3 bytes per pixel (RGB)
        then the width should be 720 * 3

        The stride should be at least the size of the width or the engine will
        error out

        Parmaeters
        ----------
        width: int
            Number of bytes within one row of data

        Returns
        -------
        None
        """
        self.mmio.write(REG_S2MM_HSIZE, width)
        self.set_ingress_stride(width)

    def set_ingress_height(self, height):
        """Set the height of the ingress frame

        Note
        ----
        This function is usually the last to be called when updating the register
        values and will start off either the egress engine or the ingress engine

        Parameters
        ----------
        height: int
            Number of rows of an image

        Returns
        -------
        None
        """
        self.mmio.write(REG_S2MM_VSIZE, height)

    def set_ingress_stride(self, stride):
        """Sets the stride of the image

        Note
        ----
        The stride must be equal or longer than the width of the image

        Parameters
        ----------
        stride: int
            The physical width of where the image is stored, this can be longer
            than the width of the image, this is usually used to align memory rows

        Returns
        -------
        None
        """
        self.mmio.write_register_bitmask(REG_S2MM_FRMDLY_STRIDE, BITMASK_STRIDE, stride)

    def set_ingress_frame_mem_address(self, address, index):
        """ Sets the physical address of the frame associated with the index

        Note
        ----
        The FPGA must write image data to the memory, this memory is within
        the kernel space and can be accessed by the FPGA

        Parameters
        ----------
        address: int
            physical address of the buffer in kernel memory
        index: int
            Which index the egress engine will associate with the frame

        Returns
        -------
        None
        """
        multiplier = self.config_dict['ADDR_WIDTH'] / 8
        pos = 0
        if self.debug: print("Entered set_ingress_frame_mem_address with index: %d" % index)
        while (pos < multiplier):
            if (((pos * multiplier) / 8) >= 16):
                self.mmio.write(REG_S2MM_REG_INDEX, 1)
            else:
                self.mmio.write(REG_S2MM_REG_INDEX, 0)
            if self.debug: print ("Writing: 0x%08X:0x%08X" % (int(REG_S2MM_START_ADDR + (index * multiplier) + pos), (address & 0xFFFFFFFF)))
            self.mmio.write(int(REG_S2MM_START_ADDR + (index * multiplier) + pos), \
                (address & 0xFFFFFFFF))
            address = address >> 32
            pos += 4

    def set_ingress_frame_index(self, index):
        """ Tell the ingress engine which frame index to use when sending data

        Note
        ----
        When configuring the ingress frame engine to read data a fixed number
        of frames this function will specify which framebuffer to send out.

        Parameters
        ----------
        index: int
            the index of the framebuffer to use

        Returns
        -------
        None
        """
        multiplier = self.config_dict['ADDR_WIDTH'] / 8
        index = int(multiplier * index)
        self.mmio.write_register_bitmask(REG_PARK_PTR_REG, BITMASK_WR_FRM_PTR, index)

    def get_current_ingress_frame_index(self):
        """ Returns the current frame index

        Parameters
        ----------
        None

        Returns
        -------
        int
            index of the frame the egress engine is working on
        """
        return self.mmio.read_register_bitmask(REG_PARK_PTR_REG, BITMASK_WR_FRM_PTR)

    def get_wip_ingress_frame(self):
        """Gets the frame that the ingress engine is currently working on

        Parameters
        ----------
        None

        Returns
        -------
        int
            The frame the ingress engine is currently working on
        """
        return self.mmio.read_register_bitmask(REG_S2MM_SR, BITMASK_CR_FRM_CNT)

    def get_ingress_control(self):
        """ Debug: Returns the control register
        """
        return self.mmio.read(REG_S2MM_CR)

    def get_ingress_status(self):
        """ Debug: Returns the current status register
        """
        return self.mmio.read(REG_S2MM_SR)

    def dump_ingress_registers(self):
        """ Debug: Dumps all the register
        """
        print ("")
        print ("Ingress Registers:")
        print ("  Control     [%02X]: 0x%08X" % (REG_S2MM_CR, self.mmio.read(REG_S2MM_CR)))
        print ("  Status      [%02X]: 0x%08X" % (REG_S2MM_SR, self.mmio.read(REG_S2MM_SR)))
        print ("  Reg Index   [%02X]: 0x%08X" % (REG_S2MM_REG_INDEX, self.mmio.read(REG_S2MM_REG_INDEX)))
        print ("  Park Pointer[%02X]: 0x%08X" % (REG_PARK_PTR_REG, self.mmio.read(REG_PARK_PTR_REG)))
        print ("  VSize       [%02X]: 0x%08X" % (REG_S2MM_VSIZE, self.mmio.read(REG_S2MM_VSIZE)))
        print ("  HSize       [%02X]: 0x%08X" % (REG_S2MM_HSIZE, self.mmio.read(REG_S2MM_HSIZE)))
        print ("  Dly/Stride  [%02X]: 0x%08X" % (REG_S2MM_FRMDLY_STRIDE, self.mmio.read(REG_S2MM_FRMDLY_STRIDE)))
        print ("  Frame Memory Map")
        for i in range (self.get_max_number_of_frames()):
            print ("    %d [%02X]: 0x%08X" % (i, REG_S2MM_START_ADDR + (i * 4), self.mmio.read(REG_S2MM_START_ADDR + (i * 4))))
        print ("")

