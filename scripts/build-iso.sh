#!/bin/bash
set -e

WORK_DIR="/tmp/rizzo-build"
ISO_OUTPUT="/home/runner/work/RizzoOS/RizzoOS/iso/RizzoOS-1.0.iso"

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

# Télécharger le fond d'écran AVANT d'entrer dans le chroot
sudo mkdir -p "$WORK_DIR/chroot/usr/share/wallpapers/RizzoOS/contents/images"
sudo wget -O "$WORK_DIR/chroot/usr/share/wallpapers/RizzoOS/contents/images/1920x1080.png" \
    "https://raw.githubusercontent.com/arnoldino06-spec/RizzoOS/main/assets/Fond_OS.png" || true
    
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

# Logo SVG RizzoOS
cat > /etc/calamares/branding/rizzoos/logo.svg << 'LOGOSVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <defs>
    <linearGradient id="logoGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#00d4ff"/>
      <stop offset="100%" style="stop-color:#00ff88"/>
    </linearGradient>
  </defs>
  <circle cx="100" cy="100" r="90" fill="#1a1a2e" stroke="url(#logoGrad)" stroke-width="8"/>
  <text x="100" y="115" text-anchor="middle" font-family="Arial, sans-serif" font-size="45" font-weight="bold" fill="url(#logoGrad)">R</text>
  <text x="100" y="160" text-anchor="middle" font-family="Arial, sans-serif" font-size="18" fill="#ffffff">RizzoOS</text>
</svg>
LOGOSVG

# Convertir en PNG
convert -background none /etc/calamares/branding/rizzoos/logo.svg /etc/calamares/branding/rizzoos/logo.png 2>/dev/null || cp /etc/calamares/branding/rizzoos/logo.svg /etc/calamares/branding/rizzoos/logo.png

# Welcome image
cat > /etc/calamares/branding/rizzoos/welcome.svg << 'WELCOMESVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 300">
  <defs>
    <linearGradient id="welGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1a1a2e"/>
      <stop offset="100%" style="stop-color:#16213e"/>
    </linearGradient>
    <linearGradient id="textGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:#00d4ff"/>
      <stop offset="100%" style="stop-color:#00ff88"/>
    </linearGradient>
  </defs>
  <rect width="800" height="300" fill="url(#welGrad)"/>
  <text x="400" y="150" text-anchor="middle" font-family="Arial, sans-serif" font-size="80" font-weight="bold" fill="url(#textGrad)">RizzoOS</text>
  <text x="400" y="200" text-anchor="middle" font-family="Arial, sans-serif" font-size="25" fill="#ffffff" opacity="0.8">Bienvenue dans l'installation</text>
  <text x="400" y="240" text-anchor="middle" font-family="Arial, sans-serif" font-size="18" fill="#00d4ff">Par Arnaud</text>
</svg>
WELCOMESVG

convert -background none /etc/calamares/branding/rizzoos/welcome.svg /etc/calamares/branding/rizzoos/welcome.png 2>/dev/null || cp /etc/calamares/branding/rizzoos/welcome.svg /etc/calamares/branding/rizzoos/welcome.png

# ============================================
# === NAVIGATEURS ===
# ============================================
apt-get install -y \
    chromium
    
# ============================================
# === RIZZO NAVIGATOR ===
# ============================================
apt-get install -y python3-pyqt5 python3-pyqt5.qtwebengine

cat > /usr/local/bin/rizzo-navigator << 'BROWSER'
#!/usr/bin/env python3
import sys
from PyQt5.QtCore import QUrl
from PyQt5.QtWidgets import QApplication, QMainWindow, QToolBar, QLineEdit, QAction, QTabWidget, QStatusBar
from PyQt5.QtWebEngineWidgets import QWebEngineView

