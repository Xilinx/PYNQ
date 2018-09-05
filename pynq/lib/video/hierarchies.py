#   Copyright (c) 2018, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"

import contextlib
from pynq import DefaultHierarchy
from .pipeline import ColorConverter, PixelPacker
from .frontend import VideoInFrontend, VideoOutFrontend
from .dma import AxiVDMA
from .common import *


class VideoIn(DefaultHierarchy):
    """Wrapper for the input video pipeline.

    This wrapper assumes the following pipeline structure and naming

    color_convert_in -> pixel_pack ->axi_vdma
    with vtc_in and axi_gpio_hdmiiin helper IP

    Attributes
    ----------
    frontend : pynq.lib.video.HDMIInFrontend
        The HDMI frontend for signal detection
    color_convert : pynq.lib.video.ColorConverter
        The input color format converter
    pixel_pack : pynq.lib.video.PixelPacker
        Converts the input pixel size to that required by the VDMA

    """

    @staticmethod
    def checkhierarchy(description):
        if 'frontend' in description['hierarchies']:
            frontend_dict = description['hierarchies']['frontend']
        elif 'frontend' in description['ip']:
            frontend_dict = description['ip']['frontend']
        else:
            return False
        return (
            'pixel_pack' in description['ip'] and
            'color_convert' in description['ip'] and
            description['ip']['pixel_pack']['driver'] == PixelPacker and
            description['ip']['color_convert']['driver'] == ColorConverter and
            issubclass(frontend_dict['driver'], VideoInFrontend))

    def __init__(self, description, vdma=None):
        """Initialise the drivers for the pipeline

        Parameters
        ----------
        path : str
            name of the hierarchy containing all of the video blocks

        """
        super().__init__(description)
        ip_dict = self.description
        self._vdma = vdma
        self._color = self.color_convert
        self._pixel = self.pixel_pack
        self._hdmi = self.frontend

    def configure(self, pixelformat=PIXEL_BGR):
        """Configure the pipeline to use the specified pixel format.

        If the pipeline is running it is stopped prior to the configuration
        being changed

        Parameters
        ----------
        pixelformat : PixelFormat
            The pixel format to configure the pipeline for

        """
        if self._vdma.readchannel.running:
            self._vdma.readchannel.stop()
        self._color.colorspace = pixelformat.in_color
        self._pixel.bits_per_pixel = pixelformat.bits_per_pixel
        self._hdmi.start()
        input_mode = self._hdmi.mode
        self._vdma.readchannel.mode = VideoMode(input_mode.width,
                                                input_mode.height,
                                                pixelformat.bits_per_pixel,
                                                input_mode.fps)
        return self._closecontextmanager()

    def start(self):
        """Start the pipeline

        """
        self._vdma.readchannel.start()
        return self._stopcontextmanager()

    def stop(self):
        """Stop the pipeline

        """
        self._vdma.readchannel.stop()

    @contextlib.contextmanager
    def _stopcontextmanager(self):
        """Context Manager to stop the VDMA at the end of the block

        """
        yield
        self.stop()

    @contextlib.contextmanager
    def _closecontextmanager(self):
        """Context Manager to close the HDMI port at the end of the block

        """
        yield
        self.close()

    def close(self):
        """Uninitialise the drivers, stopping the pipeline beforehand

        """
        self.stop()
        self._hdmi.stop()

    @property
    def colorspace(self):
        """The colorspace of the pipeline, can be changed without stopping
        the pipeline

        """
        return self._color.colorspace

    @colorspace.setter
    def colorspace(self, new_colorspace):
        self._color.colorspace = new_colorspace

    @property
    def mode(self):
        """Video mode of the input

        """
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


