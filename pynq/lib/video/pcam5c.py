#   Copyright (c) 2020-2021, Xilinx, Inc.
#   Copyright (c) 2025-2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import asyncio
import contextlib
import time
from enum import Enum

from pynq import DefaultHierarchy
from .ov5640 import OV5640


class MIPIMode(Enum):
    """Supported input video modes.

    Each value is (mode_id, width, height).
    """

    r1280x720_60 = (0, 1280, 720)
    r1920x1080_30 = (1, 1920, 1080)
    r1920x1080_15 = (2, 1920, 1080)


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
    bayer_phase : int
        Demosaic Bayer phase (0=RGGB, 1=GRBG, 2=GBRG, 3=BGGR). Adjust
        if the captured image has wrong hue.
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

    def __init__(self, description, mode=MIPIMode.r1280x720_60, bayer_phase=0x0):
        super().__init__(description)
        self._vdma = self.axi_vdma
        self._bayer_phase = bayer_phase
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

        # Enable the MIPI CSI-2 RX core
        self.mipi_csi2_rx_subsyst.configure(active_lanes=2)

        # Configure image processing pipeline
        self.demosaic.configure(width, height, self._bayer_phase)
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
        self.mipi_csi2_rx_subsyst.configure(active_lanes=2)
        self.demosaic.configure(width, height, self._bayer_phase)
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

    @property
    def bayer_phase(self):
        """Demosaic Bayer phase (0=RGGB, 1=GRBG, 2=GBRG, 3=BGGR)."""
        return self._bayer_phase

    @bayer_phase.setter
    def bayer_phase(self, value):
        self._bayer_phase = value
        self.demosaic.register_map.bayer_phase = value & 0x3

    def mirror(self):
        """Toggle horizontal mirror of the sensor image."""
        self._sensor.mirror()

    def flip(self):
        """Toggle vertical flip of the sensor image."""
        self._sensor.flip()

    def test_pattern(self, enable=True):
        """Toggle the sensor's built-in color-bar test pattern.

        Useful to isolate the MIPI/D-PHY/VDMA transport from sensor
        imaging: if color bars stream but normal capture does not, the
        transport is fine and the issue is imaging/AWB/exposure config;
        if color bars also fail, the problem is in the MIPI path.

        Parameters
        ----------
        enable : bool
            True to emit color bars, False for normal imaging.
        """
        self._sensor.test_pattern(enable)

    def diagnostics(self):
        """Return CSI-2 RX + D-PHY status to help triage a stalled capture.

        Reads the CSI-2 RX controller status and the D-PHY clock/data-lane
        status registers. Rough narrowing:

        - all lanes in stop state, packet_count 0 => no HS burst reaching
          the D-PHY (sensor silent, gated clock, or wrong HS_SETTLE).
        - dphy_cl_init_done 0 => D-PHY never initialized (clock/reset/PLL).
        - dphy_dl0_pkt_count > 0 but packet_count 0 => data dropped before
          the line buffer (lane map or filtered data type).
        - packet_count > 0 but readframe hangs => downstream (VDMA/format).

        Returns
        -------
        dict
            CSI-2 RX controller status, lane counts, and D-PHY status.
        """
        csi = self.mipi_csi2_rx_subsyst.register_map
        status = csi.core_status
        proto = csi.protocol_configuration
        cl = csi.dphy_cl_status
        dl0 = csi.dphy_dl0_status
        dl1 = csi.dphy_dl1_status
        return {
            "packet_count": int(status.packet_count),
            "stream_line_buffer_full": bool(status.stream_full),
            "short_packet_fifo_not_empty":
                bool(status.shot_packet_fifo_not_empty),
            "short_packet_fifo_full": bool(status.shot_packet_fifo_full),
            "active_lanes": int(proto.active_lanes) + 1,
            "maximum_lanes": int(proto.maximum_lanes) + 1,
            "dphy_enabled": bool(csi.dphy_control.dphy_en),
            "dphy_cl_init_done": bool(cl.init_done),
            "dphy_cl_stop_state": bool(cl.stop_state),
            "dphy_cl_mode": int(cl.mode),
            "dphy_dl0_init_done": bool(dl0.init_done),
            "dphy_dl0_stop_state": bool(dl0.stop_state),
            "dphy_dl0_pkt_count": int(dl0.pkt_count),
            "dphy_dl1_init_done": bool(dl1.init_done),
            "dphy_dl1_stop_state": bool(dl1.stop_state),
            "dphy_dl1_pkt_count": int(dl1.pkt_count),
        }

    def readframe(self, timeout=None):
        """Read a video frame.

        Parameters
        ----------
        timeout : float, optional
            Maximum seconds to wait for a frame. If None, blocks indefinitely.
            Raises TimeoutError if no frame arrives within the timeout.
        """
        if timeout is None:
            return self._vdma.readchannel.readframe()
        # Poll the VDMA frame-complete bit directly rather than using
        # asyncio. run_until_complete does not work reliably under the
        # Jupyter event loop, whereas a plain deadline poll behaves the
        # same in a script or a notebook.
        ch = self._vdma.readchannel
        if not ch.running:
            raise RuntimeError("DMA channel not started")
        deadline = time.monotonic() + timeout
        while ch._mmio.read(0x34) & 0x1000 == 0:
            if time.monotonic() > deadline:
                raise TimeoutError(f"readframe timed out after {timeout}s")
            time.sleep(0.001)
        ch._mmio.write(0x34, 0x1000)
        return ch._readframe_internal()

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
