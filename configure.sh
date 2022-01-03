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
paru -S pipewire pipewire-alsa pipewire-pulse pipewire-media-session

# bbswitch
paru -S bbswitch-dkms
echo "options bbswitch load_state=0 unload_state=1" > /etc/modprobe.d/bbswitch.conf
echo "bbswitch" > /etc/modules-load.d/bbswitch.conf

# Fonts
paru -S ttf-liberation ttf-windows noto-fonts-emoji ttf-ibm-plex

# Miscellaneous system tools
paru -S systemd-boot-pacman-hook

#
# GUI (KDE)
#
paru -S plasma-desktop plasma-wayland-session sddm sddm-kcm powerdevil bluedevil kscreen plasma-nm plasma-pa konsole xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-kde
paru -S kwallet-pam ksshaskpass kwalletmanager
paru -S iio-sensor-proxy libva-vdpau-driver intel-media-driver
sudo systemctl enable sddm

mkdir -p ~/.config/systemd/user
cat <<EOF > ssh-agent.service
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOF

systemctl --user enable ssh-agent

mkdir -p ~/.config/autostart
cat <<EOF > ssh-add.desktop
[Desktop Entry]
Exec=ssh-add -q ~/.ssh/id_rsa ~/.ssh/id_ed25519
Name=ssh-add
Type=Application
EOF

mkdir -p ~/.config/plasma-workspace/env
cat <<EOF > askpass.sh
#!/bin/sh
export SSH_ASKPASS='/usr/bin/ksshaskpass'
export GIT_ASKPASS='/usr/bin/ksshaskpass'
EOF

#
# GUI (GNOME)
#
paru -S gnome-shell gdm gnome-control-center gnome-terminal gnome-tweaks xdg-user-dirs-gtk xdg-desktop-portal-gtk libva-mesa-driver mesa-vdpau intel-media-driver iio-sensor-proxy
paru -S nautilus seahorse
sudo systemctl enable gdm

#
# GUI (sway)
#
paru -S sway swayidle xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-wlr alacritty wayland-protocols swaylock-effects ulauncher

#
# GUI settings
#

#
# Software
#
paru -S chromium bitwarden-bin slack-desktop
paru -S rider dotnet-host dotnet-runtime dotnet-sdk visual-studio-code-bin nodejs npm postman-bin

mkdir -p ~/.config
echo "--enable-features=UseOzonePlatform" >> ~/.config/chromium-flags.conf
echo "--ozone-platform=wayland" >> ~/.config/chromium-flags.conf