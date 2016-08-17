#!/bin/bash

if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi

echo "127.0.0.1    localhost" > /etc/hosts
if [ $# = 0 ]; then
    hostname pynq
    echo "pynq" > /etc/hostname
    echo "127.0.1.1    pynq" >> /etc/hosts
else
    hostname $1 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "The board needs a restart to update hostname"
    fi
    echo $1 > /etc/hostname
    echo "127.0.1.1    $1" >> /etc/hosts
fi

echo "Please manually reboot board:"
echo "sudo shutdown -r now"
echo ""
