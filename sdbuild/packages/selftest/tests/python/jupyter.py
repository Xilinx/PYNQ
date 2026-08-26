# Verify Jupyter server is installed and responds on the expected port.

# p: manifest params dict for this test (from selftest.json "params").
from results import bad, ok, sh, main_entry


def run(p=None):
    rc, _ = sh("systemctl is-active --quiet jupyter.service")
    if rc == 0:
        ok("jupyter.service active")
    else:
        bad("jupyter.service not active")
    rc, _ = sh("ss -tln | grep -q ':9090'")
    if rc == 0:
        ok("listening on :9090")
    else:
        bad("nothing listening on :9090")


if __name__ == "__main__":
    main_entry(run)
