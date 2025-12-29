#!/bin/bash
set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         RizzoOS 1.2 - VERSION CORRIGÉE                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"

WORK_DIR="/tmp/rizzo-build"
ISO_OUTPUT="$HOME/RizzoOS-1.2.iso"

# Nettoyage complet
sudo rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"/{chroot,iso/{boot/grub,live}}

echo "[1/10] Bootstrap Debian..."
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

echo "[2/10] Installation système de base..."
apt-get install -y \
    linux-image-amd64 \
    live-boot \
    live-boot-initramfs-tools \
    systemd-sysv \
    sudo \
    locales \
    console-setup \
    keyboard-configuration \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    firmware-realtek \
    firmware-iwlwifi \
    firmware-atheros \
    firmware-amd-graphics \
    intel-microcode \
    amd64-microcode \
    grub-pc \
    grub-efi-amd64 \
    os-prober \
    efibootmgr \
    initramfs-tools

# Configurer les locales
sed -i 's/# fr_FR.UTF-8/fr_FR.UTF-8/' /etc/locale.gen
sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/default/locale

echo "[3/10] Installation KDE Plasma..."
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

echo "[4/10] Installation Calamares..."
apt-get install -y \
    calamares \
    calamares-settings-debian \
    qml-module-qtquick2 \
    qml-module-qtquick-controls \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts \
    qml-module-qtquick-window2 || true

echo "[5/10] Installation navigateurs et bureautique..."
apt-get install -y \
    firefox-esr \
    chromium \
    libreoffice \
    libreoffice-kde5 \
    libreoffice-l10n-fr \
    hunspell-fr

echo "[6/10] Installation multimédia..."
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

echo "[7/10] Installation Wine et Gaming..."
apt-get install -y \
    wine \
    wine64 \
    wine32 \
    winetricks \
    playonlinux \
    q4wine || true

apt-get install -y \
    steam-installer \
    lutris \
    gamemode \
    mangohud \
    mesa-vulkan-drivers \
    libvulkan1 \
    vulkan-tools || true

echo "[8/10] Installation serveur LAMP..."
apt-get install -y \
    apache2 \
    mariadb-server \
    mariadb-client \
    php \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-xmlrpc \
    php-soap \
    php-intl \
    php-zip \
    php-cli \
    php-common \
    php-opcache \
    php-readline \
    libapache2-mod-php

echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password root" | debconf-set-selections
apt-get install -y phpmyadmin || true
ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin || true

echo "[9/10] Installation outils..."
apt-get install -y \
    git \
    curl \
    wget \
    nano \
    vim \
    build-essential \
    python3 \
    python3-pip \
    python3-pyqt5 \
    python3-pyqt5.qtwebengine \
    nodejs \
    npm \
    htop \
    btop \
    neofetch \
    gparted \
    baobab \
    gnome-disk-utility \
    timeshift \
    bleachbit \
    network-manager \
    network-manager-gnome \
    bluetooth \
    blueman \
    transmission-qt \
    filezilla \
    remmina \
    ufw \
    gufw \
    apparmor \
    clamav \
    clamtk \
    keepassxc \
    wireguard \
    wireguard-tools \
    openvpn \
    pipewire \
    pipewire-audio \
    pipewire-pulse \
    wireplumber \
    pavucontrol-qt \
    cups \
    cups-browsed \
    printer-driver-all \
    system-config-printer \
    flatpak \
    docker.io \
    docker-compose \
    unzip \
    zip \
    p7zip-full \
    unrar \
    tar \
    gzip \
    fonts-noto \
    fonts-noto-color-emoji \
    fonts-liberation \
    fonts-dejavu \
    fonts-ubuntu \
    xorg \
    xinit \
    x11-xserver-utils || true

# Flatpak config
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

echo "[10/10] Installation Waydroid..."
apt-get install -y curl ca-certificates gnupg lxc || true
curl -s https://repo.waydro.id/waydroid.gpg | tee /usr/share/keyrings/waydroid.gpg > /dev/null || true
echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydro.id/ bookworm main" > /etc/apt/sources.list.d/waydroid.list || true
apt-get update || true
apt-get install -y waydroid || true

# ============================================
# === RIZZOBROWSER ===
# ============================================
cat > /usr/local/bin/rizzobrowser << 'BROWSER'
#!/usr/bin/env python3
import sys
from PyQt5.QtCore import QUrl
from PyQt5.QtWidgets import (QApplication, QMainWindow, QToolBar, 
    QLineEdit, QAction, QTabWidget, QStatusBar)
from PyQt5.QtWebEngineWidgets import QWebEngineView

