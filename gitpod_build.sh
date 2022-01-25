#!/bin/bash

# Main dependencies
echo "Installing Dependencies"
sudo apt update 2>&1 > /tmp/buildlog
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
    2>&1 > /tmp/buildlog
    
echo "At any time, if you wish to view the builder log, you can open your browser to:"
gp url 8123

# coreboot source
echo "Obtaining Coreboot Source"
git clone https://review.coreboot.org/coreboot 2>&1 > /tmp/buildlog

# coreboot submodules
echo "Getting Coreboot submodules" 
cd coreboot 
git submodule update --init --checkout 2>&1 > /tmp/buildlog

# crosstools
echo -e "Building Coreboot crosstools.\n This may take a few minutes"
make crossgcc-i386 CPUS=$(nproc) 2>&1 > /tmp/buildlog

# coreboot tools
echo "Installing Helper Tools" 
# CBFSTool
cd /util/cbfstool 
make 2>&1 > /tmp/buildlog
sudo make install 2>&1 > /tmp/buildlog

# IFDTool
cd ../ifdtool 
make 2>&1 > /tmp/buildlog 
sudo make install 2>&1 > /tmp/buildlog

# Process blobs
cd /workspace/coreboot_glk 
echo "Preparing Firmware Blobs" 
bash ./crosfirmware.sh octopus glk

echo "Setup has completed"

# Launch build script
bash ./build.sh
