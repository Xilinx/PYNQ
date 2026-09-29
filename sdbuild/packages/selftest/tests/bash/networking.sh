# Verify at least one network interface has a global IPv4 address.

ip4=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $2" "$4}' | head -1)
if [[ -n $ip4 ]]; then
    ok "global IPv4 present ($ip4)"
else
    bad "no global IPv4 address on any interface"
fi
