# Verify no systemd units are in failed state.

failed=$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | tr '\n' ' ')
if [[ -z $failed ]]; then
    ok "no failed units"
else
    bad "failed units:${failed}"
fi
