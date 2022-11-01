#!/bin/bash

#   # ---------------------------------------------
#   # Connect to WiFi:
#   # ---------------------------------------------
#
#   # Get network device name
#   ip -c a
#
#   # Connect to network
#   iwctl
#   [iwd] station wlan0 connect MyWirelessNetwork
#
#   # Test connection by refreshing packages
#   pacman -Sy
#
#
#   # ---------------------------------------------
#   # Preconfigure:
#   # ---------------------------------------------
#
#   # Ensure booted with EFI mode
#   ls /sys/firmware/efi/efivars
#
#   # Set and check time
#   timedatectl set-ntp true
#   timedatectl status
#
#
#   # ---------------------------------------------
#   # Partition & format data disk (if applicable):
#   # ---------------------------------------------
#
#   # List devices
#   lsblk -f
#
#   # Create partitions
#   cgdisk /dev/sda
#   #- data: NEW, default, default, 8300
#
#   # Format data partition
#   mkfs.btrfs -L data /dev/sda1
#
#   # Create btrfs subvolumes
#   mount /dev/sda1 /mnt
#   cd /mnt
#   btrfs subvolume create @
#   btrfs subvolume create @data
#   btrfs subvolume create @volumes
#   cd / && umount /mnt
#
#   # ---------------------------------------------
#   # Partition & format raid disk (if applicable):
#   # ---------------------------------------------
#
#   # List devices
#   lsblk -f
#
#   # Create partitions
#   cgdisk /dev/sdb
#   #- raid: NEW, default, default, 8300
#
#   # Format data partition
#   mkfs.btrfs -L raid /dev/sdb1
#
#   # Create btrfs subvolumes
#   mount /dev/sdb1 /mnt
#   cd /mnt
#   btrfs subvolume create @
#   btrfs subvolume create @archives
#   btrfs subvolume create @audiobooks
#   btrfs subvolume create @books
#   btrfs subvolume create @games
#   btrfs subvolume create @movies
#   btrfs subvolume create @music
#   btrfs subvolume create @photos
#   btrfs subvolume create @series
#   btrfs subvolume create @videos
#   cd / && umount /mnt
#
#   # ---------------------------------------------
#   # Partition & format root disk:
#   # ---------------------------------------------
#
#   # List devices
#   lsblk -f
#
#   # Create partitions
#   cgdisk /dev/nvme0n1
#   #- boot: NEW, default, 512M, ef00
#   #- swap: NEW, default, 32G, 8200
#   #- root: NEW, default, default, 8300
#
#   # Format boot partition
#   mkfs.fat -F32 /dev/nvme0n1p1
#
#   # Format swap partition
#   mkswap /dev/nvme0n1p2
#   swapon /dev/nvme0n1p2
#
#   # Format root partition
#   mkfs.btrfs -L root /dev/nvme0n1p3
#
#   # Create btrfs subvolumes
#   mount /dev/nvme0n1p3 /mnt
#   cd /mnt
#   btrfs subvolume create @
#   btrfs subvolume create @home
#   btrfs subvolume create @log
#   btrfs subvolume create @docker
#   cd / && umount /mnt
#
#   # ---------------------------------------------
#   # Mount volumes:
#   # ---------------------------------------------
#
#   # Mount root subvolume
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/nvme0n1p3 /mnt
#
#   # Mount boot partition
#   mkdir /mnt/boot
#   mount /dev/nvme0n1p1 /mnt/boot
#
#   # Mount home subvolume
#   mkdir /mnt/home
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@home /dev/nvme0n1p3 /mnt/home
#
#   # Mount log subvolume
#   mkdir -p /mnt/var/log
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@log /dev/nvme0n1p3 /mnt/var/log
#
#   # Mount docker subvolume
#   mkdir -p /mnt/var/lib/docker
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@docker /dev/nvme0n1p3 /mnt/var/lib/docker
#
#   # Mount data subvolume (if applicable):
#   mkdir /mnt/data
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@data /dev/sda1 /mnt/data
#
#   # Mount data volumes subvolume (if applicable):
#   mkdir /mnt/var/lib/docker/volumes
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@volumes /dev/sda1 /mnt/var/lib/docker/volumes
#
#   # Mount archives subvolume (if applicable):
#   mkdir /mnt/data/archives
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@archives /dev/sdb1 /mnt/data/archives
#
#   # Mount audiobooks subvolume (if applicable):
#   mkdir /mnt/data/audiobooks
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@audiobooks /dev/sdb1 /mnt/data/audiobooks
#
#   # Mount books subvolume (if applicable):
#   mkdir /mnt/data/books
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@books /dev/sdb1 /mnt/data/books
#
#   # Mount games subvolume (if applicable):
#   mkdir /mnt/data/games
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@games /dev/sdb1 /mnt/data/games
#
#   # Mount movies subvolume (if applicable):
#   mkdir /mnt/data/movies
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@movies /dev/sdb1 /mnt/data/movies
#
#   # Mount music subvolume (if applicable):
#   mkdir /mnt/data/music
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@music /dev/sdb1 /mnt/data/music
#
#   # Mount photos subvolume (if applicable):
#   mkdir /mnt/data/photos
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@photos /dev/sdb1 /mnt/data/photos
#
#   # Mount series subvolume (if applicable):
#   mkdir /mnt/data/series
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@series /dev/sdb1 /mnt/data/series
#
#   # Mount videos subvolume (if applicable):
#   mkdir /mnt/data/videos
#   mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@videos /dev/sdb1 /mnt/data/videos
#
#
#   # ---------------------------------------------
#   # Create fstab from mounts:
#   # ---------------------------------------------
#
#   # Verify partitions and subvolumes
#   lsblk -f
#   btrfs subvolume list /mnt
#
#   # Generate fstab
#   genfstab -U /mnt >> /mnt/etc/fstab
#
#
#   # ---------------------------------------------
#   # Install base packages:
#   # ---------------------------------------------
#
#   # Install base packages to new volume
#   pacstrap /mnt base base-devel linux linux-firmware git vim intel-ucode
#   
#
#   # ---------------------------------------------
#   # Enter system and run install script:
#   # ---------------------------------------------
#
#   # Enter installation
#   arch-chroot /mnt
#   
#   # Download install script, edit and run
#   git clone https://github.com/suderman/dotfiles.git /tmp/dotfiles
#   sh /tmp/dotfiles/arch.sh
#
#

