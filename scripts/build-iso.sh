#!/bin/bash
set -e

WORK_DIR="/tmp/rizzo-build"
ISO_OUTPUT="$GITHUB_WORKSPACE/iso/RizzoOS-1.0.iso"

mkdir -p "$WORK_DIR"/{chroot,iso/{boot/grub,live}}
mkdir -p "$(dirname "$ISO_OUTPUT")"

sudo debootstrap --arch=amd64 --variant=minbase bookworm "$WORK_DIR/chroot" http://deb.debian.org/debian

cat << 'EOF' | sudo tee "$WORK_DIR/chroot/etc/apt/sources.list"
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
EOF

sudo mount --bind /dev "$WORK_DIR/chroot/dev"
sudo mount --bind /dev/pts "$WORK_DIR/chroot/dev/pts"
sudo mount -t proc proc "$WORK_DIR/chroot/proc"
sudo mount -t sysfs sysfs "$WORK_DIR/chroot/sys"

sudo chroot "$WORK_DIR/chroot" /bin/bash << 'CHROOT'
export DEBIAN_FRONTEND=noninteractive

dpkg --add-architecture i386
apt-get update

# === SYSTÈME DE BASE ===
apt-get install -y linux-image-amd64 live-boot systemd-sysv sudo firmware-linux

# === KDE PLASMA ===
apt-get install -y kde-plasma-desktop sddm dolphin konsole kate ark gwenview okular kcalc kde-spectacle

# === NAVIGATEURS ET APPS ===
apt-get install -y firefox-esr libreoffice vlc gimp

# === WINE (Apps Windows) ===
apt-get install -y wine wine64 wine32 winetricks

# === OUTILS SYSTÈME ===
apt-get install -y htop neofetch git curl wget nano gparted

# === SÉCURITÉ ===
apt-get install -y ufw apparmor

# === RÉSEAU ===
apt-get install -y network-manager plasma-nm

# === AUDIO ===
apt-get install -y pipewire pipewire-audio pipewire-pulse wireplumber

# === CRÉER UTILISATEUR RIZZO ===
useradd -m -s /bin/bash -G sudo,audio,video,cdrom,plugdev,netdev rizzo
echo "rizzo:rizzo" | chpasswd
echo "root:root" | chpasswd

# === AUTOLOGIN SDDM ===
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf << 'SDDM'
[Autologin]
User=rizzo
Session=plasma
SDDM

# === BRANDING RIZZOOS ===
echo "RizzoOS" > /etc/hostname
cat > /etc/os-release << 'OSREL'
PRETTY_NAME="RizzoOS 1.0 (Valais)"
NAME="RizzoOS"
VERSION_ID="1.0"
VERSION="1.0 (Valais)"
ID=rizzoos
ID_LIKE=debian
HOME_URL="https://rizzoos.ch"
SUPPORT_URL="https://rizzoos.ch/support"
BUG_REPORT_URL="https://rizzoos.ch/bugs"
OSREL

cat > /etc/lsb-release << 'LSB'
DISTRIB_ID=RizzoOS
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=Valais
DISTRIB_DESCRIPTION="RizzoOS 1.0 (Valais)"
LSB

# === ACTIVER SERVICES ===
systemctl enable NetworkManager
systemctl enable ufw
systemctl enable apparmor

# === CONFIGURER UFW ===
ufw default deny incoming
ufw default allow outgoing

# === FORCER RENDU LOGICIEL KWIN (évite les crashs en VM) ===
mkdir -p /home/rizzo/.config
cat > /home/rizzo/.config/kwinrc << 'KWIN'
[Compositing]
Backend=XRender
Enabled=true
GLCore=false
OpenGLIsUnsafe=true
WindowsBlockCompositing=false
KWIN

# === THÈME SOMBRE PAR DÉFAUT ===
cat > /home/rizzo/.config/kdeglobals << 'THEME'
[General]
ColorScheme=BreezeDark

[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
THEME

# === DÉSACTIVER EFFETS 3D ===
cat > /home/rizzo/.config/kwineffectsrc << 'EFFECTS'
[Plugins]
blurEnabled=false
contrastEnabled=false
slidingpopupsEnabled=false
EFFECTS

chown -R 1000:1000 /home/rizzo

# === MESSAGE DE BIENVENUE ===
mkdir -p /home/rizzo/Desktop
cat > /home/rizzo/Desktop/Bienvenue.txt << 'WELCOME'
Bienvenue sur RizzoOS 1.0 (Valais) !

Créé par Arnaud depuis la Suisse.

Identifiants :
- Utilisateur : rizzo
- Mot de passe : rizzo

Logiciels inclus :
- KDE Plasma (bureau)
- Firefox (navigateur)
- LibreOffice (bureautique)
- VLC (multimédia)
- GIMP (images)
- Wine (apps Windows)

Bonne utilisation !
WELCOME
chown -R 1000:1000 /home/rizzo

apt-get clean
CHROOT

sudo umount -lf "$WORK_DIR/chroot/dev/pts" || true
sudo umount -lf "$WORK_DIR/chroot/dev" || true
sudo umount -lf "$WORK_DIR/chroot/proc" || true
sudo umount -lf "$WORK_DIR/chroot/sys" || true

sudo mksquashfs "$WORK_DIR/chroot" "$WORK_DIR/iso/live/filesystem.squashfs" -comp xz

sudo cp "$WORK_DIR/chroot/boot/vmlinuz-"* "$WORK_DIR/iso/boot/vmlinuz"
sudo cp "$WORK_DIR/chroot/boot/initrd.img-"* "$WORK_DIR/iso/boot/initrd"

cat << 'EOF' | sudo tee "$WORK_DIR/iso/boot/grub/grub.cfg"
set timeout=10
set default=0

menuentry "RizzoOS 1.0 (Valais)" {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd
}

menuentry "RizzoOS 1.0 (Mode récupération)" {
    linux /boot/vmlinuz boot=live single
    initrd /boot/initrd
}
EOF

sudo grub-mkrescue -o "$ISO_OUTPUT" "$WORK_DIR/iso"

echo "==================================="
echo "RizzoOS 1.0 (Valais) créé avec succès !"
echo "==================================="