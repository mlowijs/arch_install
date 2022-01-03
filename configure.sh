# Blacklist modules
echo "blacklist psmouse" > /etc/modprobe.d/psmouse.conf
echo "blacklist nouveau" > /etc/modprobe.d/nouveau.conf
echo "options snd_hda_intel power_save=3" > /etc/modprobe.d/snd_hda_intel.conf
echo "options iwlwifi power_save=1" > /etc/modprobe.d/iwlwifi.conf
echo "options iwlmvm power_scheme=3" > /etc/modprobe.d/iwlmvm.conf

# Network and time
systemctl enable --now NetworkManager
nmcli d wifi connect "BS55" password $1

timedatectl set-ntp true

# Update system (just to be sure)
pacman -Syu

# User
useradd -mUG wheel,audio,video,input,disk -s /bin/zsh michiel
passwd michiel
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
su - michiel

# Setup pacman and builds
sed -i -E 's/#Color/Color/' /etc/pacman.conf
sed -i -E 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i -E 's/#MAKEFLAGS=.+$/MAKEFLAGS="-j4"/' /etc/makepkg.conf

# Setup systemd logind.conf
sed -i -E 's/#KillUserProcesses=.+$/KillUserProcesses=yes/' /etc/systemd/logind.conf
sed -i -E 's/#HandlePowerKey=.+$/HandlePowerKey=ignore/' /etc/systemd/logind.conf
sed -i -E 's/#HandleLidSwitch=.+$/HandleLidSwitch=suspend-then-hibernate/' /etc/systemd/logind.conf

sed -i -E 's/#HibernateDelaySec=.+$/HibernateDelaySec=60min/' /etc/systemd/sleep.conf

# Install paru
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si
cd
rm -rf paru

sed -i -E 's/#BottomUp/BottomUp/' /etc/paru.conf
sed -i -E 's/#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf

# Bluetooth
paru -S --noconfirm bluez bluez-utils
sed -i -E 's/#AutoEnable=.+$/AutoEnable=true/' /etc/bluetooth/main.conf
systemctl enable --now bluetooth

# Audio
paru -S --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-media-session

# bbswitch
paru -S --noconfirm bbswitch-dkms
echo "options bbswitch load_state=0 unload_state=1" > /etc/modprobe.d/bbswitch.conf
echo "bbswitch" > /etc/modules-load.d/bbswitch.conf

# Fonts
paru -S --noconfirm ttf-liberation ttf-windows noto-fonts-emoji ttf-ibm-plex

# Miscellaneous system tools
paru -S --noconfirm systemd-boot-pacman-hook

#
# GUI (KDE)
#
paru -S --noconfirm plasma-desktop plasma-wayland-session sddm sddm-kcm powerdevil bluedevil kscreen plasma-nm plasma-pa konsole xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-kde
paru -S --noconfirm kwallet-pam ksshaskpass kwalletmanager
paru -S --noconfirm iio-sensor-proxy intel-media-driver libva-vdpau-driver
systemctl enable sddm

mkdir -p ~/.config/systemd/user
cat <<EOF > ~/.config/systemd/user/ssh-agent.service
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
cat <<EOF > ~/.config/autostart/ssh-add.desktop
[Desktop Entry]
Exec=ssh-add -q ~/.ssh/id_rsa ~/.ssh/id_ed25519
Name=ssh-add
Type=Application
EOF

mkdir -p ~/.config/plasma-workspace/env
cat <<EOF > ~/.config/plasma-workspace/env/askpass.sh
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