# Verify RFSoC Python packages import successfully.
# Params: modules (list of package names).

from results import bad, ok, main_entry


def run(p=None):
    p = p or {}
    modules = p.get("modules", ["xrfclk", "xrfdc", "xsdfec"])
    for mod in modules:
        try:
            __import__(mod)
            ok("import %s" % mod)
        except Exception as e:
            bad("import %s failed: %r" % (mod, e))


if __name__ == "__main__":
    main_entry(run)
