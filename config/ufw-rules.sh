#!/bin/bash
# ===========================================
# RizzoOS - Configuration Pare-feu UFW
# ===========================================

set -e

echo "🔒 Configuration du pare-feu RizzoOS..."

# Réinitialiser UFW
ufw --force reset

# Politique par défaut : bloquer tout en entrée, autoriser en sortie
ufw default deny incoming
ufw default allow outgoing

# Autoriser les connexions établies
ufw allow in on lo

# --- Règles optionnelles (décommenter si nécessaire) ---

# SSH (décommenter pour accès distant)
# ufw allow 22/tcp comment 'SSH'

# Serveur Web (décommenter si serveur web local)
# ufw allow 80/tcp comment 'HTTP'
# ufw allow 443/tcp comment 'HTTPS'

# KDE Connect (pour synchronisation téléphone)
ufw allow 1714:1764/tcp comment 'KDE Connect TCP'
ufw allow 1714:1764/udp comment 'KDE Connect UDP'

# Samba/Partage réseau local (décommenter si partage de fichiers)
# ufw allow from 192.168.0.0/16 to any port 445 comment 'Samba'
# ufw allow from 192.168.0.0/16 to any port 139 comment 'NetBIOS'

# mDNS / Avahi (découverte réseau local)
ufw allow 5353/udp comment 'mDNS'

# CUPS (impression réseau)
ufw allow 631 comment 'CUPS Printing'

# Steam (Remote Play)
# ufw allow 27031:27036/udp comment 'Steam Remote Play'
# ufw allow 27036/tcp comment 'Steam Remote Play'

# --- Activer le pare-feu ---
ufw --force enable

# Afficher le statut
echo ""
echo "✅ Pare-feu RizzoOS configuré !"
echo ""
ufw status verbose
