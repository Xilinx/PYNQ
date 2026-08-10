#   Copyright (c) 2020-2021, Xilinx, Inc.
#   Copyright (c) 2025-2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import contextlib
from enum import Enum

from pynq import DefaultHierarchy

from .common import VideoMode
from .sensors import SENSORS, CameraSensor, detect_sensor


class MIPIMode(Enum):
    """Supported input video modes.

    Each value is (width, height, fps). The corresponding sensor-specific
    mode id comes from the detected sensor's ``MODES`` table.
    """

    r1280x720_60 = (1280, 720, 60)
    r1920x1080_30 = (1920, 1080, 30)
    r1920x1080_15 = (1920, 1080, 15)


class MipiCamera(DefaultHierarchy):
    """Driver for a MIPI CSI-2 camera on the base overlay.

    Supports every sensor in :data:`pynq.lib.video.sensors.SENSORS`. The
    attached camera is identified over I2C the first time
    :meth:`configure` is called, and its driver then programs the sensor
    while its metadata programs the rest of the pipeline (D-PHY HS_SETTLE,
    demosaic Bayer phase).

    Construction performs no hardware access, so loading the overlay
    always succeeds whether or not a camera is attached.

    Parameters
    ----------
    description : dict
        Entry in the ip_dict for the hierarchy
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

    def __init__(self, description):
        super().__init__(description)
        self._vdma = self.axi_vdma
        # Resolved on the first configure(); no I2C at construction time so
        # that overlay load cannot fail when no camera is attached.
        self._sensor = None
        self._bayer_phase = None

    def configure(self, videomode, sensor=None, bayer_phase=None):
        """Configure the camera and pipeline for the given video mode.

        Identifies the attached camera if it is not already known, then
        programs the sensor, the CSI-2 receiver and the image processing
        pipeline. If the pipeline is running it is stopped first.

        Parameters
        ----------
        videomode : VideoMode
            Format to configure the pipeline for. Its width, height and
            fps must correspond to a mode the detected sensor supports.
        sensor : type or None
            A :class:`CameraSensor` subclass to use instead of
            auto-detecting. Only needed to override detection.
        bayer_phase : int or None
            Demosaic Bayer phase (0=RGGB, 1=GRBG, 2=GBRG, 3=BGGR).
            Defaults to the sensor's ``BAYER_PHASE``; override if the
            captured image has the wrong hue.

        Returns
        -------
        context manager
            Closes the camera at the end of the block.
        """
        if self._vdma.readchannel.running:
            self._vdma.readchannel.stop()

        # Reset demosaic, gamma LUT and CSC before reprogramming them, then
        # power up the camera so it can answer on I2C.
        self.gpio_ip_reset.write(0x00, 0x01)
        self.gpio_ip_reset.write(0x00, 0x00)
        self.gpio_ip_reset.write(0x00, 0x01)
        CameraSensor.power_cycle(self.gpio_ip_reset)

        self._open_sensor(sensor)

        key = (videomode.width, videomode.height, videomode.fps)
        if key not in self._sensor.MODES:
            supported = ", ".join(f"{w}x{h}@{f}"
                                  for w, h, f in self._sensor.MODES)
            raise ValueError(
                f"{self._sensor.NAME} does not support "
                f"{videomode.width}x{videomode.height}@{videomode.fps}; "
                f"supported modes are {supported}")
        mode_id = self._sensor.MODES[key]

        if bayer_phase is None:
            bayer_phase = self._sensor.BAYER_PHASE
        self._bayer_phase = bayer_phase

        # Already powered up above, so skip the sensor's own power cycle.
        self._sensor.configure(mode_id, self.gpio_ip_reset,
                               power_cycle=False)

        # active_lanes is inert: the subsystem is built with
        # C_CSI_EN_ACTIVELANES = false, so the lane count is fixed in
        # hardware.
        #
        # HS_SETTLE is deliberately NOT written here. The build-time
        # C_HS_SETTLE_NS = 124 ns already sits inside the D-PHY spec
        # window for every supported sensor -- the windows are
        # [93.9, 159.9] ns for the OV5640 at 672 Mbps and [91.6, 156.0] ns
        # for the IMX parts at ~912 Mbps, which intersect at
        # [93.9, 156.0] ns. One build therefore covers all three, and
        # overwriting it at runtime only risks pushing a working link out
        # of spec. Each sensor still declares HS_SETTLE_NS so the value is
        # recorded next to its line rate if a future part needs it.
        self.mipi_csi2_rx_subsyst.configure(
            active_lanes=self._sensor.LANE_COUNT)

        self.demosaic.configure(videomode.width, videomode.height,
                                bayer_phase)
        self.gamma_lut.configure(videomode.width, videomode.height)
        self.v_proc_sys.configure(videomode.width, videomode.height)

        self.pixel_pack.bits_per_pixel = videomode.bits_per_pixel
        self._vdma.readchannel.mode = videomode

        self._sensor.start()
        return self._closecontextmanager()

    def _open_sensor(self, sensor=None):
        """Resolve and cache the attached sensor, opening its I2C bus."""
        if self._sensor is not None:
            if sensor is None or isinstance(self._sensor, sensor):
                return
            self._sensor.close()
            self._sensor = None
        i2c_bus = CameraSensor.find_i2c_bus()
        if sensor is None:
            sensor = detect_sensor(i2c_bus)
            if sensor is None:
                probed = ", ".join(f"{s.NAME} @ 0x{s.I2C_ADDR:02X}"
                                   for s in SENSORS)
                raise RuntimeError(
                    f"No supported camera found on /dev/i2c-{i2c_bus}; "
                    f"probed {probed}. Check the camera is attached and "
                    f"the ribbon cable is the right way round.")
        self._sensor = sensor(i2c_bus)

    def reconfigure(self, mode, bits_per_pixel=24):
        """Switch video mode at runtime.

        Parameters
        ----------
        mode : MIPIMode
            The new video mode
        bits_per_pixel : int
            Output pixel width
        """
        width, height, fps = mode.value
        return self.configure(
            VideoMode(width, height, bits_per_pixel, fps=fps))

    def start(self):
        """Start the pipeline"""
        if self._sensor is None:
            raise RuntimeError(
                "Camera not configured; call configure() first")
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
        """Context Manager to close the camera at the end of the block"""
        yield
        self.close()

    def close(self):
        """Uninitialise the drivers, stopping the pipeline beforehand"""
        self.stop()
        if self._sensor is not None:
            self._sensor.close()
            self._sensor = None

    @property
    def sensor(self):
        """The detected camera sensor driver, or None before configure()"""
        return self._sensor

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
        """Demosaic Bayer phase (0=RGGB, 1=GRBG, 2=GBRG, 3=BGGR).

        None until the pipeline has been configured.
        """
        return self._bayer_phase

    @bayer_phase.setter
    def bayer_phase(self, value):
        self._bayer_phase = value
        self.demosaic.register_map.bayer_phase = value & 0x3

    def _require_sensor(self):
        if self._sensor is None:
            raise RuntimeError(
                "Camera not configured; call configure() first")
        return self._sensor

    def mirror(self):
        """Toggle horizontal mirror of the sensor image."""
        self._require_sensor().mirror()

    def flip(self):
        """Toggle vertical flip of the sensor image."""
        self._require_sensor().flip()

    def test_pattern(self, enable=True):
        """Toggle the sensor's built-in test pattern.

        Useful to isolate the MIPI/D-PHY/VDMA transport from sensor
        imaging: if the pattern streams but normal capture does not, the
        transport is fine and the issue is imaging/AWB/exposure config;
        if the pattern also fails, the problem is in the MIPI path.

        Parameters
        ----------
        enable : bool
            True to emit the test pattern, False for normal imaging.
        """
        self._require_sensor().test_pattern(enable)

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
            "sensor": self._sensor.NAME if self._sensor else None,
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
