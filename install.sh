source $1

BTRFS_MOUNT_OPTS='noatime,commit=120,compress-force=zstd,space_cache=v2,discard=async'

# Connect to internet and set time
timedatectl set-ntp true

# Partitioning
sgdisk -Z ${DEVICE}
sgdisk -o ${DEVICE}
sgdisk -n 1:0:+256M -t 1:EF00 -c 1:EFI -n 2:0:+${SWAP_SIZE} -t 2:8200 -c 2:swap -n 3:0:0 -t 3:8300 -c 3:root ${DEVICE}

SWAP_UUID=`blkid -t UUID -o value ${SWAP_PARTITION}`
ROOT_UUID=`blkid -t UUID -o value ${ROOT_PARTITION}` 

# Formatting
mkfs.vfat -F32 -n EFI ${BOOT_PARTITION}

cryptsetup luksFormat ${SWAP_PARTITION}
cryptsetup open ${SWAP_PARTITION} swap

mkswap -L swap /dev/mapper/swap
swapon -d /dev/mapper/swap

cryptsetup luksFormat ${ROOT_PARTITION}
cryptsetup open ${ROOT_PARTITION} root

mkfs.btrfs -f -L root /dev/mapper/root

# Creating subvolumes and mounting
mount /dev/mapper/root /mnt
cd /mnt

btrfs su cr @
btrfs su cr @home

cd /
umount /mnt

mount -o ${BTRFS_MOUNT_OPTS},subvol=@ /dev/mapper/root /mnt

cd /mnt
mkdir boot home
mkdir -p var/cache/pacman
btrfs su cr var/cache/pacman/pkg

mount -o ${BTRFS_MOUNT_OPTS},subvol=@home /dev/mapper/root /mnt/home
mount -o discard ${BOOT_PARTITION} /mnt/boot

# Install system
sed -i -E 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware btrfs-progs sudo base-devel nano git sof-firmware man-db man-pages zsh openssh cryptsetup ${MICROCODE_PKG} ${EXTRA_PACKAGES}
genfstab -U /mnt >> /mnt/etc/fstab

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
sed -i -E 's/HOOKS=\(.+?\)/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems)/' /mnt/etc/mkinitcpio.conf
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
options rd.luks.name=${ROOT_UUID}=root rd.luks.name=${SWAP_UUID}=swap rd.luks.options=discard root=/dev/mapper/root rootflags=subvol=@ resume=/dev/mapper/swap rw nowatchdog ${KERNEL_OPTIONS}
EOF

arch-chroot /mnt systemctl enable systemd-boot-update.service

# Reboot
cd
echo "Unmount /mnt and reboot to complete installation"
