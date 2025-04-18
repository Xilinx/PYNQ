#!/bin/bash

for f in */script.tcl
do
  vitis-run --mode hls --tcl $f
done
