#!/bin/bash

REPO_DIR=/home/xilinx/pynq_git
MAKEFILE_PATH=${REPO_DIR}/scripts/linux/makefile.pynq
PYNQ_REPO=https://github.com/Xilinx/PYNQ.git

if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi

usage="Usage : $(basename "$0") [-h] [-l] [-s] [-d]
Update pynq python, notebooks and scripts from PYNQ repository

where:
    -h  show this help text
    -l  update packages to latest branch
	Note: This could result in an unstable build
    -s  update packages to latest stable release
    -d  rebuild docs from source"


cleanup_exit(){
echo "Cleaning up.."
cd ${REPO_DIR}
git checkout -q master
git reset --hard
git clean -fdq
chown -R xilinx:xilinx ${REPO_DIR}
# Update itself and exit
make -f ${MAKEFILE_PATH} new_pynq_update
exit $1
}

while getopts ':hlsd' option; do
    case "$option" in
        h) echo "$usage"
           exit
           ;;
        l) branch=master
           echo "Using master branch for update.."
           ;;
        s) echo "Updating to latest stable release"
           ;;
        d) docs=true
           ;;
       \?) echo "Updating to latest stable release (default action)"
           ;;
    esac
done

echo "Info: This operation will overwrite all the example notebooks"
read -rsp $'Press any key to continue...\n' -n1 key
 
if [[ -d $REPO_DIR/.git ]] ; then
    echo ""
    echo "Github Repo Detected. Pulling latest changes from upstream.."
    cd ${REPO_DIR}
    git checkout master
    git pull || exit 1
    echo ""
else
    echo "Cloning Pynq repo"
    mkdir $REPO_DIR -p
    git clone ${PYNQ_REPO} ${REPO_DIR} || exit 1
fi

cd ${REPO_DIR}

if [[ -z $branch ]]; then
    latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)
    echo checking out ${latestTag}
    git checkout -q ${latestTag}
fi

make -f ${MAKEFILE_PATH} update_pynq || cleanup_exit 1

if [[ -n $docs ]]; then
    echo "Starting Docs Build"
    make -f ${MAKEFILE_PATH} update_docs
fi

cleanup_exit 0
