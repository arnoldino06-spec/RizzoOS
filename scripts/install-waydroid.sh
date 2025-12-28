#!/bin/bash
# ===========================================
# RizzoOS - Installation Waydroid (Android)
# ===========================================
# Permet d'exécuter des applications Android
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
echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   RizzoOS - Installation Waydroid (Android)   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier la compatibilité
log_info "Vérification de la compatibilité..."

# Vérifier si le CPU supporte la virtualisation
if ! grep -E 'vmx|svm' /proc/cpuinfo > /dev/null; then
    log_warning "Virtualisation CPU non détectée. Waydroid pourrait ne pas fonctionner."
fi

# Vérifier Wayland
if [[ -z "$WAYLAND_DISPLAY" ]]; then
    log_warning "Session Wayland non détectée. Waydroid fonctionne mieux sous Wayland."
    log_info "Sur KDE Plasma, vous pouvez activer Wayland dans les paramètres SDDM."
fi

# Installer les dépendances
log_info "Installation des dépendances..."
apt-get update
apt-get install -y \
    curl \
    ca-certificates \
    lxc \
    python3 \
    python3-pip \
    python3-gbinder \
    python3-pyclip \
    weston

# Ajouter le dépôt Waydroid
log_info "Ajout du dépôt Waydroid..."
curl -fsSL https://repo.waydro.id/waydroid.gpg | gpg --dearmor -o /usr/share/keyrings/waydroid.gpg

cat > /etc/apt/sources.list.d/waydroid.list << EOF
deb [signed-by=/usr/share/keyrings/waydroid.gpg] https://repo.waydro.id/ bookworm main
EOF

# Installer Waydroid
log_info "Installation de Waydroid..."
apt-get update
apt-get install -y waydroid

# Initialiser Waydroid
log_info "Initialisation de Waydroid..."
echo ""
echo "Choisissez le type d'image Android :"
echo "1) VANILLA - Android pur (sans Google)"
echo "2) GAPPS   - Android avec Google Play Services"
echo ""
read -p "Votre choix [1/2]: " choice

case $choice in
    2)
        log_info "Téléchargement de l'image GAPPS..."
        waydroid init -s GAPPS
        ;;
    *)
        log_info "Téléchargement de l'image VANILLA..."
        waydroid init
        ;;
esac

# Activer le service
log_info "Activation du service Waydroid..."
systemctl enable waydroid-container
systemctl start waydroid-container

# Créer un script de lancement facile
cat > /usr/local/bin/android << 'EOF'
#!/bin/bash
# Lancer Waydroid (Android sur RizzoOS)

case "$1" in
    start)
        waydroid session start &
        sleep 3
        waydroid show-full-ui
        ;;
    stop)
        waydroid session stop
        ;;
    app)
        shift
        waydroid app launch "$@"
        ;;
    install)
        shift
        waydroid app install "$@"
        ;;
    *)
        echo "Usage: android {start|stop|app <package>|install <apk>}"
        echo ""
        echo "Commandes:"
        echo "  start          - Démarrer Android"
        echo "  stop           - Arrêter Android"
        echo "  app <package>  - Lancer une application"
        echo "  install <apk>  - Installer un APK"
        ;;
esac
EOF
chmod +x /usr/local/bin/android

# Instructions finales
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Waydroid installé avec succès !${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "   ${YELLOW}Commandes utiles:${NC}"
echo ""
echo -e "   ${BLUE}android start${NC}     - Démarrer Android"
echo -e "   ${BLUE}android stop${NC}      - Arrêter Android"
echo -e "   ${BLUE}android install fichier.apk${NC} - Installer un APK"
echo ""
echo -e "   ${YELLOW}Accéder au Play Store (si GAPPS):${NC}"
echo -e "   Le Play Store sera disponible dans l'interface Android"
echo ""
echo -e "   ${YELLOW}Note:${NC} Pour de meilleures performances, utilisez"
echo -e "   une session Wayland (KDE Plasma Wayland)"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
