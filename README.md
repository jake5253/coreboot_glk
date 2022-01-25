# coreboot_glk
Hacky way to build functional Coreboot for GeminiLake-based Chromebooks


USAGE:
Works best [and very quickly] on Gitpod 
[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/jake5253/coreboot_glk)


Or, if you have to use your own system.


**The startup.sh script does everything for you.** 

**`git clone https://github.com/jake5253/coreboot_glk && coreboot_glk/startup.sh`**


...OR: If you wish to do all the work yourself, follow these steps:

 1. Install dependencies [debian,ubuntu,mint,etc.]: 
>build-essential gnat-10 flex bison libncurses5-dev wget zlib1g-dev sharutils e2fsprogs parted curl unzip ca-certificates
 2. Clone Coreboot repo:

    `git clone https://review.coreboot.org/coreboot coreboot_glk`
    
    `cd coreboot_glk`
    
    `git submodule update --init --checkout`
    

 3. Build crossgcc:
 
`make crossgcc-i386 CPUS=$(nproc)`

> YES. i386 IS correct -- its the only one that works
> NOTE: this step could take a while

4. Build cbfstool

`cd util/cbfstool`

`make`

`sudo make install`

5. Build ifdtool

`cd ../ifdtool`

`make`

`sudo make install`

6. Use my modified crosfirmware.sh script 

`cd ../../..`

`curl -O https://raw.githubusercontent.com/jake5253/coreboot_glk/main/crosfirmware.sh`

`chmod +x crosfirmware.sh`

`bash crosfirmware.sh octopus glk`

>Essentially, we download the full recovery image from Google, extract the root filesystem, copy out the firmware_update_tool, run firmware_update_tool locally -- in unpack-only mode, use cbfstool and ifdtool to extract the blobs we need from the firmware files, drop the blobs into coreboot, and finally tell coreboot where to find the files

7. Build Coreboot

`curl -O https://raw.githubusercontent.com/jake5253/coreboot_glk/main/build.sh`

`chmod +x build.sh`

`bash build.sh`
