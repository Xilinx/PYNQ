#!/bin/bash

for f in */script.tcl
do
  vivado_hls -f $f
done
