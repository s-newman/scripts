#!/bin/bash
mkdir -p "${HOME}/Documents/packages"
pacman -Qqett | sort | tee "${HOME}/Documents/packages/installed-packages-$(date +'%Y-%m-%d').txt"