class Browser(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Rizzo Navigator")
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

    def add_tab(self, url="file:///usr/share/rizzoos/homepage.html"):
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
    app.setApplicationName("Rizzo Navigator")
    window = Browser()
    window.show()
    sys.exit(app.exec_())
BROWSER
chmod +x /usr/local/bin/rizzo-navigator

# Menu application
cat > /usr/share/applications/rizzo-navigator.desktop << 'MENU'
[Desktop Entry]
Name=Rizzo Navigator
Comment=Navigateur Web RizzoOS
Exec=/usr/local/bin/rizzo-navigator
Icon=web-browser
Type=Application
Categories=Network;WebBrowser;
MENU

# Page d'accueil Rizzo Navigator
mkdir -p /usr/share/rizzoos
cat > /usr/share/rizzoos/homepage.html << 'HOMEPAGE'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>RizzoOS - Accueil</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }
        .container { text-align: center; padding: 40px; }
        h1 {
            font-size: 4em;
            background: linear-gradient(90deg, #00d4ff, #00ff88);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 10px;
        }
        .subtitle { color: #aaa; font-size: 1.2em; margin-bottom: 40px; }
        .search-box {
            background: rgba(255,255,255,0.1);
            border-radius: 50px;
            padding: 15px 30px;
            display: flex;
            align-items: center;
            width: 600px;
            max-width: 90vw;
            margin-bottom: 40px;
        }
        .search-box input {
            flex: 1;
            background: none;
            border: none;
            color: white;
            font-size: 1.1em;
            outline: none;
        }
        .search-box button {
            background: linear-gradient(90deg, #00d4ff, #00ff88);
            border: none;
            padding: 10px 25px;
            border-radius: 25px;
            color: #1a1a2e;
            font-weight: bold;
            cursor: pointer;
        }
        .links { display: flex; gap: 20px; flex-wrap: wrap; justify-content: center; }
        .link {
            background: rgba(255,255,255,0.1);
            padding: 20px 30px;
            border-radius: 15px;
            text-decoration: none;
            color: white;
            transition: all 0.3s;
        }
        .link:hover { background: rgba(0,212,255,0.3); transform: translateY(-5px); }
        .link-icon { font-size: 2em; margin-bottom: 10px; }
        .footer { position: fixed; bottom: 20px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 RizzoOS</h1>
        <p class="subtitle">Par Arnaud</p>
        <div class="search-box">
            <input type="text" id="search" placeholder="Rechercher sur DuckDuckGo..." onkeypress="if(event.key==='Enter')search()">
            <button onclick="search()">🔍</button>
        </div>
        <div class="links">
            <a href="https://duckduckgo.com" class="link"><div class="link-icon">🦆</div>DuckDuckGo</a>
            <a href="https://youtube.com" class="link"><div class="link-icon">▶️</div>YouTube</a>
            <a href="https://github.com" class="link"><div class="link-icon">💻</div>GitHub</a>
            <a href="https://wikipedia.org" class="link"><div class="link-icon">📚</div>Wikipedia</a>
            <a href="http://localhost" class="link"><div class="link-icon">🖥️</div>Serveur Local</a>
        </div>
    </div>
    <div class="footer">RizzoOS 1.0</div>
    <script>
        function search() {
            const q = document.getElementById('search').value;
            if(q) window.location.href = 'https://duckduckgo.com/?q=' + encodeURIComponent(q);
        }
    </script>
</body>
</html>
HOMEPAGE

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
# === SERVEUR WEB LAMP ===
# ============================================
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
    php-zip \
    libapache2-mod-php || true

    # Page d'accueil Apache
cat > /var/www/html/index.html << 'WEBPAGE'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>RizzoOS - Serveur Web</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #1a1a2e, #16213e);
            color: white;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            margin: 0;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(255,255,255,0.1);
            border-radius: 20px;
        }
        h1 {
            color: #00d4ff;
            font-size: 3em;
        }
        a {
            display: inline-block;
            margin: 10px;
            padding: 15px 30px;
            background: #00d4ff;
            color: #1a1a2e;
            text-decoration: none;
            border-radius: 30px;
            font-weight: bold;
        }
        a:hover {
            background: #00ff88;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 RizzoOS</h1>
        <p>Serveur web opérationnel !</p>
        <a href="/phpmyadmin">📊 phpMyAdmin</a>
    </div>
</body>
</html>
WEBPAGE

# phpMyAdmin (config auto)
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections || true
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections || true
apt-get install -y phpmyadmin || true
ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin || true

# Configurer MariaDB avec mot de passe root
service mariadb start || true
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('root'); FLUSH PRIVILEGES;" || true
service mariadb stop || true

# IMPORTANT: Désactiver démarrage auto (évite kernel panic)
systemctl disable apache2 || true
systemctl disable mariadb || true

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
# === TIMESHIFT (Sauvegardes) ===
# ============================================
apt-get install -y timeshift || true

# ============================================
# === FLATPAK (Magasin d'apps) ===
# ============================================
apt-get install -y flatpak || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

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
# === PLYMOUTH (Écran de démarrage) ===
# ============================================
apt-get install -y plymouth plymouth-themes || true

# Créer thème RizzoOS
mkdir -p /usr/share/plymouth/themes/rizzoos

cat > /usr/share/plymouth/themes/rizzoos/rizzoos.plymouth << 'PLYMOUTHCONF'
[Plymouth Theme]
Name=RizzoOS
Description=RizzoOS Boot Screen
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/rizzoos
ScriptFile=/usr/share/plymouth/themes/rizzoos/rizzoos.script
PLYMOUTHCONF

cat > /usr/share/plymouth/themes/rizzoos/rizzoos.script << 'PLYMOUTHSCRIPT'
Window.SetBackgroundTopColor(0.10, 0.10, 0.18);
Window.SetBackgroundBottomColor(0.09, 0.13, 0.24);

logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2);

message_sprite = Sprite();
message_sprite.SetPosition(Window.GetWidth() / 2, Window.GetHeight() - 50, 1);

fun message_callback(text) {
    my_image = Image.Text(text, 0, 0.83, 1);
    message_sprite.SetImage(my_image);
    message_sprite.SetX(Window.GetWidth() / 2 - my_image.GetWidth() / 2);
}
Plymouth.SetMessageFunction(message_callback);
PLYMOUTHSCRIPT

# Logo Plymouth
cat > /usr/share/plymouth/themes/rizzoos/logo.svg << 'PLYLOGO'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 100">
  <text x="150" y="70" text-anchor="middle" font-family="Arial" font-size="60" font-weight="bold" fill="#00d4ff">RizzoOS</text>
</svg>
PLYLOGO

convert -background none /usr/share/plymouth/themes/rizzoos/logo.svg /usr/share/plymouth/themes/rizzoos/logo.png 2>/dev/null || true

# Activer le thème
plymouth-set-default-theme rizzoos || true
update-initramfs -u || true

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
# === FOND D'ÉCRAN RIZZOOS ===
# ============================================
# (Image déjà téléchargée avant le chroot)

# Metadata
cat > /usr/share/wallpapers/RizzoOS/metadata.desktop << 'WALLMETA'
[Desktop Entry]
Name=RizzoOS
X-KDE-PluginInfo-Name=RizzoOS
WALLMETA

# FORCER le wallpaper en remplaçant TOUS les défauts
rm -rf /usr/share/wallpapers/Next 2>/dev/null || true
mkdir -p /usr/share/wallpapers/Next/contents/images
cp /usr/share/wallpapers/RizzoOS/contents/images/1920x1080.png /usr/share/wallpapers/Next/contents/images/1920x1080.png || true
cp /usr/share/wallpapers/RizzoOS/contents/images/1920x1080.png /usr/share/wallpapers/Next/contents/images/3840x2160.png || true
cp /usr/share/wallpapers/RizzoOS/contents/images/1920x1080.png /usr/share/wallpapers/Next/contents/images/5120x2880.png || true

cat > /usr/share/wallpapers/Next/metadata.desktop << 'NEXTMETA'
[Desktop Entry]
Name=Next
X-KDE-PluginInfo-Name=Next
NEXTMETA

# Remplacer aussi desktop-base
mkdir -p /usr/share/desktop-base/active-theme/wallpaper/contents/images/
cp /usr/share/wallpapers/RizzoOS/contents/images/1920x1080.png /usr/share/desktop-base/active-theme/wallpaper/contents/images/1920x1080.png 2>/dev/null || true

# Forcer dans la config Plasma par défaut
mkdir -p /usr/share/plasma/look-and-feel/org.kde.breezedark.desktop/contents/defaults
cat > /usr/share/plasma/look-and-feel/org.kde.breezedark.desktop/contents/defaults/wallpaperTheme << 'PLASMADEF'
[Wallpaper]
defaultWallpaperTheme=RizzoOS
defaultFileSuffix=.png
defaultWidth=1920
defaultHeight=1080
PLASMADEF

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
# Supprimer l'icône Install Debian (on garde seulement Installer RizzoOS)
rm -f /usr/share/applications/calamares-debian.desktop || true
rm -f /usr/share/applications/install-debian.desktop || true
rm -f /home/live/Desktop/calamares-debian.desktop || true
rm -f /home/live/Desktop/install-debian.desktop || true

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
# === THÈME SDDM RIZZOOS ===
# ============================================
mkdir -p /usr/share/sddm/themes/rizzoos

# Télécharger le fond pour SDDM aussi
cp /usr/share/wallpapers/RizzoOS/contents/images/1920x1080.png /usr/share/sddm/themes/rizzoos/background.png 2>/dev/null || true

cat > /usr/share/sddm/themes/rizzoos/theme.conf << 'SDDMTHEME'
[General]
background=/usr/share/sddm/themes/rizzoos/background.png
type=image
SDDMTHEME

cat > /usr/share/sddm/themes/rizzoos/Main.qml << 'SDDMQML'
import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    
    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
    }
}
SDDMQML

cat > /usr/share/sddm/themes/rizzoos/metadata.desktop << 'SDDMMETA'
[SddmGreeterTheme]
Name=RizzoOS
Description=RizzoOS Login Theme
Author=Arnaud
Version=1.0
SDDMMETA
# ============================================
# === AUTOLOGIN SDDM ===
# ============================================
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf << 'SDDM'
[Autologin]
User=live
Session=plasma

[Theme]
Current=rizzoos
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

# Fond d'écran pour utilisateur live
cat > /home/live/.config/plasma-org.kde.plasma.desktop-appletsrc << 'PLASMALIVE'
[Containments][1]
activityId=
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.plasma.folder
wallpaperplugin=org.kde.image

[Containments][1][Wallpaper][org.kde.image][General]
Image=file:///usr/share/wallpapers/RizzoOS/contents/images/1920x1080.png
PreviewImage=file:///usr/share/wallpapers/RizzoOS/contents/images/1920x1080.png
PLASMALIVE

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

cat > /home/live/Desktop/rizzo-navigator.desktop << 'NAVIGATOR'
[Desktop Entry]
Name=Rizzo Navigator
Comment=Navigateur Web RizzoOS
Exec=/usr/local/bin/rizzo-navigator
Icon=web-browser
Type=Application
NAVIGATOR

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

cat > /home/live/Desktop/lamp.desktop << 'LAMPICON'
[Desktop Entry]
Name=Serveur Web
Comment=Démarrer Apache et MariaDB
Exec=konsole -e start-lamp
Icon=server-database
Type=Application
Terminal=false
LAMPICON

cat > /home/live/Desktop/flatpak.desktop << 'FLATPAK'
[Desktop Entry]
Name=Logiciels (Flatpak)
Comment=Installer des applications
Exec=konsole -e bash -c "echo '=== Flatpak ==='; echo 'Pour installer une app:'; echo 'flatpak install flathub nom-app'; echo ''; echo 'Exemples:'; echo 'flatpak install flathub com.spotify.Client'; echo 'flatpak install flathub com.discordapp.Discord'; echo 'flatpak install flathub com.visualstudio.code'; echo ''; echo 'Appuyez sur Entrée...'; read"
Icon=system-software-install
Type=Application
Terminal=false
FLATPAK

cat > /home/live/Desktop/timeshift.desktop << 'TIMESHIFT'
[Desktop Entry]
Name=Timeshift
Comment=Sauvegardes système
Exec=sudo timeshift-gtk
Icon=timeshift
Type=Application
Terminal=false
TIMESHIFT

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
║   🌐 Rizzo Navigator, Chromium                            ║
║   📄 LibreOffice                                          ║
║   🎬 VLC, GIMP, Inkscape, Kdenlive, OBS                   ║
║   🎮 Steam, Lutris, Wine                                  ║
║   🤖 Waydroid (Android)                                   ║
║   🔒 Firewall, KeePassXC, ClamAV                          ║
║   💾 Timeshift (sauvegardes)                              ║
║   📦 Flatpak (magasin d'apps)                             ║
╚═══════════════════════════════════════════════════════════╝
WELCOME

chmod +x /home/live/Desktop/*.desktop
chown -R 1000:1000 /home/live

# ============================================
# === SQUELETTE UTILISATEUR (pour tous les nouveaux users) ===
# ============================================
mkdir -p /etc/skel/Desktop
mkdir -p /etc/skel/.config

# Copier les icônes bureau
cp /home/live/Desktop/*.desktop /etc/skel/Desktop/
cp /home/live/Desktop/Bienvenue.txt /etc/skel/Desktop/

# Copier la config KDE
cp -r /home/live/.config/* /etc/skel/.config/

# Permissions
chmod +x /etc/skel/Desktop/*.desktop

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
# === SCRIPT START LAMP ===
# ============================================
cat > /usr/local/bin/start-lamp << 'STARTLAMP'
#!/bin/bash
echo "======================================"
echo "   Démarrage du serveur web LAMP"
echo "======================================"
sudo systemctl start mariadb
sudo systemctl start apache2
echo ""
echo "✅ Serveur web démarré !"
echo ""
echo "→ http://localhost"
echo "→ http://localhost/phpmyadmin"
echo ""
echo "Appuyez sur Entrée pour fermer..."
read
STARTLAMP
chmod +x /usr/local/bin/start-lamp

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
