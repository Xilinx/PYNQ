# PYNQ.remote self-test

On-target checks for PYNQ.remote images, installed by the
`pynq-remote-selftest` Yocto recipe.

## On the board

```sh
sudo remote-selftest
```

Runs modular bash checks from
`/usr/local/share/pynq-remote-selftest/tests/remote/` (service, gRPC, XRT,
FPGA manager, networking, MAC, board identity, systemd).

Sources live in `sdbuild/packages/selftest/tests/bash/remote/` and
`sdbuild/packages/selftest/pynq-remote-selftest`.

## From a host

Requires the `pynq` package on the host (`pynq/remote/selftest/`):

```sh
pynq-remote-selftest --ip <board-ip>
pynq-remote-selftest --ip <board-ip> --bitstream base.xsa
pynq-remote-selftest --ip <board-ip> --list 
```

