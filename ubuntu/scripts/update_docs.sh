#!/bin/bash

REPO_DIR=/home/xpp/pynq_git
PYNQ_DIR=/usr/local/lib/python3.4/dist-packages/pynq
BACKUP_DIR=/home/xpp/pynq_backup

FINAL_DOCS_DIR=/home/xpp/docs
FINAL_NOTEBOOKS_DIR=/home/xpp/jupyter_notebooks
FINAL_SCRIPTS_DIR=/home/xpp/scripts


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

make -f makefile.pynq update_docs







