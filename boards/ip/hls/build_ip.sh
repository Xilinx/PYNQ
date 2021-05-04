#!/bin/bash

for f in */script.tcl
do
  vitis_hls -f $f
done
