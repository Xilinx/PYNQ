#!/bin/bash

. /etc/environment

if [ -z "$PYNQ_PYTHON" ]; then
  PYNQ_PYTHON=python3.6
fi

start_pl_server.py & 
