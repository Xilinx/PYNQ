# Verify outbound internet connectivity (DNS + HTTP fetch).

# p: manifest params dict for this test (from selftest.json "params").
from results import bad, ok, sh, main_entry


def run(p=None):
    rc, _ = sh(
        "curl -fsS --max-time 15 -o /dev/null https://github.com "
        "|| wget -q --timeout=15 -O /dev/null https://github.com",
        timeout=40,
    )
    if rc == 0:
        ok("reached https://github.com (overlay download possible)")
    else:
        bad("no internet reachable (overlay download needs DNS/gateway/proxy)")


if __name__ == "__main__":
    main_entry(run)
