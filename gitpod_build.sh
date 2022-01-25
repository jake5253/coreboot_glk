#!/bin/bash

# Main dependencies
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

# coreboot source
echo "Obtaining Coreboot Source"
git clone --quiet https://review.coreboot.org/coreboot

# coreboot submodules
echo "Getting Coreboot submodules" 
cd coreboot 
git submodule --quiet update --init --checkout

# crosstools
echo -e "Building Coreboot crosstools.\n This may take a few minutes"
make crossgcc-i386 CPUS=$(nproc) > /dev/null

# coreboot tools
echo "Installing Helper Tools" 
# CBFSTool
cd /util/cbfstool 
make > /dev/null 
sudo make install > /dev/null

# IFDTool
cd ../ifdtool 
make > /dev/null 
sudo make install > /dev/null

# Process blobs
cd /workspace/coreboot_glk 
echo "Preparing Firmware Blobs" 
bash ./crosfirmware.sh octopus glk

echo "Setup has completed"

# Launch build script
bash ./build.sh