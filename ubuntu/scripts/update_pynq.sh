#!/bin/bash


# Global Paths
SCRIPT_NAME=`basename "$0"`
BACKUP_DIR=/home/xpp/pynq_update_backup
REPO_DIR=/home/xpp/Pynq_git
PYNQ_DIR=/usr/local/lib/python3.4/dist-packages/pynq

FINAL_DOCS_DIR=/home/xpp/docs
FINAL_NOTEBOOKS_DIR=/home/xpp/jupyter_notebooks
FINAL_SCRIPTS_DIR=/home/xpp/scripts


# Error checking
if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi
 
if [ -d $REPO_DIR ] || [ -d $BACKUP_DIR ] ; then
   echo ""
   echo "plesae manually move or delete git an backup folders before running this script."
   echo "rm -rf ${REPO_DIR} ${BACKUP_DIR}"
   echo ""
   exit 1
fi
 

echo "1. Backing up files into ${BACKUP_DIR}"
mkdir $BACKUP_DIR
cp -r $FINAL_DOCS_DIR $FINAL_NOTEBOOKS_DIR $FINAL_SCRIPTS_DIR $BACKUP_DIR

echo "2. Clone Pynq repository into ${REPO_DIR}"
git clone https://github.com/Xilinx/Pynq $REPO_DIR

echo "3. Pip install latest pynq python package"
cd $REPO_DIR/python
sudo -H pip install --upgrade .

echo "4. Build docs"
cd $REPO_DIR/docs
sphinx-apidoc -f -o ./source $PYNQ_DIR
python3 ipynb_post_processor.py
make clean ; make html

echo "5. Transfer Git files into final filesystem locations with correct ownership"
rm -rf $FINAL_DOCS_DIR/* $FINAL_NOTEBOOKS_DIR/* 
cp -r $REPO_DIR/docs/build/html/* $FINAL_DOCS_DIR
cp -r $REPO_DIR/python/notebooks/* $FINAL_NOTEBOOKS_DIR
cp -r $REPO_DIR/ubuntu/scripts/hostname.sh $FINAL_SCRIPTS_DIR

# 5a. (PLACEHOLDER) Jupyer_notebooks/Getting Started derived contents
rm -rf $FINAL_NOTEBOOKS_DIR/Getting_Started/*
cp $REPO_DIR/docs/source/*.ipynb $FINAL_NOTEBOOKS_DIR/Getting_Started
rm -rf $FINAL_NOTEBOOKS_DIR/Getting_Started/*_pp.ipynb


chmod -R a+rw $FINAL_NOTEBOOKS_DIR $FINAL_DOCS_DIR $PYNQ_DIR
chmod -R a+x $FINAL_SCRIPTS_DIR/*
chown -R xpp:xpp $REPO_DIR $BACKUP_DIR
chown -R xpp:xpp $FINAL_NOTEBOOKS_DIR $FINAL_DOCS_DIR $FINAL_SCRIPTS_DIR $PYNQ_DIR  

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


