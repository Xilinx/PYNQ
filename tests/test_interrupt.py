import asyncio
import functools
import importlib
import pynq
import pynq.interrupt
import pytest

from .mock_devices import MockIPDevice
from .mock_ip import MockRegisterIP

ZYNQ_PROC_INTERRUPTS = """
           CPU0       CPU1
 16:          1          0     GIC-0  27 Edge      gt
 17:          0          0     GIC-0  43 Level     ttc_clockevent
 18:       5171       6442     GIC-0  29 Edge      twd
 19:          0          0     GIC-0  37 Level     arm-pmu
 20:          0          0     GIC-0  38 Level     arm-pmu
 21:         43          0     GIC-0  39 Level     f8007100.adc
 23:          0          0     GIC-0  57 Level     cdns-i2c
 24:          0          0     GIC-0  80 Level     cdns-i2c
 26:          0          0     GIC-0  35 Level     f800c000.ocmc
 27:        245          0     GIC-0  59 Level     xuartps
 28:          7          0     GIC-0  51 Level     e000d000.spi
 29:          5          0     GIC-0  54 Level     eth0
 30:      20432          0     GIC-0  56 Level     mmc0
 31:          0          0     GIC-0  45 Level     f8003000.dmac
 32:          0          0     GIC-0  46 Level     f8003000.dmac
 33:          0          0     GIC-0  47 Level     f8003000.dmac
 34:          0          0     GIC-0  48 Level     f8003000.dmac
 35:          0          0     GIC-0  49 Level     f8003000.dmac
 36:          0          0     GIC-0  72 Level     f8003000.dmac
 37:          0          0     GIC-0  73 Level     f8003000.dmac
 38:          0          0     GIC-0  74 Level     f8003000.dmac
 39:          0          0     GIC-0  75 Level     f8003000.dmac
 40:         43          0     GIC-0  40 Level     f8007000.devcfg
 46:          0          0     GIC-0  53 Level     e0002000.usb
 47:          0          0     GIC-0  41 Edge      f8005000.watchdog
 48:          0          0     GIC-0  61 Level     fabric
IPI1:          0          0  Timer broadcast interrupts
IPI2:       2905       6470  Rescheduling interrupts
IPI3:          5          3  Function call interrupts
IPI4:          0          0  CPU stop interrupts
IPI5:          0          0  IRQ work interrupts
IPI6:          0          0  completion interrupts
"""

ZU_PROC_INTERRUPTS = """
           CPU0       CPU1       CPU2       CPU3
  3:      13287      12046       8626      10805     GICv2  30 Level     arch_timer
  6:          0          0          0          0     GICv2  67 Level     zynqmp_ipi
  7:          0          0          0          0     GICv2 175 Level     arm-pmu
  8:          0          0          0          0     GICv2 176 Level     arm-pmu
  9:          0          0          0          0     GICv2 177 Level     arm-pmu
 10:          0          0          0          0     GICv2 178 Level     arm-pmu
 12:          0          0          0          0     GICv2 156 Level     zynqmp-dma
 13:          0          0          0          0     GICv2 157 Level     zynqmp-dma
 14:          0          0          0          0     GICv2 158 Level     zynqmp-dma
 15:          0          0          0          0     GICv2 159 Level     zynqmp-dma
 16:          0          0          0          0     GICv2 160 Level     zynqmp-dma
 17:          0          0          0          0     GICv2 161 Level     zynqmp-dma
 18:          0          0          0          0     GICv2 162 Level     zynqmp-dma
 19:          0          0          0          0     GICv2 163 Level     zynqmp-dma
 21:          0          0          0          0     GICv2 109 Level     zynqmp-dma
 22:          0          0          0          0     GICv2 110 Level     zynqmp-dma
 23:          0          0          0          0     GICv2 111 Level     zynqmp-dma
 24:          0          0          0          0     GICv2 112 Level     zynqmp-dma
 25:          0          0          0          0     GICv2 113 Level     zynqmp-dma
 26:          0          0          0          0     GICv2 114 Level     zynqmp-dma
 27:          0          0          0          0     GICv2 115 Level     zynqmp-dma
 28:          0          0          0          0     GICv2 116 Level     zynqmp-dma
 30:       1192          0          0          0     GICv2  95 Level     eth0, eth0
 32:       1268          0          0          0     GICv2  50 Level     cdns-i2c
 33:          0          0          0          0     GICv2  42 Level     ff960000.memory-controller
 34:          0          0          0          0     GICv2  57 Level     axi-pmon, axi-pmon
 35:          0          0          0          0     GICv2 155 Level     axi-pmon, axi-pmon
 36:         45          0          0          0     GICv2  47 Level     ff0f0000.spi
 37:          0          0          0          0     GICv2  58 Level     ffa60000.rtc
 38:          0          0          0          0     GICv2  59 Level     ffa60000.rtc
 39:         60          0          0          0     GICv2 165 Level     ahci-ceva[fd0c0000.ahci]
 40:      19929          0          0          0     GICv2  81 Level     mmc0
 41:        205          0          0          0     GICv2  53 Level     xuartps
 44:          0          0          0          0     GICv2  84 Edge      ff150000.watchdog
 45:          0          0          0          0     GICv2  88 Level     ams-irq
 46:          0          0          0          0     GICv2 154 Level     fd4c0000.dma
 47:          0          0          0          0     GICv2 151 Level     fd4a0000.zynqmp-display
 48:          0          0          0          0     GICv2 121 Level     fabric
 49:          0          0          0          0     GICv2  97 Level     xhci-hcd:usb1
IPI0:      6410      10900       7427       7162       Rescheduling interrupts
IPI1:      1174       1560       1464       1218       Function call interrupts
IPI2:         0          0          0          0       CPU stop interrupts
IPI3:         0          0          0          0       CPU stop (for crash dump) interrupts
IPI4:       817        390        682        826       Timer broadcast interrupts
IPI5:         0          0          0          0       IRQ work interrupts
IPI6:         0          0          0          0       CPU wake-up interrupts
Err: 
"""  # NOQA


