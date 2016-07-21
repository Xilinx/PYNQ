#!/bin/bash

SCRIPT_NAME=`basename "$0"`
BACKUP_DIR=/home/xpp/pynq_backup
REPO_DIR=/home/xpp/pynq_git
PYNQ_DIR=/usr/local/lib/python3.4/dist-packages/pynq

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

echo "1. Backing up files into ${BACKUP_DIR}"
mkdir $BACKUP_DIR
cp -r $FINAL_DOCS_DIR $FINAL_NOTEBOOKS_DIR $FINAL_SCRIPTS_DIR $BACKUP_DIR
python3.4 /home/xpp/scripts/stop_pl_server.py &

echo "2. Clone PYNQ repository into ${REPO_DIR}"
git clone https://github.com/Xilinx/PYNQ $REPO_DIR

echo "3. Pip install latest pynq python package"
rm -rf $PYNQ_DIR/*
cp -rf $REPO_DIR/$BOARD/sdk/bin/*.bin $REPO_DIR/python/pynq/iop/
cp -rf $REPO_DIR/$BOARD/bitstream $REPO_DIR/python/pynq/
cd $REPO_DIR/python
sudo -H pip install --upgrade .
python3.4 /home/xpp/scripts/start_pl_server.py &

echo ""
echo "Completed build."
echo "Documentation folder is at: $FINAL_DOCS_DIR"
echo "Notebooks     folder is at: $FINAL_NOTEBOOKS_DIR"
echo "Scripts       folder is at: $FINAL_SCRIPTS_DIR"
echo ""
echo "If needed, please manually replace this script from local git"
echo "cp -r $REPO_DIR/ubuntu/scripts/$SCRIPT_NAME $FINAL_SCRIPTS_DIR"
echo ""
echo ""
