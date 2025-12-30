#!/bin/bash
set -e

WORK_DIR="/tmp/rizzo-build"
ISO_OUTPUT="$GITHUB_WORKSPACE/iso/RizzoOS-1.0.iso"

mkdir -p "$WORK_DIR"/{chroot,iso/{boot/grub,live}}
mkdir -p "$(dirname "$ISO_OUTPUT")"

sudo debootstrap --arch=amd64 --variant=minbase bookworm "$WORK_DIR/chroot" http://deb.debian.org/debian

cat << 'EOF' | sudo tee "$WORK_DIR/chroot/etc/apt/sources.list"
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

sudo mount --bind /dev "$WORK_DIR/chroot/dev"
sudo mount --bind /dev/pts "$WORK_DIR/chroot/dev/pts"
sudo mount -t proc proc "$WORK_DIR/chroot/proc"
sudo mount -t sysfs sysfs "$WORK_DIR/chroot/sys"

sudo chroot "$WORK_DIR/chroot" /bin/bash << 'CHROOT'
export DEBIAN_FRONTEND=noninteractive

dpkg --add-architecture i386
apt-get update

# ============================================
# === SYSTÈME DE BASE ===
# ============================================
apt-get install -y \
    linux-image-amd64 \
    live-boot \
    systemd-sysv \
    sudo \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    firmware-realtek \
    firmware-iwlwifi \
    firmware-atheros \
    firmware-amd-graphics \
    intel-microcode \
    amd64-microcode

# ============================================
# === KDE PLASMA COMPLET ===
# ============================================
apt-get install -y \
    kde-plasma-desktop \
    sddm \
    plasma-workspace \
    plasma-nm \
    plasma-pa \
    powerdevil \
    bluedevil \
    kde-spectacle \
    dolphin \
    konsole \
    kate \
    ark \
    gwenview \
    okular \
    kcalc \
    kwrite \
    partitionmanager \
    plasma-systemmonitor \
    kinfocenter \
    kscreen \
    sddm-theme-breeze \
    kde-config-sddm \
    breeze-icon-theme \
    papirus-icon-theme

# ============================================
# === CALAMARES (Installateur) ===
# ============================================
apt-get install -y \
    calamares \
    calamares-settings-debian || true

mkdir -p /etc/calamares/branding/rizzoos
touch /etc/calamares/branding/rizzoos/logo.png
touch /etc/calamares/branding/rizzoos/welcome.png

# ============================================
# === NAVIGATEURS ===
# ============================================
apt-get install -y \
    firefox-esr \
    chromium

# ============================================
# === BUREAUTIQUE ===
# ============================================
apt-get install -y \
    libreoffice \
    libreoffice-plasma \
    libreoffice-l10n-fr \
    hunspell-fr

# ============================================
# === MULTIMÉDIA ===
# ============================================
apt-get install -y \
    vlc \
    gimp \
    inkscape \
    kdenlive \
    audacity \
    obs-studio \
    mpv \
    ffmpeg \
    imagemagick

# ============================================
# === WINE (Apps Windows) ===
# ============================================
apt-get install -y \
    wine \
    wine64 \
    wine32 \
    winetricks \
    playonlinux \
    q4wine

# ============================================
# === GAMING ===
# ============================================
apt-get install -y \
    steam-installer \
    lutris \
    gamemode \
    mangohud \
    mesa-vulkan-drivers \
    libvulkan1 \
    vulkan-tools || true

# ============================================
# === DÉVELOPPEMENT ===
# ============================================
apt-get install -y \
    git \
    curl \
    wget \
    nano \
    vim \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm || true

# ============================================
# === OUTILS SYSTÈME ===
# ============================================
apt-get install -y \
    htop \
    btop \
    neofetch \
    gparted \
    baobab \
    gnome-disk-utility \
    bleachbit || true

# ============================================
# === RÉSEAU & INTERNET ===
# ============================================
apt-get install -y \
    network-manager \
    network-manager-gnome \
    bluetooth \
    blueman \
    transmission-qt \
    filezilla \
    remmina

