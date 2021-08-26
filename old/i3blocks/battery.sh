#!/usr/bin/env bash
#------------------------------------------------------------------------------
# NAME
#	battery.sh - an i3blocks script to display the current battery status.
#
# SYNOPSIS
#	battery.sh NUMBER
#
# OPTIONS
#	NUMBER
#		The number of the battery to display status information for.
#
# EXAMPLES
#	battery.sh 0
#
#------------------------------------------------------------------------------

NUM=$1

PERCENT="$(acpi -b | grep "Battery ${NUM}" | awk '{ print $4 }' | tr -d "%,")"
STATUS="$(acpi -b | grep "Battery ${NUM}" | awk '{ print $3 }' | tr -d "%,")"

# Set the color based on current charge
if [ "${PERCENT}" -le "25" ]; then
	COLOR="#FF0000"
elif [ "${PERCENT}" -ge "75" ]; then
	COLOR="#00FF00"
else
	COLOR="#FFFFFF"
fi

# Determine what the status is
if [ "${STATUS}" == "Charging" ]; then
 	STATUSTEXT="CHG"
	COLOR="#00FF00"
elif [ "${STATUS}" == "Unknown" ]; then
 	STATUSTEXT="UNK"
elif [ "${STATUS}" == "Full" ]; then
 	STATUSTEXT="FUL"
elif [ "${STATUS}" == "Discharging" ]; then
 	STATUSTEXT="USE"
else
	STATUSTEXT="?? - ${STATUS}"
fi

# Full text
echo "BAT$1: ${PERCENT}% ${STATUSTEXT}"

# Short text
echo "${PERCENT}"

# Color
echo "${COLOR}"