class VideoOut(DefaultHierarchy):
    """Wrapper for the output video pipeline.

    This wrapper assumes the following pipeline structure and naming

    axi_vdma -> pixel_unpack -> color_convert -> frontend
    with vtc_out and axi_dynclk helper IP

    Attributes
    ----------
    frontend : pynq.lib.video.HDMIOutFrontend
        The HDMI frontend for mode setting
    color_convert : pynq.lib.video.ColorConverter
        The output color format converter
    pixel_unpack : pynq.lib.video.PixelPacker
        Converts the input pixel size to 24 bits-per-pixel

    """

    @staticmethod
    def checkhierarchy(description):
        if 'frontend' in description['hierarchies']:
            frontend_dict = description['hierarchies']['frontend']
        elif 'frontend' in description['ip']:
            frontend_dict = description['ip']['frontend']
        else:
            return False
        return (
            'pixel_unpack' in description['ip'] and
            'color_convert' in description['ip'] and
            description['ip']['pixel_unpack']['driver'] == PixelPacker and
            description['ip']['color_convert']['driver'] == ColorConverter and
            issubclass(frontend_dict['driver'], VideoOutFrontend))

    def __init__(self, description, vdma=None):
        """Initialise the drivers for the pipeline

        Parameters
        ----------
        path : str
            name of the hierarchy containing all of the video blocks

        """
        super().__init__(description)
        self._vdma = vdma
        self._color = self.color_convert
        self._pixel = self.pixel_unpack
        self._hdmi = self.frontend

    def configure(self, mode, pixelformat=None):
        """Configure the pipeline to use the specified pixel format and size.

        If the pipeline is running it is stopped prior to the configuration
        being changed

        Parameters
        ----------
        mode : VideoMode
            The video mode to output
        pixelformat : PixelFormat
            The pixel format to configure the pipeline for

        """
        if self._vdma.writechannel.running:
            self._vdma.writechannel.stop()
        if pixelformat is None:
            if mode.bits_per_pixel == 8:
                pixelformat = PIXEL_GRAY
            elif mode.bits_per_pixel == 24:
                pixelformat = PIXEL_BGR
            elif mode.bits_per_pixel == 32:
                pixelformat = PIXEL_RGBA
            else:
                raise ValueError(
                    "No default pixel format for ${mode.bits_per_pixel} bpp")
        if pixelformat.bits_per_pixel != mode.bits_per_pixel:
            raise ValueError(
                "Video mode and pixel format have different sized pixels")

        self._color.colorspace = pixelformat.out_color
        self._pixel.bits_per_pixel = pixelformat.bits_per_pixel
        self._hdmi.mode = mode
        self._vdma.writechannel.mode = mode
        self._hdmi.start()
        return self._closecontextmanager()

    def start(self):
        """Start the pipeline

        """
        self._vdma.writechannel.start()
        return self._stopcontextmanager()

    def stop(self):
        """Stop the pipeline

        """
        self._vdma.writechannel.stop()

    def close(self):
        """Close the pipeline an unintialise the drivers

        """
        self.stop()
        self._hdmi.stop()

    @contextlib.contextmanager
    def _stopcontextmanager(self):
        """Context Manager to stop the VDMA at the end of the block

        """
        yield
        self.stop()

    @contextlib.contextmanager
    def _closecontextmanager(self):
        """Context Manager to close the HDMI port at the end of the block

        """
        yield
        self.close()

    @property
    def colorspace(self):
        """Set the colorspace for the pipeline - can be done without
        stopping the pipeline

        """
        return self._color.colorspace

    @colorspace.setter
    def colorspace(self, new_colorspace):
        self._color.colorspace = new_colorspace

    @property
    def mode(self):
        """The currently configured video mode

        """
        return self._vdma.writechannel.mode

    @property
    def cacheable_frames(self):
        """Whether frames should be cacheable or non-cacheable

        Only valid if a VDMA has been specified

        """
        if self._vdma:
            return self._vdma.writechannel.cacheable_frames
        else:
            raise RuntimeError("No VDMA specified")

    @cacheable_frames.setter
    def cacheable_frames(self, value):
        if self._vdma:
            self._vdma.writechannel.cacheable_frames = value
        else:
            raise RuntimeError("No VDMA specified")

    def newframe(self):
        """Return an unintialised video frame of the correct type for the
        pipeline

        """
        return self._vdma.writechannel.newframe()

    def writeframe(self, frame):
        """Write the frame to the video output

        See AxiVDMA.MM2SChannel.writeframe for more details

        """
        self._vdma.writechannel.writeframe(frame)

    async def writeframe_async(self, frame):
        """Write the frame to the video output

        See AxiVDMA.MM2SChannel.writeframe for more details

        """
        await self._vdma.writechannel.writeframe_async(frame)


class HDMIWrapper(DefaultHierarchy):
    """Hierarchy driver for the entire video subsystem.

    Exposes the input, output and video DMA as attributes. For most
    use cases the wrappers for the input and output pipelines are
    sufficient and the VDMA will not need to be used directly.

    Attributes
    ----------
    hdmi_in : pynq.lib.video.HDMIIn
        The HDMI input pipeline
    hdmi_out : pynq.lib.video.HDMIOut
        The HDMI output pipeline
    axi_vdma : pynq.lib.video.AxiVDMA
        The video DMA.

    """
    @staticmethod
    def checkhierarchy(description):
        in_pipeline = None
        out_pipeline = None
        dma = None
        for hier, details in description['hierarchies'].items():
            if details['driver'] == VideoIn:
                in_pipeline = hier
            elif details['driver'] == VideoOut:
                out_pipeline = hier

        for ip, details in description['ip'].items():
            if details['driver'] == AxiVDMA:
                dma = ip

        return (in_pipeline is not None and
                out_pipeline is not None and
                dma is not None)

    def __init__(self, description):
        super().__init__(description)
        in_pipeline = None
        out_pipeline = None
        dma = None
        for hier, details in description['hierarchies'].items():
            if details['driver'] == VideoIn:
                in_pipeline = hier
            elif details['driver'] == VideoOut:
                out_pipeline = hier
        for ip, details in description['ip'].items():
            if details['driver'] == AxiVDMA:
                dma = ip
        getattr(self, in_pipeline)._vdma = getattr(self, dma)
        getattr(self, out_pipeline)._vdma = getattr(self, dma)
