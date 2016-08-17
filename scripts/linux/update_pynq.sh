#!/bin/bash

BACKUP_DIR=/home/xilinx/pynq_backup
REPO_DIR=/home/xilinx/pynq_git

if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi
 
if [ -d $REPO_DIR ] || [ -d $BACKUP_DIR ] ; then
   echo ""
   echo "please manually remove git backup folders before running this script."
   echo "rm -rf ${REPO_DIR} ${BACKUP_DIR}"
   echo ""
   exit 1
fi

make -f makefile.pynq update_pynq
