#!/bin/bash

# The following line determines if the script was run directly or sourced by gitpod_build.sh
#(return 0 2>/dev/null) && sourced=1 || sourced=0

#[[ $sourced == 0 ]] && {
#exec 3>&1 4>&2;
#trap 'exec 2>&4 1>&3' 0 1 2 3;
#exec 1>>logger/build.log 2>&1;
#}

# This file assumes it is located in a directory parallel to coreboot_glk
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

do_crosfirmware()
{
    bash ${SCRIPT_DIR}/crosfirmware.sh
}

do_build()
{
    _dev=$1
    cd "${SCRIPT_DIR}/coreboot"
    make distclean
    cp configs/config.$_dev .config
    make olddefconfig
    make CPUS=$(nproc)
}

while [ ! -f ${SCRIPT_DIR}/devices ]; do
    do_crosfirmware
    devices=($(cat "${SCRIPT_DIR}/devices"))
done
while [ -z $dev ]; do
    echo "Choose one of the following devices for the build:"
    for ((i = 0; i < ${#devices}; i++)); do
        echo "${devices[$i]}";
    done
    echo 
    echo "Type x or exit to stop the build"
    read -r -p "Selection : " dev
    for ((i = 0; i < ${#devices}; i++)); do
        if [[ ${devices[$i]} = "${dev,,}" ]]; then
            do_build $dev
            break
        elif [[ ${dev,,} =~ ^(x|exit)$ ]]; then
            exit
        fi
    done

    if ((i == ${#devices})); then
        unset dev
        continue
    fi
done

echo -e "Build process completed. \
    \nA window will pop open containing your compiled \
    \nfirmware so you can download and store the file locally"
echo 
echo "To build for another device, run build.sh again."
python3 -m http.server --directory ./ 3000
