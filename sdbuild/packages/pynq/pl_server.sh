#!/bin/bash

. /etc/environment

if [ -z "$PYNQ_PYTHON" ]; then
  PYNQ_PYTHON=python3.4
else
  PATH=/opt/$PYNQ_PYTHON/bin:$PATH
fi

start_pl_server.py & 
