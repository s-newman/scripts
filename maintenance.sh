#!/bin/bash
if [ -x "/usr/bin/pacman" ]; then
  mkdir -p "${HOME}/Documents/packages"
  pacman -Qqett | sort | tee "${HOME}/Documents/packages/installed-packages-$(date +'%Y-%m-%d').txt"
else
  echo "pacman not found, skipping package listing..."
fi

if [ -x "/usr/bin/dconf" ]; then
  mkdir -p "${HOME}/Documents/dconf-backups"
  dconf dump / | tee "${HOME}/Documents/dconf-backups/$(date +'%Y-%m-%d').txt"
else
  echo "dconf not found, skipping settings backup..."
fi
