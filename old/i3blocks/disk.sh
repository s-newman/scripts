#!/usr/bin/env bash
#------------------------------------------------------------------------------
# NAME
#	disk.sh - an i3blocks script that displays the available space on a drive.
#
# SYNOPSIS
#	template FILESYSTEM LABEL
#
# OPTIONS
#	FILESYSTEM
#		The path to the filesystem, as shown in df.
#	LABEL
#		The label that should be displayed in the status bar.
#
# DESCRIPTION
#	An i3blocks script to that displays the available space on a drive, as
#	reported by df.
#
# EXAMPLES
#	disk.sh /dev/mapper/vg--main-lv--home /home
#
#------------------------------------------------------------------------------

# Unpack arguments
FILESYSTEM=$1
LABEL=$2

AVAIL=$(df -h | grep ${FILESYSTEM} | awk '{ print $4 }')
USE=$(df -h | grep ${FILESYSTEM} | awk '{ print $5 }' | sed 's/%//g')

# Full text
echo "${LABEL}: ${AVAIL} (${USE}%)"

# Short text
echo "${AVAIL}"

# Use an urgent display if usage goes above 90%
[ ${USE} -ge "90" ] && exit 33

# Otherwise, just use white
echo "#FFFFFF"
