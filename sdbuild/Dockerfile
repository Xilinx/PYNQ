# PYNQ SDBuild DockerFile
# Adapted from https://hub.docker.com/r/jjsuperpower/pynq-sdbuild-env (BSD-2)

FROM ubuntu:22.04

# User details will be overridden when running the Docker build command
# given in the sdbuild README. Otherwise, fill in the details below.
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000

SHELL ["/bin/bash", "-c"]

WORKDIR /tmp

# Enable i386 architecture and install core dependencies
RUN dpkg --add-architecture i386 \
 && apt-get update && apt-get upgrade -y \
 && apt-get install -y software-properties-common gnupg2 wget curl \
 # Add toolchain PPA
 && add-apt-repository -y ppa:ubuntu-toolchain-r/ppa \
 && apt-get update \
 # Install build and host packages
 && apt-get install -y \
    bc libtool-bin gperf bison flex texi2html texinfo help2man gawk libtool \
    build-essential automake libglib2.0-dev libfdt-dev device-tree-compiler \
    qemu-user-static binfmt-support multistrap git lib32z1 lib32stdc++6 \
    libssl-dev kpartx dosfstools nfs-common zerofree u-boot-tools rpm2cpio \
    libsdl1.2-dev libpixman-1-dev libc6-dev chrpath socat zlib1g-dev unzip \
    rsync python3-pip gcc-multilib xterm net-tools ninja-build python3-testresources \
    libncurses5-dev libncursesw5-dev vim nano tmux zip dnsutils sudo binfmt-support \
    dbus-x11 libswt-glx-gtk-4-jni libgtk2.0-0 xvfb \
 # Configures timezone interactively (2: Americas, 37: Central)
 && echo -e '2\n37\n' | apt-get install -y lsb-core \
 # Locale for Vivado
 && locale-gen en_US.utf8 && update-locale \
 # Clean up APT
 && rm -rf /var/lib/apt/lists/*

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

# Build and install QEMU
RUN mkdir /opt/qemu-src \
 && cd /opt/qemu-src \
 && qemuver=5.2.0 \
 && wget http://download.qemu.org/qemu-$qemuver.tar.bz2 \
 && tar -xf qemu-$qemuver.tar.bz2 \
 && cd qemu-$qemuver \
 && ./configure --target-list=arm-linux-user,aarch64-linux-user --prefix=/opt/qemu --static \
 && make -j$(nproc) && make install \
 && cd /opt/qemu/bin \
 && rm -f qemu-arm-static qemu-aarch64-static \
 && ln -s qemu-arm qemu-arm-static \
 && ln -s qemu-aarch64 qemu-aarch64-static \
 && rm -rf /opt/qemu-src

# Create gmake symlink for Vitis
RUN command -v gmake >/dev/null 2>&1 || ln -s /usr/bin/make /usr/bin/gmake

# Ensure resolv.conf for chroot environments
RUN mkdir -p /run/systemd/resolve \
 && cp -L /etc/resolv.conf /run/systemd/resolve/stub-resolv.conf

# Update Python setuptools and install PYNQ Python deps
RUN pip3 install --no-cache-dir --upgrade "setuptools>=24.2.0" numpy cffi

# Create a shared build directory
RUN mkdir /build && chmod a+rwx /build

# Create non-root user with sudo privileges
RUN useradd -m ${USERNAME} \
 && echo "${USERNAME}:${USERNAME}" | chpasswd \
 && usermod --shell /bin/bash ${USERNAME} \
 && usermod --uid ${USER_UID} ${USERNAME} \
 && groupmod --gid ${USER_GID} ${USERNAME} \
 && usermod -aG sudo ${USERNAME} \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME}

ENV PATH="/opt/qemu/bin:/opt/crosstool-ng/bin:${PATH}"
ENV LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1

# Switch to non-root user
USER ${USERNAME}
WORKDIR /workspace
ENV USERNAME=${USERNAME}

CMD /bin/bash