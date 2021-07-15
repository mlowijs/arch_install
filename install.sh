DEVICE=/dev/nvme1n1

# Connect to internet and set time
iwctl station wlan0 connect "BS55"
timedatectl set-ntp true

# Partitioning

# Formatting
mkfs.vfat -n EFI ${DEVICE}p1

mkswap -L swap ${DEVICE}p2
swapon ${DEVICE}p2

mkfs.btrfs -L arch ${DEVICE}p3

# Creating subvolumes and mounting
mount ${DEVICE}p3 /mnt
cd /mnt

btrfs su cr @
btrfs su cr @home
btrfs su cr @opt

cd /
umount /mnt

mount -o noatime,commit=120,compress-force=zstd,space_cache,discard=async,subvol=@ ${DEVICE}p3 /mnt

cd /mnt
mkdir boot home opt

mount -o noatime,commit=120,compress-force=zstd,space_cache,discard=async,subvol=@home ${DEVICE}p3 /mnt/home
mount -o noatime,commit=120,compress-force=zstd,space_cache,discard=async,subvol=@opt ${DEVICE}p3 /mnt/opt
mount ${DEVICE}p1 /mnt/boot

# Install system
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware btrfs-progs sudo base-devel networkmanager nano intel-ucode
genfstab -L /mnt >> /mnt/etc/fstab

# Chroot
arch-chroot /mnt

# Time zone and locale
ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc

nano /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "michielxps15" > /etc/hostname
nano /etc/hosts

# Mkinitcpio
nano /etc/mkinitcpio
mkinitcpio -P

# Root password
passwd

# Boot loader
bootctl install
nano /boot/loader/loader.conf
nano /boot/loader/entries/arch.conf

# Reboot
exit
cd
umount -R /mnt
