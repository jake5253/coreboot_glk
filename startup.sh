#!/bin/bash
# This file assumes it is located in a directory parallel to coreboot_glk
$SCRIPT_DIR=$(dirname "$(readlink -f "$0")")


echo "Installing Dependencies"
sudo apt update
sudo apt install --yes \
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
    libglib2.0-dev

echo "Obtaining Coreboot Source"
git clone --quiet https://review.coreboot.org/coreboot "${SCRIPT_DIR}/coreboot"
cd "${SCRIPT_DIR}/coreboot"
git submodule --quiet update --init --checkout

#echo "Building Coreboot crosstools"
#cd "${SCRIPT_DIR}/coreboot"
#make crossgcc-i386 CPUS=$(nproc) >/dev/null

echo "Installing Helper Tools"
cd "${SCRIPT_DIR}/coreboot/util/cbfstool"
make cbfstool >/dev/null
sudo install -m 0755 cbfstool /usr/bin/cbfstool >/dev/null 
cd "${SCRIPT_DIR}/coreboot/util/ifdtool"
make >/dev/null
sudo make install >/dev/null

bash ${SCRIPT_DIR}/build.sh
echo "Finished"
exit
