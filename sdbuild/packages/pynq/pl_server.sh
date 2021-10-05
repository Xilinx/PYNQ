#!/bin/bash

. /etc/environment
for f in /etc/profile.d/*.sh; do source $f; done

if [ -z "$PYNQ_PYTHON" ]; then
  PYNQ_PYTHON=python3
fi

start_pl_server.py & 
