FROM gitpod/workspace-full

COPY --chown=gitpod:gitpod ./* ./

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
        libflashrom-dev \
        pkg-config \
        libglib2.0-dev \
        python3 \
        python3-pip \
        python-is-python3 \
        nasm \
    && sudo rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip \
    && pip3 install flask

#
#RUN echo "Obtaining Coreboot source and submodules" \
#    && git clone https://review.coreboot.org/coreboot \
#    && cd coreboot \
#    && git submodule update --init --checkout
#
#WORKDIR coreboot
#RUN echo -e "Building Coreboot crossgcc.\nThis could take a while (10-15 minutes)" \
#    && make crossgcc-i386 CPUS=$(nproc)
#
#RUN echo "Building and installing helper tools"
#
#WORKDIR util/cbfstool
#RUN make cbfstool \
#    && sudo install -m 0755 cbfstool /usr/bin/cbfstool
#
#WORKDIR ../ifdtool
#RUN make \
#    && sudo install -m 0755  ifdtool /usr/bin/ifdtool
#
#WORKDIR ../../../
#ENTRYPOINT exec bash build.sh
