# Verify CMA pool size is at least ~512 MB (CmaTotal in /proc/meminfo).

# p: manifest params dict for this test (from selftest.json "params").
from results import bad, ok, params, sh, main_entry


def run(p=None):
    _, val = sh("awk '/CmaTotal/{print $2}' /proc/meminfo")
    kb = int(val) if val.isdigit() else 0
    if kb >= 500000:
        ok("CmaTotal %d kB (~512 MB)" % kb)
    else:
        bad("CmaTotal %d kB (<500 MB)" % kb)


if __name__ == "__main__":
    main_entry(run)
