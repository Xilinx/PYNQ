"""python3 -m pynq.remote.selftest --ip <target-ip> [--port 7967] [--bitstream base.xsa]"""

from pynq.remote.selftest.runner import main

if __name__ == "__main__":
    raise SystemExit(main())
