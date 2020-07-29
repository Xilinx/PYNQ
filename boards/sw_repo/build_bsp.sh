#!/bin/bash

set -e

bsp_folders=$(find . -maxdepth 1 -name "bsp_*_mb" | cut -d'/' -f2)

for i in ${bsp_folders}; 
do
	bsp_name=$(echo $i | sed 's/^bsp_//g')
	cd $i/$bsp_name/standalone_domain/bsp; make; cd -; \
done
