# Verify base-config overlay patches are applied to the live device tree.

# p: manifest params dict for this test (from selftest.json "params").
import os

from results import FailError, bad, ok, read, read_priv, main_entry


def run(p=None):
    sudoers = read_priv("/etc/sudoers")
    if not sudoers:
        raise FailError("/etc/sudoers not readable (needs root)")
    if 'env_keep="BOARD"' in sudoers:
        ok("sudoers keeps BOARD env")
    else:
        bad("sudoers missing env_keep BOARD")
    ssh_cfg = read("/etc/ssh/ssh_config")
    if any(l.strip().startswith("ForwardX11 yes") for l in ssh_cfg.splitlines()):
        ok("ssh_config ForwardX11 yes")
    else:
        bad("ssh_config ForwardX11 not enabled")
    if os.path.isfile("/etc/pip.conf"):
        ok("/etc/pip.conf present")
    else:
        bad("/etc/pip.conf missing")
    if "/opt/microblazeel-xilinx-elf/bin" in read("/etc/environment"):
        ok("PATH includes microblaze toolchain")
    else:
        bad("microblaze toolchain not on PATH")
    if os.environ.get("PYNQ_PYTHON") == "python3":
        ok("PYNQ_PYTHON=python3")
    else:
        bad("PYNQ_PYTHON not python3")
    if "[xilinx]" in read("/etc/samba/smb.conf"):
        ok("samba [xilinx] share present")
    else:
        bad("samba [xilinx] share missing")


if __name__ == "__main__":
    main_entry(run)
