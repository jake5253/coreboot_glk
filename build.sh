#!/bin/bash

# The following line determines if the script was run directly or sourced by gitpod_build.sh
(return 0 2>/dev/null) && sourced=1 || sourced=0

[[ $sourced == 0 ]] && {
exec 3>&1 4>&2;
trap 'exec 2>&4 1>&3' 0 1 2 3;
exec 1>>logger/build.log 2>&1;
}

# This file assumes it is located in a directory parallel to coreboot_glk
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

do_build()
{
    _dev=$1
    cd "${SCRIPT_DIR}/coreboot"
    [[ $sourced == 0 ]] && make distclean
    cp configs/config.$_dev .config
    make olddefconfig
    make CPUS=$(nproc)
}


devices=($(cat devices))
while [ -z $dev ]; do
    echo "Choose one of the following devices for the build:"
    echo "Choose one of the following devices for the build:" >&3
    for ((i = 0; i < ${#devices}; i++)); do
        echo "${devices[$i]}";
        echo "${devices[$i]}" >&3
    done
    read -r -p "Selection : " dev >&3
    for ((i = 0; i < ${#devices}; i++)); do
        if [[ ${devices[$i]} = "${dev,,}" ]]; then
            do_build $dev
            break
        fi
    done

    if ((i == ${#devices})); then
        unset dev
        continue
    fi
done

echo "Build done"
echo "Build process completed. A window will pop open containing your compiled firmware so you can download and store the file locally" >&3
echo >&3
echo "To build for another device, run build.sh again." >&3
python3 -m http.server --directory coreboot 3000
