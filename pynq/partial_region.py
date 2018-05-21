import os
import pynq
import pynq.lib
from pynq.pl import Bitstream
from pynq.interrupt import Interrupt
from pynq.dto_loader import DTO_Loader

__author__ = "Jeff Goeders, Tanner Gaskin"
__email__ = "jgoeders@byu.edu, gaskin.tanner@byu.edu"

class Partial_Region():  
    ADDR_SPACE_SIZE = 0x00010000

    GPIO_DATA_OFFSET = 0x0000
    GPIO_TRI_OFFSET = 0x0004
    """
    Helper Class to handle partially reconfigurable(PR) regions in the pl.

    Note
    ----
    This class assumes that there is a PR decoupler attached to the PR region
    and is controlled by a gpio module.

    Attributes
    ----------
    name : string
        The name of the PR region. This is used to uniquely idetify the PR region,
        and is provided by the user.

    baseAddr : int
        This if the base address of the AXI connection into the PR block. This is
        only used when accessing the PR region from userspace drivers. If linux drivers
        are being used then that information is provided in the device tree overlay's
        
    decouplerBaseAddr : int
        This is the base address of the PR decoupler core attached to this PR region.
        This is used to activate and deactivate the core when reprogramming the PR region. 

    decouplerPinNum : int
        This is the gpio pin number the decoupler is attached to.
        
    partialBitDir : string
        This is the path to the directory where the partial bitstreams are stored. This
        is so the full path doesn't have to be given every time the PR region is reprogrammed.
        Note that if not provided then the full path will have to be given when reprogramming 
        the PR region.

    dtboBaseDir : string
        This is the path to the directory where the dtbo files are stored. This is so
        the full path doesn't have to be given every time a new dtbo file is loaded. Note that
        if not provided then the full path will have to be given when inserting a new dtbo file.

    programmed : bool
        This is a boolean that indicates whether or not the PR region is currently programmed.
        This is reset when release is called.

    linuxDTOprogrammed : bool
        This is a boolean that indicates whether or not the a dtbo file has been inserted for
        this region.
    
    mmio_reserved : bool
        This is a boolean that indicates whether or not mmio has been reserved.

    mmio : pynq.mmio.MMIO() 
            This is an instance of the pynq.mmio.MMIO object, which is interacted with to 
            reserve and release the mmio.


    """
    def __init__(self, name, baseAddr, decouplerGpioBaseAddr, decouplerGpioPinNum, partialBitDir = None, dtboBaseDir = None, interrupt = None):
        """
        This method initializes the Partial Region Object.

        Parameters
        ----------
        name : string
            The name of the PR region. This is used to uniquely idetify the PR region,
            and is provided by the user.

        baseAddr : int
            This if the base address of the AXI connection into the PR block. This is
            only used when accessing the PR region from userspace drivers. If linux drivers
            are being used then that information is provided in the device tree overlay's
            
        decouplerBaseAddr : int
            This is the base address of the PR decoupler core attached to this PR region.
            This is used to activate and deactivate the core when reprogramming the PR region. 

        decouplerPinNum : int
            This is the gpio pin number the decoupler is attached to.
            
        partialBitDir : string
            This is the path to the directory where the partial bitstreams are stored. This
            is so the full path doesn't have to be given every time the PR region is reprogrammed.
            Note that if not provided then the full path will have to be given when reprogramming 
            the PR region. If nothing is provided then it will default to None.

        dtboBaseDir : string
            This is the path to the directory where the dtbo files are stored. This is so
            the full path doesn't have to be given every time a new dtbo file is loaded. Note that
            if not provided then the full path will have to be given when inserting a new dtbo file.
            If nothing is provided then it will default to None.

        interrupt : string
            This is a string that gives the name of the interrupt line associated with the PR region
            as found in the TCL file. If linux drivers are being used then leave this field blank
            or set to None, as that information is provided via device tree overlays. It nothing is 
            provided it will default to None.

        Returns
        -------
        None

        """        
        self.name = name
        self.baseAddr = baseAddr
        self.decouplerBaseAddr = decouplerGpioBaseAddr
        self.decouplerPinNum = decouplerGpioPinNum
        self.partialBitDir = partialBitDir
        self.dtboBaseDir = dtboBaseDir
        self.programmed = False
        self.linuxDTOprogrammed = False
        self.mmio_reserved = False
        self.mmio = None

        if interrupt is not None:
            self.interrupt = Interrupt(interrupt)

    def program(self, bitfile, linuxOverlayFile = None):
        """
        This method will program the partial bitsteam with the provided bitsteam file
        and will apply the provided device tree overlay file, if applicable.

        Parameters
        ----------
        bitfile : string
            The path to the partial bitstream file. This can either be relative to the 
            path provided when initialized or the absolute path.

        linuxOverlayFile : string
            The path to the dtbo file. This can either be relative to the 
            path provided when initialized or the absolute path. 
            Will default to None.
            
        Returns
        -------
        None

        """
        if (self.programmed):
            raise Exception(self.name + " is already programmed. Release before programming again")


        bitfile_abs = os.path.join(self.partialBitDir, bitfile)


        if os.path.isfile(bitfile):
            bitfile_path = bitfile
        elif os.path.isfile(bitfile_abs):
            bitfile_path = bitfile_abs
        else:
            raise IOError('Bitstream file {} does not exist.'
                          .format(bitfile))

        # First program hardware, this consists of activating the decoupler,
        # writing the bitstream, and then deactivating the decoupler
        decouplerMMIO = pynq.mmio.MMIO(self.decouplerBaseAddr)
        decouplerMMIO.write(self.GPIO_DATA_OFFSET, 1 << self.decouplerPinNum)

        b = Bitstream(bitfile_path, partial = True)
        b.download()

        decouplerMMIO.write(self.GPIO_DATA_OFFSET, 0)

        # Next, if there is an associated linux overlay, apply the overlay
        if linuxOverlayFile:  
            linuxOverlayFile_abs = os.path.join(self.dtboBaseDir, linuxOverlayFile)

            if os.path.isfile(linuxOverlayFile):
                linuxOverlayFile_name = linuxOverlayFile
            elif os.path.isfile(linuxOverlayFile_abs):
                linuxOverlayFile_name = linuxOverlayFile_abs
            else:
                raise IOError('Device Tree Overlay file {} does not exist.'
                              .format(linuxOverlayFile))

            DTO_Loader.loadOverlay(self.name, linuxOverlayFile_name)           
            self.linuxDTOprogrammed = True

        self.programmed = True

    def release(self):
        """
        This method will release the partial region, opening it up to being reprogrammed.
        If a device tree overlay has been inserted than it will remove it.

        Parameters
        ----------
        None
            
        Returns
        -------
        None

        """
        if (not self.programmed):
            raise Exception(self.name + " is not programmed")

        # If there is a associated linux overlay, remove the overlay
        if self.linuxDTOprogrammed:
            DTO_Loader.removeOverlay(self.name)
            self.linuxDTOprogrammed = False

        self.programmed = False

    def reserveMMIO(self, size = None):
        """
        This method will reserve MMIO for the PR region using the address provided 
        during init, of a provided size. This is a helper method when creating 
        userspace drivers.

        Parameters
        ----------
        size : int
            Size of memory block to be reserved. If nothing is specified it will 
            default to 0x00010000.
            
        Returns
        -------
        None

        """
        if size is None:
            size = self.ADDR_SPACE_SIZE
        self.mmio = pynq.mmio.MMIO(self.baseAddr, size)
        self.mmio_reserved = True

    def releaseMMIO(self):
        """
        This method will release the reserved mmio.
        Parameters
        ----------
        None
            
        Returns
        -------
        None

        """
        del self.mmio
        self.mmio = None
        self.mmio_reserved = False

    def writeDevice(self, offset, val):
        """
        This method will write a given value to a given offset in the reserved memory.

        Parameters
        ----------
        offset : int
            The offset from the base address to write to.

        val : int
            The value to write.
            
        Returns
        -------
        None

        """
        mmioWasReserved = False

        if not self.mmio_reserved:
            self.reserveMMIO(offset + 4)
            mmioWasReserved = True

        self.mmio.write(offset, val)

        if mmioWasReserved:
            self.releaseMMIO()

    def readDevice(self, offset):
        """
        This method will read a value from memory at the given offset.

        Parameters
        ----------
        offset : int
            The offset from the base address to read from.
            
        Returns
        -------
        int 
            The value read from memory.

        """
        mmioWasReserved = False

        if not self.mmio_reserved:
            self.reserveMMIO(offset + 4)
            mmioWasReserved = True

        val = self.mmio.read(offset)

        if mmioWasReserved:
            self.releaseMMIO()

        return val
    
    # def getLinuxDriverPath(self):
    #     return self.LINUX_DRIVER_PATH