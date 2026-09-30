import importlib.util
import sys
from pathlib import Path
from types import ModuleType, SimpleNamespace
from unittest.mock import Mock

PY_ROOT = Path(__file__).parents[1] / "src" / "py"


def load_module(monkeypatch, name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    monkeypatch.setitem(sys.modules, name, module)
    spec.loader.exec_module(module)
    return module


def test_avr_registers_mock_serial_port_with_event_loop(monkeypatch):
    serial = ModuleType("serial")
    serial.Serial = Mock()
    serial_port = serial.Serial.return_value
    bbctrl = ModuleType("bbctrl")
    bbctrl.__path__ = [str(PY_ROOT / "bbctrl")]
    bbctrl.Cmd = ModuleType("bbctrl.Cmd")
    monkeypatch.setitem(sys.modules, "bbctrl", bbctrl)
    monkeypatch.setitem(sys.modules, "bbctrl.Cmd", bbctrl.Cmd)
    monkeypatch.setitem(sys.modules, "serial", serial)

    avr_module = load_module(
        monkeypatch, "avr_under_test", PY_ROOT / "bbctrl" / "AVR.py"
    )
    logger = Mock()
    logger.get.return_value = logger
    ioloop = SimpleNamespace(READ=1, add_handler=Mock())
    ctrl = SimpleNamespace(
        args=SimpleNamespace(avr_addr=4, serial="/dev/fake", baud=115200),
        ioloop=ioloop,
        log=logger,
    )

    avr_module.AVR(ctrl)._start()

    serial.Serial.assert_called_once_with(
        "/dev/fake", 115200, rtscts=1, timeout=0, write_timeout=0
    )
    serial_port.nonblocking.assert_called_once_with()
    ioloop.add_handler.assert_called_once()


def test_camera_registers_mock_udev_monitor(monkeypatch):
    pyudev = ModuleType("pyudev")
    pyudev.Context = Mock()
    monitor = Mock()
    pyudev.Monitor = SimpleNamespace(from_netlink=Mock(return_value=monitor))
    monkeypatch.setitem(sys.modules, "pyudev", pyudev)

    bbctrl = ModuleType("bbctrl")
    bbctrl.__path__ = [str(PY_ROOT / "bbctrl")]
    bbctrl.get_resource = Mock()
    monkeypatch.setitem(sys.modules, "bbctrl", bbctrl)

    camera_module = load_module(
        monkeypatch, "camera_under_test", PY_ROOT / "bbctrl" / "Camera.py"
    )
    monkeypatch.setattr(camera_module.os.path, "exists", lambda path: False)
    ioloop = SimpleNamespace(READ=1, add_handler=Mock())
    args = SimpleNamespace(width=640, height=480, fps=30, camera_clients=2)

    camera_module.Camera(ioloop, args, Mock())

    pyudev.Context.assert_called_once_with()
    pyudev.Monitor.from_netlink.assert_called_once_with(pyudev.Context.return_value)
    monitor.filter_by.assert_called_once_with(subsystem="video4linux")
    ioloop.add_handler.assert_called_once()
    monitor.start.assert_called_once_with()