# ============================================
# === SÉCURITÉ ===
# ============================================
apt-get install -y \
    ufw \
    gufw \
    apparmor \
    clamav \
    clamtk \
    keepassxc

# ============================================
# === AUDIO ===
# ============================================
apt-get install -y \
    pipewire \
    pipewire-audio \
    pipewire-pulse \
    wireplumber \
    pavucontrol-qt

# ============================================
# === COMPRESSION ===
# ============================================
apt-get install -y \
    unzip \
    zip \
    p7zip-full \
    unrar \
    tar \
    gzip

# ============================================
# === POLICES ===
# ============================================
apt-get install -y \
    fonts-noto \
    fonts-noto-color-emoji \
    fonts-liberation \
    fonts-dejavu \
    fonts-ubuntu

# ============================================
# === WAYDROID (Apps Android) ===
# ============================================
apt-get install -y curl ca-certificates gnupg lxc || true
curl -s https://repo.waydro.id/waydroid.gpg | tee /usr/share/keyrings/waydroid.gpg > /dev/null || true
echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydro.id/ bookworm main" > /etc/apt/sources.list.d/waydroid.list || true
apt-get update || true
apt-get install -y waydroid || true

# ============================================
# === UTILISATEUR LIVE ===
# ============================================
useradd -m -s /bin/bash -G sudo,audio,video,cdrom,plugdev,netdev,bluetooth,lpadmin live
echo "live:live" | chpasswd
echo "live ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ============================================
# === CONFIG CALAMARES ===
# ============================================
mkdir -p /etc/calamares/branding/rizzoos
mkdir -p /etc/calamares/modules

cat > /etc/calamares/settings.conf << 'CALA'
modules-search: [ local, /usr/lib/calamares/modules ]
sequence:
  - show:
    - welcome
    - locale
    - keyboard
    - partition
    - users
    - summary
  - exec:
    - partition
    - mount
    - unpackfs
    - machineid
    - fstab
    - locale
    - keyboard
    - localecfg
    - users
    - displaymanager
    - networkcfg
    - hwclock
    - services-systemd
    - bootloader
    - umount
  - show:
    - finished
branding: rizzoos
prompt-install: true
dont-chroot: false
CALA

cat > /etc/calamares/branding/rizzoos/branding.desc << 'BRAND'
componentName: rizzoos
welcomeStyleCalamares: true
strings:
    productName:         "RizzoOS"
    shortProductName:    "RizzoOS"
    version:             "1.0"
    shortVersion:        "1.0"
    versionedName:       "RizzoOS 1.0"
    shortVersionedName:  "RizzoOS 1.0"
    bootloaderEntryName: "RizzoOS"
    productUrl:          "https://rizzoos.com"
    supportUrl:          "https://rizzoos.com/support"
    knownIssuesUrl:      "https://rizzoos.com/issues"
    releaseNotesUrl:     "https://rizzoos.com/releases"
images:
    productLogo:         "logo.png"
    productIcon:         "logo.png"
    productWelcome:      "welcome.png"
slideshow:               "show.qml"
style:
   sidebarBackground:    "#1a1a2e"
   sidebarText:          "#FFFFFF"
   sidebarTextSelect:    "#00d4ff"
BRAND

