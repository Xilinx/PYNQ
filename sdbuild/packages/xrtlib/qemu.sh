set -e
set -x


# Get architecture using uname -m
ARCH=$(uname -m)
# Map uname -m output to AARCH values
case $ARCH in
    aarch64)
        AARCH="arm64"
        ;;
    armv7l|armv6l)
        AARCH="arm32"
        ;;
    *)
        echo "Error: Unsupported architecture $ARCH"
        exit 1
        ;;
esac

# Define download URLs and filenames
if [[ $AARCH == "arm32" ]]; then
    # Get the current script directory & setup patch file
    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    PATCH_FILE="$SCRIPT_DIR/0001-size_t-32b-fix.patch"
    echo $PATCH_FILE
fi


DEB_FILE="xrt_embedded_202410.2.17.0_${AARCH}.deb"
SO_FILE="pyxrt_${AARCH}.so"

# Define the required Python version to utilise downloadable pyxrt.so
REQUIRED_PYTHON_VERSION="3.10"

# Function to download and install files
download_and_install() {
    echo "Debian install not supported"
    exit 1
}

manual_build() 
{

    # PLNX 2024.1 environment variable causing cmake failure on finding packages, removing it.
    unset PKG_CONFIG_LIBDIR
    
    # build and install
    cd /root

    apt -y update
    apt -y install systemtap-sdt-dev cppcheck libdw-dev libelf-dev libudev-dev

    git clone https://github.com/Xilinx/XRT xrt-git
    cd xrt-git
    git checkout tags/202410.2.17.319 -b temp
    git submodule init
    git submodule update

    # PYNQv3.1 - patches to force cmake to build pyxrt
    echo -e "\nset (XRT_INSTALL_PYTHON_DIR \"\${XRT_INSTALL_DIR}/python\")\nadd_subdirectory(python)" >> src/CMake/embedded_system.cmake

    #If on arm32 then apply the patch file
    if [[ $AARCH == "arm32" ]]; then
        echo "Applying 32b patch from $PATCH_FILE..."
        git apply $PATCH_FILE
        rm $PATCH_FILE
    fi

    cd build
    XRT_NATIVE_BUILD=no ./build.sh -dbg -noctest -noinit -noert
    cd Debug
    make install

    # Build and install xclbinutil
    cd ../..
    mkdir xclbinutil_build
    sed -i 's/xdp_hw_emu_pl_deadlock_plugin xdp_core xrt_coreutil xrt_hwemu/xdp_core xrt_coreutil/g' ./src/runtime_src/xdp/profile/plugin/pl_deadlock/CMakeLists.txt
    sed -i 's/xdp_hw_emu_device_offload_plugin xdp_core xrt_coreutil xrt_hwemu/xdp_core xrt_coreutil/g' ./src/runtime_src/xdp/profile/plugin/device_offload/hw_emu/CMakeLists.txt
    cd xclbinutil_build/
    cmake ../src/
    make install -C runtime_src/tools/xclbinutil

    # Get the path to the python3 executable
    PYTHON_PATH=$(command -v python3)

    if [[ -z "$PYTHON_PATH" ]]; then
        echo "python3 not found in PATH."
        exit 1
    fi

    # Get the Python version (e.g., 3.10)
    PYTHON_VERSION=$($PYTHON_PATH --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)

    if [[ -z "$PYTHON_VERSION" ]]; then
        echo "Unable to determine Python version."
        exit 1
    fi

    # Construct the library folder path
    PY_LIB_DIR="/usr/lib/python$PYTHON_VERSION"

    # Verify if the directory exists
    if [[ -d "$PY_LIB_DIR" ]]; then
        echo "Python library directory: $PY_LIB_DIR"
    else
        echo "Library directory $PY_LIB_DIR does not exist."
        exit 1
    fi
    
    # Check AARCH and copy the appropriate generated pyxrt.so
    if [[ $AARCH == "arm64" ]]; then
        cp "/root/xrt-git/build/Debug/python/pybind11/pyxrt.cpython-310-aarch64-linux-gnu.so" "${PY_LIB_DIR}/pyxrt.so"
    elif [[ $AARCH == "arm32" ]]; then
        cp "/root/xrt-git/build/Debug/python/pybind11/pyxrt.cpython-310-arm-linux-gnueabihf.so" "${PY_LIB_DIR}/pyxrt.so"
    else
        echo "Error: $AARCH not a valid architecture option"
        exit 1
    fi

    #cleanup
    cd /
    /bin/rm -rf /root/xrt-git
    exit 0
}


# Parse script arguments
FORCE_REBUILD=true
for arg in "$@"; do
    case $arg in
        --force-rebuild)
            FORCE_REBUILD=true
            shift
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--force-rebuild]"
            exit 1
            ;;
    esac
done

# Execute appropriate action
if $FORCE_REBUILD; then
    manual_build
else
    download_and_install
fi
