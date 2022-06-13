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

do_defconfig()
{
	_board=$1
	cat <<-EOF | tee -a "${SCRIPT_DIR}/coreboot/configs/config.$_board"
CONFIG_VENDOR_GOOGLE=y
CONFIG_BOARD_GOOGLE_OCTOPUS=y
CONFIG_BOARD_GOOGLE_${_board^^}=y
CONFIG_VARIANT_DIR="${_board,,}"
CONFIG_BOARD_GOOGLE_BASEBOARD_OCTOPUS=y
CONFIG_ADD_FSP_BINARIES=y
CONFIG_CPU_MICROCODE_CBFS_EXTERNAL_BINS=y
CONFIG_CPU_UCODE_BINARIES="3rdparty/blobs/mainboard/google/cpu_microcode_blob.bin"
CONFIG_FSP_M_FILE="3rdparty/blobs/mainboard/google/fspm.bin"
CONFIG_FSP_COMPRESS_FSP_M_LZMA=y
CONFIG_FSP_S_FILE="3rdparty/blobs/mainboard/google/fsps.bin"
CONFIG_FSP_COMPRESS_FSP_S_LZMA=y
CONFIG_PAYLOAD_TIANOCORE=y
CONFIG_PAYLOAD_FILE="\$(obj)/UEFIPAYLOAD.fd"
CONFIG_PAYLOAD_OPTIONS=""
CONFIG_TIANOCORE_UPSTREAM=y
CONFIG_TIANOCORE_REPOSITORY="https://github.com/tianocore/edk2"
CONFIG_TIANOCORE_TAG_OR_REV="origin/master"
CONFIG_TIANOCORE_RELEASE=y
CONFIG_COMPRESSED_PAYLOAD_LZMA=y
CONFIG_INCLUDE_NHLT_BLOBS=y

	EOF
}

extract_octopus_blobs()
{
	_shellball=$1
	_unpacked=$( mktemp -d )
	_boards=

	echo "Unpacking recovery image"
	sh $_shellball --unpack $_unpacked
	for bios in $(ls $_unpacked/images/bios-*.bin); do
		_boardname=$(basename $bios | cut -d- -f2 | cut -d. -f1)
		_board_dir="${SCRIPT_DIR}/coreboot/3rdparty/blobs/mainboard/google/$_boardname"
		_nhlt_blobs="${SCRIPT_DIR}/coreboot/3rdparty/blobs/soc/intel/glk/nhlt-blobs"
		mkdir -p $_board_dir
		mkdir -p $_nhlt_blobs
		echo "Extracting $_boardname blobs"
		ifdtool -x $bios
		mv flashregion_0_flashdescriptor.bin $_board_dir/flashdescriptor.bin
		rm flashregion*
		cbfstool $bios read -r IFWI -f $_board_dir/ifwi.bin
		_blobs="vbt.bin cpu_microcode_blob.bin fsps.bin fspm.bin"
		for blob in $_blobs; do
			cbfstool $bios extract -n $blob -f $_board_dir/$blob
		done
		for dsp in $(cbfstool $bios print | grep khz | cut -d" " -f1); do \
			cbfstool $bios extract -n $dsp -f $_nhlt_blobs/$dsp
		done
		do_defconfig $_boardname
		#_boards+=" $_boardname"
		echo "$_boardname" | tee -a "${SCRIPT_DIR}/devices" >/dev/null
	done
	#echo "$_boards" | tee "${SCRIPT_DIR}/devices" >/dev/null
}

do_octopus()
{
	_board=$1
	_url=$2
	_file=$3

	if [[ ! -f $_file ]]; then 
		download_image $_url $_file
		extract_partition ROOT-A $_file root-a.ext2
		extract_shellball root-a.ext2 chromeos-firmwareupdate-$_board
		extract_octopus_blobs chromeos-firmwareupdate-$_board
		rm -rf $_file root-a.ext2 chromeos-firmware*
	fi
}

#
# Main
#

BOARD=octopus

exit_if_dependencies_are_missing
CONF=$( mktemp )
get_inventory $CONF

echo "Processing board $BOARD"
eval $( grep $BOARD $CONF | grep '\(url=\|file=\)' )
do_octopus $BOARD $url $file
rm $CONF
	