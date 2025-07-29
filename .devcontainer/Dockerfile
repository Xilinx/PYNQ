FROM mcr.microsoft.com/devcontainers/base:focal
RUN dpkg --add-architecture i386
RUN \
    apt update && \
    apt install -y \
    libxtst6 libx11-6 libtinfo-dev libxrender-dev libfreetype6 libxi6

RUN \
    apt install -y \
    libncurses5 wget git xterm \
    libncurses5-dev libncursesw5-dev \
    lib32ncurses6 autoconf libtool\
    texinfo gcc-multilib nano
RUN locale-gen en_US.utf8 && update-locale
RUN \
    apt install -y \
    software-properties-common lsb-core
WORKDIR /tmp/work
COPY ./sdbuild/scripts/setup_host.sh .
RUN chmod +x setup_host.sh
RUN /bin/sh -c /tmp/work/setup_host.sh
RUN rm -r /tmp/work/*
LABEL reference="https://superuser.com/questions/715722/how-to-do-dpkg-reconfigure-dash-as-bash-automatically"
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

WORKDIR /workspace
