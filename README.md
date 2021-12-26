# coreboot_glk
Hacky way to build functional Coreboot for GeminiLake-based Chromebooks


USAGE:
Works best [and very quickly] on Gitpod 
[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/jake5253/coreboot_glk>)

Or, if you have to use your own system:
clone this repo
run startup.sh
-> This installs dependencies: (build-essential gnat-10 flex bison libncurses5-dev wget zlib1g-dev sharutils e2fsprogs parted curl unzip ca-certificates)
-> Clones Coreboot repo:
--> git clone https://review.coreboot.org/coreboot
--> cd coreboot
--> git submodule update --init --checkout
-> Builds crossgcc:
--> make crossgcc-i386 CPUS=$(nproc)
!--> YES. i386 IS correct -- its the only one that works
-> Builds cbfstool
--> cd util/cbfstool
--> make
--> sudo make install
-> Builds ifdtool
--> cd util/ifdtool
--> make
--> sudo make install
-> Runs modified script from Coreboot source to fetch and extract important bits of Google's Firmware
--> have a look at crosfirmware.sh to see what's happening.
---> Essentially, we download recovery image, extract root filesystem, copy firmware_update_tool
----> run firmware_update_tool locally, but only unpack, use cbfstool and ifdtool to extract the blobs we 
----> need from the firmware files, drop the blobs into coreboot, tell coreboot where to find the files
-> Build Coreboot
