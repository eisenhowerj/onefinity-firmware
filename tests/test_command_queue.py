import importlib.util
import sys
from pathlib import Path
from types import ModuleType, SimpleNamespace
from unittest.mock import Mock

import pytest

COMMAND_QUEUE = Path(__file__).parents[1] / "src" / "py" / "bbctrl" / "CommandQueue.py"


@pytest.fixture
def queue_class(monkeypatch):
    bbctrl = ModuleType("bbctrl")
    bbctrl.log = SimpleNamespace(WARNING=30)
    monkeypatch.setitem(sys.modules, "bbctrl", bbctrl)

    spec = importlib.util.spec_from_file_location(
        "command_queue_under_test", COMMAND_QUEUE
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.CommandQueue


def test_commands_release_in_order_when_ids_are_acknowledged(queue_class):
    logger = Mock()
    logger.get.return_value = logger
    queue = queue_class(SimpleNamespace(log=logger))
    released = []

    queue.enqueue(1, released.append, "first")
    queue.enqueue(2, released.append, "second")
    queue.enqueue(3, released.append, "third")

    queue.release(2)
    assert released == ["first", "second"]
    assert queue.is_active() == 1

    queue.release(3)
    assert released == ["first", "second", "third"]
    assert queue.is_active() == 0
