export DEVICE=/dev/nvme0n1
export BOOT_PARTITION=${DEVICE}p1
export SWAP_PARTITION=${DEVICE}p2
export ROOT_PARTITION=${DEVICE}p3
export SWAP_SIZE=32G
export HOSTNAME=michieldesktop
export MICROCODE_PKG="amd-ucode"
export EXTRA_MODULES="amdgpu"