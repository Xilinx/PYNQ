#!/bin/bash

REPO_DIR=/home/xpp/Pynq_git
PYNQ_DIR=/usr/local/lib/python3.4/dist-packages/pynq
FINAL_DOCS_DIR=/home/xpp/docs

if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi
 
if [ -d $REPO_DIR ]; then
   echo "plesae manually remove ${REPO_DIR} before running this script."
   echo "rm -rf ${REPO_DIR}"
   echo ""
   exit 1
fi
 

git clone https://github.com/Xilinx/Pynq $REPO_DIR
cd $REPO_DIR/docs
sphinx-apidoc -f -o ./source $PYNQ_DIR
python3 ipynb_post_processor.py
make clean ; make html

pushd $REPO_DIR/docs/source/temp
for f in *.tmp
do 
    mv -- "$f" "$REPO_DIR/docs/source/${f%.tmp}.ipynb"
done
popd
rm -rf $REPO_DIR/docs/source/temp
rm -rf $FINAL_DOCS_DIR/*
cp -r $REPO_DIR/docs/build/html/* $FINAL_DOCS_DIR
chmod -R a+rw $FINAL_DOCS_DIR
chown -R xpp:xpp $FINAL_DOCS_DIR

echo ""
echo "Completed build."
echo "Documentation folder is at: $FINAL_DOCS_DIR"
echo ""
echo ""
