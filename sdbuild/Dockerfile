# PYNQ SDBuild DockerFile
# Adapted from https://hub.docker.com/r/jjsuperpower/pynq-sdbuild-env (BSD-2)

FROM ubuntu:24.04

# User details will be overridden when running the Docker build command
# given in the sdbuild README. Otherwise, fill in the details below.
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

WORKDIR /tmp

# Install build, host, EDF/Yocto and Vivado runtime dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bc libtool-bin gperf bison flex texinfo help2man gawk libtool \
    build-essential automake device-tree-compiler \
    qemu-user-static binfmt-support multistrap git \
    libssl-dev kpartx dosfstools nfs-common zerofree u-boot-tools rpm2cpio \
    libc6-dev chrpath socat zlib1g-dev unzip \
    rsync python3-pip crossbuild-essential-arm64 xterm net-tools ninja-build \
    libncurses-dev vim nano tmux zip dnsutils sudo \
    ca-certificates cpio curl diffstat file gnupg wget xz-utils zstd lz4 \
    liblz4-tool python3-git python3-jinja2 python3-subunit python3-pexpect python3-yaml \
    debootstrap mtools parted e2fsprogs udev locales \
    lsb-release x11-utils xvfb dbus-x11 libswt-glx-gtk-4-jni \
    libpixman-1-0 libgtk2.0-0t64 libcanberra-gtk-module \
    libx11-6 libxext6 libxrender1 libxtst6 libxi6 libxft2 \
    libfontconfig1 libfreetype6 libsm6 libice6 libglib2.0-0t64 libtinfo6 \
 # Locale for Vivado
 && locale-gen en_US.utf8 && update-locale \
 # Clean up APT
 && rm -rf /var/lib/apt/lists/*

# Google's repo tool syncs AMD's EDF manifest of Yocto layers
RUN curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo \
 && chmod +x /usr/local/bin/repo

# Build and install crosstool-ng
RUN mkdir /opt/crosstool-ng-src \
 && cd /opt/crosstool-ng-src \
 && ctver=1.24.0 \
 && wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-$ctver.tar.bz2 \
 && tar -xf crosstool-ng-$ctver.tar.bz2 \
 && cd crosstool-ng-$ctver \
 && ./configure --prefix=/opt/crosstool-ng \
 && make -j$(nproc) && make install \
 && rm -rf /opt/crosstool-ng-src

# Create gmake symlink for Vitis
RUN command -v gmake >/dev/null 2>&1 || ln -s /usr/bin/make /usr/bin/gmake

# Ensure resolv.conf for chroot environments
RUN mkdir -p /run/systemd/resolve \
 && cp -L /etc/resolv.conf /run/systemd/resolve/stub-resolv.conf

# Update Python setuptools and install PYNQ Python deps
RUN pip3 install --no-cache-dir --break-system-packages --upgrade "setuptools>=24.2.0,<81" numpy cffi

# Create a shared build directory
RUN mkdir /build && chmod a+rwx /build

# Create non-root user with sudo privileges
RUN (userdel -r ubuntu 2>/dev/null || true) \
 && useradd -m ${USERNAME} \
 && echo "${USERNAME}:${USERNAME}" | chpasswd \
 && usermod --shell /bin/bash ${USERNAME} \
 && usermod --uid ${USER_UID} ${USERNAME} \
 && groupmod --gid ${USER_GID} ${USERNAME} \
 && usermod -aG sudo ${USERNAME} \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME}

ENV PATH="/opt/crosstool-ng/bin:${PATH}"
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm
ENV LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1
ENV EDF_DIR=/edf-cache/pynq-edf
ENV SSTATE_DIR=/edf-cache/sstate
ENV DL_DIR=/edf-cache/downloads

# Switch to non-root user
USER ${USERNAME}
WORKDIR /workspace
ENV USERNAME=${USERNAME}

CMD /bin/bash
