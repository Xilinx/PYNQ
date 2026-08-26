# Verify board notebooks were delivered to the jupyter tree.

# p: manifest params dict for this test (from selftest.json "params").
import os

from results import bad, ok, main_entry


def run(p=None):
    nbdir = os.environ.get("PYNQ_JUPYTER_NOTEBOOKS", "")
    if not nbdir:
        bad("PYNQ_JUPYTER_NOTEBOOKS unset in /etc/environment")
        return
    ok("PYNQ_JUPYTER_NOTEBOOKS=%s" % nbdir)
    if os.path.isdir(nbdir) and os.listdir(nbdir):
        ok("notebook dir exists and is populated")
    else:
        bad("notebook dir missing or empty (%s)" % nbdir)


if __name__ == "__main__":
    main_entry(run)
