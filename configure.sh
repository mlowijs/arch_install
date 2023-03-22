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
echo "blacklist psmouse" | sudo tee /etc/modprobe.d/psmouse.conf
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/nouveau.conf
echo "options snd_hda_intel power_save=3" | sudo tee /etc/modprobe.d/snd_hda_intel.conf
echo "options iwlwifi power_save=1" | sudo tee /etc/modprobe.d/iwlwifi.conf
echo "options iwlmvm power_scheme=3" | sudo tee /etc/modprobe.d/iwlmvm.conf

# Network and time
sudo systemctl enable --now NetworkManager
sudo nmcli d wifi connect "BS55" password $1

sudo pacman -S --noconfirm wireless-regdb
echo 'WIRELESS_REGDOM="NL"' | sudo tee /etc/conf.d/wireless-regdom

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
cd ..
rm -rf paru-bin

sudo sed -i -E 's/#BottomUp/BottomUp/' /etc/paru.conf
sudo sed -i -E 's/#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf

# Bluetooth
paru -S --noconfirm bluez bluez-utils
sudo systemctl enable --now bluetooth

# Audio
paru -S --noconfirm pipewire pipewire-alsa pipewire-pulse wireplumber

# bbswitch
paru -S --noconfirm bbswitch-dkms
echo "options bbswitch load_state=0 unload_state=1" | sudo tee /etc/modprobe.d/bbswitch.conf
echo "bbswitch" | sudo tee /etc/modules-load.d/bbswitch.conf

# Fonts
paru -S --noconfirm ttf-liberation ttf-windows noto-fonts-emoji ttf-ibm-plex

#
# GUI (KDE)
#
paru -S --noconfirm plasma-desktop plasma-wayland-session sddm sddm-kcm powerdevil power-profiles-daemon bluedevil kscreen plasma-nm plasma-pa konsole xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-kde breeze-gtk
paru -S --noconfirm kwallet-pam ksshaskpass kwalletmanager
paru -S --noconfirm iio-sensor-proxy intel-media-driver libva-vdpau-driver
paru -S --noconfirm spectacle ark
sudo systemctl enable sddm

#
# KDE configuration
#
mkdir -p ~/.config/systemd/user
cat <<'EOF' > ~/.config/systemd/user/ssh-agent.service
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

echo 'export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"' >> ~/.zprofile

mkdir -p ~/.config/plasma-workspace/env
cat <<EOF > ~/.config/plasma-workspace/env/envvars.sh
#!/bin/sh
export SSH_ASKPASS='/usr/bin/ksshaskpass'
export GIT_ASKPASS='/usr/bin/ksshaskpass'
export MOZ_ENABLE_WAYLAND=1
EOF

chmod +x ~/.config/plasma-workspace/env/envvars.sh

#
# Software
#
paru -S --noconfirm firefox bitwarden slack-desktop thunderbird spotify
paru -S --noconfirm rider dotnet-host dotnet-runtime dotnet-sdk visual-studio-code-bin nodejs npm postman-bin

#
# Software settings
#
mkdir -p ~/.config
echo "--enable-features=UseOzonePlatform" | tee ~/.config/chromium-flags.conf ~/.config/code-flags.conf
echo "--ozone-platform=wayland" | tee ~/.config/chromium-flags.conf ~/.config/code-flags.conf
