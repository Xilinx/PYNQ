#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#   Copyright (c) 2016, NECST Laboratory, Politecnico di Milano
#   All rights reserved.
# 
#   Redistribution and use in source and binary forms, with or without 
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its 
#       contributors may be used to endorse or promote products derived from 
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

__author__      = "Luca Cerina"
__copyright__   = "Copyright 2016, NECST Laboratory, Politecnico di Milano"
__email__       = "luca.cerina@mail.polimi.it"

import os
import re
import subprocess as sproc

class Usb_Wifi(object):
    """This class controls the usb dongle wifi connection.

    The board is compatible with RALink RT5370 devices.

    Attributes
    ----------
    """

    def __init__(self):
        """Return an instance for the usb wifi connection"""

        net_devices = sproc.check_output('ip a', shell=True).decode()

        for line in net_devices.splitlines():
            m = re.match('^([\d]): ([\w]+): *', line)
            if m:
                if m.group(2) != 'lo' and m.group(2) != 'eth0':
                    self.wifi_port = m.group(2)
        print(self.wifi_port)

    def gen_network_file(self, ssid, password):
        """Generate connection file from ssid and password"""

        # get bash string into string format for key search
        wifikey_str = sproc.check_output('wpa_passphrase {} {}'.format(ssid,
                                         password), shell=True)
        wifikey_tokens = wifikey_str.decode().split('\n')

        # search clean list for tpsk key value
        for key_val in wifikey_tokens:
            if '\tpsk=' in key_val:
                wifi_wpa_key = key_val.split('=')[1]

        # write the network interface file with new ssid/password entry
        os.system('ip link set {} up'.format(self.wifi_port))

        net_iface_fh = open("/etc/network/interfaces.d/" + self.wifi_port, 'w')
        net_iface_fh.write("iface " + self.wifi_port + " inet dhcp\n")
        net_iface_fh.write(" wpa-ssid " + ssid + "\n")
        net_iface_fh.write(" wpa-psk " + wifi_wpa_key + "\n\n")
        net_iface_fh.close()

    def connect(self, ssid, password):
        """Connect to a network using ssid and password"""
        os.system('ifdown {}'.format(self.wifi_port))
        self.gen_network_file(ssid, password)
        os.system('ifup {}'.format(self.wifi_port))

    def reset(self):
        """Close connection and reset interface"""
        os.system('killall -9 wpa_supplicant')
        os.system('ifdown {}'.format(self.wifi_port))
        os.system('rm -fr /etc/network/interfaces.d/wl*')
	
    def list_ssid(self):
        """To be implemented with iwlist tool"""
