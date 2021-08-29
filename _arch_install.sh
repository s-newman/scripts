# directory must exist
ls /sys/firmware/efi/efivars

# Need networking
ping -c 1 archlinux.org

# Update the system clock
timedatectl set-ntp true

# Formatting (encrypted EFI)
parted /dev/sda mklabel gpt
parted /dev/sda mkpart primary fat32 1MiB 513MiB # This will make it 512 MiB instead of 511 MiB
parted /dev/sda set 1 esp on
parted /dev/sda mkpart primary 513MiB 100%
cryptsetup -yv luksFormat /dev/sda2
cryptsetup open /dev/sda2 cryptroot
mkfs.fat -F 32 /dev/sda1
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
parted /dev/sda print
lsblk

# Mirror setup
curl -so - 'https://archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&use_mirror_status=on' | sed -e 's/^#Server/Server/' -e '/^## United States/d' | tee /etc/pacman.d/mirrorlist

# Faster installation (have to redo this later because the config isn't copied)
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Initial installation (note intel-ucode for intel procs)
pacstrap /mnt base base-devel linux linux-firmware grub efibootmgr intel-ucode sudo zsh tmux vi vim networkmanager wpa_supplicant man-db man-pages texinfo gnome gnome-shell-extensions gnome-tweaks
# networkmanager-openvpn if using vpn
# add any other packages you want

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Enter the chroot
arch-chroot /mnt

# Set time information
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# Generate locales
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# Hostname
echo "hostname" > /etc/hostname
cat > /etc/hosts << EOF
# Static table lookup for hostnames.
# See hosts(5) for details.
127.0.0.1	localhost
127.0.1.1	hostname

::1		localhost
EOF

# Initramfs
sed -i 's/^HOOKS.*$/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Enable parallel pacman downloads
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# User
useradd -c "Local Administrator" -d /home/ladmin -G wheel -m --shell /bin/zsh ladmin
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/10-wheel
passwd ladmin

# Grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
uuid=$(blkid /dev/sda2 | awk '{print $2}' | tr -d '"')
sed -i -e '/^GRUB_CMDLINE_LINUX_DEFAULT/d' -e 's/^GRUB_CMDLINE_LINUX.*$/GRUB_CMDLINE_LINUX="cryptdevice='${uuid}':cryptroot root=\/dev\/mapper\/cryptroot"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# On-boot services
systemctl enable gdm.service NetworkManager.service wpa_supplicant.service

# Look at mkinitcpio -P output and install missing firmware for modules
