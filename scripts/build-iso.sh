#!/bin/bash
# ===========================================
# RizzoOS - Script de construction ISO
# ===========================================
# Ce script crée une ISO installable de RizzoOS
# Basé sur Debian 12 + KDE Plasma
# ===========================================

set -e

# --- Configuration ---
RIZZO_VERSION="1.0"
RIZZO_NAME="RizzoOS"
RIZZO_CODENAME="Valais"
WORK_DIR="/tmp/rizzo-build"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ISO_OUTPUT="${SCRIPT_DIR}/iso/${RIZZO_NAME}-${RIZZO_VERSION}.iso"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Fonctions ---
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en root (sudo)"
    fi
}

check_dependencies() {
    log_info "Vérification des dépendances..."
    
    local deps=(debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools)
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! dpkg -l | grep -q "^ii  $dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_info "Installation des dépendances manquantes: ${missing[*]}"
        apt-get update
        apt-get install -y "${missing[@]}"
    fi
    
    log_success "Dépendances OK"
}

setup_workspace() {
    log_info "Préparation de l'espace de travail..."
    
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"/{chroot,iso/{boot/grub,live,EFI/BOOT}}
    mkdir -p "$(dirname "$ISO_OUTPUT")"
    
    log_success "Espace de travail prêt: $WORK_DIR"
}

bootstrap_system() {
    log_info "Bootstrap du système Debian 12..."
    
    debootstrap --arch=amd64 --variant=minbase \
        --include=systemd,systemd-sysv,dbus \
        bookworm "$WORK_DIR/chroot" http://deb.debian.org/debian
    
    log_success "Bootstrap terminé"
}

configure_apt() {
    log_info "Configuration des dépôts APT..."
    
    cat > "$WORK_DIR/chroot/etc/apt/sources.list" << 'EOF'
# Debian 12 Bookworm - RizzoOS
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

# Backports (pour logiciels plus récents)
deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
EOF
    
    log_success "Dépôts configurés"
}

configure_chroot() {
    log_info "Configuration de l'environnement chroot..."
    
    # Monter les systèmes de fichiers virtuels
    mount --bind /dev "$WORK_DIR/chroot/dev"
    mount --bind /dev/pts "$WORK_DIR/chroot/dev/pts"
    mount -t proc proc "$WORK_DIR/chroot/proc"
    mount -t sysfs sysfs "$WORK_DIR/chroot/sys"
    
    # Copier resolv.conf pour le réseau
    cp /etc/resolv.conf "$WORK_DIR/chroot/etc/resolv.conf"
    
    log_success "Chroot configuré"
}

cleanup_chroot() {
    log_info "Nettoyage du chroot..."
    
    umount -lf "$WORK_DIR/chroot/dev/pts" 2>/dev/null || true
    umount -lf "$WORK_DIR/chroot/dev" 2>/dev/null || true
    umount -lf "$WORK_DIR/chroot/proc" 2>/dev/null || true
    umount -lf "$WORK_DIR/chroot/sys" 2>/dev/null || true
    
    log_success "Chroot nettoyé"
}

install_packages() {
    log_info "Installation des paquets RizzoOS..."
    
    # Script d'installation à exécuter dans le chroot
    cat > "$WORK_DIR/chroot/tmp/install.sh" << 'INSTALL_SCRIPT'
#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# Configurer les locales
apt-get update
apt-get install -y locales
sed -i 's/# fr_FR.UTF-8/fr_FR.UTF-8/' /etc/locale.gen
sed -i 's/# fr_CH.UTF-8/fr_CH.UTF-8/' /etc/locale.gen
sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=fr_CH.UTF-8

# Configurer le clavier suisse français
echo 'XKBLAYOUT="ch"' > /etc/default/keyboard
echo 'XKBVARIANT="fr"' >> /etc/default/keyboard

# Activer i386 pour Wine
dpkg --add-architecture i386
apt-get update

# Installer le noyau et les paquets essentiels
apt-get install -y \
    linux-image-amd64 \
    linux-headers-amd64 \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    live-boot \
    sudo \
    console-setup \
    keyboard-configuration

# Installer KDE Plasma
apt-get install -y \
    kde-plasma-desktop \
    plasma-workspace \
    plasma-nm \
    plasma-pa \
    sddm \
    dolphin \
    konsole \
    kate \
    ark \
    gwenview \
    okular \
    kcalc \
    spectacle

# Installer les applications essentielles
apt-get install -y \
    firefox-esr \
    firefox-esr-l10n-fr \
    vlc \
    libreoffice \
    libreoffice-l10n-fr \
    gimp \
    git \
    curl \
    wget \
    htop \
    neofetch

# Installer les outils de sécurité
apt-get install -y \
    ufw \
    gufw \
    fail2ban \
    apparmor \
    apparmor-utils \
    cryptsetup

# Installer Wine
apt-get install -y \
    wine \
    wine64 \
    wine32:i386 \
    winetricks || true

# Installer Flatpak
apt-get install -y \
    flatpak \
    plasma-discover-backend-flatpak

# Configurer Flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

# Installer les codecs multimédia
apt-get install -y \
    ffmpeg \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav

# Installer PipeWire (audio moderne)
apt-get install -y \
    pipewire \
    pipewire-audio \
    pipewire-pulse \
    wireplumber

# Thèmes et polices
apt-get install -y \
    papirus-icon-theme \
    fonts-noto \
    fonts-liberation

# Installer Calamares (installateur graphique)
apt-get install -y \
    calamares \
    calamares-settings-debian \
    qml-module-qtquick2 \
    qml-module-qtquick-controls \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts \
    qml-module-qtquick-window2

# Nettoyer
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

# Activer les services
systemctl enable sddm
systemctl enable NetworkManager
systemctl enable ufw
systemctl enable apparmor

echo "✅ Installation des paquets terminée"
INSTALL_SCRIPT

    chmod +x "$WORK_DIR/chroot/tmp/install.sh"
    chroot "$WORK_DIR/chroot" /tmp/install.sh
    rm "$WORK_DIR/chroot/tmp/install.sh"
    
    log_success "Paquets installés"
}

