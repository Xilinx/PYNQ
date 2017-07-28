#!/bin/bash

set -e
set -x

builddir=/root/phantom
mkdir $builddir
cd $builddir

git clone https://github.com/ariya/phantomjs.git
cd phantomjs
git checkout 2.1.1
git submodule init
git submodule update

python build.py -c

cp bin/phantomjs /usr/local/bin

cd ..
rm -r $builddir
