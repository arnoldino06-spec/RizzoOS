#!/bin/bash
set -euo pipefail

# ============================================================
# RizzoOS 1.3 ISO Builder - CORRIGÉ
# ============================================================

WORK_DIR="/tmp/rizzo-build"
ISO_OUTPUT="${GITHUB_WORKSPACE:-$PWD}/iso/RizzoOS-1.0.iso"

mkdir -p "$WORK_DIR"/{chroot,iso/{boot/grub,live}}
mkdir -p "$(dirname "$ISO_OUTPUT")"

# --- Cleanup mounts even if build fails
cleanup() {
  sudo umount -lf "$WORK_DIR/chroot/dev/pts" 2>/dev/null || true
  sudo umount -lf "$WORK_DIR/chroot/dev" 2>/dev/null || true
  sudo umount -lf "$WORK_DIR/chroot/proc" 2>/dev/null || true
  sudo umount -lf "$WORK_DIR/chroot/sys" 2>/dev/null || true
}
trap cleanup EXIT

# --- Host deps (runner)
sudo apt-get update
sudo apt-get install -y \
  debootstrap squashfs-tools xorriso \
  grub-pc-bin grub-efi-amd64-bin mtools dosfstools

# --- Bootstrap Debian
sudo debootstrap --arch=amd64 --variant=minbase bookworm "$WORK_DIR/chroot" http://deb.debian.org/debian

# DNS inside chroot
sudo cp -f /etc/resolv.conf "$WORK_DIR/chroot/etc/resolv.conf" || true

cat << 'EOF' | sudo tee "$WORK_DIR/chroot/etc/apt/sources.list"
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# --- Mount special FS for chroot
sudo mount --bind /dev "$WORK_DIR/chroot/dev"
sudo mount --bind /dev/pts "$WORK_DIR/chroot/dev/pts"
sudo mount -t proc proc "$WORK_DIR/chroot/proc"
sudo mount -t sysfs sysfs "$WORK_DIR/chroot/sys"

# ============================================================
# CHROOT CONFIG
# ============================================================
sudo chroot "$WORK_DIR/chroot" /bin/bash << 'CHROOT'
set -e
export DEBIAN_FRONTEND=noninteractive

# Helpers
install_must() { apt-get install -y "$@"; }
install_maybe() { apt-get install -y "$@" || true; }

dpkg --add-architecture i386
apt-get update

install_must debconf-utils ca-certificates

# ============================================
# === SYSTÈME DE BASE ===
# ============================================
install_must \
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

# GRUB en install_maybe (évite conflit kernel)
install_maybe grub-pc grub-efi-amd64 os-prober efibootmgr

# Vérifier que le kernel est installé
ls /boot/vmlinuz-* || install_must --reinstall linux-image-amd64

# ============================================
# === KDE PLASMA COMPLET ===
# ============================================
install_must \
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

install_maybe polkit-kde-agent-1

# ============================================
# === CALAMARES (Installateur) ===
# ============================================
install_must calamares
install_maybe calamares-settings-debian

install_maybe \
  qml-module-qtquick2 \
  qml-module-qtquick-controls \
  qml-module-qtquick-controls2 \
  qml-module-qtquick-layouts \
  qml-module-qtquick-window2

# ============================================
# === NAVIGATEURS ===
# ============================================
install_must firefox-esr chromium

# ============================================
# === BUREAUTIQUE ===
# ============================================
install_must libreoffice libreoffice-plasma libreoffice-l10n-fr hunspell-fr

# ============================================
# === MULTIMÉDIA ===
# ============================================
install_must vlc gimp inkscape kdenlive audacity obs-studio mpv ffmpeg imagemagick

# ============================================
# === WINE (Apps Windows) ===
# ============================================
install_must wine wine64 wine32 winetricks playonlinux q4wine

# ============================================
# === GAMING ===
# ============================================
install_maybe \
  steam-installer \
  lutris \
  gamemode \
  mangohud \
  mesa-vulkan-drivers \
  libvulkan1 \
  vulkan-tools

# ============================================
# === DÉVELOPPEMENT ===
# ============================================
install_maybe git curl wget nano vim build-essential python3 python3-pip nodejs npm

# ============================================
# === SERVEUR WEB LAMP ===
# ============================================
install_must \
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

