#!/bin/bash

if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi
 
if [ -d "/home/xpp/Pynq_doc" ]; then
   echo "plesae manually remove ~xpp/Pynq_doc before running this script."
   exit 1
fi
 
cd ~xpp
git clone https://github.com/Xilinx/Pynq Pynq_doc
cd Pynq_doc/docs
sphinx-apidoc -f -o ./source /usr/local/lib/python3.4/dist-packages/pynq
python3 ipynb_post_processor.py
make clean ; make html

