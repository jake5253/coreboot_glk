#!/bin/bash
# This file assumes it is located in a directory parallel to coreboot_glk
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

do_build()
{
    _dev=$1
    cd "${SCRIPT_DIR}/coreboot"
    cp configs/config.$_dev .config
    make olddefconfig
    make CPUS=$(nproc)
}


devices=($(cat devices))
while [ -z $dev ]; do
    echo "Choose one of the following devices for the build:"
    for ((i = 0; i < ${#devices}; i++)); do
        echo "${devices[$i]}";
    done
    read -r -p "Selection : " dev
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

echo "Build process completed. A window will pop open containing your compiled firmware so you can download and store the file locally"
echo
echo "To build for another device, run build.sh again."
python3 -m http.server --directory coreboot 3000
