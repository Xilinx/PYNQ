#!/bin/bash

. /etc/environment
. /usr/local/share/pynq-venv/bin/activate

if [ -z "$PYNQ_PYTHON" ]; then
  PYNQ_PYTHON=python3
fi

start_pl_server.py & 
