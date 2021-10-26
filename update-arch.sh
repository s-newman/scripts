#!/bin/bash
set -eoux pipefail

sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup
temp_mirrorlist=$(mktemp)
rate-mirrors --save "${temp_mirrorlist}" --protocol https --country-neighbors-per-country 0 --country-test-mirrors-per-country 5 arch
sudo mv "${temp_mirrorlist}" /etc/pacman.d/mirrorlist
sudo pacman -Syyu
yay --aur -Syu