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

import os
import subprocess as sproc

__author__ = "Luca Cerina"
__copyright__ = "Copyright 2016, NECST Laboratory, Politecnico di Milano"
__email__ = "luca.cerina@mail.polimi.it"


class Wifi(object):
    """This class controls the WiFi connection.

    For USB WiFi, RALink RT5370 devices are recommended.

    Note
    ----
    Administrator rights are necessary to create network interface file

    Attributes
    ----------
    wifi_port : str
        string identifier of the wireless network device

    """

    def __init__(self, interface='wlan0'):
        """Initializes the wireless connection and assign devices identifier.

        Network devices are checked to find wireless components.
        Program will first try the default wireless interface name `wlan0`;
        if not found, it will look for interface name starting from `wl`.

        Parameters
        ----------
        interface : str
            The name of the network interface.

        """
        try:
            import netifaces
        except ImportError:
            raise ImportError("netifaces must be installed to configure WiFi")

        self.wifi_port = None
        net_device_list = netifaces.interfaces()

        if interface in net_device_list:
            self.wifi_port = interface
        else:
            for net_device in net_device_list:
                if net_device.startswith('wl'):
                    self.wifi_port = net_device
                    break

        if not self.wifi_port:
            raise ValueError("No WiFi device found. Re-attach the device "
                             "or check compatibility.")

    def gen_network_file(self, ssid, password, auto=False):
        """Generate the network authentication file.

        Generate the file from network SSID and WPA passphrase

        Parameters
        ----------
        ssid : str
            String unique identifier of the wireless network
        password : str
            String WPA passphrase necessary to access the network
        auto : bool
            Whether to set the interface as auto connected after boot.

        Returns
        -------
        None

        """

        # get bash string into string format for key search
        wifikey_str = sproc.check_output('wpa_passphrase "{}" "{}"'.format(
                                         ssid, password), shell=True)
        wifikey_tokens = wifikey_str.decode().split('\n')

        # search clean list for tpsk key value
        wifi_wpa_key = ''
        for key_val in wifikey_tokens:
            if '\tpsk=' in key_val:
                wifi_wpa_key = key_val.split('=')[1]

        # write the network interface file with new ssid/password entry
        os.system('ip link set {} up'.format(self.wifi_port))

        net_iface_fh = open("/etc/network/interfaces.d/" + self.wifi_port, 'w')
        if auto:
            net_iface_fh.write("auto " + self.wifi_port + "\n")
            net_iface_fh.write("allow-hotplug " + self.wifi_port + "\n")
        net_iface_fh.write("iface " + self.wifi_port + " inet dhcp\n")
        net_iface_fh.write(" wpa-ssid " + ssid + "\n")
        net_iface_fh.write(" wpa-psk " + wifi_wpa_key + "\n\n")
        net_iface_fh.close()

    def connect(self, ssid, password, auto=False):
        """Make a new wireless connection.

        This function kills the wireless connection and connect to a new one
        using network ssid and WPA passphrase. Wrong ssid or passphrase will
        reject the connection.

        Parameters
        ----------
        ssid : str
            Unique identifier of the wireless network
        password : str
            String WPA passphrase necessary to access the network
        auto : bool
            Whether to set the interface as auto connected after boot.

        Returns
        -------
        None

        """
        os.system('ifdown {}'.format(self.wifi_port))
        self.gen_network_file(ssid, password, auto)
        os.system('ifup {}'.format(self.wifi_port))

    def reset(self):
        """Shutdown the network connection.

        This function shutdown the network connection and delete the
        interface file.

        Returns
        -------
        None

        """
        os.system('killall -9 wpa_supplicant')
        os.system('ifdown {}'.format(self.wifi_port))
        os.system('rm -fr /etc/network/interfaces.d/wl*')
