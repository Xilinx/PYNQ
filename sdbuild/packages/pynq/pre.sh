#!/bin/bash

set -x
set -e

target=$1
pynqoverlays_dir=$target/usr/local/share/pynq-venv/lib/python3.12/site-packages/pynq/overlays
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 1. Copy files from build area to the qemu environment
sudo git clone --recursive $BUILD_ROOT/PYNQ  $target/home/xilinx/pynq_git
sudo mkdir -p $target/home/xilinx/pynq_git/dist

sudo cp $script_dir/pynq_hostname.sh $target/usr/local/bin
sudo cp $script_dir/boardname.sh $target/etc/profile.d


# 2. Create and copy the REVISION file
echo "Release 4.0.0 (Verona) $(date +'%Y_%m_%d') $(git rev-parse --short=7 --verify HEAD)" \
	> $BUILD_ROOT/PYNQ/REVISION

if [ ${PYNQ_BOARD} != "Unknown" ]; then
	cd ${PYNQ_BOARDDIR}
	if git tag > /dev/null 2>&1 && [ $? -eq 0 ]; then
		echo "Board $(date +'%Y_%m_%d')"\
			"$(git rev-parse --short=7 --verify HEAD)"\
			"$(git config --get remote.origin.url)"\
			>> $BUILD_ROOT/PYNQ/REVISION
	fi
fi

sudo cp -rf $BUILD_ROOT/PYNQ/REVISION $target/home/xilinx/REVISION
sudo cp -rf $BUILD_ROOT/PYNQ/REVISION $target/boot/REVISION
if [ -d /usr/local/share/fatfs_contents ]; then
    sudo cp -rf $BUILD_ROOT/PYNQ/REVISION /usr/local/share/fatfs_contents/REVISION
fi


# 3. Deliver the board's overlays and notebooks. These are read from the board
# directory itself, which holds the built bitstream or PDI that is not in git.
if [ -d "$PYNQ_BOARDDIR" ] && [ "$PYNQ_BOARD" != "Unknown" ]; then

    overlays=$(find -L "$PYNQ_BOARDDIR" -maxdepth 2 \
        \( -iname '*.bit' -o -iname '*.pdi' \) ! -iname '*_boot.pdi' \
        -printf '%h\n' | sort -u)

    for ol in $overlays ; do
        ol_name=$(basename "$ol")
        sudo mkdir -p "$pynqoverlays_dir/$ol_name"
        for f in "$ol"/*.bit "$ol"/*.pdi "$ol"/*.hwh "$ol"/*.py "$ol"/*.dtbo ; do
            [ -f "$f" ] || continue
            # A boot PDI is loaded by the platform, not by an overlay.
            case "$(basename "$f")" in *_boot.pdi) continue ;; esac
            sudo cp -fL "$f" "$pynqoverlays_dir/$ol_name/"
        done

        if [ -d "$ol/notebooks" ]; then
            sudo mkdir -p "$target/home/xilinx/pynq_git/notebooks/$ol_name"
            sudo cp -fLr "$ol/notebooks/"* "$target/home/xilinx/pynq_git/notebooks/$ol_name"
        fi
    done

    if [ -d "$PYNQ_BOARDDIR/notebooks" ]; then
        sudo mkdir -p "$target/home/xilinx/pynq_git/notebooks"
        sudo cp -fLr "$PYNQ_BOARDDIR/notebooks/"* "$target/home/xilinx/pynq_git/notebooks"
    fi
fi

# 4. Deliver PYNQ python source distribution for installation
if [ -n "$REBUILD_PYNQ_SDIST" ]; then
    echo "

    Warning ... setting REBUILD_PYNQ_SDIST will result in several bitstream and bsp builds
                      please rerun Makefile without REBUILD_PYNQ_SDIST set using latest PYNQ source
                      distribution on PYPI at: https://pypi.org/project/pynq/#files
    "
    sleep 10

    # build bitstream, microblazes' bsps and binaries
    cd $BUILD_ROOT/PYNQ
    make -f build.mk
    sudo cp dist/*.tar.gz $target/home/xilinx/pynq_git/dist
else
    # using prebuilt sdist with non-external board
    # nothing to do except copy sdist to target folder
    sudo cp ${PYNQ_SDIST} $target/home/xilinx/pynq_git/dist	
fi