configure_system() {
    log_info "Configuration du système RizzoOS..."
    
    # Hostname
    echo "rizzo" > "$WORK_DIR/chroot/etc/hostname"
    
    # Hosts
    cat > "$WORK_DIR/chroot/etc/hosts" << EOF
127.0.0.1   localhost
127.0.1.1   rizzo

::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF
    
    # OS Release
    cat > "$WORK_DIR/chroot/etc/os-release" << EOF
PRETTY_NAME="RizzoOS ${RIZZO_VERSION} (${RIZZO_CODENAME})"
NAME="RizzoOS"
VERSION_ID="${RIZZO_VERSION}"
VERSION="${RIZZO_VERSION} (${RIZZO_CODENAME})"
VERSION_CODENAME=${RIZZO_CODENAME,,}
ID=rizzo
ID_LIKE=debian
HOME_URL="https://github.com/arnaud/rizzoos"
SUPPORT_URL="https://github.com/arnaud/rizzoos/issues"
BUG_REPORT_URL="https://github.com/arnaud/rizzoos/issues"
EOF
    
    # Créer un utilisateur par défaut pour le Live
    chroot "$WORK_DIR/chroot" useradd -m -s /bin/bash -G sudo,audio,video,cdrom,plugdev rizzo || true
    echo "rizzo:rizzo" | chroot "$WORK_DIR/chroot" chpasswd
    
    # Autoriser sudo sans mot de passe pour le live
    echo "rizzo ALL=(ALL) NOPASSWD:ALL" > "$WORK_DIR/chroot/etc/sudoers.d/rizzo-live"
    
    # Copier la configuration sysctl
    if [[ -f "$SCRIPT_DIR/config/sysctl.conf" ]]; then
        cp "$SCRIPT_DIR/config/sysctl.conf" "$WORK_DIR/chroot/etc/sysctl.d/99-rizzo-hardening.conf"
    fi
    
    # Message de bienvenue
    cat > "$WORK_DIR/chroot/etc/motd" << 'EOF'

  ██████╗ ██╗███████╗███████╗ ██████╗  ██████╗ ███████╗
  ██╔══██╗██║╚══███╔╝╚══███╔╝██╔═══██╗██╔═══██╗██╔════╝
  ██████╔╝██║  ███╔╝   ███╔╝ ██║   ██║██║   ██║███████╗
  ██╔══██╗██║ ███╔╝   ███╔╝  ██║   ██║██║   ██║╚════██║
  ██║  ██║██║███████╗███████╗╚██████╔╝╚██████╔╝███████║
  ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝
                                                        
  Bienvenue sur RizzoOS - Votre système indépendant
  
EOF
    
    log_success "Système configuré"
}

configure_calamares() {
    log_info "Configuration de Calamares (installateur graphique)..."
    
    # Créer les dossiers Calamares
    mkdir -p "$WORK_DIR/chroot/etc/calamares/branding/rizzoos"
    mkdir -p "$WORK_DIR/chroot/etc/calamares/modules"
    
    # Copier les configurations
    if [[ -d "$SCRIPT_DIR/config/calamares" ]]; then
        cp "$SCRIPT_DIR/config/calamares/settings.conf" "$WORK_DIR/chroot/etc/calamares/"
        cp "$SCRIPT_DIR/config/calamares/modules/"*.conf "$WORK_DIR/chroot/etc/calamares/modules/"
        cp "$SCRIPT_DIR/config/calamares/branding/rizzoos/"* "$WORK_DIR/chroot/etc/calamares/branding/rizzoos/"
    fi
    
    # Créer le lanceur sur le bureau
    mkdir -p "$WORK_DIR/chroot/etc/skel/Desktop"
    cat > "$WORK_DIR/chroot/etc/skel/Desktop/install-rizzoos.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Installer RizzoOS
Name[fr]=Installer RizzoOS
Comment=Install this system to your hard drive
Comment[fr]=Installer ce système sur votre disque dur
Exec=pkexec calamares
Icon=calamares
Terminal=false
Categories=System;
StartupNotify=true
EOF
    chmod +x "$WORK_DIR/chroot/etc/skel/Desktop/install-rizzoos.desktop"
    
    # Copier aussi pour l'utilisateur live
    mkdir -p "$WORK_DIR/chroot/home/rizzo/Desktop"
    cp "$WORK_DIR/chroot/etc/skel/Desktop/install-rizzoos.desktop" "$WORK_DIR/chroot/home/rizzo/Desktop/"
    chroot "$WORK_DIR/chroot" chown -R rizzo:rizzo /home/rizzo/Desktop
    
    # Créer une image placeholder pour le branding
    cat > "$WORK_DIR/chroot/etc/calamares/branding/rizzoos/show.qml" << 'QMLEOF'
import QtQuick 2.5

Rectangle {
    id: root
    width: 800
    height: 450
    color: "#1a1a2e"
    
    Text {
        anchors.centerIn: parent
        text: "Installation de RizzoOS en cours..."
        color: "#ffffff"
        font.pointSize: 24
        font.bold: true
    }
    
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        text: "Votre système indépendant et sécurisé"
        color: "#58b5f0"
        font.pointSize: 14
    }
}
QMLEOF
    
    log_success "Calamares configuré"
}

