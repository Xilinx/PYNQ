#!/bin/bash

if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi

echo "127.0.0.1    localhost" > /etc/hosts
if [ $# = 0 ]; then
    echo "pynq" > /etc/hostname
    echo "127.0.1.1    pynq" >> /etc/hosts
else
    echo $1 > /etc/hostname
    echo "127.0.1.1    $1" >> /etc/hosts
fi

echo "Please manually reboot board for hostname changes to take effect:"
echo "sudo shutdown -r now"
echo ""
