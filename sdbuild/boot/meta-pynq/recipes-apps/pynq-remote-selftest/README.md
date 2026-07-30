# PYNQ.remote tests

Two tests for the PYNQ.remote appliance image, one on each side of the link.

## On-target (`pynq-remote-selftest`)

Baked into the remote image (installed to `/usr/bin` by `pynq-remote-selftest.bb`,
pulled in via `pynq-remote-image.bb`). Log in on the board and run:

```sh
pynq-remote-selftest
```

Checks that the board is ready to serve a remote host — no host connection
needed: `pynq-remote.service` active and listening on gRPC :7967, `zocl` + XRT
render node, the FPGA manager, `eth0` address, the `pynq_board` device-tree id,
and no failed systemd units.

## Off-board (`pynq-remote-hosttest.py`)

Runs on a **host** with the `pynq` package installed and network access to the
board. It uses the normal PYNQ API (routed to the target via
`PYNQ_REMOTE_DEVICES`) to exercise the host<->target data paths in both
directions:

```sh
python3 pynq-remote-hosttest.py --ip <board-ip>            # core checks
python3 pynq-remote-hosttest.py --ip <board-ip> --bitstream base.xsa
```

- **Connect + identity** — open the gRPC channel; read arch/board id (target->host).
- **File round-trip** — `write_file` then `read_file` (host->target->host).
- **Buffer round-trip** — `allocate` + `sync_to_device` (host->target) +
  `sync_from_device` (target->host), verifying data and `physical_address`.
- **Overlay download** *(with `--bitstream`)* — program the PL (host->target).
- **MMIO round-trip** *(with `--bitstream`)* — write then read back an AXI GPIO
  (host->target, target->host).

### Installing the client (host)

The client is the `pynq` package installed in "remote" mode (no C extensions):

```sh
PYNQ_REMOTE=1 pip install "pynq @ git+https://github.com/Xilinx/PYNQ.git"
```
