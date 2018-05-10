#! /bin/bash

set -e
set -x

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp $SCRIPT_DIR/xkcd.otf $1/usr/share/fonts
