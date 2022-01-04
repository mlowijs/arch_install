# Setup shell
cat <<EOF >> ~/.zshrc
PS1='%n@%m %F{blue}%~ %f$ '

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey ";5C" forward-word
bindkey ";5D" backward-word

alias ls="ls --color"
EOF

source ~/.zshrc

# Blacklist modules
sudo echo "blacklist psmouse" > /etc/modprobe.d/psmouse.conf
sudo echo "blacklist nouveau" > /etc/modprobe.d/nouveau.conf
sudo echo "options snd_hda_intel power_save=3" > /etc/modprobe.d/snd_hda_intel.conf
sudo echo "options iwlwifi power_save=1" > /etc/modprobe.d/iwlwifi.conf
sudo echo "options iwlmvm power_scheme=3" > /etc/modprobe.d/iwlmvm.conf

# Network and time
sudo systemctl enable --now NetworkManager
sudo nmcli d wifi connect "BS55" password $1

sudo timedatectl set-ntp true

# Setup pacman and builds
sudo sed -i -E 's/#Color/Color/' /etc/pacman.conf
sudo sed -i -E 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sudo sed -i -E 's/#MAKEFLAGS=.+$/MAKEFLAGS="-j4"/' /etc/makepkg.conf

# Setup systemd logind.conf
sudo sed -i -E 's/#KillUserProcesses=.+$/KillUserProcesses=yes/' /etc/systemd/logind.conf
sudo sed -i -E 's/#HandlePowerKey=.+$/HandlePowerKey=ignore/' /etc/systemd/logind.conf
sudo sed -i -E 's/#HandleLidSwitch=.+$/HandleLidSwitch=suspend-then-hibernate/' /etc/systemd/logind.conf
sudo sed -i -E 's/#HandleLidSwitchDocked=.+$/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf

sudo sed -i -E 's/#HibernateDelaySec=.+$/HibernateDelaySec=60min/' /etc/systemd/sleep.conf

# Install paru
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si
cd
rm -rf paru

sudo sed -i -E 's/#BottomUp/BottomUp/' /etc/paru.conf
sudo sed -i -E 's/#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf

# Bluetooth
paru -S --noconfirm bluez bluez-utils
sudo sed -i -E 's/#AutoEnable=.+$/AutoEnable=true/' /etc/bluetooth/main.conf
sudo systemctl enable --now bluetooth

# Audio
paru -S --noconfirm pipewire pipewire-alsa pipewire-pulse wireplumber

# bbswitch
paru -S --noconfirm bbswitch-dkms
sudo echo "options bbswitch load_state=0 unload_state=1" > /etc/modprobe.d/bbswitch.conf
sudo echo "bbswitch" > /etc/modules-load.d/bbswitch.conf

# Fonts
paru -S --noconfirm ttf-liberation ttf-windows noto-fonts-emoji ttf-ibm-plex

# Miscellaneous system tools
paru -S --noconfirm systemd-boot-pacman-hook

#
# GUI (KDE)
#
paru -S --noconfirm plasma-desktop plasma-wayland-session sddm sddm-kcm powerdevil bluedevil kscreen plasma-nm plasma-pa konsole xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-kde breeze-gtk
paru -S spectacle
paru -S --noconfirm kwallet-pam ksshaskpass kwalletmanager
paru -S --noconfirm iio-sensor-proxy intel-media-driver libva-vdpau-driver
sudo systemctl enable sddm

#
# KDE configuration
#
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
# Software
#
paru -S --noconfirm chromium bitwarden-bin slack-desktop thunderbird spotify
paru -S --noconfirm rider dotnet-host dotnet-runtime dotnet-sdk visual-studio-code-bin nodejs npm postman-bin

#
# Software settings
#
mkdir -p ~/.config
echo "--enable-features=UseOzonePlatform" >> ~/.config/chromium-flags.conf
echo "--ozone-platform=wayland" >> ~/.config/chromium-flags.conf