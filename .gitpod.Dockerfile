FROM gitpod/workspace-full

# ARG WORKDIRBASE
# ENV WORKDIRBASE=${WORKDIRBASE:-workspace/coreboot_glk}

# Install custom tools, runtime, etc.
RUN echo "Installing dependencies" \
    && sudo apt-get update \
    && sudo apt-get install -y \
        git \
        build-essential \
        gnat-10 \
        flex \
        bison \
        libncurses5-dev \
        wget \
        zlib1g-dev \
        sharutils \
        e2fsprogs \
        parted \
        curl \
        unzip \
        ca-certificates \
        flashrom \
    && sudo rm -rf /var/lib/apt/lists/*

# WORKDIR $WORKDIRBASE
RUN echo "Obtaining Coreboot source and submodules" \
    && git clone https://review.coreboot.org/coreboot \
    && cd coreboot \
    && git submodule update --init --checkout

WORKDIR coreboot
RUN echo -e "Building Coreboot crossgcc.\nThis could take a while (10-15 minutes)" \
    && make crossgcc-i386 CPUS=$(nproc)

RUN echo "Building and installing helper tools"

WORKDIR util/cbfstool
RUN make \
    && sudo make install

WORKDIR ../ifdtool
RUN make \
    && sudo make install

WORKDIR ../../../
ENTRYPOINT exec bash build.sh
