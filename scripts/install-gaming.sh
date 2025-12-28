#!/bin/bash
# ===========================================
# RizzoOS - Installation Gaming
# ===========================================
# Steam, Proton-GE, Lutris, MangoHud, GameMode
# ===========================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Vérifier root
if [[ $EUID -ne 0 ]]; then
    log_error "Ce script doit être exécuté en root (sudo)"
fi

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   RizzoOS - Installation Gaming Suite     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
echo ""

# Activer i386
log_info "Activation de l'architecture i386..."
dpkg --add-architecture i386
apt-get update

# Installer les pilotes graphiques
log_info "Installation des pilotes graphiques..."

# Détecter le GPU
GPU_VENDOR=""
if lspci | grep -i nvidia > /dev/null; then
    GPU_VENDOR="nvidia"
elif lspci | grep -i amd > /dev/null; then
    GPU_VENDOR="amd"
elif lspci | grep -i intel > /dev/null; then
    GPU_VENDOR="intel"
fi

case $GPU_VENDOR in
    nvidia)
        log_info "GPU NVIDIA détecté - Installation des pilotes..."
        apt-get install -y nvidia-driver nvidia-driver-libs:i386
        ;;
    amd)
        log_info "GPU AMD détecté - Installation des pilotes..."
        apt-get install -y firmware-amd-graphics libgl1-mesa-dri:i386 mesa-vulkan-drivers:i386
        ;;
    intel)
        log_info "GPU Intel détecté - Installation des pilotes..."
        apt-get install -y intel-media-va-driver:i386 mesa-vulkan-drivers:i386
        ;;
    *)
        log_warning "GPU non détecté - Installation des pilotes génériques..."
        apt-get install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386
        ;;
esac

# Installer Vulkan
log_info "Installation de Vulkan..."
apt-get install -y \
    vulkan-tools \
    libvulkan1 \
    libvulkan1:i386

# Installer Wine avec toutes les dépendances gaming
log_info "Installation de Wine gaming..."
apt-get install -y \
    wine \
    wine64 \
    wine32:i386 \
    winetricks \
    libwine:i386 \
    fonts-wine

# Installer GameMode (optimisation CPU/GPU pendant le jeu)
log_info "Installation de GameMode..."
apt-get install -y gamemode

# Activer GameMode pour l'utilisateur courant
REAL_USER="${SUDO_USER:-$USER}"
usermod -aG gamemode "$REAL_USER" 2>/dev/null || true

# Installer MangoHud (overlay FPS/performance)
log_info "Installation de MangoHud..."
apt-get install -y mangohud

# Installer Steam via Flatpak (plus à jour)
log_info "Installation de Steam..."
flatpak install -y flathub com.valvesoftware.Steam

# Installer Lutris (gestionnaire de jeux)
log_info "Installation de Lutris..."
flatpak install -y flathub net.lutris.Lutris

# Installer Heroic Games Launcher (Epic/GOG)
log_info "Installation de Heroic Games Launcher..."
flatpak install -y flathub com.heroicgameslauncher.hgl

# Installer Bottles (Wine avancé)
log_info "Installation de Bottles..."
flatpak install -y flathub com.usebottles.bottles

# Installer Proton-GE (meilleure compatibilité)
log_info "Installation de ProtonUp-Qt pour Proton-GE..."
flatpak install -y flathub net.davidotek.pupgui2

# Créer le script de lancement gaming
cat > /usr/local/bin/rizzo-gaming << 'EOF'
#!/bin/bash
# RizzoOS Gaming Launcher

case "$1" in
    steam)
        gamemoderun flatpak run com.valvesoftware.Steam
        ;;
    lutris)
        gamemoderun flatpak run net.lutris.Lutris
        ;;
    heroic)
        gamemoderun flatpak run com.heroicgameslauncher.hgl
        ;;
    bottles)
        flatpak run com.usebottles.bottles
        ;;
    proton)
        flatpak run net.davidotek.pupgui2
        ;;
    benchmark)
        echo "=== Informations GPU ==="
        vulkaninfo --summary 2>/dev/null || echo "Vulkan non disponible"
        echo ""
        echo "=== Test de performance ==="
        glxgears -info &
        sleep 5
        killall glxgears 2>/dev/null
        ;;
    *)
        echo "RizzoOS Gaming Launcher"
        echo ""
        echo "Usage: rizzo-gaming <commande>"
        echo ""
        echo "Commandes:"
        echo "  steam      - Lancer Steam avec GameMode"
        echo "  lutris     - Lancer Lutris avec GameMode"
        echo "  heroic     - Lancer Heroic (Epic/GOG)"
        echo "  bottles    - Lancer Bottles (Wine)"
        echo "  proton     - Gérer les versions de Proton-GE"
        echo "  benchmark  - Tester les performances GPU"
        echo ""
        echo "Pour activer MangoHud dans un jeu:"
        echo "  MANGOHUD=1 <commande_du_jeu>"
        ;;
esac
EOF
chmod +x /usr/local/bin/rizzo-gaming

# Configuration MangoHud par défaut
mkdir -p /etc/MangoHud
cat > /etc/MangoHud/MangoHud.conf << 'EOF'
# RizzoOS MangoHud Configuration
fps
frametime
cpu_stats
cpu_temp
gpu_stats
gpu_temp
ram
vram
position=top-left
font_size=20
background_alpha=0.5
EOF

# Instructions finales
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Suite Gaming RizzoOS installée !${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "   ${YELLOW}Applications installées:${NC}"
echo -e "   • Steam          - Plateforme de jeux"
echo -e "   • Lutris         - Gestionnaire de jeux multi-plateforme"
echo -e "   • Heroic         - Epic Games & GOG"
echo -e "   • Bottles        - Gestionnaire Wine avancé"
echo -e "   • ProtonUp-Qt    - Installer Proton-GE"
echo -e "   • MangoHud       - Overlay de performance"
echo -e "   • GameMode       - Optimisation automatique"
echo ""
echo -e "   ${YELLOW}Commande rapide:${NC}"
echo -e "   ${BLUE}rizzo-gaming steam${NC}  - Lancer Steam optimisé"
echo ""
echo -e "   ${YELLOW}Activer l'overlay FPS dans un jeu:${NC}"
echo -e "   Steam > Propriétés du jeu > Options de lancement:"
echo -e "   ${BLUE}MANGOHUD=1 gamemoderun %command%${NC}"
echo ""
echo -e "   ${YELLOW}Installer Proton-GE:${NC}"
echo -e "   ${BLUE}rizzo-gaming proton${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
