# Verify deb-src entries allow apt-get source for a core package.

# p: manifest params dict for this test (from selftest.json "params").
from results import bad, ok, sh, main_entry


def run(p=None):
    _, out = sh("grep -rh '^deb-src' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null")
    line = out.splitlines()[0] if out else ""
    if line:
        ok("deb-src source configured (%s)" % line)
    else:
        bad(
            "no 'deb-src' line in /etc/apt/sources.list(.d) -- "
            "GPL/legal source-availability regression (apt-get source will fail)"
        )
    rc, src_out = sh("apt-get source --print-uris bash 2>&1 | tail -5", timeout=30)
    if rc == 0 and ".dsc" in src_out:
        ok("apt-get source --print-uris bash resolved source URIs")
    else:
        bad(
            "apt-get source --print-uris bash failed (rc=%d): %s"
            % (rc, src_out.replace("\n", " | "))
        )


if __name__ == "__main__":
    main_entry(run)
