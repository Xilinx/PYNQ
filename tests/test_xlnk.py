import inspect
import pynq
import pytest
import sys
import warnings


class DummyXlnkLib:
    pass


def fake_root():
    return 0


def linenumber():
    cf = inspect.currentframe()
    return cf.f_back.f_lineno


def test_deprecation_level(monkeypatch, recwarn):
    monkeypatch.setattr(pynq.xlnk.os, 'getuid', fake_root)
    pynq.Xlnk.libxlnk = DummyXlnkLib
    warnings.filterwarnings("ignore", category=DeprecationWarning)
    warnings.filterwarnings("default", category=DeprecationWarning,
                            module=__name__,
                            lineno=linenumber()+1)
    xlnk = pynq.Xlnk()
    pynq.Xlnk.libxlnk = None
    if len(recwarn) == 0:
        pytest.fail("Xlnk deprecation should be seen at top-level")


def indirect_xlnk():
    xlnk = pynq.Xlnk()


def test_deprecation_level_indirect(monkeypatch, recwarn):
    monkeypatch.setattr(pynq.xlnk.os, 'getuid', fake_root)
    pynq.Xlnk.libxlnk = DummyXlnkLib
    warnings.filterwarnings("ignore", category=DeprecationWarning)
    warnings.filterwarnings("default", category=DeprecationWarning,
                            module=__name__,
                            lineno=linenumber()+1)
    indirect_xlnk()
    pynq.Xlnk.libxlnk = None
    if len(recwarn) != 0:
        pytest.fail("Xlnk deprecation should not be seen at below top-level")
