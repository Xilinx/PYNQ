#   Copyright (c) 2026, Xilinx, Inc.
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

import os
from pathlib import Path

import pynq

_GPIO_MAP = {
    "leds": ("axi_gpio_led", "out", 4),
    "buttons": ("axi_gpio_pb", "in", 4),
    "switches": ("axi_gpio_dip_sw", "in", 4),
}


def _remap_bit_to_pdi(bitfile_name: str) -> str:
    """Versal PL programming uses ``.pdi``, not ``.bit``. Several
    stock PYNQ notebooks hardcode ``BaseOverlay("base.bit")`` though
    -- on Versal boards that filename has no on-disk match and the
    overlay load fails. Auto-remap to ``<stem>.pdi`` when the caller
    passes a ``.bit`` path that doesn't exist but a sibling ``.pdi``
    does (either absolute-file, local-cwd, or inside the installed
    overlay package directory).
    """
    if not isinstance(bitfile_name, str) or not bitfile_name.endswith(".bit"):
        return bitfile_name
    if Path(bitfile_name).is_file():
        return bitfile_name

    stem = bitfile_name[:-4]
    candidates = [stem + ".pdi"]
    # When bitfile_name is a bare name (no path), Overlay() would look
    # it up under the package dir. Do the same remap check there.
    if os.sep not in bitfile_name:
        pkg_dir = Path(__file__).resolve().parent
        candidates.append(str(pkg_dir / (stem + ".pdi")))

    for candidate in candidates:
        if Path(candidate).is_file():
            return candidate
    return bitfile_name


class BaseOverlay(pynq.Overlay):
    """VCK190 base design overlay.

    Provides convenient access to the board's LEDs, push-buttons,
    DIP switches, and DMA engine through the loaded base design.

    Parameters
    ----------
    bitfile_name : str
        Path to the PDI (default: ``"base.pdi"``). A ``.bit`` filename
        is silently remapped to ``.pdi`` when no ``.bit`` file exists
        -- this keeps stock PYNQ notebooks that hardcode
        ``BaseOverlay("base.bit")`` working on Versal.
    **kwargs
        Forwarded to :class:`pynq.Overlay`.
    """

    def __init__(self, *args, **kwargs) -> None:
        if args:
            args = (_remap_bit_to_pdi(args[0]),) + args[1:]
        elif "bitfile_name" in kwargs:
            kwargs["bitfile_name"] = _remap_bit_to_pdi(kwargs["bitfile_name"])
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
