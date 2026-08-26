# Verify xilinx user exists with expected group memberships.

# p: manifest params dict for this test (from selftest.json "params").
from results import bad, ok, sh, main_entry


def run(p=None):
    rc, _ = sh("id xilinx")
    if rc == 0:
        ok("xilinx user exists")
    else:
        bad("xilinx user missing")
    _, grps = sh("id -nG xilinx")
    g = grps.split()
    if "sudo" in g:
        ok("xilinx in sudo group")
    else:
        bad("xilinx not in sudo group")
    if "adm" in g:
        ok("xilinx in adm group")
    else:
        bad("xilinx not in adm group")


if __name__ == "__main__":
    main_entry(run)
