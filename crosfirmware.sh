#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-2.0-only

##########################################
# Modified from coreboot source to extract specific bits of 
# firmware for building coreboot that works on glk-based Chromebooks
# Modifications made by github.com/jake5253
#         USE AT YOUR OWN RISK
# This file assumes it is located in a directory parallel to coreboot (coreboot source)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
##########################################


# On some systems, `parted` and `debugfs` are located in /sbin.
export PATH="$PATH:/sbin"

exit_if_uninstalled() {
	local cmd_name="$1"
	local deb_pkg_name="$2"

	if type "$cmd_name" >/dev/null 2>&1; then
		return
	fi

	printf '`%s` was not found. ' "$cmd_name" >&2
	printf 'On Debian-based systems, it can be installed\n' >&2
	printf 'by running `apt install %s`.\n' "$deb_pkg_name" >&2

	exit 1
}

exit_if_dependencies_are_missing() {
	exit_if_uninstalled "uudecode" "sharutils"
	exit_if_uninstalled "debugfs" "e2fsprogs"
	exit_if_uninstalled "parted" "parted"
	exit_if_uninstalled "curl" "curl"
	exit_if_uninstalled "unzip" "unzip"
}

get_inventory()
{
	_conf=$1
	_url=https://dl.google.com/dl/edgedl/chromeos/recovery/recovery.conf

	echo "Downloading recovery image inventory..."

	curl -s "$_url" > $_conf
}

download_image()
{
	_url=$1
	_file=$2

	echo "Downloading recovery image"
	curl "$_url" > "$_file.zip"
	echo "Decompressing recovery image"
	unzip -q "$_file.zip"
	sudo rm -rf "$_file.zip"
}

extract_partition()
{
	NAME=$1
	FILE=$2
	ROOTFS=$3
	_bs=1024

	echo "Extracting ROOT-A partition"
	ROOTP=$( printf "unit\nB\nprint\nquit\n" | \
		 parted $FILE 2>/dev/null | grep $NAME )

	START=$(( $( echo $ROOTP | cut -f2 -d\ | tr -d "B" ) ))
	SIZE=$(( $( echo $ROOTP | cut -f4 -d\ | tr -d "B" ) ))

	dd if=$FILE of=$ROOTFS bs=$_bs skip=$(( $START / $_bs )) \
		count=$(( $SIZE / $_bs ))  > /dev/null
}

extract_shellball()
{
	ROOTFS=$1
	SHELLBALL=$2

	echo "Extracting chromeos-firmwareupdate"
	printf "cd /usr/sbin\ndump chromeos-firmwareupdate $SHELLBALL\nquit" | \
		debugfs $ROOTFS > /dev/null 2>&1
}

extract_coreboot()
{
	_shellball=$1
	_unpacked=$( mktemp -d )

	echo "Extracting coreboot image"
	sh $_shellball --unpack $_unpacked > /dev/null

	_version=$( cat $_unpacked/VERSION | grep BIOS\ version: | \
			cut -f2 -d: | tr -d \  )

	cp $_unpacked/bios.bin coreboot-$_version.bin
	sudo rm -rf "$_unpacked"
}

do_defconfig()
{
	_board=$1
	cat <<-EOF | tee "${SCRIPT_DIR}/coreboot/configs/config.$_board" > /dev/null
		CONFIG_VENDOR_GOOGLE=y
		CONFIG_NO_POST=y
		CONFIG_IFD_BIN_PATH="3rdparty/blobs/mainboard/google/$_board/flashdescriptor.bin"
		CONFIG_BOARD_GOOGLE_${_board^^}=y
		# CONFIG_CONSOLE_SERIAL is not set
		CONFIG_INCLUDE_NHLT_BLOBS=y
		CONFIG_INTEL_GMA_ADD_VBT=y
		CONFIG_INTEL_GMA_VBT_FILE="3rdparty/blobs/mainboard/google/$_board/vbt.bin"
		CONFIG_NEED_IFWI=y
		CONFIG_IFWI_FILE_NAME="3rdparty/blobs/mainboard/google/$_board/ifwi.bin"
		CONFIG_HAVE_IFD_BIN=y
		CONFIG_ADD_FSP_BINARIES=y
		CONFIG_FSP_M_FILE="3rdparty/blobs/mainboard/google/$_board/fspm.bin"
		CONFIG_FSP_S_FILE="3rdparty/blobs/mainboard/google/$_board/fsps.bin"
		CONFIG_CPU_MICROCODE_CBFS_EXTERNAL_BINS=y
		CONFIG_CPU_UCODE_BINARIES="3rdparty/blobs/mainboard/google/$_board/cpu_microcode_blob.bin"
		CONFIG_LOCK_MANAGEMENT_ENGINE=y
		CONFIG_HAVE_INTEL_FIRMWARE=y
		CONFIG_HAVE_FSP_GOP=y
		CONFIG_RUN_FSP_GOP=y
		CONFIG_TIANOCORE_BOOT_TIMEOUT=2
		CONFIG_PAYLOAD_TIANOCORE=y
		CONFIG_PAYLOAD_FILE="payloads/external/tianocore/tianocore/Build/UEFIPAYLOAD.fd"
		CONFIG_TIANOCORE_UEFIPAYLOAD=y
		# CONFIG_TIANOCORE_UPSTREAM is not set
		CONFIG_TIANOCORE_REVISION_ID=""
		# CONFIG_TIANOCORE_DEBUG is not set
		CONFIG_TIANOCORE_RELEASE=y
		# CONFIG_TIANOCORE_CBMEM_LOGGING is not set
		# CONFIG_TIANOCORE_BOOTSPLASH_IMAGE is not set

	EOF
}

