#!/bin/bash
if [ -x "pacman" ]; then
  mkdir -p "${HOME}/Documents/packages"
  pacman -Qqett | sort | tee "${HOME}/Documents/packages/installed-packages-$(date +'%Y-%m-%d').txt"
fi

if [ -x "dconf" ]; then
  mkdir -p "${HOME}/Documents/dconf-backups"
  dconf dump / | tee "${HOME}/Documents/dconf-backups/$(date +'%Y-%m-%d').txt"
fi