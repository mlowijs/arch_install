DEVICE=/dev/nvme1n1
BOOT_PARTITION=${DEVICE}p1
SWAP_PARTITION=${DEVICE}p2
ROOT_PARTITION=${DEVICE}p3
BTRFS_MOUNT_OPTS='noatime,commit=120,compress-force=zstd,space_cache=v2,discard=async'

# Connect to internet and set time
iwctl station wlan0 connect "BS55"
timedatectl set-ntp true

# Partitioning
sgdisk -Z ${DEVICE}
sgdisk -o ${DEVICE}
sgdisk -n 1:0:+256M -t 1:EF00 -c 1:EFI -n 2:0:+32G -t 2:8200 -c 2:swap -n 3:0:0 -t 3:8300 -c 3:root ${DEVICE}

# Formatting
mkfs.vfat -F32 -n EFI ${BOOT_PARTITION}

mkswap -L swap ${SWAP_PARTITION}
swapon -d ${SWAP_PARTITION}

mkfs.btrfs -L root ${ROOT_PARTITION}

# Creating subvolumes and mounting
mount ${ROOT_PARTITION} /mnt
cd /mnt

btrfs su cr @
btrfs su cr @home

cd /
umount /mnt

mount -o ${BTRFS_MOUNT_OPTS},subvol=@ ${ROOT_PARTITION} /mnt

cd /mnt
mkdir boot home opt

mount -o ${BTRFS_MOUNT_OPTS},subvol=@home ${ROOT_PARTITION} /mnt/home
mount -o discard ${BOOT_PARTITION} /mnt/boot

# Install system
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware btrfs-progs sudo base-devel networkmanager nano intel-ucode git sof-firmware man-db man-pages zsh
genfstab -L /mnt >> /mnt/etc/fstab

#
# Setup system
#

# Time zone and locale
ln -sf /mnt/usr/share/zoneinfo/Europe/Amsterdam /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc

sed -i -E 's/#en_US\.UTF-8/en_US.UTF-8/' /mnt/etc/locale.gen
sed -i -E 's/#nl_NL\.UTF-8/nl_NL.UTF-8/' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

# Hostname
echo "michielxps15" > /mnt/etc/hostname

# Mkinitcpio
sed -i -E 's/MODULES=\(\)/MODULES=(btrfs i915)/' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

# Root password
arch-chroot /mnt passwd

# Boot loader
arch-chroot /mnt bootctl install

echo <<EOF > /mnt/boot/loader/loader.conf
timeout 1
console-mode 1
default arch.conf
editor yes
EOF

echo <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux-zen
initrd /intel-ucode.img
initrd /initramfs-linux-zen.img
options root=LABEL=root rootflags=subvol=@ resume=LABEL=swap rw nowatchdog
EOF

# Reboot
cd
umount -R /mnt
reboot