# ============================================
# === PHPMYADMIN ===
# ============================================
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections || true
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections || true
echo "phpmyadmin phpmyadmin/mysql/admin-pass password root" | debconf-set-selections || true
echo "phpmyadmin phpmyadmin/mysql/app-pass password root" | debconf-set-selections || true
echo "phpmyadmin phpmyadmin/app-password-confirm password root" | debconf-set-selections || true
install_maybe phpmyadmin
ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin || true

# ============================================
# === RIZZOBROWSER ===
# ============================================
install_must python3-pyqt5 python3-pyqt5.qtwebengine

cat > /usr/local/bin/rizzobrowser << 'BROWSER'
#!/usr/bin/env python3
import sys
from PyQt5.QtCore import QUrl
from PyQt5.QtWidgets import QApplication, QMainWindow, QToolBar, QLineEdit, QAction, QTabWidget, QStatusBar
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
            QLineEdit {
                background-color: #0f3460;
                color: white;
                border: 2px solid #00d4ff;
                border-radius: 15px;
                padding: 8px 15px;
                font-size: 14px;
                min-width: 400px;
            }
            QLineEdit:focus { border-color: #00ff88; }
            QTabWidget::pane { border: none; }
            QTabBar::tab {
                background-color: #16213e;
                color: white;
                padding: 10px 20px;
                margin-right: 2px;
                border-top-left-radius: 10px;
                border-top-right-radius: 10px;
            }
            QTabBar::tab:selected { background-color: #0f3460; }
            QStatusBar { background-color: #16213e; color: #00d4ff; }
        """)

    def add_tab(self, url="https://duckduckgo.com"):
        browser = QWebEngineView()
        browser.setUrl(QUrl(url))
        browser.urlChanged.connect(self.update_url)
        browser.titleChanged.connect(lambda title: self.tabs.setTabText(
            self.tabs.indexOf(browser), (title[:20] + "...") if len(title) > 20 else title))
        i = self.tabs.addTab(browser, "Nouvel onglet")
        self.tabs.setCurrentIndex(i)
        return browser

    def current_browser(self):
        return self.tabs.currentWidget()

    def navigate(self):
        url = self.url_bar.text().strip()
        if not url.startswith("http"):
            if "." in url:
                url = "https://" + url
            else:
                url = f"https://duckduckgo.com/?q={url}"
        self.current_browser().setUrl(QUrl(url))

    def update_url(self, url):
        self.url_bar.setText(url.toString())
        self.status.showMessage(url.toString())

    def go_home(self):
        self.current_browser().setUrl(QUrl("https://duckduckgo.com"))

    def close_tab(self, i):
        if self.tabs.count() > 1:
            self.tabs.removeTab(i)
        else:
            self.close()

    def tab_changed(self, i):
        if self.current_browser():
            self.update_url(self.current_browser().url())

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationName("RizzoBrowser")
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
# === OUTILS SYSTÈME ===
# ============================================
install_maybe htop btop neofetch gparted baobab gnome-disk-utility bleachbit

# ============================================
# === RÉSEAU & INTERNET ===
# ============================================
install_must network-manager bluetooth
install_maybe network-manager-gnome blueman transmission-qt filezilla remmina

# ============================================
# === SÉCURITÉ ===
# ============================================
install_maybe ufw gufw apparmor clamav clamtk keepassxc

# ============================================
# === AUDIO ===
# ============================================
install_must pipewire pipewire-audio pipewire-pulse wireplumber pavucontrol-qt

# ============================================
# === COMPRESSION ===
# ============================================
install_must unzip zip p7zip-full unrar tar gzip

# ============================================
# === POLICES ===
# ============================================
install_must fonts-noto fonts-noto-color-emoji fonts-liberation fonts-dejavu fonts-ubuntu

# ============================================
# === WAYDROID (Apps Android) ===
# ============================================
install_maybe curl ca-certificates gnupg lxc
curl -s https://repo.waydro.id/waydroid.gpg | tee /usr/share/keyrings/waydroid.gpg > /dev/null || true
echo "deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydro.id/ bookworm main" > /etc/apt/sources.list.d/waydroid.list || true
apt-get update || true
install_maybe waydroid

# ============================================
# === UTILISATEUR LIVE ===
# ============================================
useradd -m -s /bin/bash -G sudo,audio,video,cdrom,plugdev,netdev,bluetooth,lpadmin,www-data live
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
    version:             "1.3"
    shortVersion:        "1.3"
    versionedName:       "RizzoOS 1.3"
    shortVersionedName:  "RizzoOS 1.3"
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
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"
            Text {
                anchors.centerIn: parent
                text: "Bienvenue sur RizzoOS 1.3\n\nInstallation en cours..."
                color: "#00d4ff"
                font.pixelSize: 32
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
QML

# Images placeholder (évite crash)
touch /etc/calamares/branding/rizzoos/logo.png
touch /etc/calamares/branding/rizzoos/welcome.png

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
grubProbe: "grub-probe"
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
autologinGroup: autologin
doAutologin: false
sudoersGroup: sudo
setRootPassword: true
doReusePassword: true
USERS

cat > /etc/calamares/modules/welcome.conf << 'WELCOME'
showSupportUrl: true
showKnownIssuesUrl: true
showReleaseNotesUrl: true
requirements:
    requiredStorage: 10
    requiredRam: 2.0
    internetCheckUrl: https://google.com
    check:
        - storage
        - ram
        - root
    required:
        - storage
        - ram
        - root
WELCOME

cat > /etc/calamares/modules/locale.conf << 'LOCALE'
region: "Europe"
zone: "Zurich"
LOCALE

cat > /etc/calamares/modules/keyboard.conf << 'KEYBOARD'
xOrgConfFileName: "/etc/X11/xorg.conf.d/00-keyboard.conf"
convertedKeymapPath: "/lib/kbd/keymaps/xkb"
writeEtcDefaultKeyboard: true
KEYBOARD

# ============================================
# === BRANDING OS ===
# ============================================
cat > /etc/os-release << 'OSREL'
PRETTY_NAME="RizzoOS 1.3"
NAME="RizzoOS"
VERSION_ID="1.3"
VERSION="1.3"
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
DISTRIB_RELEASE=1.3
DISTRIB_CODENAME=rizzoos
DISTRIB_DESCRIPTION="RizzoOS 1.3"
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

  RizzoOS 1.3 - Par Arnaud

ISSUE

cp /etc/issue /etc/issue.net

cat > /etc/motd << 'MOTD'

  Bienvenue sur RizzoOS 1.3 !

  Mode Live - Cliquez sur "Installer RizzoOS" sur le bureau

  rizzobrowser    → Navigateur RizzoOS
  start-web       → Démarrer serveur web
  http://localhost → Serveur Web

MOTD

# ============================================
# === PAGE D'ACCUEIL APACHE ===
# ============================================
cat > /var/www/html/index.html << 'APACHE'
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>RizzoOS - Serveur Web</title>
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    body{
      font-family: 'Segoe UI', sans-serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
      min-height:100vh; display:flex; justify-content:center; align-items:center;
      color:white;
    }
    .container{
      text-align:center; padding:40px;
      background:rgba(255,255,255,0.1);
      border-radius:20px; backdrop-filter:blur(10px);
      box-shadow:0 8px 32px rgba(0,0,0,0.3);
    }
    h1{
      font-size:3em; margin-bottom:10px;
      background:linear-gradient(90deg,#00d4ff,#00ff88);
      -webkit-background-clip:text; -webkit-text-fill-color:transparent;
    }
    p{ font-size:1.2em; margin:20px 0; color:#ccc; }
    .links{ margin-top:30px; }
    .links a{
      display:inline-block; margin:10px; padding:15px 30px;
      background:linear-gradient(90deg,#00d4ff,#00ff88);
      color:#1a1a2e; text-decoration:none; border-radius:30px;
      font-weight:bold; transition:transform .3s, box-shadow .3s;
    }
    .links a:hover{
      transform:translateY(-3px);
      box-shadow:0 10px 30px rgba(0,212,255,0.4);
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 RizzoOS 1.3</h1>
    <p>Votre serveur web est opérationnel !</p>
    <div class="links">
      <a href="/phpmyadmin">📊 phpMyAdmin</a>
      <a href="https://rizzoos.com">🌐 Site RizzoOS</a>
    </div>
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
Exec=konsole --hold -e sudo -E calamares
Icon=system-software-install
Type=Application
Terminal=false
Categories=System;
INSTALL

cat > /home/live/Desktop/rizzobrowser.desktop << 'RBROWSER'
[Desktop Entry]
Name=RizzoBrowser
Comment=Navigateur Web RizzoOS
Exec=/usr/local/bin/rizzobrowser
Icon=web-browser
Type=Application
RBROWSER

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
Exec=waydroid show-full-ui
Icon=waydroid
Type=Application
WAYDROID

cat > /home/live/Desktop/phpmyadmin.desktop << 'PMA'
[Desktop Entry]
Name=phpMyAdmin
Exec=firefox-esr http://localhost/phpmyadmin
Icon=web-browser
Type=Application
PMA

cat > /home/live/Desktop/Bienvenue.txt << 'WELCOME'
╔═══════════════════════════════════════════════════════════╗
║              RizzoOS 1.3 - Par Arnaud                     ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║   🔧 INSTALLATION                                         ║
║   Cliquez sur "Installer RizzoOS" sur le bureau           ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║   🌐 SERVEUR WEB                                          ║
║   start-web           → Démarrer Apache/MariaDB           ║
║   http://localhost    → Page d'accueil                    ║
║   http://localhost/phpmyadmin → phpMyAdmin                ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║   LOGICIELS                                               ║
║   🌐 RizzoBrowser, Firefox, Chromium                      ║
║   📄 LibreOffice                                          ║
║   🎬 VLC, GIMP, Inkscape, Kdenlive, OBS                   ║
║   🎮 Steam, Lutris, Wine                                  ║
║   🤖 Waydroid (Android)                                   ║
║   🔒 Firewall, KeePassXC, ClamAV                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
WELCOME

chmod +x /home/live/Desktop/*.desktop
chown -R live:live /home/live

# ============================================
# === SCRIPTS UTILITAIRES ===
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

cat > /usr/local/bin/start-web << 'WEBSCRIPT'
#!/bin/bash
echo "Démarrage du serveur web..."
sudo systemctl start mariadb || true
sudo systemctl start apache2 || true
echo "✅ Apache et MariaDB démarrés !"
echo "→ http://localhost"
echo "→ http://localhost/phpmyadmin"
WEBSCRIPT
chmod +x /usr/local/bin/start-web

# ============================================
# === SERVICES ===
# ============================================
systemctl enable NetworkManager 2>/dev/null || true
systemctl enable bluetooth 2>/dev/null || true
systemctl enable ufw 2>/dev/null || true
systemctl enable apparmor 2>/dev/null || true
systemctl enable apache2 2>/dev/null || true
systemctl enable mariadb 2>/dev/null || true
systemctl enable sddm 2>/dev/null || true

# Firewall
if command -v ufw >/dev/null 2>&1; then
  ufw default deny incoming || true
  ufw default allow outgoing || true
  ufw allow 80/tcp || true
  ufw allow 443/tcp || true
fi

# Nettoyage
apt-get clean
apt-get autoremove -y || true
rm -rf /var/lib/apt/lists/* /tmp/*

CHROOT

# ============================================================
# BUILD ISO
# ============================================================
# Démonter AVANT squashfs
sudo umount -lf "$WORK_DIR/chroot/dev/pts" || true
sudo umount -lf "$WORK_DIR/chroot/dev" || true
sudo umount -lf "$WORK_DIR/chroot/proc" || true
sudo umount -lf "$WORK_DIR/chroot/sys" || true

sudo mksquashfs "$WORK_DIR/chroot" "$WORK_DIR/iso/live/filesystem.squashfs" -comp xz -b 1M -no-progress -e proc -e sys -e dev -e run

sudo cp "$WORK_DIR/chroot/boot/vmlinuz-"* "$WORK_DIR/iso/boot/vmlinuz"
sudo cp "$WORK_DIR/chroot/boot/initrd.img-"* "$WORK_DIR/iso/boot/initrd"

cat << 'EOF' | sudo tee "$WORK_DIR/iso/boot/grub/grub.cfg"
set timeout=10
set default=0

menuentry "RizzoOS 1.3 - Live" {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd
}

menuentry "RizzoOS 1.3 - Live (Mode sans échec)" {
    linux /boot/vmlinuz boot=live nomodeset quiet
    initrd /boot/initrd
}

menuentry "RizzoOS 1.3 - Live (Mode récupération)" {
    linux /boot/vmlinuz boot=live single
    initrd /boot/initrd
}
EOF

sudo grub-mkrescue -o "$ISO_OUTPUT" "$WORK_DIR/iso" -- -volid "RizzoOS"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          RizzoOS 1.3 créé avec succès ! 🎉                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo "ISO : $ISO_OUTPUT"