class MockInterruptController(MockRegisterIP):
    def __init__(self, address, callback=None):
        self.callback = callback
        self.ISR = 0
        self.IER = 0
        self.MER = 0
        self.lines = 0
        super().__init__(address, 0x20)

    def read_register(self, address):
        if address == 0x00:  # ISR
            return self.ISR | self.lines
        elif address == 0x04:  # IPR
            return (self.lines | self.ISR) & self.IER
        elif address == 0x08:  # IER
            return self.IER
        elif address == 0x0C:  # IAR
            return 0
        elif address == 0x10:  # SIE
            return 0
        elif address == 0x14:  # CIE
            return 0
        elif address == 0x18:  # IVR
            return 0
        elif address == 0x1C:  # MER
            return self.MER
        else:
            assert 0, 'Uknown register read'

    @property
    def active(self):
        return (self.lines | self.ISR) & self.IER != 0 and self.MER == 3

    def write_register(self, address, value):
        pre_active = self.active
        if address == 0x00:  # ISR
            assert 0, 'ISR is not writable'
        elif address == 0x04:  # IPR
            assert 0, 'IPR is not writable'
        elif address == 0x08:  # IER
            self.IER = value
        elif address == 0x0C:  # IAR
            self.ISR &= ~value
        elif address == 0x10:  # SIE
            self.IER |= value
        elif address == 0x14:  # CIE
            self.IER &= ~value
        elif address == 0x18:  # IVR
            assert 0, 'IVR is not writable'
        elif address == 0x1C:  # MER
            self.MER = value & 0x3
        else:
            assert 0, 'Unknown register written'
        post_active = self.active
        if pre_active ^ post_active:
            self.callback(post_active)

    def set_line(self, number, value):
        pre_active = self.active
        if value:
            self.ISR |= 1 << number
            self.lines |= 1 << number
        else:
            self.lines &= ~(1 << number)
        post_active = self.active
        if pre_active ^ post_active:
            self.callback(post_active)
        print("Lines: " + str(self.lines))
        print("ISR: " + str(self.ISR))


class MockUioController:
    def __init__(self):
        self._events = []
        self.value = False

    def add_event(self, event, number):
        if self.value:
            loop = asyncio.get_event_loop()
            loop.call_soon(event.set)
        else:
            self._events.append(event)

    def set_line(self, value):
        print(hash(asyncio.get_event_loop()))
        self.value = value
        if value is True:
            old_events = self._events
            self._events = []
            loop = asyncio.get_event_loop()
            for e in old_events:
                loop.call_soon(e.set)


@pytest.fixture
def interrupt():
    new_interrupt = importlib.reload(pynq.interrupt)
    yield new_interrupt


def _dummy_get_uio_device(dev_name):
    return "UIO Device: " + dev_name


GET_UIO_TESTS = {
    pynq.ps.ZYNQ_ARCH: (ZYNQ_PROC_INTERRUPTS, 61),
    pynq.ps.ZU_ARCH: (ZU_PROC_INTERRUPTS, 121)
}


