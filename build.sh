#!/bin/bash

# This file assumes it is located in a directory parallel to coreboot_glk
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
GITPOD_REPO_ROOT=${GITPOD_REPO_ROOT:-.}
LOG_DIR=${GITPOD_REPO_ROOT}/log
LOG_FILE=${LOG_DIR}/coreboot_${date +'%F_%I%M%S'}.log

. ${SCRIPT_DIR}/helpers/spinner.sh

echo "Log will be stored in: ${LOG_DIR}"

do_crosfirmware()
{
    [[ -f ${SCRIPT_DIR}/helpers/crosfirmware.sh ]] && bash ${SCRIPT_DIR}/helpers/crosfirmware.sh || { echo "ERROR! crosfirmware.sh file not found!"; exit 1; }
}

build_coreboot()
{
    _dev=${1:? "device not specified!"}
    pushd "${GITPOD_REPO_ROOT}/coreboot"
    cp configs/config.$_dev .config || { echo "File not found: $PWD/configs/config.$_dev"; exit 1; }
    make olddefconfig
    until [ ! -z $REPLY ]; do 
        read -N1 -i'x' -srp "Do you want to edit config before building? [y|N]: ";
        [[ "$REPLY" =~ ^(y|Y)$ ]] && make nconfig;
        break; 
    done
    echo
    touch ${LOG_FILE}
    LOGPID=$( ( nohup python $LOG_DIR/log_stream.py ${LOG_FILE} >/dev/null 2>&1 & echo $! ) )
    MAKEPID=$( ( nohup make all CPUS=$(nproc) >${LOG_FILE} 2>&1 & echo $! ) )
    spinner ${MAKEPID} 2>/dev/null
    kill -9 $LOGPID
    popd
}

showfiles()
{
    echo -e "Build process completed. \
    \nA window will pop open containing your compiled \
    \nfirmware so you can download and store the file locally"
    echo 
    echo "To build for another device, run build.sh again."
    python3 -m http.server --directory ${SCRIPT_DIR}/coreboot/build 3000
}

#
## MAIN
#

[[ ! -f ${GITPOD_REPO_ROOT}/devices ]] && { do_crosfirmware; sync; }

devices=( $(cat ${GITPOD_REPO_ROOT}/devices | sort -u) )

while [ -z $dev ]; do
    clear
    echo "Choose one of the following devices for the build:"
    for d in ${devices[*]}; do
        echo "${d}";
    done
    echo 
    echo "Type 'x' or 'exit' to cancel"
    read -r -p "Selection: " dev
    for dv in ${devices[*]}; do
        if [[ "${dv,,}" = "${dev,,}" ]]; then
            valid=true
            break            
        elif [[ ${dev,,} =~ ^(x|exit)$ ]]; then
            quit=true
            break
        fi
    done
    echo
    [[ quit ]] && exit
    [[ $valid ]] && build_coreboot $dev || { echo "$dev is not a valid selection"; unset dev; }
done
unset dev
# at this point build finished or failed but 
# the return code is useless. check for coreboot.rom
[[ -f ${SCRIPT_DIR}/coreboot/build ]] && showfiles || { echo "ERROR!! Coreboot build failed! See log for further details."; exit 1; } }
