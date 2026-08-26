# Verify serial console autologins as the xilinx user.

sg=/usr/lib/systemd/system/serial-getty@.service
if grep -q -- '--autologin xilinx' "$sg" 2>/dev/null; then
    ok "serial-getty@.service autologins xilinx"
else
    bad "serial-getty@.service missing --autologin xilinx"
fi
