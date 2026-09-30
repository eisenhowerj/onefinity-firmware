import importlib.util
import sys
from pathlib import Path
from types import ModuleType, SimpleNamespace
from unittest.mock import Mock

import pytest

GPIO_COMPAT = Path(__file__).parents[1] / "src" / "py" / "bbctrl" / "gpio_compat.py"


def load_gpio_compat(monkeypatch, lgpio=None, rpi_gpio=None):
    if lgpio is None:
        monkeypatch.setitem(sys.modules, "lgpio", None)
    else:
        monkeypatch.setitem(sys.modules, "lgpio", lgpio)

    if rpi_gpio is not None:
        rpi = ModuleType("RPi")
        rpi.__path__ = []
        monkeypatch.setitem(sys.modules, "RPi", rpi)
        monkeypatch.setitem(sys.modules, "RPi.GPIO", rpi_gpio)

    spec = importlib.util.spec_from_file_location("gpio_compat_under_test", GPIO_COMPAT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_lgpio_backend_delegates_pin_operations(monkeypatch):
    lgpio = SimpleNamespace(
        SET_PULL_UP=1,
        gpiochip_open=Mock(return_value=4),
        gpio_claim_output=Mock(),
        gpio_claim_input=Mock(),
        gpio_write=Mock(),
        gpio_read=Mock(return_value=1),
        gpio_free=Mock(),
        gpiochip_close=Mock(),
    )
    gpio = load_gpio_compat(monkeypatch, lgpio=lgpio)

    instance = gpio.GPIOCompat()
    instance.setup(17, gpio.OUT)
    instance.setup(18, gpio.IN, gpio.PUD_UP)
    instance.output(17, 1)

    assert instance.input(18) == 1
    lgpio.gpio_claim_output.assert_called_with(4, 17, 0)
    lgpio.gpio_claim_input.assert_called_with(4, 18, 1)
    lgpio.gpio_write.assert_called_with(4, 17, 1)
    lgpio.gpio_read.assert_called_with(4, 18)

    instance.cleanup()
    assert lgpio.gpio_free.call_count == 2
    lgpio.gpiochip_close.assert_called_once_with(4)


def test_rpi_gpio_fallback_delegates_pin_operations(monkeypatch):
    rpi_gpio = SimpleNamespace(
        BCM=11,
        OUT=1,
        IN=0,
        PUD_UP=2,
        PUD_DOWN=3,
        setwarnings=Mock(),
        setmode=Mock(),
        setup=Mock(),
        output=Mock(),
        input=Mock(return_value=1),
        cleanup=Mock(),
    )
    gpio = load_gpio_compat(monkeypatch, rpi_gpio=rpi_gpio)

    instance = gpio.GPIOCompat()
    instance.setup(17, gpio.OUT)
    instance.setup(18, gpio.IN, gpio.PUD_UP)
    instance.output(17, 1)

    assert instance.input(18) == 1
    rpi_gpio.setup.assert_any_call(17, rpi_gpio.OUT)
    rpi_gpio.setup.assert_any_call(18, rpi_gpio.IN, pull_up_down=rpi_gpio.PUD_UP)
    rpi_gpio.output.assert_called_once_with(17, 1)
    instance.cleanup()
    rpi_gpio.cleanup.assert_called_once_with()


@pytest.mark.hardware
def test_pi5_gpio_chip_is_available():
    lgpio = pytest.importorskip("lgpio")
    handle = lgpio.gpiochip_open(4)
    try:
        assert handle >= 0
    finally:
        if handle >= 0:
            lgpio.gpiochip_close(handle)