create_squashfs() {
    log_info "Création du système de fichiers SquashFS..."
    
    # Nettoyer les fichiers temporaires
    rm -rf "$WORK_DIR/chroot/tmp/"*
    rm -f "$WORK_DIR/chroot/etc/resolv.conf"
    
    # Créer le SquashFS
    mksquashfs "$WORK_DIR/chroot" "$WORK_DIR/iso/live/filesystem.squashfs" \
        -comp xz -b 1M -Xbcj x86 -e boot
    
    log_success "SquashFS créé"
}

setup_bootloader() {
    log_info "Configuration du bootloader GRUB..."
    
    # Copier le noyau et l'initrd
    cp "$WORK_DIR/chroot/boot/vmlinuz-"* "$WORK_DIR/iso/boot/vmlinuz"
    cp "$WORK_DIR/chroot/boot/initrd.img-"* "$WORK_DIR/iso/boot/initrd"
    
    # Configuration GRUB
    cat > "$WORK_DIR/iso/boot/grub/grub.cfg" << 'EOF'
set timeout=10
set default=0

insmod all_video
insmod gfxterm
set gfxmode=auto
terminal_output gfxterm

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "RizzoOS - Démarrer en Live" {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd
}

menuentry "RizzoOS - Démarrer et Installer" {
    linux /boot/vmlinuz boot=live quiet splash systemd.unit=graphical.target
    initrd /boot/initrd
}

menuentry "RizzoOS - Mode sans échec (nomodeset)" {
    linux /boot/vmlinuz boot=live nomodeset
    initrd /boot/initrd
}

menuentry "RizzoOS - Mode texte (dépannage)" {
    linux /boot/vmlinuz boot=live systemd.unit=multi-user.target
    initrd /boot/initrd
}

menuentry "Démarrer depuis le disque dur" {
    set root=(hd0)
    chainloader +1
}
EOF
    
    log_success "Bootloader configuré"
}

create_iso() {
    log_info "Création de l'image ISO..."
    
    # Créer l'ISO avec support UEFI et BIOS
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "RIZZOOS" \
        -output "$ISO_OUTPUT" \
        -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
        --grub2-boot-info \
        --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        -eltorito-alt-boot \
        -e EFI/efiboot.img \
        -no-emul-boot \
        -append_partition 2 0xef "$WORK_DIR/iso/EFI/efiboot.img" \
        -m "EFI/efiboot.img" \
        "$WORK_DIR/iso" 2>/dev/null || {
        
        # Fallback: ISO simple sans UEFI
        log_warning "Création ISO simplifiée (BIOS uniquement)..."
        grub-mkrescue -o "$ISO_OUTPUT" "$WORK_DIR/iso"
    }
    
    log_success "ISO créée: $ISO_OUTPUT"
}

show_summary() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   RizzoOS ${RIZZO_VERSION} - Construction terminée !${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "   📀 ISO: ${BLUE}$ISO_OUTPUT${NC}"
    echo -e "   📦 Taille: $(du -h "$ISO_OUTPUT" | cut -f1)"
    echo ""
    echo -e "   ${YELLOW}Pour tester avec QEMU:${NC}"
    echo -e "   qemu-system-x86_64 -m 4G -enable-kvm -cdrom $ISO_OUTPUT"
    echo ""
    echo -e "   ${YELLOW}Pour créer une clé USB bootable:${NC}"
    echo -e "   sudo dd if=$ISO_OUTPUT of=/dev/sdX bs=4M status=progress"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
}

# --- Main ---
main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   RizzoOS ${RIZZO_VERSION} - Construction ISO   ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    
    check_root
    check_dependencies
    setup_workspace
    bootstrap_system
    configure_apt
    configure_chroot
    
    trap cleanup_chroot EXIT
    
    install_packages
    configure_system
    configure_calamares
    
    cleanup_chroot
    trap - EXIT
    
    create_squashfs
    setup_bootloader
    create_iso
    
    # Nettoyer
    rm -rf "$WORK_DIR"
    
    show_summary
}

main "$@"
