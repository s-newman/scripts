#!/bin/bash
set -eoux pipefail

sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup
temp_mirrorlist=$(mktemp)
# Rutgers doesn't support TLS 1.2
# Clarkson times out
reflector \
  --ipv4 \
  --country US \
  --protocol https \
  --include '\.(edu|org)' \
  --exclude 'rutgers' \
  --exclude 'clarkson' \
  --sort score \
  --save "${temp_mirrorlist}"
sudo mv "${temp_mirrorlist}" /etc/pacman.d/mirrorlist
sudo pacman -Syyu
yay --aur -Syu
