#!/bin/bash

# This file assumes it is located in a directory parallel to coreboot_glk
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
GITPOD_REPO_ROOT=${GITPOD_REPO_ROOT:-.}
LOG_DIR=${GITPOD_REPO_ROOT}/log

echo "Logs will be stored in: ${LOG_DIR}"

do_crosfirmware()
{
    [[ -f crosfirmware.sh ]] && bash crosfirmware.sh || { echo "ERROR! crosfirmware.sh file not found!"; exit 1; }
}

build_coreboot()
{
    _dev=${1:? "device not specified!"}
    cd "${GITPOD_REPO_ROOT}/coreboot"
    cp configs/config.$_dev .config || { echo "File not found: $PWD/configs/config.$_dev"; exit 1; }
    make olddefconfig
    touch $LOG_DIR/coreboot.log
    LOGPID=$( ( nohup python $LOG_DIR/log_stream.py $LOG_DIR/coreboot.log >/dev/null 2>&1 & echo $! ) )
    ( nohup make CPUS=$(nproc) 2>&1 >$LOG_DIR/coreboot.log & ${GITPOD_REPO_ROOT}/spinner.sh $! 2>/dev/null )
    kill -9 $LOGPID
}

showfiles()
{
    echo -e "Build process completed. \
    \nA window will pop open containing your compiled \
    \nfirmware so you can download and store the file locally"
    echo 
    echo "To build for another device, run build.sh again."
    python3 -m http.server --directory ./ 3000
}

[[ ! -f ${GITPOD_REPO_ROOT}/devices ]] && { do_crosfirmware; sync; }

devices=( $(cat ${GITPOD_REPO_ROOT}/devices | sort -u) )

while [ -z $dev ]; do
    clear
    echo "Choose one of the following devices for the build:"
    for d in ${devices[*]}; do
        echo "${d}";
    done
    echo 
    echo "Type x or exit to cancel"
    read -r -p "Selection: " dev
    for ((i = 0; i < ${#devices[*]}; i++)); do
        if [[ ${devices[$i]} = "${dev,,}" ]]; then
            build_coreboot $dev && showfiles || { echo "ERROR!! Coreboot build failed!"; exit 1; }
            break
        elif [[ ${dev,,} =~ ^(x|exit)$ ]]; then
            exit
        else
            echo "ERROR: Invalid selection: ${dev}";
            unset dev
            break
        fi
    done
    unset dev
done
