#!/bin/bash  

set -e

UPDATEPYNQ_DIR=/home/xilinx/scripts
REPO_DIR=/home/xilinx/pynq_git
MAKEFILE_PATH=${REPO_DIR}/scripts/linux/makefile.pynq
PYNQ_REPO=https://github.com/Xilinx/PYNQ.git


if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi

usage="Usage : $(basename "$0") [-h] [-s] [-l] [-b branch] [-d]
Update pynq python, notebooks and scripts from PYNQ repository

where:
    -h  show this help text and exit
    -s  update packages to latest stable release [DEFAULT]
    -l  update packages to latest commit [Overrides -s]
        Note: This could result in an unstable build

    Development Options:
    -b branch   update package to this repository branch [DEFAULT: master]
    -d          rebuild docs from source"

    


_repo_branch=master


function cleanup_exit()
{

    # Final steps - update this file and change repo ownership
    cd ${UPDATEPYNQ_DIR}
    cp update_pynq.sh update_pynq.sh.bkup
    make -f ${MAKEFILE_PATH} new_pynq_update

    cd ${REPO_DIR}
    chown -R xilinx:xilinx ${REPO_DIR}


    exit $1
}

function build_docs()
{
    echo "Starting Docs Build"
    make -f ${MAKEFILE_PATH} update_docs
}

function build_pynq()
{
    make -f ${MAKEFILE_PATH} update_pynq 
}

function init_repo()
{
    echo "Info: This operation will overwrite all the example notebooks"
    read -rsp $'Press any key to continue...\n' -n1 key

    if [[ -d $REPO_DIR/.git ]] ; then
        echo ""
        echo "Github Repo Detected. Pulling latest changes from upstream.."
        cd ${REPO_DIR}
        git checkout --track origin/${_repo_branch} || git checkout -f ${_repo_branch}
        git fetch
        git pull 
        echo ""
    else
        echo "Cloning Pynq repo ${_repo_branch}"
        rm -rf $REPO_DIR
        mkdir $REPO_DIR -p
        git clone  ${PYNQ_REPO} ${REPO_DIR}
        cd ${REPO_DIR}
        git checkout --track origin/${_repo_branch}
    fi

    cd ${REPO_DIR}
}

function checkout_stable()
{
    latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)
    echo checking out ${latestTag}
    git checkout -q ${latestTag}
}

if [[ "$#" -eq 0 ]]; then
    stable_latest=true
fi

while getopts 'hlsb:d' option; do
    case "$option" in
        h) echo "$usage"
           exit
           ;;
        l) echo "+ Using latest commit for update.."
           latest=true
           ;;
        s) echo "+ Updating to latest stable release"
           stable_latest=true
           ;;
        b) _repo_branch=$OPTARG
           echo "+ Using ${_repo_branch} branch"
           ;;
        d) docs=true
           ;;
       \?) echo "+ Unknown option -${OPTARG} use '-h' for help"
           exit 1
           ;;
    esac
done

#execute operations sequentially

if [[ $latest ]]; then
    init_repo
    build_pynq
elif [[ $stable_latest ]]; then
    init_repo
    checkout_stable
    build_pynq
fi

if [[ $docs ]]; then
    build_docs
fi

cleanup_exit 0