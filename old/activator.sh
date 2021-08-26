#!/usr/bin/env bash
#------------------------------------------------------------------------------
# NAME
#	activator - a python virtual environment activator for the lazy.
#
# SYNOPSIS
#	Anywhere:	activator.sh
#
# DESCRIPTION
#	activator will automatically search the current working directory for
#	a virtual environment activation script. If it finds exactly one
#	virtual environment, it will activate it.
#
#	If no virtual environments are found, activator will print an error
#	message and exit. If multiple are found, the paths to each activation
#	script that was found will be printed, and the program will exit.
#
#	Once a virtual environment is activated, the program will print the
#	current pip path to verify that activation worked correctly.
#
#------------------------------------------------------------------------------

# Find the activation script
script="$(find . -maxdepth 3 -type f -name "activate" 2>/dev/null)"

# Check if no activation script was found
if [ -z "$script" ]; then
    echo "No activation script found."
else
    # Check if multiple scripts were found
    scripts="$(find . -maxdepth 3 -type f -name "activate" 2>/dev/null | wc -l)"
    if [ "$scripts" -gt "1" ]; then
        echo "Multiple activation scripts found. Cowardly refusing to pick one."
        echo "$scripts scripts found:"
        echo "$script"
    else
        # Activate the script
        echo "Activating virtual environment using $script"
        source $script
        echo "Current pip binary: $(which pip)"
    fi
fi
