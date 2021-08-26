#!/usr/bin/env bash
#------------------------------------------------------------------------------
# NAME
#	temps.sh - an i3blocks script that displays the current CPU temperature.
#
# SYNOPSIS
#	temps.sh
#
#------------------------------------------------------------------------------
DEGREES=$(acpi -t | sed 's/\./ /g' | awk '{ print $(NF-3) }')
UNITS=$(acpi -t | awk '{ print $NF }')

# Full text
echo "CPU: ${DEGREES} ${UNITS}"

# Short text
echo "${DEGREES} ${UNITS}"

# Use an urgent display if temps go above 69
[ ${DEGREES} -gt "69" ] && exit 33

# Otherwise, display a pretty text color
if [ ${DEGREES} -ge "60" ]; then
	echo "#FF0000"	# Red if temps over 60C
elif [ ${DEGREES} -lt "50" ]; then
	echo "#00FF00"	# Green if temps under 50C
else
	echo "#FFFFFF" 	# White otherwise
fi
