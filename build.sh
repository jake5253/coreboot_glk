#!/bin/bash

# This file assumes it is located in a directory parallel to coreboot_glk
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_DIR=${GITPOD_REPO_ROOT}/log

echo ${SCRIPT_DIR}

do_crosfirmware()
{
    bash ${SCRIPT_DIR}/crosfirmware.sh
}

build_crossgcc()
{
    cd "${GITPOD_REPO_ROOT}/coreboot"
    echo "Building the coreboot toolchain"
    echo "This may take a while"
    touch $LOG_DIR/crossgcc.log
    LOGPID=$( (nohup python $LOG_DIR/log_stream.py $LOG_DIR/crossgcc.log >/dev/null 2>&1 & echo $!) )
    echo "LOGPID = ${LOGPID}"
    (nohup make crossgcc-i386 CPUS=$(nproc) >$LOG_DIR/crossgcc.log 2>&1 & ${GITPOD_REPO_ROOT}/spinner.sh $! 2>/dev/null)
    kill -9 $LOGPID
}

build_coreboot()
{
    _dev=$1
    cd "${GITPOD_REPO_ROOT}/coreboot"
    cp configs/config.$_dev .config
    make olddefconfig
    touch $LOG_DIR/coreboot.log
    LOGPID=$( (nohup python $LOG_DIR/log_stream.py $LOG_DIR/coreboot.log >/dev/null 2>&1 & echo $!) )
    echo "LOGPID = ${LOGPID}"
    (nohup make CPUS=$(nproc) 2>&1 >$LOG_DIR/coreboot.log &)
        ${GITPOD_REPO_ROOT}/spinner.sh $! 2>/dev/null
    kill -9 $LOGPID
}

build_crossgcc || { echo "ERROR! crossgcc toolchain build failed!"; exit 1; }

[[ ! -f devices ]] && { do_crosfirmware; sync; }

devices=($(cat devices | sort -u))

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
            build_coreboot $dev || { echo "ERROR!! Coreboot build failed!"; exit 1; }
            break
        elif [[ ${dev,,} =~ ^(x|exit)$ ]]; then
            exit
        else
            echo "ERROR: Invalid selection: ${dev}";
            unset dev
            break
        fi
    done

    if ((i == ${#devices[*]})); then
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
