#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

"""VCK190 BaseOverlay -- board-specific overlay wrapper.

Installed as ``pynq.overlays.base`` by the sdbuild pynq recipe so that
notebooks on a VCK190 image can do::

    from pynq.overlays.base import BaseOverlay
    base = BaseOverlay("base.pdi")
    base.leds[0].on()
    base.buttons[0].read()
    base.switches[0].read()
    base.dma  # AXI DMA (loopback via AXI Stream FIFO)

The ``leds``, ``buttons``, and ``switches`` attributes are AXI GPIO
channels configured with the correct direction and length for the
VCK190 board (4 LEDs, 4 push-buttons, 4 DIP switches).

The ``dma`` attribute exposes the AXI DMA engine connected in loopback
through an AXI Stream FIFO -- useful for validating the PL-to-DDR
data path end-to-end.
"""

from __future__ import annotations

import pynq

_GPIO_MAP = {
    "leds": ("axi_gpio_led", "out", 4),
    "buttons": ("axi_gpio_pb", "in", 4),
    "switches": ("axi_gpio_dip_sw", "in", 4),
}


class BaseOverlay(pynq.Overlay):
    """VCK190 base design overlay.

    Provides convenient access to the board's LEDs, push-buttons,
    DIP switches, and DMA engine through the loaded base design.

    Parameters
    ----------
    bitfile_name : str
        Path to the PDI, for example ``"base.pdi"``.
    **kwargs
        Forwarded to :class:`pynq.Overlay`.
    """

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        if self.is_loaded():
            self._init_gpio()

    def _init_gpio(self) -> None:
        """Configure the AXI GPIO channels for the VCK190 board."""
        for attr, (ip_name, direction, length) in _GPIO_MAP.items():
            if hasattr(self, ip_name):
                gpio = getattr(self, ip_name)
                channel = gpio.channel1
                channel.setdirection(direction)
                channel.setlength(length)
                setattr(self, attr, channel)

    @property
    def dma(self):
        """AXI DMA engine (loopback via AXI Stream FIFO).

        Returns the ``axi_dma_0`` IP driver, which provides the
        ``sendchannel`` (MM2S) and ``recvchannel`` (S2MM) attributes
        used for DMA transfers.
        """
        return self.axi_dma_0

    def download(self) -> None:
        super().download()
        if self.is_loaded():
            self._init_gpio()
