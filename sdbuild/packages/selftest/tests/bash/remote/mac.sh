#!/bin/bash
# Verify Ethernet MAC is factory-assigned from EEPROM (not random/locally-administered).

iface=eth0
mac=$(cat "/sys/class/net/${iface}/address" 2>/dev/null || true)
if [[ -z $mac ]]; then
    for n in /sys/class/net/*; do
        name=${n##*/}
        case "$name" in
            lo|usb*|docker*|veth*|sit*) continue ;;
        esac
        mac=$(cat "$n/address" 2>/dev/null || true)
        if [[ -n $mac ]]; then
            iface=$name
            break
        fi
    done
fi
if [[ -z $mac ]]; then
    bad "no ethernet interface with a MAC found"
    exit 0
fi
first=$(printf '%d' "0x${mac%%:*}" 2>/dev/null || echo 0)
if (( first & 1 )); then
    bad "${iface} MAC ${mac} is multicast (invalid unicast address)"
elif (( first & 2 )); then
    bad "${iface} MAC ${mac} is locally-administered (random/fallback, not from EEPROM)"
else
    ok "${iface} MAC ${mac} is globally-administered (factory MAC from EEPROM)"
fi