@pytest.mark.parametrize('arch', [pynq.ps.ZYNQ_ARCH, pynq.ps.ZU_ARCH])
def test_get_uio(interrupt, fs, arch):
    interrupt.get_uio_device = _dummy_get_uio_device
    proc_contents, index = GET_UIO_TESTS[arch]
    fs.create_file('/proc/interrupts', contents=proc_contents)
    assert interrupt.get_uio_irq(index) == 'UIO Device: fabric'
    assert interrupt.get_uio_irq(1234) is None


DIRECT_SETUP = {
    'interrupt_pins': {
        'direct_interrupt': {'controller': '', 'index': 0, 'raw_irq': 61}
    },
    'interrupt_controllers': {},
    'ip_dict': {}
}


STANDARD_SETUP = {
    'interrupt_pins': {
        'standard_interrupt': {'controller': 'pynq_intc', 'index': 0}
    },
    'interrupt_controllers': {
        'pynq_intc': {'parent': '', 'index': 0, 'raw_irq': 61}
    },
    'ip_dict': {
        'pynq_intc': {
            'phys_addr': 0x10000,
            'address_range': 0x100
        }
    }
}


DOUBLE_SETUP = {
    'interrupt_pins': {
        'interrupt1': {'controller': 'pynq_intc', 'index': 0},
        'interrupt2': {'controller': 'pynq_intc', 'index': 1}
    },
    'interrupt_controllers': {
        'pynq_intc': {'parent': '', 'index': 0, 'raw_irq': 61}
    },
    'ip_dict': {
        'pynq_intc': {
            'phys_addr': 0x10000,
            'address_range': 0x100
        }
    }
}


NESTED_SETUP = {
    'interrupt_pins': {
        'interrupt1': {'controller': 'pynq_intc', 'index': 0},
        'interrupt2': {'controller': 'pynq_intc', 'index': 1}
    },
    'interrupt_controllers': {
        'pynq_intc': {'parent': 'parent_intc', 'index': 0},
        'parent_intc': {'parent': '', 'index': 0, 'raw_irq': 61}
    },
    'ip_dict': {
        'pynq_intc': {
            'phys_addr': 0x10000,
            'address_range': 0x100
        },
        'parent_intc': {
            'phys_addr': 0x20000,
            'address_range': 0x100
        }
    }
}


class MockParser:
    def __init__(self, setup):
        self.ip_dict = setup.get('ip_dict', {})
        self.hierarchy_dict = setup.get('hierarchy_dict', {})
        self.gpio_dict = setup.get('gpio_dict', {})
        self.clock_dict = setup.get('clock_dict', {})
        self.mem_dict = setup.get('mem_dict', {})
        self.interrupt_pins = setup.get('interrupt_pins', {})
        self.interrupt_controllers = setup.get('interrupt_controllers', {})


def _setup_device(device, setup, interrupt):
    parser = MockParser(setup)
    device.reset(parser, timestamp='now')
    controllers = {}
    uio_devices = {}
    for name, details in parser.interrupt_controllers.items():
        controllers[name] = MockInterruptController(
            parser.ip_dict[name]['phys_addr'])
        device.ip.append(controllers[name])
    for name, details in parser.interrupt_controllers.items():
        index = details['index']
        if details['parent'] == '':
            if index not in uio_devices:
                uio_devices[index] = MockUioController()
            controllers[name].callback = uio_devices[index].set_line
        else:
            controllers[name].callback = functools.partial(
                controllers[details['parent']].set_line, index)
    endpoints = {}
    for name, details in parser.interrupt_pins.items():
        index = details['index']
        parent = details['controller']
        if parent == '':
            if index not in uio_devices:
                uio_devices[index] = MockUioController()
            endpoints[name] = uio_devices[index].set_line
        else:
            endpoints[name] = functools.partial(
                controllers[parent].set_line, index)

    def UioController(dev_name):
        return uio_devices[dev_name]

    def get_uio_irq(index):
        return index - 61

    interrupt.UioController = UioController
    interrupt.get_uio_irq = get_uio_irq
    return endpoints


@pytest.fixture
def ipdevice():
    device = MockIPDevice([], "ipdevice")
    pynq.Device.active_device = device
    yield device
    pynq.Device.active_device = None


@pytest.mark.asyncio
async def test_simple_interrupt(interrupt, ipdevice):
    endpoints = _setup_device(ipdevice, STANDARD_SETUP, interrupt)
    pin = interrupt.Interrupt('standard_interrupt')
    endpoints['standard_interrupt'](True)
    await pin.wait()


