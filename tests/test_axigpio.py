# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import pytest
from pynq.lib import AxiGPIO


from .mock_devices import MockRegisterDevice

@pytest.fixture
def device():
    device = MockRegisterDevice('register_device')
    yield device


BASE_ADDR = 0x10000
ADDR_RANGE = 0x10000


@pytest.fixture
def description(device):
    return {
        'phys_addr': BASE_ADDR,
        'addr_range': ADDR_RANGE,
        'interrupts' : {},
        'gpio': {},
        'parameters': {},
        'device': device,
    }


def test_output_on(description):
    gpio = AxiGPIO(description)
    gpio.setdirection(AxiGPIO.Output)
    device = description['device']
    with device.check_transactions([], [(BASE_ADDR, b'\x01\x00\x00\x00')]):
        gpio.channel1[0].on()


def test_output_read(description):
    gpio = AxiGPIO(description)
    gpio.setdirection(AxiGPIO.Output)
    device = description['device']
    with device.check_transactions([], [(BASE_ADDR, b'\x01\x00\x00\x00')]):
        gpio.channel1[0].on()
        assert gpio.channel1[0].read() == 1


def test_output_off(description):
    gpio = AxiGPIO(description)
    gpio.setdirection(AxiGPIO.Output)
    device = description['device']
    with device.check_transactions([], [(BASE_ADDR, b'\x07\x00\x00\x00'),
                                        (BASE_ADDR, b'\x04\x00\x00\x00')]):
        gpio.channel1[0:3].on()
        gpio.channel1[0:2].off()


def test_output_toggle(description):
    gpio = AxiGPIO(description)
    gpio.setdirection(AxiGPIO.Output)
    device = description['device']
    with device.check_transactions([], [(BASE_ADDR, b'\x06\x00\x00\x00'),
                                        (BASE_ADDR, b'\x09\x00\x00\x00')]):
        gpio.channel1[1:3].on()
        gpio.channel1[0:4].toggle()


def test_output_write(description):
    gpio = AxiGPIO(description)
    gpio.setdirection(AxiGPIO.Output)
    device = description['device']
    with device.check_transactions([], [(BASE_ADDR, b'\x06\x00\x00\x00'),
                                        (BASE_ADDR, b'\x1a\x00\x00\x00')]):
        gpio.channel1[1:3].write(3)
        gpio.channel1[2:5].write(6)


def test_input_read(description):
    gpio = AxiGPIO(description)
    gpio.setdirection(AxiGPIO.Input)
    device = description['device']
    with device.check_transactions([(BASE_ADDR, b'\x01\x00\x00\x00')], []):
        assert gpio.channel1[0].read() == 1


def test_inout_read(description):
    gpio = AxiGPIO(description)
    gpio.setdirection(AxiGPIO.InOut)
    device = description['device']
    with device.check_transactions([(BASE_ADDR + 4, b'\x12\x34\x56\x78'),
                                    (BASE_ADDR, b'\x01\x00\x00\x00')],
                                   [(BASE_ADDR + 4, b'\x13\x34\x56\x78')]):
        assert gpio.channel1[0].read() == 1


def test_inout_write(description):
    gpio = AxiGPIO(description)
    gpio.setdirection(AxiGPIO.InOut)
    device = description['device']
    with device.check_transactions([(BASE_ADDR + 4, b'\x12\x34\x56\x78')],
                                   [(BASE_ADDR + 4, b'\x12\x00\x56\x78'),
                                    (BASE_ADDR, b'\x00\x12\x00\x00')]):
        gpio.channel1[8:16].write(0x12)
