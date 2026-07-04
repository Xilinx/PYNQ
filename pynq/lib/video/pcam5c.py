#   Copyright (c) 2020-2021, Xilinx, Inc.
#   Copyright (c) 2025-2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import contextlib
from enum import Enum

from pynq import DefaultHierarchy
from .ov5640 import OV5640


class MIPIMode(Enum):
    """Supported input video modes.

    Each value is (mode_id, width, height).
    """

    r1280x720_60 = (0, 1280, 720)
    r1920x1080_30 = (1, 1920, 1080)


class Pcam5C(DefaultHierarchy):
    """Driver for PCAM 5C.

    Initializes the OV5640 camera sensor over I2C and configures
    the image processing pipeline (demosaic, gamma LUT, CSC) via
    MMIO. No shared library required.

    Parameters
    ----------
    description : dict
        Entry in the ip_dict for the hierarchy
    mode : MIPIMode
        Initial video mode (default: 720p @ 60fps)
    """

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

    def __init__(self, description, mode=MIPIMode.r1280x720_60):
        super().__init__(description)
        self._vdma = self.axi_vdma
        mode_id, width, height = mode.value

        print("Not using using shared object library for PCAM5C. Using Python driver instead.")

        # Reset demosaic, gamma LUT, and CSC IPs
        self.gpio_ip_reset.write(0x00, 0x01)
        self.gpio_ip_reset.write(0x00, 0x00)
        self.gpio_ip_reset.write(0x00, 0x01)

        # Initialize camera sensor over I2C
        i2c_bus = OV5640.find_i2c_bus()
        self._sensor = OV5640(i2c_bus)
        self._sensor.configure(mode_id, self.gpio_ip_reset)

        # Configure image processing pipeline
        self.demosaic.configure(width, height)
        self.gamma_lut.configure(width, height)
        self.v_proc_sys.configure(width, height)

        # Start camera streaming
        self._sensor.start()

    def reconfigure(self, mode):
        """Switch video mode at runtime.

        Parameters
        ----------
        mode : MIPIMode
            The new video mode
        """
        self.stop()
        mode_id, width, height = mode.value
        self._sensor.reconfigure(mode_id, self.gpio_ip_reset)
        self.demosaic.configure(width, height)
        self.gamma_lut.configure(width, height)
        self.v_proc_sys.configure(width, height)

    def configure(self, videomode):
        """Configure the pipeline to use the specified VideoMode format.

        If the pipeline is running it is stopped prior to the configuration
        being changed.

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
        if hasattr(self, '_sensor') and self._sensor is not None:
            self._sensor.close()
            self._sensor = None

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

    def mirror(self):
        """Toggle horizontal mirror of the sensor image."""
        self._sensor.mirror()

    def flip(self):
        """Toggle vertical flip of the sensor image."""
        self._sensor.flip()

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
