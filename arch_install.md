# Arch Installation

First, make sure you have the latest Arch install ISO. [RIT's mirrors](https://mirrors.rit.edu/archlinux/iso/) are a good source, and not just because I'm an alum.

## Base Setup

Boot into the ISO in UEFI mode and make sure EFI variables are available:
```shell
# directory must exist with contents
ls /sys/firmware/efi/efivars
```

Make sure you have networking:
```shell
ping -c 1 archlinux.org
```

Update the system clock with systemd-timesyncd:
```shell
timedatectl set-ntp true
```

Format the primary disk. The following sets up a 512MiB EFI boot partition and a LUKS-encrypted root partition that takes up the rest of the disk.
```shell
# replace /dev/sda as necessary
# can run `parted /dev/sda` to get a prompt
parted /dev/sda mklabel gpt
parted /dev/sda mkpart primary fat32 1MiB 513MiB # This will make it 512 MiB instead of 511 MiB
parted /dev/sda set 1 esp on
parted /dev/sda mkpart primary 513MiB 100%
# (parted) quit

# Set up LUKS
cryptsetup -yv luksFormat /dev/sda2
cryptsetup open /dev/sda2 cryptroot
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt

# Boot partition
mkfs.fat -F 32 /dev/sda1
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Make sure everything looks right
parted /dev/sda print
lsblk
```

Set up mirrorlist:
```shell
reflector --ipv4 --country US --protocol https --save /etc/pacman.d/mirrorlist
```

Configure parallel downloading to speed up the first-time installation. In `/etc/pacman.conf`, uncomment the following line:
```conf
#ParallelDownloads = 5
```
> We'll have to do this again later after `pacstrap` because this config file doesn't get copied over during the installation.

Install base set of packages
```shell
pacstrap /mnt base base-devel linux linux-firmware grub efibootmgr intel-ucode sudo zsh tmux vi vim networkmanager wpa_supplicant man-db man-pages texinfo gnome gnome-shell-extensions gnome-tweaks htop python ipython mypy python-black flake8 alacritty bind zsh-autosuggestions zsh-completions zsh-syntax-highlighting tree firefox noto-fonts gnome-shell-extension-gtile wireshark-qt docker docker-compose virtualbox virtualbox-host-modules-arch git
```

Other possibly useful packages (depends on environment):
- `keepassxc`
- `networkmanager-openvpn`
- `signal-desktop`

Generate fstab
```shell
genfstab -U /mnt >> /mnt/etc/fstab
```

## Chroot Steps

Enter the chroot with `arch-chroot /mnt` and continue with these steps within the chroot.

Configure timezone and hardware clock
```shell
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc
```

Uncomment the following line in `/etc/locale.gen`:
```
#en_US.UTF-8 UTF-8
```

Generate locales:
```shell
locale-gen
```

Put your desired hostname in `/etc/hostname`, and then put the following in your `/etc/hosts`:
```
# Static table lookup for hostnames.
# See hosts(5) for details.
127.0.0.1	localhost
127.0.1.1	hostname

::1		localhost
```
> Remember to replace `hostname` in the above with your actual hostname!

Set up your user:
```shell
useradd -c "Local Administrator" -d /home/ladmin -G wheel,docker,wireshark,vboxusers -m --shell /bin/zsh ladmin
passwd ladmin
```

Enable passwordless SSH by creating a file at `/etc/sudoers.d/10-wheel` with the following content:
```
%wheel ALL=(ALL) NOPASSWD: ALL
```

## User Configuration

Switch to your user with `su ladmin` and continue with the following steps.

Make sure passwordless sudo works:
```shell
sudo su
exit
```

Set up dotfiles and scripts
```shell
cd ~
mkdir src
cd src
git clone https://github.com/s-newman/dotfiles
git clone https://github.com/s-newman/scripts
cd dotfiles
./install.sh
cd ../scripts
./install.sh
cd ~
```

Install and configure yay
```shell
git clone https://aur.archlinux.org/yay
cd yay
makepkg -sirf
cd ~
rm -rf yay
yay --answerclean All --answerdiff None --answeredit None --removemake --cleanafter --save
```

Install AUR packages
```shell
yay -S visual-studio-code-bin nerd-fonts-complete zsh-theme-powerlevel10k-git zsh-you-should-use gnome-shell-extension-dash-to-dock rate-mirrors
```

Add the following content to `~/.config/systemd/user/maintenance.timer`:
```
[Unit]
Description=Weekly system maintenance

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

Add the following content to `~/.config/systemd/user/maintenance.service`:
```
[Unit]
Description=Weekly system maintenance

[Service]
Type=oneshot
ExecStart=/home/ladmin/bin/maintenance
```

## Boot Steps

Return to the root user within the chroot and finish with the following steps.

Configure your initramfs hooks. The HOOKS line in `/etc/mkinitcpio.conf` should look like this:
```
HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck)
```

Build initramfs:
```shell
mkinitcpio -P
```

Enable parallel pacman downloads by uncommenting the following line in `/etc/pacman.conf`:
```shell
#ParallelDownloads = 5
```

Append your LUKS disk UUID to `/etc/default/grub` so you can use it later:
```shell
blkid /dev/sda2 | awk '{print $2}' | tr -d '"' | tee -a /etc/default/grub
```

Delete the `GRUB_CMD_LINUX_DEFAULT` line in `/etc/default/grub` and configure the kernel parameters line with the following:
```
GRUB_CMDLINE_LINUX="cryptdevice=UUID=00000000-1111-2222-3333-444444444444:cryptroot root=/dev/mapper/cryptroot
```

Install grub to the EFI partition:
```shell
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
grub-mkconfig -o /boot/grub/grub.cfg
```
> The `--removable` option is important for some firmwares that only look in a specific location for the EFI boot image.

Enable on-boot services:
```shell
systemctl enable gdm NetworkManager wpa_supplicant docker
```

## Final Steps

Exit the chroot, unmount everything with `umount -R /mnt`, reboot, and pray it boots properly!

Once you log in, restore from a backup if you have one. It'll fail on the files you track with the `dotfiles` script, but that's okay.

Check if there's any other packages you need to install:
```shell
pacman -Qqett | sort | comm -1 -3 - ~/Documents/packages/installed-packages-YYYY-MM-DD.txt
```

Restore dconf settings:
```shell
dconf load / < ~/Documents/dconf-backups/YYYY-MM-DD.txt
```

Enable and run the weekly maintenance script:
```shell
systemctl --user enable maintenance.timer
systemctl --user start maintenance.timer
systemctl --user start maintenance.service
systemctl --user list-timers # Make sure the `maintenance` timer has a "next" time
```

Open the Settings app and configure:
- Region & Language
  - Language = English
- Date & Time
  - Automatic Date & Time = Enabled

Set up git config:
```shell
git config --global pull.ff "only"
git config --global init.defaultBranch "main"
git config --global user.name "Your Name"
git config --global user.email "youremail@example.com"
```

Restart and enjoy your installation!