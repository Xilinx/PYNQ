# Verify overlay package download, install, and import.
# Params: package or pip_url, module, nb_dir, etc.

import importlib.util
import os
import sys

from results import bad, ok, params, sh, main_entry


def run(p=None):
    p = p or {}
    py = sys.executable
    package = p.get("package")
    pip_url = p.get("pip_url")
    module = p.get("module")
    nb_dir = p.get("nb_dir")

    if pip_url and module:
        rc, _ = sh(
            "'%s' -m pip install --no-input '%s' >/tmp/ovl-pip.log 2>&1" % (py, pip_url),
            timeout=240,
        )
        if rc != 0:
            bad("pip install %s failed (no internet? see /tmp/ovl-pip.log)" % module)
            return
        ok("pip installed %s" % module)
        sh("'%s' -m %s uninstall >/tmp/ovl-uninstall.log 2>&1 || true" % (py, module), timeout=60)
        rc, _ = sh("'%s' -m %s install >/tmp/ovl-get.log 2>&1" % (py, module), timeout=180)
        if rc == 0:
            ok("%s install delivered overlay + notebooks" % module)
        else:
            bad("%s install step failed (see /tmp/ovl-get.log)" % module)
            return
        _, moddir = sh("'%s' -c 'import os,%s as m; print(os.path.dirname(m.__file__))'" % (py, module))
        _, bit = sh("find '%s' -name '*.bit' 2>/dev/null | head -1" % moddir)
    elif package and nb_dir:
        rc, _ = sh(
            "'%s' -m pip install --no-build-isolation --no-input %s >/tmp/ovl-pip.log 2>&1"
            % (py, package),
            timeout=180,
        )
        if rc != 0:
            bad("pip install %s failed (see /tmp/ovl-pip.log)" % package)
            return
        ok("pip installed %s" % package)
        sh("rm -rf %s" % nb_dir)
        rc, _ = sh(
            "pynq-get-notebooks %s -p %s --force >/tmp/ovl-get.log 2>&1" % (package, nb_dir),
            timeout=180,
        )
        if rc == 0:
            ok("pynq-get-notebooks delivered %s" % package)
        else:
            bad("pynq-get-notebooks failed (see /tmp/ovl-get.log)")
            return
        _, bit = sh(
            "find %s /usr/local/share/pynq-venv -name 'resizer.bit' 2>/dev/null | head -1" % nb_dir
        )
    else:
        bad("overlay_download params need (package + nb_dir) or (pip_url + module)")
        return

    if bit:
        rc, _ = sh(
            "'%s' -c \"from pynq import Overlay; Overlay('%s')\" >/tmp/ovl-load.log 2>&1"
            % (py, bit),
            timeout=120,
        )
        if rc == 0:
            ok("downloaded overlay programmed the PL (%s)" % os.path.basename(bit))
        else:
            bad("could not load a downloaded overlay bitstream (see /tmp/ovl-load.log)")
    else:
        bad("no bitstream found in the downloaded overlay")


if __name__ == "__main__":
    main_entry(run)
