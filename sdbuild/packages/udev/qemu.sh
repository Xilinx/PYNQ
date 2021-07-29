#!/bin/bash

set -x
set -e

# udev rule to keep wlan# numbering
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