@pytest.mark.asyncio
async def test_invalidate(interrupt, ipdevice):
    endpoints = _setup_device(ipdevice, STANDARD_SETUP, interrupt)
    pin = interrupt.Interrupt('standard_interrupt')
    endpoints['standard_interrupt'](True)
    ipdevice.reset(MockParser(STANDARD_SETUP), timestamp='not now')
    pin2 = interrupt.Interrupt('standard_interrupt')  # NOQA
    with pytest.raises(RuntimeError):
        await pin.wait()


@pytest.mark.asyncio
async def test_duplicate_interrupt(interrupt, ipdevice):
    endpoints = _setup_device(ipdevice, STANDARD_SETUP, interrupt)
    pin = interrupt.Interrupt('standard_interrupt')
    pin2 = interrupt.Interrupt('standard_interrupt')
    wait1 = asyncio.ensure_future(pin.wait())
    wait2 = asyncio.ensure_future(pin2.wait())
    await(asyncio.sleep(0))
    endpoints['standard_interrupt'](True)
    await wait1
    await wait2


@pytest.mark.asyncio
async def test_double_wait(interrupt, ipdevice):
    endpoints = _setup_device(ipdevice, STANDARD_SETUP, interrupt)
    pin = interrupt.Interrupt('standard_interrupt')
    wait1 = asyncio.ensure_future(pin.wait())
    wait2 = asyncio.ensure_future(pin.wait())
    await(asyncio.sleep(0))
    endpoints['standard_interrupt'](True)
    await wait1
    await wait2


@pytest.mark.asyncio
@pytest.mark.parametrize('setup', [DOUBLE_SETUP, NESTED_SETUP])
async def test_two_interrupts(interrupt, ipdevice, setup):
    endpoints = _setup_device(ipdevice, setup, interrupt)
    pin = interrupt.Interrupt('interrupt1')
    pin2 = interrupt.Interrupt('interrupt2')
    endpoints['interrupt1'](True)
    await pin.wait()
    endpoints['interrupt1'](False)
    endpoints['interrupt2'](True)
    await pin2.wait()
    endpoints['interrupt2'](False)


@pytest.mark.asyncio
@pytest.mark.parametrize('setup', [DOUBLE_SETUP, NESTED_SETUP])
async def test_simul_wait(interrupt, ipdevice, setup):
    endpoints = _setup_device(ipdevice, setup, interrupt)
    pin = interrupt.Interrupt('interrupt1')
    pin2 = interrupt.Interrupt('interrupt2')
    wait1 = asyncio.ensure_future(pin.wait())
    wait2 = asyncio.ensure_future(pin2.wait())
    await(asyncio.sleep(0))
    print('Post sleep')
    endpoints['interrupt1'](True)
    await wait1
    endpoints['interrupt1'](False)
    endpoints['interrupt2'](True)
    await wait2
    endpoints['interrupt2'](False)


@pytest.mark.asyncio
async def test_direct_interrupt(interrupt, ipdevice):
    endpoints = _setup_device(ipdevice, DIRECT_SETUP, interrupt)
    pin = interrupt.Interrupt('direct_interrupt')
    wait = asyncio.ensure_future(pin.wait())    
    endpoints['direct_interrupt'](True)
    await wait
    endpoints['direct_interrupt'](False)


@pytest.mark.asyncio
async def test_direct_duplicate_interrupt(interrupt, ipdevice):
    endpoints = _setup_device(ipdevice, DIRECT_SETUP, interrupt)
    pin = interrupt.Interrupt('direct_interrupt')
    pin2 = interrupt.Interrupt('direct_interrupt')
    assert pin.parent == pin2.parent
    wait1 = asyncio.ensure_future(pin.wait())
    wait2 = asyncio.ensure_future(pin2.wait())
    await(asyncio.sleep(0))
    endpoints['direct_interrupt'](True)
    await wait1
    await wait2


def test_invalid_interrupt(interrupt, ipdevice):
    endpoints = _setup_device(ipdevice, STANDARD_SETUP, interrupt)  # NOQA
    with pytest.raises(ValueError):
        pin = interrupt.Interrupt('invalid')  # NOQA


def failing_uio(number):
    return None


def test_missing_uio(interrupt, ipdevice):
    endpoints = _setup_device(ipdevice, STANDARD_SETUP, interrupt)  # NOQA
    interrupt.get_uio_irq = failing_uio
    with pytest.raises(ValueError):
        pin = interrupt.Interrupt('standard_interrupt')  # NOQA
