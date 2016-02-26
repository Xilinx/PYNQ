#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/proj/gsd/vivado/SDK/2015.3/bin:/proj/gsd/vivado/Vivado/2015.3/ids_lite/ISE/bin/lin64:/proj/gsd/vivado/Vivado/2015.3/bin
else
  PATH=/proj/gsd/vivado/SDK/2015.3/bin:/proj/gsd/vivado/Vivado/2015.3/ids_lite/ISE/bin/lin64:/proj/gsd/vivado/Vivado/2015.3/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=/proj/gsd/vivado/Vivado/2015.3/ids_lite/ISE/lib/lin64
else
  LD_LIBRARY_PATH=/proj/gsd/vivado/Vivado/2015.3/ids_lite/ISE/lib/lin64:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD=/home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.runs/synth_1
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log top.vds -m64 -mode batch -messageDb vivado.pb -notrace -source top.tcl
