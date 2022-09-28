#   Copyright (c) 2020-2021, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import contextlib
import os
from enum import Enum

import cffi

from pynq import DefaultHierarchy
from .constants import LIB_SEARCH_PATH



_pcam5c_lib_header = R"""
int pcam_mipi(
        int i2cbus,
        int usermode,
        unsigned long GPIO_IP_RESET_BaseAddress,
        unsigned long VPROCSSCS_BaseAddress,
        unsigned long GAMMALUT_BaseAddress,
        unsigned long DEMOSAIC_BaseAddress);
"""


class MIPIMode(Enum):
    """Suported input video modes"""

    r1280x720_60 = 0
    r1920x1080_30 = 1


class Pcam5C(DefaultHierarchy):
    """Driver for PCAM 5C"""

    @staticmethod
    def checkhierarchy(description):
        return (
            "gpio_ip_reset" in description["ip"]
            and "mipi_csi2_rx_subsyst" in description["ip"]
            and "demosaic" in description["ip"]
            and "gamma_lut" in description["ip"]
            and "v_proc_sys" in description["ip"]
            and "pixel_pack" in description["ip"]
        )

    def __init__(self, description):
        """Create a new instance of the driver

        Can raise `RuntimeError` if the shared library was not found.

        Parameters
        ----------
        description : dict
            Entry in the ip_dict for the device

        """
        pcam5c_ffi = cffi.FFI()
        pcam5c_ffi.cdef(_pcam5c_lib_header)
        pcam5c_lib = pcam5c_ffi.dlopen(os.path.join(LIB_SEARCH_PATH, "libpcam5c.so"))

        super().__init__(description)
        self._vdma = self.axi_vdma

        virtaddr_gpio_ip_reset = self.gpio_ip_reset.mmio.array.ctypes.data
        virtaddr_v_proc_sys = self.v_proc_sys.mmio.array.ctypes.data
        virtaddr_gamma_lut = self.gamma_lut.mmio.array.ctypes.data
        virtaddr_demosaic = self.demosaic.mmio.array.ctypes.data

        # todo read /sys/bus/i2c/devices/i2c-6/of_node/label

        self._handle = pcam5c_lib.pcam_mipi(
            6,
            int(MIPIMode.r1280x720_60.value),
            virtaddr_gpio_ip_reset,
            virtaddr_v_proc_sys,
            virtaddr_gamma_lut,
            virtaddr_demosaic,
        )
        if self._handle < 0:
            raise RuntimeError("PCam 5C cannot be initialized")

    def configure(self, videomode):
        """Configure the pipeline to use the specified VideoMode format.

        If the pipeline is running it is stopped prior to the configuration
        being changed

        Parameters
        ----------
        videomode : VideoMode
            The VideoMode format to configure the pipeline for
        """
        if self._vdma.readchannel.running:
            self._vdma.readchannel.stop()
        self.pixel_pack.bits_per_pixel = videomode.bits_per_pixel
        self._vdma.readchannel.mode = videomode
        return self._closecontextmanager()

    def start(self):
        """Start the pipeline"""
        self._vdma.readchannel.start()
        return self._stopcontextmanager()

    def stop(self):
        """Stop the pipeline"""
        self._vdma.readchannel.stop()

    @contextlib.contextmanager
    def _stopcontextmanager(self):
        """Context Manager to stop the VDMA at the end of the block"""
        yield
        self.stop()

    @contextlib.contextmanager
    def _closecontextmanager(self):
        """Context Manager to close the HDMI port at the end of the block"""
        yield
        self.close()

    def close(self):
        """Uninitialise the drivers, stopping the pipeline beforehand"""
        self.stop()

    @property
    def mode(self):
        """Video mode of the input"""
        return self._vdma.readchannel.mode

    @property
    def cacheable_frames(self):
        """Whether frames should be cacheable or non-cacheable

        Only valid if a VDMA has been specified
        """
        if self._vdma:
            return self._vdma.readchannel.cacheable_frames
        else:
            raise RuntimeError("No VDMA specified")

    @cacheable_frames.setter
    def cacheable_frames(self, value):
        if self._vdma:
            self._vdma.readchannel.cacheable_frames = value
        else:
            raise RuntimeError("No VDMA specified")

    def readframe(self):
        """Read a video frame

        See AxiVDMA.S2MMChannel.readframe for details
        """
        return self._vdma.readchannel.readframe()

    async def readframe_async(self):
        """Read a video frame

        See AxiVDMA.S2MMChannel.readframe for details
        """
        return await self._vdma.readchannel.readframe_async()

    def tie(self, output):
        """Mirror the video input on to an output channel

        Parameters
        ----------
        output : HDMIOut
            The output to mirror on to
        """
        self._vdma.readchannel.tie(output._vdma.writechannel)


