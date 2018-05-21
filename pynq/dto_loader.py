import errno
import shutil
import os

__author__ = "Tanner Gaskin"
__email__ = "gaskin.tanner@byu.edu"

class DTO_Loader():

    CONFIGFS_PATH = "/sys/kernel/config/device-tree/overlays/"
    """
    Helper Class to handle inserting a device tree overlay (dtbo) file

    Note
    ----
    This class assumes that the kernel has been configured to allow for 
    device tree overlay's to be inserted via CONFIGFS.

    Attributes
    ----------
    CONFIGFS_PATH : string
        This is the path the location in the kernel that allows device tree 
        overlay files to be inserted into the device tree. This should not 
        need to change.


    """
    @classmethod
    def loadOverlay(self, name, dtboPath):
        """
        This method loads a device tree overlay into the device tree.

        Parameters
        ----------
        name : str
            The name of the PR region this overlay is associated with. This same name
            should be given when removing this same overlay.

        dtboPath : str
            The absolute path of the .dtbo file.

        Returns
        -------
        None

        """
        try:
            os.makedirs(self.CONFIGFS_PATH + name)
            shutil.copy2(dtboPath, self.CONFIGFS_PATH + name + "/dtbo")
        except OSError as e:
            if e.errno == errno.EEXIST:
                raise Exception(name + " overlay is already inserted into the device-tree. Release before trying again")
            raise


    @classmethod
    def removeOverlay(self, name):
        """
        This method removes a device tree overlay from the device tree.

        Parameters
        ----------
        name : str
            The name of the PR region this overlay is associated with. This same name
            should have been given when loading this same overlay.

        Returns
        -------
        None

        """
    
        if os.path.exists(self.CONFIGFS_PATH + name):
            shutil.rmtree(self.CONFIGFS_PATH + name, ignore_errors=True)
        else:
            raise Exception(name + " is not inserted into the device-tree")