# Timezone
ln -sf /usr/share/zoneinfo/Canada/Mountain /etc/localtime
hwclock --systohc

# Locale
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# Hostname (change for each device)
export HOSTNAME=arch
echo "$HOSTNAME" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Root password
echo root:password | chpasswd

# Packages
pacman -Syy
pacman -S acpi acpi_call acpid alsa-utils arch-install-scripts avahi bash-completion bluez bluez-utils bridge-utils cups dialog dnsmasq dnsutils dosfstools edk2-ovmf efibootmgr firewalld flatpak grub grub-btrfs gvfs gvfs-smb hplip inetutils ipset iptables-nft linux-headers man-db mtools network-manager-applet nfs-utils nss-mdns ntfs-3g openbsd-netcat openssh os-prober pipewire pipewire-alsa pipewire-jack pipewire-pulse qemu qemu-arch-extra reflector rsync sof-firmware tlp vde2 virt-manager wpa_supplicant xdg-user-dirs xdg-utils zsh

# Enable Grub's OS prober
echo GRUB_DISABLE_OS_PROBER=false >> /etc/default/grub

# Add deep suspend to kernel parameters
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet mem_sleep_default=deep"/' /etc/default/grub

# Install and config Grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# System Services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid


# Install paru
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si


# Install & configure Docker for bfrfs
pacman -S docker
mkdir -p /etc/docker
echo '{' >> /etc/docker/daemon.json
echo '  "storage-driver": "btrfs"' >> /etc/docker/daemon.json
echo '}' >> /etc/docker/daemon.json
systemctl enable docker


# Install Gnome
pacman -S gnome
systemctl enable gnome


# Configure Interception caps2esc
pacman -S interception-caps2esc
mkdir -p /etc/interception/udevmon.d
echo '- JOB: intercept -g $DEVNODE | caps2esc -m 1 | uinput -d $DEVNODE' >> /etc/interception/udevmon.d/caps2esc.yaml
echo '  DEVICE:' >> /etc/interception/udevmon.d/caps2esc.yaml
echo '    EVENTS:' >> /etc/interception/udevmon.d/caps2esc.yaml
echo '      EV_KEY: [KEY_CAPSLOCK, KEY_ESC]' >> /etc/interception/udevmon.d/caps2esc.yaml
systemctl enable udevmon


# Install tailscale
pacman -S tailscale
systemctl enable tailscaled


# User
useradd -m me
echo me:password | chpasswd
usermod -aG libvirt me
usermod -aG docker me
echo "me ALL=(ALL) ALL" >> /etc/sudoers.d/me
chsh -s /usr/bin/zsh me


# Override system's gnome-terminal with script in user's .local/bin directory
ln -sf /home/me/.local/bin/gnome-terminal /usr/local/bin/gnome-terminal
chown -R me:me /usr/local/bin


# Done
printf "\e[1;32mDone! Reboot and login as user.\e[0m"


#   # ---------------------------------------------
#   # Final steps onced logged in as user:
#   # ---------------------------------------------
#
#   # Goodies
#   sudo pacman -S --needed neovim neomutt mosh zsh tmux fzf ncdu ranger micro htop jq lazydocker firefox
#   paru -S --needed foot lf-bin
#
#   # https://github.com/harshadgavali/searchprovider-for-browser-tabs/
#   xdg-open https://addons.mozilla.org/firefox/downloads/file/3887875/tab_search_provider_for_gnome-1.0.1-fx.xpi
#   gnome-extensions install https://extensions.gnome.org/extension-data/browser-tabscom.github.harshadgavali.v4.shell-extension.zip
#   paru -S --needed tabsearchproviderconnector
#
#   # Gnome settings
#   gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" 
#   gsettings get org.gnome.desktop.peripherals.touchpad disable-while-typing
#
#   # Install ydotool
#   paru -S --needed ydotool
#   sudo usermod -aG input me
#   systemctl --user enable --now ydotoold

