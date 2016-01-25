#!/bin/bash

folder=$(echo "`python3 -m site --user-site`")

if [ -d $folder ]; then
    echo 'package directory exists, no need to create it.'
else
    echo 'creating packages directory'
    mkdir -p $folder
fi

echo 'drop your packages into '$folder
