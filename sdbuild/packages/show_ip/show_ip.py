#!/usr/bin/python3.6

from pynq.overlays.base import BaseOverlay
from pynq import PL
from pynq.lib.pmod import PMOD_GROVE_G3
from pynq.lib.pmod import Grove_OLED
import subprocess as sp
import signal
from sys import exit


def show_ip(ol, interface, ip_addr):
    """Displays the given IP address on a GROVE OLED screen"""
    PL.reset()
    oled = Grove_OLED(ol.PMODB,PMOD_GROVE_G3)
    oled.clear()
    if interface:
        msg = f"IP for {interface:<5} is:{' '*16}{ip_addr}"
    else:
        f"Can't find interface with an IP"
    oled.write(msg)
    del oled

    
def parse_ip(interface):
    """Returns the IP address of a given network interface.
    
    Will return an empty string on error.
    """
    cmd = "ifconfig "+interface+" | grep 'inet ' | cut -f1 | awk '{ print $2}'"
    ip_output = sp.getoutput(cmd)
    if ip_output.endswith('Device not found'):
        return ''
    return ip_output


def get_first_ip(interfaces):
    """Search through the given interfaces for the first with an IP.
    
    Use the order of names in interfaces for setting priority.
    Returns a tuple of the interface name and its IP address.
    """
    for interface in interfaces:
        ip = parse_ip(interface)
        if ip:
            return interface, ip
    return '', ''


def timeout_handler(sig_num, stack_frame):
    """A simple handler for timeout signals"""
    raise Exception('Timeout!')

    
# Load base overlay
ol = BaseOverlay("base.bit")
timeout_secs = 5*60

# Setup signal for button timeout
signal.signal(signal.SIGALRM, timeout_handler)
signal.alarm(timeout_secs)

print("Ready for button press...")
print(f"Timing out in {timeout_secs} seconds")

# Try to wait for button press
try:
    ol.buttons[0].wait_for_value(1)
except Exception:
    print("Timed out. Exiting...")
    exit(0)

# Clear timeout
signal.alarm(0)

# Print IP
print("Button pressed. Continuing...")
interface, ip = get_first_ip(['wlan0', 'eth0'])
show_ip(ol, interface, ip)
