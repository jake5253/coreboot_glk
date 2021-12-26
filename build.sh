#!/bin/bash
do_build()
{
    _dev=$1
    cd /workspace/coreboot_glk/coreboot
    make defconfig configs/config.$_dev
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