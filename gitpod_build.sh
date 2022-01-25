#!/bin/bash
[[ -f logger/build.log ]] && rm logger/build.log || touch logger/build.log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>logger/build.log 2>&1

# Main dependencies
echo "Installing Dependencies" >&3
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
    python3-pip
    
# Set up a python server to display "tail -f" in a browser window
python3 -m pip install websockets
nohup python3 -u logger/tail.py webserver ./build.log > logger/pythonwebserver.log &
nohup python3 -u logger/tail.py tailserver ./build.log > logger/pythontailserver.log &

echo "At any time, if you wish to view the builder log, you can open your browser to:" >&3
gp url 8123 >&3

# coreboot source
echo "Obtaining Coreboot Source" >&3
git clone https://review.coreboot.org/coreboot

# coreboot submodules
echo "Getting Coreboot submodules" >&3
cd coreboot 
git submodule update --init --checkout

# crosstools
echo -e "Building Coreboot crosstools.\nThis may take a few minutes" >&3
make crossgcc-i386 CPUS=$(nproc)

# coreboot tools
echo "Installing Helper Tools" >&3
# CBFSTool
cd /util/cbfstool 
make
sudo make install

# IFDTool
cd ../ifdtool 
make 
sudo make install

# Process blobs
cd /workspace/coreboot_glk 
echo "Preparing Firmware Blobs" >&3
bash ./crosfirmware.sh octopus glk

echo "Setup has completed" >&3

# Launch build script
bash ./build.sh
