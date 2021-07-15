# Blacklist module
echo "blacklist psmouse" > /etc/modprobe.d/psmouse.conf

# Network
systemctl enable NetworkManager
systemctl start NetworkManager
nmcli d wifi connect "BS55" password xxx

# User
useradd -mUG wheel -s /bin/bash michiel
passwd michiel
EDITOR=nano visudo
exit

#
# Login as michiel
#

# Install paru
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
