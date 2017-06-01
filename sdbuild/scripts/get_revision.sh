#!/bin/bash

echo "Release $(date +'%Y_%m_%d') $(git describe) $(git rev-parse --short --verify HEAD)"
