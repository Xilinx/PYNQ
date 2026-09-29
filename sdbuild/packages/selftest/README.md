# PYNQ image self-test

On-board verification for classic PYNQ images. Each check is a small module
under `tests/bash/` or `tests/python/`. The board manifest selects which
checks run and passes per-test options.

## Layout

```
sdbuild/packages/selftest/
├── pynq-selftest              # entry point → lib/orchestrator.py
├── lib/
│   ├── orchestrator.py        # reads manifest, runs tests in order
│   ├── run_test.sh            # dispatches one test (bash or python)
│   ├── run_python.sh          # venv + XRT setup for Python tests
│   ├── results.py / results.sh  # shared ok/bad/skip helpers
│   └── board_helpers.py       # overlay helpers for hardware tests
├── tests/bash/                # OS / image checks (sourced by run_test.sh)
├── tests/python/              # PYNQ / overlay checks (run as scripts)
└── manifests/                 # optional defaults; board JSON installed at build time
```

During an image build, `pre.sh` installs this tree and copies
`boards/<BOARD>/selftest.json` to
`/usr/local/share/pynq-selftest/manifests/<BOARD>.json` when `PYNQ_BOARDDIR`
is set.

## Running on the board

Log in as `xilinx` and run:

```bash
sudo pynq-selftest                     # full run (hardware tests enabled)
sudo pynq-selftest --no-peripherals      # software-only; skips hardware tests
sudo pynq-selftest --list                # list manifest test ids
sudo pynq-selftest --test python/gpio    # run one test by id
```

Python tests run via `run_python.sh`, which sources the PYNQ venv and
`/etc/profile.d/xrt_setup.sh`. Root is required.

## Manifest format

Each board provides `boards/<BOARD>/selftest.json`:

```json
{
  "board": "MyBoard",
  "defaults": { "hardware": false, "timeout": 30 },
  "tests": [
    { "id": "bash/resize", "name": "Root filesystem auto-resize" },
    {
      "id": "python/overlay_allocate",
      "name": "PYNQ overlay + DMA buffer",
      "timeout": 90,
      "hardware": true,
      "params": { "bitstream": "base.bit" }
    }
  ]
}
```

| Field | Meaning |
|-------|---------|
| `id` | Test module path: `bash/<name>` → `tests/bash/<name>.sh`, `python/<name>` → `tests/python/<name>.py` |
| `name` | Label printed in the run log (optional; defaults to `id`) |
| `timeout` | Seconds before the test is killed (default 30) |
| `hardware` | When true, skipped with `--no-peripherals` |
| `params` | JSON object passed to Python tests (see below) |

Add the `selftest` package to `STAGE4_PACKAGES_<BOARD>` in your board `.spec`
and place `selftest.json` next to the spec file.

## Python test modules

Each Python test defines `run(p)` where **`p` is the manifest `params` dict**
for that test entry (empty dict if omitted). The orchestrator serialises
`params` into the `SELFTEST_PARAMS` environment variable; `main_entry()` in
`results.py` parses it and calls `run(p)`.

Example:

```python
from results import ok, params, main_entry

def run(p=None):
    p = p or {}
    bit = p.get("bitstream", "base.bit")
    ...

if __name__ == "__main__":
    main_entry(run)
```

Use `raise FailError("reason")` when a manifest-listed test finds a missing
capability or misconfiguration. Skips are reserved for optional steps (e.g.
remote host overlay download when `--bitstream` is omitted).

## PYNQ.remote images

PYNQ.remote checks use a separate runner and install path. See
`sdbuild/boot/meta-pynq/recipes-apps/pynq-remote-selftest/README.md`.
Sources live alongside this package in `tests/bash/remote/` and
`pynq-remote-selftest`; the Yocto recipe installs them on remote images only.
