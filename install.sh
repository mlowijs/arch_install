source $1

BTRFS_MOUNT_OPTS='noatime,commit=120,compress-force=zstd,space_cache=v2,discard=async'

# Connect to internet and set time
timedatectl set-ntp true

# Partitioning
sgdisk -Z ${DEVICE}
sgdisk -o ${DEVICE}
sgdisk -n 1:0:+256M -t 1:EF00 -c 1:EFI -n 2:0:+${SWAP_SIZE} -t 2:8200 -c 2:swap -n 3:0:0 -t 3:8300 -c 3:root ${DEVICE}

# Formatting
mkfs.vfat -F32 -n EFI ${BOOT_PARTITION}

mkswap -L swap ${SWAP_PARTITION}
swapon -d ${SWAP_PARTITION}

mkfs.btrfs -f -L root ${ROOT_PARTITION}

# Creating subvolumes and mounting
mount ${ROOT_PARTITION} /mnt
cd /mnt

btrfs su cr @
btrfs su cr @home
btrfs su cr @pkgcache

cd /
umount /mnt

mount -o ${BTRFS_MOUNT_OPTS},subvol=@ ${ROOT_PARTITION} /mnt

cd /mnt
mkdir boot home
mkdir -p /var/cache/pacman/pkg

mount -o ${BTRFS_MOUNT_OPTS},subvol=@home ${ROOT_PARTITION} /mnt/home
mount -o ${BTRFS_MOUNT_OPTS},subvol=@pkgcache ${ROOT_PARTITION} /var/cache/pacman/pkg
mount -o discard ${BOOT_PARTITION} /mnt/boot

# Install system
sed -i -E 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware btrfs-progs sudo base-devel nano git sof-firmware man-db man-pages zsh openssh ${MICROCODE_PKG} ${EXTRA_PACKAGES}
genfstab -L /mnt >> /mnt/etc/fstab

#
# Setup system
#

# Time zone and locale
ln -srf /mnt/usr/share/zoneinfo/Europe/Amsterdam /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc

sed -i -E 's/#en_US\.UTF-8/en_US.UTF-8/' /mnt/etc/locale.gen
sed -i -E 's/#nl_NL\.UTF-8/nl_NL.UTF-8/' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

# Hostname
echo ${HOSTNAME} > /mnt/etc/hostname

# Mkinitcpio
sed -i -E 's/MODULES=\(\)/MODULES=(btrfs ${EXTRA_MODULES})/' /mnt/etc/mkinitcpio.conf
sed -i -E 's/HOOKS=\(.+?\)/HOOKS=(base systemd autodetect modconf block filesystems keyboard)/' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

# Root password
echo "Enter new password for user 'root'"
arch-chroot /mnt passwd

# User
arch-chroot /mnt useradd -mUG wheel,audio,video,input,disk -s /bin/zsh michiel
echo "Enter new password for user 'michiel'"
arch-chroot /mnt passwd michiel
echo "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers.d/wheel

# Boot loader
arch-chroot /mnt bootctl install

cat << EOF > /mnt/boot/loader/loader.conf
timeout 1
console-mode 1
default arch.conf
EOF

cat << EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux-zen
initrd /${MICROCODE_PKG}.img
initrd /initramfs-linux-zen.img
options root=LABEL=root rootflags=subvol=@ resume=LABEL=swap rw nowatchdog ${KERNEL_OPTIONS}
EOF

# Reboot
cd
echo "Unmount /mnt and reboot to complete installation"
