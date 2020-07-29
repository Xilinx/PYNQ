import os
import pynq
import pytest
import shutil
import importlib


@pytest.fixture(params=[pynq.ps.ZU_ARCH, pynq.ps.ZYNQ_ARCH])
def gpio(request):
    old_arch = pynq.ps.CPU_ARCH
    pynq.ps.CPU_ARCH = request.param
    new_gpio = importlib.reload(pynq.gpio)
    yield new_gpio
    pynq.ps.CPU_ARCH = old_arch


expected_min_pins = {
    pynq.ps.ZYNQ_ARCH: 54,
    pynq.ps.ZU_ARCH: 78
}


def test_gpio_offset(gpio):
    assert gpio.GPIO._GPIO_MIN_USER_PIN == expected_min_pins[pynq.ps.CPU_ARCH]


def test_gpio_warning():
    with pytest.warns(ResourceWarning):
        importlib.reload(pynq.gpio)


ZYNQ_CHIPS = [
    (338, 96, 'zynq_gpio'),
    (120, 32, 'ti-gpio')
]


# Offset the base so user index is the same
ZU_CHIPS = [
    (314, 96, 'zynq_gpio'),
    (120, 32, 'ti-gpio')
]

chip_dict = {
    pynq.ps.ZYNQ_ARCH: ZYNQ_CHIPS,
    pynq.ps.ZU_ARCH: ZU_CHIPS
}


def be_root():
    return 0


@pytest.fixture
def as_root(monkeypatch):
    monkeypatch.setattr(os, 'geteuid', be_root)


def export_hook(f):
    f.filesystem.create_file(
        '/sys/class/gpio/gpio' + f.byte_contents.decode() + '/value',
        contents='1')


def unexport_hook(f):
    shutil.rmtree('/sys/class/gpio/gpio' + f.byte_contents.decode())


def _create_gpiofs(fs, chips=None):
    if chips is None:
        chips = chip_dict[pynq.ps.CPU_ARCH]
    fs.create_file('/sys/class/gpio/export', side_effect=export_hook)
    fs.create_file('/sys/class/gpio/unexport', side_effect=unexport_hook)
    os.mkdir('/sys/class/gpio/other_dir')
    for base, width, name in chips:
        chippath = os.path.join('/sys/class/gpio/gpiochip' + str(base))
        fs.create_file(os.path.join(chippath, 'label'), contents=name)
        fs.create_file(os.path.join(chippath, 'ngpio'), contents=str(width))


def _file_contents(path):
    with open(path, 'r') as f:
        return f.read()


def _set_contents(path, contents):
    with open(path, 'w') as f:
        f.write(contents)


def test_get_base(gpio, fs):
    _create_gpiofs(fs)
    assert gpio.GPIO.get_gpio_pin(10) == 402
    assert gpio.GPIO.get_gpio_npins() == 96
    assert gpio.GPIO.get_gpio_pin(10, 'ti-gpio') == 130
    assert gpio.GPIO.get_gpio_npins('ti-gpio') == 32
#    assert gpio.GPIO.get_gpio_pin(10, 'unknown') == None
    assert gpio.GPIO.get_gpio_npins('unknown') is None
    assert gpio.GPIO.get_gpio_base('unknonw') is None


def test_gpio_in(gpio, fs, as_root):
    _create_gpiofs(fs)
    pin = gpio.GPIO(400, 'in')
    assert _file_contents('/sys/class/gpio/export') == '400'
    assert _file_contents('/sys/class/gpio/gpio400/direction') == 'in'
    assert pin.path == '/sys/class/gpio/gpio400/'
    assert pin.index == 400
    assert pin.direction == 'in'
    assert pin.read() == 1
    _set_contents('/sys/class/gpio/gpio400/value', '0')
    assert pin.read() == 0
    with pytest.raises(AttributeError):
        pin.write(1)
    pin.release()
    assert os.path.exists('/sys/class/gpio/gpio400') is False


def test_gpio_out(gpio, fs, as_root):
    _create_gpiofs(fs)
    pin = gpio.GPIO(400, 'out')
    assert _file_contents('/sys/class/gpio/export') == '400'
    assert _file_contents('/sys/class/gpio/gpio400/direction') == 'out'
    assert pin.path == '/sys/class/gpio/gpio400/'
    assert pin.index == 400
    assert pin.direction == 'out'
    pin.write(1)
    assert _file_contents('/sys/class/gpio/gpio400/value') == '1'
    pin.write(0)
    assert _file_contents('/sys/class/gpio/gpio400/value') == '0'
    with pytest.raises(AttributeError):
        pin.read()
    with pytest.raises(ValueError):
        pin.write(2)

    pin.release()
    assert os.path.exists('/sys/class/gpio/gpio400') is False


def test_gpio_exists(gpio, fs, as_root):
    _create_gpiofs(fs)
    _set_contents('/sys/class/gpio/export', '400')
    in_gpio = gpio.GPIO(400, 'in')
    with pytest.raises(AttributeError):
        out_gpio = gpio.GPIO(400, 'out')
    in_gpio.release()
    out_gpio = gpio.GPIO(400, 'out')
    out_gpio2 = gpio.GPIO(400, 'out')
    assert out_gpio._impl == out_gpio2._impl
    out_gpio.release()
    assert os.path.exists('/sys/class/gpio/gpio400') is False
    out_gpio2.release()


def test_permissions_check(gpio):
    with pytest.raises(EnvironmentError):
        gpio.GPIO(400, 'out')


def test_invalid_direction(gpio, as_root):
    with pytest.raises(ValueError):
        gpio.GPIO(400, 'direction')