extract_octopus_blobs()
{
	_shellball=$1
	_unpacked=$( mktemp -d )
	_boards=

	echo "Unpacking recovery image"
	sh $_shellball --unpack $_unpacked > /dev/null
	for bios in $(ls $_unpacked/images/bios-*.bin); do
		_boardname=$(basename $bios | cut -d- -f2 | cut -d. -f1)
		_board_dir="${SCRIPT_DIR}/coreboot/3rdparty/blobs/mainboard/google/$_boardname"
		_nhlt_blobs="${SCRIPT_DIR}/coreboot/3rdparty/blobs/soc/intel/glk/nhlt-blobs"
		mkdir -p $_board_dir
		echo "Extracting $_boardname Blobs"
		cd $_board_dir
		ifdtool -x $bios > /dev/null
		mv flashregion_0_flashdescriptor.bin flashdescriptor.bin
		rm flashregion*
		cbfstool $bios read -r IFWI -f $_board_dir/ifwi.bin > /dev/null
		_blobs="vbt.bin cpu_microcode_blob.bin"
		for blob in $_blobs; do
			cbfstool $bios extract -n $blob -f $blob > /dev/null
		done
		for dsp in $(cbfstool $bios print | grep khz | cut -d" " -f1); do \
			cbfstool $bios extract -n $dsp -f $_nhlt_blobs/$dsp > /dev/null
		done
		do_defconfig $_boardname
		_boards+=" $_boardname"
	done
	echo "$_boards" | tee "${SCRIPT_DIR}/devices"
	#sudo rm -rf "$_unpacked"
}

do_one_board()
{
	_board=$1
	_url=$2
	_file=$3

	download_image $_url $_file

	extract_partition ROOT-A $_file root-a.ext2
	extract_shellball root-a.ext2 chromeos-firmwareupdate-$_board
	sudo rm -rf $_file root-a.ext2

	extract_coreboot chromeos-firmwareupdate-$_board
}

do_glk_board()
{
	_board=$1
	_url=$2
	_file=$3

	download_image $_url $_file

	extract_partition ROOT-A $_file root-a.ext2
	extract_shellball root-a.ext2 chromeos-firmwareupdate-$_board
	extract_octopus_blobs chromeos-firmwareupdate-$_board

	#sudo rm -rf $_file root-a.ext2

}

#
# Main
#

BOARD=$1

exit_if_dependencies_are_missing

if [ "$BOARD" == "all" ]; then
	CONF=$( mktemp )
	get_inventory $CONF

	grep ^name= $CONF| while read _line; do
		name=$( echo $_line | cut -f2 -d= )
		echo Processing board $name
		eval $( grep -v hwid= $CONF | grep -A11 "$_line" | \
						grep '\(url=\|file=\)' )
		BOARD=$( echo $url | cut -f3 -d_ )
		do_one_board $BOARD $url $file
	done

	sudo rm -rf "$CONF"
elif [ "$BOARD" != "" ]; then
	CONF=$( mktemp )
	get_inventory $CONF

	echo Processing board $BOARD
	eval $( grep $BOARD $CONF | grep '\(url=\|file=\)' )
	if [ "$2" == "glk" ]; then
		do_glk_board $BOARD $url $file
	else
		do_one_board $BOARD $url $file
	fi
	#sudo rm -rf "$CONF"
else
	echo "Usage: $0 <boardname>"
	echo "       $0 all"
	echo
	exit 1
fi
