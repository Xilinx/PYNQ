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

_repo_init_done=""

cleanup_exit()
{
    echo "Cleaning up.."
    cd ${REPO_DIR}
    git checkout -q master
    git reset --hard -q
    git clean -fdq
    chown -R xilinx:xilinx ${REPO_DIR}
    # Update itself and exit
    make -f ${MAKEFILE_PATH} new_pynq_update
    exit $1
}

build_docs()
{
    echo "Starting Docs Build"
    make -f ${MAKEFILE_PATH} update_docs
}

build_pynq()
{
    make -f ${MAKEFILE_PATH} update_pynq || cleanup_exit 1
}

init_repo()
{
    if [[ $_repo_init_done ]]; then
    return
    fi

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
    _repo_init_done=true
    cd ${REPO_DIR}
}

checkout_stable()
{
    latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)
    echo checking out ${latestTag}
    git checkout -q ${latestTag}
}

while getopts ':hlsd' option; do
    case "$option" in
        h) echo "$usage"
           exit
           ;;
        l) echo "Using master branch for update.."
           init_repo
           build_pynq
           ;;
        s) echo "Updating to latest stable release"
           init_repo
           checkout_stable
           build_pynq
           ;;
        d) docs=true
           # Docs are always built at end
           ;;
       \?) echo "Updating to latest stable release (default action)"
           init_repo
           checkout_stable
           build_pynq
           ;;
    esac
done

if [[ $docs ]]; then
    build_docs
fi

cleanup_exit 0
