#!/bin/bash

REPO_DIR=/home/xilinx/pynq_git
MAKEFILE_PATH=${REPO_DIR}/scripts/linux/makefile.pynq
PYNQ_REPO=https://github.com/yunqu/PYNQ.git

if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi

usage="Usage : $(basename "$0") [-h] [-r] [-l] [-s] [-d]
Update pynq python, notebooks and scripts from PYNQ repository

where:
    -h  show this help text
    -l  update packages to latest branch
	Note: This could result in an unstable build
    -s  update packages to latest stable release

    Development Options:
    -r  cleanup destination dirs before update
    -d  rebuild docs from source"

_repo_init_done=""

function cleanup_exit()
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

function build_docs()
{
    echo "Starting Docs Build"
    make -f ${MAKEFILE_PATH} update_docs
}

function build_pynq()
{
    make -f ${MAKEFILE_PATH} update_pynq || cleanup_exit 1
    echo "Successfully updated PYNQ.."
}

function init_repo()
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

function checkout_stable()
{
    latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)
    echo checking out ${latestTag}
    git checkout -q ${latestTag}
}

function do_stable_update()
{
   init_repo
   checkout_stable
   build_pynq
}

if [[ "$#" -eq 0 ]]; then
    echo "Updating to latest stable release (default action)"
    do_stable_update
fi

if [[ "$1" == "-r" ]]; then
    init_repo
    echo "Cleaning up before upgrade.."
    make -f ${MAKEFILE_PATH} clean_dirs || exit 1
fi

while getopts ':hlsdr' option; do
    case "$option" in
        h) echo "$usage"
           exit
           ;;
        l) echo "Using master branch for update.."
           init_repo
           build_pynq
           ;;
        s) echo "Updating to latest stable release"
           do_stable_update
           ;;
        r) # This is always preprocessed
           ;;
        d) docs=true
           # Docs are always built at end
           init_repo
           ;;
       \?) echo "Unknown option -${OPTARG} use '-h' for help"
           exit 1
           ;;
    esac
done

if [[ $docs ]]; then
    build_docs
fi

cleanup_exit 0