#!/bin/bash
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
    ca-certificates

echo "Obtaining Coreboot Source"
git clone --quiet https://review.coreboot.org/coreboot
cd /workspace/coreboot_glk/coreboot
git submodule --quiet update --init --checkout

echo "Building Coreboot crosstools"
cd /workspace/coreboot_glk/coreboot
make crossgcc-i386 CPUS=$(nproc) > /dev/null

echo "Installing Helper Tools"
cd /workspace/coreboot_glk/coreboot/util/cbfstool
make > /dev/null
sudo make install > /dev/null 
cd /workspace/coreboot_glk/coreboot/util/ifdtool
make > /dev/null
sudo make install > /dev/null

echo "Preparing Firmware Blobs"
cd /workspace/coreboot_glk
/workspace/coreboot_glk/crosfirmware.sh octopus glk

echo "Finished"
exit
