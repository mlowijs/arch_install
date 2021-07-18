# Blacklist modules
echo "blacklist psmouse" > /etc/modprobe.d/psmouse.conf
echo "blacklist nouveau" > /etc/modprobe.d/nouveau.conf
echo "blacklist amdgpu" > /etc/modprobe.d/amdgpu.conf
echo "options snd_hda_intel power_save=3" > /etc/modprobe.d/snd_hda_intel.conf

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
sudo nano /etc/systemd/logind.conf # KillUserProcesses, HandlePowerKey, HandleLidSwitch (suspend-then-hibernate)
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

# Fonts
paru -S ttf-liberation ttf-dejavu ttf-jetbrains-mono
cd /etc/fonts/conf.d
ln -s /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf

# Snapper
paru -S snapper
sudo snapper -c root create-config /
sudo snapper -c root create -d "before-gui"

#
# GUI (GNOME)
#
paru -S gnome-shell gdm gnome-control-center gnome-terminal gnome-tweaks xdg-user-dirs-gtk xdg-desktop-portal-gtk
paru -S nautilus
sudo systemctl enable gdm

#
# GUI (KDE)
#
paru -S plasma-desktop plasma-wayland-session plasma-wayland-protocols dbus-python qt6-wayland breeze-gtk kde-gtk-config kscreen libva-mesa-driver mesa-vdpau plasma-nm bluedevil plasma-pa plasma-thunderbolt powerdevil konsole dolphin

# Desktop software
paru -S firefox bitwarden-bin
# Development software
paru -S rider dotnet-host dotnet-runtime dotnet-sdk visual-studio-code-bin slack-desktop
