# Verify merged-/usr layout (/bin, /sbin, /lib, /lib64 symlink into /usr).

if [[ -L /bin && -L /sbin && -L /lib && -L /lib64 ]]; then
    ok "/bin,/sbin,/lib,/lib64 are symlinks into /usr"
else
    bad "split-/usr detected (not all of /bin,/sbin,/lib,/lib64 are symlinks)"
fi
