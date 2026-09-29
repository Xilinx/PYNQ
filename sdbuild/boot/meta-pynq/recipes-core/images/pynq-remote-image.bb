SUMMARY = "Minimal PYNQ.remote appliance image (gRPC PL server)"
LICENSE = "MIT"

IMAGE_INSTALL = "packagegroup-core-boot kernel-modules xrt zocl pynq-cpp pynq-remote-selftest pynq-remote-network ${CORE_IMAGE_EXTRA_INSTALL}"
IMAGE_FEATURES += "ssh-server-dropbear"
IMAGE_LINGUAS = " "
IMAGE_FSTYPES = "tar.gz"
IMAGE_ROOTFS_EXTRA_SPACE = "51200"

inherit core-image
