# Verify pybind11 can compile and import a minimal C++ extension.

# p: manifest params dict for this test (from selftest.json "params").
import os
import shutil
import sys
import tempfile

from results import bad, ok, main_entry


def run(p=None):
    d = tempfile.mkdtemp(prefix="pynq_pb_")
    cwd = os.getcwd()
    try:
        os.chdir(d)
        from pynq.lib.pybind11.proc import Pybind11Processor

        Pybind11Processor(
            "pynq_selftest_pb",
            {"cflags": None, "ldflags": None},
            "int add(int a, int b){ return a + b; }\n",
        )
        sys.path.insert(0, d)
        import pynq_selftest_pb

        if pynq_selftest_pb.add(2, 3) == 5:
            ok("pybind11 compiled a C++ module and imported it")
        else:
            bad("pybind11 module returned a wrong result")
    finally:
        os.chdir(cwd)
        shutil.rmtree(d, ignore_errors=True)


if __name__ == "__main__":
    main_entry(run)
