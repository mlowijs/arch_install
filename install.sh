DEVICE=/dev/nvme1n1

iwctl station wlan0 connect "BS55"
timedatectl set-ntp true

# FDISK

mkfs.vfat -n EFI $DEVICEp1

mkswap -L swap $DEVICEp2
swapon $DEVICEp2

mkfs.btrfs -L arch $DEVICEp3



mount $DEVICEp3 /mnt
cd /mnt

mkdir boot home opt
btrfs su cr @
btrfs su cr @home
btrfs su cr @opt

cd /
umount /mnt

mount -o noatime,commit=120,compress-force=zstd,space_cache,subvol=@ $DEVICEp3 /mnt
mount -o noatime,commit=120,compress-force=zstd,space_cache,subvol=@home $DEVICEp3 /mnt/home
mount -o noatime,commit=120,compress-force=zstd,space_cache,subvol=@opt $DEVICEp3 /mnt/opt
mount $DEVICEp1 /mnt/boot
