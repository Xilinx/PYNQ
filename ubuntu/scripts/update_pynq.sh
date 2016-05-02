#!/bin/bash


# Global Paths
SCRIPT_NAME=`basename "$0"`
BACKUP_DIR=/home/xpp/pynq_update_backup
REPO_DIR=/home/xpp/Pynq_git
PYNQ_DIR=/usr/local/lib/python3.4/dist-packages/pynq

FINAL_DOCS_DIR=/home/xpp/docs
FINAL_NOTEBOOKS_DIR=/home/xpp/jupyter_notebooks
FINAL_SCRIPTS_DIR=/home/xpp/scripts

GS_NOTEBOOK_IMAGES="edit_mode.png
dashboard_running_tab.png
python_logo.svg
dashboard_files_tab_run.png
zybo_io_opt.jpeg
command_mode.png
zybo_io.jpeg
dashboard_files_tab_new.png
dashboard_files_tab.png
menubar_toolbar.png
dashboard_files_tab_btns.png
zyboaudiovideo.jpg
Pmods_opt.png
pmod_closeup_opt.jpeg
pmod_pins_opt.png
Pmod_Grove_Adapter_opt.jpeg
tmp2_8pin_opt.jpeg
iop.jpg
zybopmods_opt.jpeg
pmodio_overlay_1_opt.png
als_oled_Demo_opt.jpeg
adc_dac_demo_opt.jpeg"



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
cp -r $REPO_DIR/ubuntu/scripts/*.bat $FINAL_SCRIPTS_DIR
pushd $FINAL_NOTEBOOKS_DIR ; ln -s $FINAL_DOCS_DIR ; popd

# Jupyer_notebooks/Getting Started derived contents
rm -rf $FINAL_NOTEBOOKS_DIR/Getting_Started/*
cp $REPO_DIR/docs/source/*.ipynb $FINAL_NOTEBOOKS_DIR/Getting_Started
rm -rf $FINAL_NOTEBOOKS_DIR/Getting_Started/*_pp.ipynb

mkdir $FINAL_NOTEBOOKS_DIR/Getting_Started/images
for f in $GS_NOTEBOOK_IMAGES
do
    cp $REPO_DIR/docs/source/images/$f $FINAL_NOTEBOOKS_DIR/Getting_Started/images/
done


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