cat > /etc/calamares/branding/rizzoos/show.qml << 'QML'
import QtQuick 2.0;
import calamares.slideshow 1.0;
Presentation {
    id: presentation
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"
            Text {
                anchors.centerIn: parent
                text: "Bienvenue sur RizzoOS 1.0\n\nInstallation en cours..."
                color: "#00d4ff"
                font.pixelSize: 32
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
QML

cat > /etc/calamares/modules/unpackfs.conf << 'UNPACK'
unpack:
  - source: /run/live/medium/live/filesystem.squashfs
    sourcefs: squashfs
    destination: ""
UNPACK

cat > /etc/calamares/modules/displaymanager.conf << 'DM'
displaymanagers:
  - sddm
defaultDesktopEnvironment:
    executable: "startplasma-x11"
    desktopFile: "plasma"
basicSetup: false
DM

cat > /etc/calamares/modules/bootloader.conf << 'BOOT'
efiBootLoader: "grub"
kernel: "/vmlinuz"
img: "/initrd.img"
timeout: 10
grubInstall: "grub-install"
grubMkconfig: "grub-mkconfig"
grubCfg: "/boot/grub/grub.cfg"
efiBootloaderId: "RizzoOS"
BOOT

cat > /etc/calamares/modules/users.conf << 'USERS'
defaultGroups:
    - sudo
    - audio
    - video
    - cdrom
    - plugdev
    - netdev
    - bluetooth
    - lpadmin
autologinGroup: autologin
doAutologin: false
sudoersGroup: sudo
setRootPassword: true
doReusePassword: true
USERS

# ============================================
# === BRANDING RIZZOOS ===
# ============================================
cat > /etc/os-release << 'OSREL'
PRETTY_NAME="RizzoOS 1.0"
NAME="RizzoOS"
VERSION_ID="1.0"
VERSION="1.0"
ID=rizzoos
ID_LIKE=debian
HOME_URL="https://rizzoos.com"
SUPPORT_URL="https://rizzoos.com/support"
BUG_REPORT_URL="https://rizzoos.com/bugs"
PRIVACY_POLICY_URL="https://rizzoos.com/privacy"
VERSION_CODENAME=rizzoos
OSREL

cat > /etc/lsb-release << 'LSB'
DISTRIB_ID=RizzoOS
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=rizzoos
DISTRIB_DESCRIPTION="RizzoOS 1.0"
LSB

echo "RizzoOS" > /etc/hostname
echo "127.0.0.1 RizzoOS" >> /etc/hosts

cat > /etc/issue << 'ISSUE'

  ██████╗ ██╗███████╗███████╗ ██████╗  ██████╗ ███████╗
  ██╔══██╗██║╚══███╔╝╚══███╔╝██╔═══██╗██╔═══██╗██╔════╝
  ██████╔╝██║  ███╔╝   ███╔╝ ██║   ██║██║   ██║███████╗
  ██╔══██╗██║ ███╔╝   ███╔╝  ██║   ██║██║   ██║╚════██║
  ██║  ██║██║███████╗███████╗╚██████╔╝╚██████╔╝███████║
  ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝

  RizzoOS 1.0 - Par Arnaud

ISSUE

cp /etc/issue /etc/issue.net

cat > /etc/motd << 'MOTD'

  Bienvenue sur RizzoOS 1.0 !
  
  Mode Live - Cliquez sur "Installer RizzoOS" pour installer
  
  neofetch    → Infos système
  waydroid    → Android

MOTD

# ============================================
# === AUTOLOGIN SDDM ===
# ============================================
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf << 'SDDM'
[Autologin]
User=live
Session=plasma

[Theme]
Current=breeze
SDDM

# ============================================
# === CONFIG KDE PLASMA ===
# ============================================
mkdir -p /home/live/.config

cat > /home/live/.config/kwinrc << 'KWIN'
[Compositing]
Backend=XRender
Enabled=true
GLCore=false
OpenGLIsUnsafe=true
WindowsBlockCompositing=false
KWIN

cat > /home/live/.config/kdeglobals << 'THEME'
[General]
ColorScheme=BreezeDark
Name=Breeze Dark
widgetStyle=Breeze

[Icons]
Theme=Papirus-Dark

[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
widgetStyle=breeze
THEME

cat > /home/live/.config/kwineffectsrc << 'EFFECTS'
[Plugins]
blurEnabled=false
contrastEnabled=false
slidingpopupsEnabled=false
translucencyEnabled=false
EFFECTS

cat > /home/live/.config/plasmarc << 'PLASMA'
[Theme]
name=breeze-dark
PLASMA

# ============================================
# === RACCOURCIS BUREAU ===
# ============================================
mkdir -p /home/live/Desktop

cat > /home/live/Desktop/install-rizzoos.desktop << 'INSTALL'
[Desktop Entry]
Name=Installer RizzoOS
Comment=Installer RizzoOS sur votre ordinateur
Exec=sudo calamares
Icon=system-software-install
Type=Application
Terminal=false
INSTALL

cat > /home/live/Desktop/firefox.desktop << 'FF'
[Desktop Entry]
Name=Firefox
Exec=firefox-esr
Icon=firefox-esr
Type=Application
FF

cat > /home/live/Desktop/dolphin.desktop << 'DOLPHIN'
[Desktop Entry]
Name=Fichiers
Exec=dolphin
Icon=system-file-manager
Type=Application
DOLPHIN

cat > /home/live/Desktop/konsole.desktop << 'KONSOLE'
[Desktop Entry]
Name=Terminal
Exec=konsole
Icon=utilities-terminal
Type=Application
KONSOLE

cat > /home/live/Desktop/wine.desktop << 'WINE'
[Desktop Entry]
Name=Wine Config
Exec=winecfg
Icon=wine
Type=Application
WINE

cat > /home/live/Desktop/waydroid.desktop << 'WAYDROID'
[Desktop Entry]
Name=Android (Waydroid)
Comment=Lancer apps Android
Exec=waydroid show-full-ui
Icon=waydroid
Type=Application
WAYDROID

cat > /home/live/Desktop/Bienvenue.txt << 'WELCOME'
╔═══════════════════════════════════════════════════════════╗
║              RizzoOS 1.0 - Par Arnaud                     ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║   🔧 INSTALLATION                                         ║
║   Cliquez sur "Installer RizzoOS" sur le bureau           ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║   LOGICIELS                                               ║
║   🌐 Firefox, Chromium                                    ║
║   📄 LibreOffice                                          ║
║   🎬 VLC, GIMP, Inkscape, Kdenlive, OBS                   ║
║   🎮 Steam, Lutris, Wine                                  ║
║   🤖 Waydroid (Android)                                   ║
║   🔒 Firewall, KeePassXC, ClamAV                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
WELCOME

chmod +x /home/live/Desktop/*.desktop
chown -R 1000:1000 /home/live

# ============================================
# === SCRIPT WAYDROID INIT ===
# ============================================
cat > /usr/local/bin/setup-waydroid << 'WAYSCRIPT'
#!/bin/bash
echo "Initialisation de Waydroid..."
sudo waydroid init
echo "Démarrage de Waydroid..."
waydroid session start &
sleep 5
waydroid show-full-ui
WAYSCRIPT
chmod +x /usr/local/bin/setup-waydroid

# ============================================
# === SERVICES ===
# ============================================
systemctl enable NetworkManager || true
systemctl enable bluetooth || true
systemctl enable ufw || true
systemctl enable apparmor || true

# ============================================
# === FIREWALL ===
# ============================================
ufw default deny incoming || true
ufw default allow outgoing || true

# ============================================
# === NETTOYAGE ===
# ============================================
apt-get clean
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

CHROOT

# ============================================
# === DÉMONTAGE ===
# ============================================
sudo umount -lf "$WORK_DIR/chroot/dev/pts" || true
sudo umount -lf "$WORK_DIR/chroot/dev" || true
sudo umount -lf "$WORK_DIR/chroot/proc" || true
sudo umount -lf "$WORK_DIR/chroot/sys" || true

# ============================================
# === CRÉATION ISO ===
# ============================================
sudo mksquashfs "$WORK_DIR/chroot" "$WORK_DIR/iso/live/filesystem.squashfs" -comp xz -b 1M

sudo cp "$WORK_DIR/chroot/boot/vmlinuz-"* "$WORK_DIR/iso/boot/vmlinuz"
sudo cp "$WORK_DIR/chroot/boot/initrd.img-"* "$WORK_DIR/iso/boot/initrd"

cat << 'EOF' | sudo tee "$WORK_DIR/iso/boot/grub/grub.cfg"
set timeout=10
set default=0

menuentry "RizzoOS 1.0" {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd
}

menuentry "RizzoOS 1.0 (Mode sans échec)" {
    linux /boot/vmlinuz boot=live nomodeset quiet
    initrd /boot/initrd
}

menuentry "RizzoOS 1.0 (Mode récupération)" {
    linux /boot/vmlinuz boot=live single
    initrd /boot/initrd
}
EOF

sudo grub-mkrescue -o "$ISO_OUTPUT" "$WORK_DIR/iso"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          RizzoOS 1.0 créé avec succès ! 🎉                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
