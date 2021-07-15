# Blacklist module
echo "blacklist psmouse" > /etc/modprobe.d/psmouse.conf

# Network
systemctl enable NetworkManager
systemctl start NetworkManager
nmcli d wifi connect "BS55" password xxx

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
