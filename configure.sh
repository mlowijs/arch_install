# Blacklist modules
echo "blacklist psmouse" > /etc/modprobe.d/psmouse.conf
echo "blacklist nouveau" > /etc/modprobe.d/nouveau.conf
echo "options snd_hda_intel power_save=3" > /etc/modprobe.d/snd_hda_intel.conf
echo "options iwlwifi power_save=1" > /etc/modprobe.d/iwlwifi.conf
echo "options iwlmvm power_scheme=3" > /etc/modprobe.d/iwlmvm.conf

# Network and time
systemctl enable --now NetworkManager
nmcli d wifi connect "BS55" password xxx

timedatectl set-ntp true

# Update system (just to be sure)
pacman -Syu

# User
useradd -mUG wheel,audio,video,plugdev,input,disk -s /bin/zsh michiel
passwd michiel
EDITOR=nano visudo
exit

#
# Login as michiel
#

# Setup pacman and builds
sudo nano /etc/pacman.conf # Color, ParallelDownloads
sudo nano /etc/makepkg.conf # MAKEFLAGS

# Setup systemd logind.conf
sudo nano /etc/systemd/logind.conf # KillUserProcesses, HandlePowerKey, HandleLidSwitch (suspend-then-hibernate)
sudo nano /etc/systemd/sleep.conf # HibernateDelaySec

# Install paru
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si
cd
rm -rf paru
sudo nano /etc/paru.conf # BottomUp, NewsOnUpgrade

# Bluetooth
paru -S bluez bluez-utils
sudo systemctl enable bluetooth
sudo nano /etc/bluetooth/main.conf # AutoEnable

# Audio
paru -S pipewire pipewire-alsa pipewire-pulse wireplumber

# bbswitch
paru -S bbswitch-dkms
echo "options bbswitch load_state=0 unload_state=1" > /etc/modprobe.d/bbswitch.conf
echo "bbswitch" > /etc/modules-load.d/bbswitch.conf

# Fonts
paru -S ttf-liberation ttf-dejavu ttf-jetbrains-mono ttf-windows noto-fonts-emoji
cd /etc/fonts/conf.d
ln -s /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf

#
# GUI (GNOME)
#
paru -S gnome-shell gdm gnome-control-center gnome-terminal gnome-tweaks xdg-user-dirs-gtk xdg-desktop-portal-gtk libva-mesa-driver mesa-vdpau intel-media-driver iio-sensor-proxy
paru -S nautilus seahorse
sudo systemctl enable gdm

mkdir -p ~/.config/environment.d
echo "MOZ_ENABLE_WAYLAND=1" >> ~/.config/environment.d/envvars.conf
echo "MOZ_DBUS_REMOTE=1" >> ~/.config/environment.d/envvars.conf
echo "MOZ_WAYLAND_USE_VAAPI=1" >> ~/.config/environment.d/envvars.conf

#
# GUI (sway)
#
paru -S sway swayidle xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-wlr alacritty wayland-protocols swaylock-effects ulauncher

mkdir ~/.config
echo "--enable-features=UseOzonePlatform" >> ~/.config/chromium-flags.conf
echo "--ozone-platform=wayland" >> ~/.config/chromium-flags.conf

# Desktop software
paru -S chromium bitwarden-bin slack-desktop

# Development software
paru -S rider dotnet-host dotnet-runtime dotnet-sdk visual-studio-code-bin nodejs npm postman-bin
