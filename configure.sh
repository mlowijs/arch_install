# Blacklist module
echo "blacklist psmouse" > /etc/modprobe.d/psmouse.conf

# Network and time
systemctl enable NetworkManager
systemctl start NetworkManager
nmcli d wifi connect "BS55" password xxx

timedatectl set-ntp true

# Update system (just to be sure)
pacman -Syu

# User
useradd -mUG wheel -s /bin/bash michiel
passwd michiel
EDITOR=nano visudo
exit

#
# Login as michiel
#

# Setup pacman and builds
sudo nano /etc/pacman.conf # Color
sudo nano /etc/makepkg.conf # MAKEFLAGS

# Setup systemd logind.conf
sudo nano /etc/systemd/logind.conf # KillUserProcesses, HandlePowerKey
sudo nano /etc/systemd/sleep.conf # HibernateDelaySec

# Install paru
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd
rm -rf paru
sudo nano /etc/paru.conf # BottomUp, NewsOnUpgrade

# Bluetooth
paru -S bluez bluez-utils
sudo systemctl enable bluetooth
sudo nano /etc/bluetooth/main.conf # AutoEnable

# Audio
paru -S pipewire pipewire-alsa pipewire-pulse

# bbswitch
paru -S bbswitch-dkms
echo "options bbswitch load_state=0 unload_state=1" > /etc/modprobe.d/bbswitch.conf
echo "bbswitch" > /etc/modules-load.d/bbswitch.conf
