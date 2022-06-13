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
    until [ ! -z $REPLY ]; do 
        read -N1 -i'x' -srp "Do you want to edit config before building? [y|N]: ";
        [[ "$REPLY" =~ ^(y|Y)$ ]] && make nconfig;
        break; 
    done
    echo
    touch $LOG_DIR/coreboot.log
    LOGPID=$( ( nohup python $LOG_DIR/log_stream.py $LOG_DIR/coreboot.log >/dev/null 2>&1 & echo $! ) )
    MAKEPID=$( ( nohup make -C ${GITPOD_REPO_ROOT}/coreboot all CPUS=$(nproc) >$LOG_DIR/coreboot.log 2>&1 & echo $! ) )
    ${GITPOD_REPO_ROOT}/spinner.sh ${MAKEPID} 2>/dev/null
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
    for dv in ${devices[*]}; do
        if [[ "${dv,,}" = "${dev,,}" ]]; then
            valid=true
            break            
        elif [[ ${dev,,} =~ ^(x|exit)$ ]]; then
            exit
        fi
    done
    [[ $valid ]] && { build_coreboot $dev && showfiles || { echo "ERROR!! Coreboot build failed!"; exit 1; } } || { echo "$dev is not a valid selection"; unset dev; }
done
unset dev