class Browser(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("RizzoBrowser")
        self.setGeometry(100, 100, 1400, 900)
        
        self.tabs = QTabWidget()
        self.tabs.setTabsClosable(True)
        self.tabs.tabCloseRequested.connect(self.close_tab)
        self.tabs.currentChanged.connect(self.tab_changed)
        self.setCentralWidget(self.tabs)
        
        navbar = QToolBar("Navigation")
        navbar.setMovable(False)
        self.addToolBar(navbar)
        
        back_btn = QAction("◀", self)
        back_btn.triggered.connect(lambda: self.current_browser().back())
        navbar.addAction(back_btn)
        
        forward_btn = QAction("▶", self)
        forward_btn.triggered.connect(lambda: self.current_browser().forward())
        navbar.addAction(forward_btn)
        
        reload_btn = QAction("⟳", self)
        reload_btn.triggered.connect(lambda: self.current_browser().reload())
        navbar.addAction(reload_btn)
        
        home_btn = QAction("🏠", self)
        home_btn.triggered.connect(self.go_home)
        navbar.addAction(home_btn)
        
        self.url_bar = QLineEdit()
        self.url_bar.returnPressed.connect(self.navigate)
        navbar.addWidget(self.url_bar)
        
        new_tab_btn = QAction("+", self)
        new_tab_btn.triggered.connect(lambda: self.add_tab())
        navbar.addAction(new_tab_btn)
        
        self.status = QStatusBar()
        self.setStatusBar(self.status)
        self.add_tab()
        
        self.setStyleSheet("""
            QMainWindow { background-color: #1a1a2e; }
            QToolBar { background-color: #16213e; border: none; padding: 5px; }
            QLineEdit { background-color: #0f3460; color: white; border: 2px solid #00d4ff; border-radius: 15px; padding: 8px 15px; font-size: 14px; min-width: 400px; }
            QTabBar::tab { background-color: #16213e; color: white; padding: 10px 20px; border-top-left-radius: 10px; border-top-right-radius: 10px; }
            QTabBar::tab:selected { background-color: #0f3460; }
            QStatusBar { background-color: #16213e; color: #00d4ff; }
        """)
    
    def add_tab(self, url="https://duckduckgo.com"):
        browser = QWebEngineView()
        browser.setUrl(QUrl(url))
        browser.urlChanged.connect(self.update_url)
        browser.titleChanged.connect(lambda title: self.tabs.setTabText(self.tabs.indexOf(browser), title[:20] + "..." if len(title) > 20 else title))
        i = self.tabs.addTab(browser, "Nouvel onglet")
        self.tabs.setCurrentIndex(i)
    
    def current_browser(self):
        return self.tabs.currentWidget()
    
    def navigate(self):
        url = self.url_bar.text()
        if not url.startswith("http"):
            url = "https://" + url if "." in url else f"https://duckduckgo.com/?q={url}"
        self.current_browser().setUrl(QUrl(url))
    
    def update_url(self, url):
        self.url_bar.setText(url.toString())
    
    def go_home(self):
        self.current_browser().setUrl(QUrl("https://duckduckgo.com"))
    
    def close_tab(self, i):
        if self.tabs.count() > 1:
            self.tabs.removeTab(i)
    
    def tab_changed(self, i):
        if self.current_browser():
            self.update_url(self.current_browser().url())

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = Browser()
    window.show()
    sys.exit(app.exec_())
BROWSER
chmod +x /usr/local/bin/rizzobrowser

cat > /usr/share/applications/rizzobrowser.desktop << 'MENU'
[Desktop Entry]
Name=RizzoBrowser
Comment=Navigateur Web RizzoOS
Exec=/usr/local/bin/rizzobrowser
Icon=web-browser
Type=Application
Categories=Network;WebBrowser;
MENU

# ============================================
# === UTILISATEUR LIVE ===
# ============================================
useradd -m -s /bin/bash -G sudo,audio,video,cdrom,plugdev,netdev,bluetooth,lpadmin,www-data,docker live
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
    version:             "1.2"
    shortVersion:        "1.2"
    versionedName:       "RizzoOS 1.2"
    shortVersionedName:  "RizzoOS 1.2"
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
                text: "Bienvenue sur RizzoOS 1.2\n\nInstallation en cours..."
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
    - www-data
    - docker
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
PRETTY_NAME="RizzoOS 1.2"
NAME="RizzoOS"
VERSION_ID="1.2"
VERSION="1.2"
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
DISTRIB_RELEASE=1.2
DISTRIB_CODENAME=rizzoos
DISTRIB_DESCRIPTION="RizzoOS 1.2"
LSB

echo "RizzoOS" > /etc/hostname
cat > /etc/hosts << 'HOSTS'
127.0.0.1	localhost
127.0.1.1	RizzoOS

::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters
HOSTS

cat > /etc/issue << 'ISSUE'

  ██████╗ ██╗███████╗███████╗ ██████╗  ██████╗ ███████╗
  ██╔══██╗██║╚══███╔╝╚══███╔╝██╔═══██╗██╔═══██╗██╔════╝
  ██████╔╝██║  ███╔╝   ███╔╝ ██║   ██║██║   ██║███████╗
  ██╔══██╗██║ ███╔╝   ███╔╝  ██║   ██║██║   ██║╚════██║
  ██║  ██║██║███████╗███████╗╚██████╔╝╚██████╔╝███████║
  ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝

  RizzoOS 1.2 - Par Arnaud

ISSUE

cp /etc/issue /etc/issue.net

cat > /etc/motd << 'MOTD'

  Bienvenue sur RizzoOS 1.2 !
  
  Mode Live - Cliquez sur "Installer RizzoOS" pour installer

MOTD

# ============================================
# === PAGE APACHE ===
# ============================================
cat > /var/www/html/index.html << 'APACHE'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>RizzoOS 1.2</title>
    <style>
        body { font-family: sans-serif; background: linear-gradient(135deg, #1a1a2e, #0f3460); min-height: 100vh; display: flex; justify-content: center; align-items: center; color: white; margin: 0; }
        .container { text-align: center; padding: 40px; background: rgba(255,255,255,0.1); border-radius: 20px; }
        h1 { font-size: 3em; background: linear-gradient(90deg, #00d4ff, #00ff88); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        a { display: inline-block; margin: 10px; padding: 15px 30px; background: linear-gradient(90deg, #00d4ff, #00ff88); color: #1a1a2e; text-decoration: none; border-radius: 30px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 RizzoOS 1.2</h1>
        <p>Serveur web opérationnel !</p>
        <a href="/phpmyadmin">phpMyAdmin</a>
    </div>
</body>
</html>
APACHE

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
# === CONFIG KDE ===
# ============================================
mkdir -p /home/live/.config

cat > /home/live/.config/kwinrc << 'KWIN'
[Compositing]
Backend=XRender
Enabled=true
GLCore=false
OpenGLIsUnsafe=true
KWIN

cat > /home/live/.config/kdeglobals << 'THEME'
[General]
ColorScheme=BreezeDark
[Icons]
Theme=Papirus-Dark
[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
THEME

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
Exec=sudo calamares
Icon=system-software-install
Type=Application
Terminal=false
INSTALL

cat > /home/live/Desktop/rizzobrowser.desktop << 'RB'
[Desktop Entry]
Name=RizzoBrowser
Exec=/usr/local/bin/rizzobrowser
Icon=web-browser
Type=Application
RB

cat > /home/live/Desktop/firefox.desktop << 'FF'
[Desktop Entry]
Name=Firefox
Exec=firefox-esr
Icon=firefox-esr
Type=Application
FF

cat > /home/live/Desktop/dolphin.desktop << 'DOL'
[Desktop Entry]
Name=Fichiers
Exec=dolphin
Icon=system-file-manager
Type=Application
DOL

cat > /home/live/Desktop/konsole.desktop << 'KON'
[Desktop Entry]
Name=Terminal
Exec=konsole
Icon=utilities-terminal
Type=Application
KON

chmod +x /home/live/Desktop/*.desktop
chown -R 1000:1000 /home/live

# ============================================
# === SERVICES ===
# ============================================
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable ufw
systemctl enable apparmor
systemctl enable apache2
systemctl enable mariadb
systemctl enable cups
systemctl enable docker
systemctl enable sddm

# ============================================
# === FIX INITRAMFS ===
# ============================================
mkdir -p /etc/live
echo "LIVE_MEDIA_PATH=/live" > /etc/live/boot.conf
update-initramfs -u -k all

# ============================================
# === NETTOYAGE ===
# ============================================
apt-get clean
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

CHROOT

echo "[ISO] Démontage..."
sudo umount -lf "$WORK_DIR/chroot/dev/pts" || true
sudo umount -lf "$WORK_DIR/chroot/dev" || true
sudo umount -lf "$WORK_DIR/chroot/proc" || true
sudo umount -lf "$WORK_DIR/chroot/sys" || true

echo "[ISO] Création squashfs..."
sudo mksquashfs "$WORK_DIR/chroot" "$WORK_DIR/iso/live/filesystem.squashfs" -comp xz -b 1M -noappend

echo "[ISO] Copie kernel..."
sudo cp "$WORK_DIR/chroot/boot/vmlinuz-"* "$WORK_DIR/iso/boot/vmlinuz"
sudo cp "$WORK_DIR/chroot/boot/initrd.img-"* "$WORK_DIR/iso/boot/initrd"

echo "[ISO] Configuration GRUB..."
cat << 'EOF' | sudo tee "$WORK_DIR/iso/boot/grub/grub.cfg"
set timeout=10
set default=0

menuentry "RizzoOS 1.2 - Live" {
    linux /boot/vmlinuz boot=live live-media-path=/live quiet
    initrd /boot/initrd
}

menuentry "RizzoOS 1.2 - Live (Mode compatible)" {
    linux /boot/vmlinuz boot=live live-media-path=/live nomodeset quiet
    initrd /boot/initrd
}

menuentry "RizzoOS 1.2 - Live (Mode texte)" {
    linux /boot/vmlinuz boot=live live-media-path=/live systemd.unit=multi-user.target
    initrd /boot/initrd
}
EOF

echo "[ISO] Création ISO finale..."
sudo grub-mkrescue -o "$ISO_OUTPUT" "$WORK_DIR/iso"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║        RizzoOS 1.2 créé avec succès ! 🎉                  ║"
echo "║   ISO: $ISO_OUTPUT                                        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
