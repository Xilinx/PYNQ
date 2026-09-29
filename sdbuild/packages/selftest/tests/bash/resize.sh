# Verify root filesystem was expanded on first boot (RESIZED=1 in /etc/environment).

root_mb=$(df -m --output=size / | tail -1 | tr -d ' ')
if grep -q 'RESIZED=1' /etc/environment 2>/dev/null; then
    ok "resizefs ran (RESIZED=1); root is ${root_mb:-?} MiB"
else
    bad "RESIZED flag not set; root is ${root_mb:-?} MiB (resizefs did not run)"
fi
