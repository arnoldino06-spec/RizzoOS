# RizzoOS

**Système d'exploitation personnalisé par Arnaud**

## 🎯 Présentation

RizzoOS est une distribution Linux personnalisée basée sur Debian 12 (Bookworm) avec l'environnement de bureau KDE Plasma. Conçu pour l'indépendance, la sécurité et la compatibilité maximale avec les applications Windows, Linux et Android.

## 🔧 Spécifications techniques

| Composant | Choix | Raison |
|-----------|-------|--------|
| Base | Debian 12 Bookworm | Stabilité, support long terme |
| Bureau | KDE Plasma 5.27+ | Personnalisation, gaming, moderne |
| Init | systemd | Standard, compatibilité |
| Noyau | Linux 6.1 LTS | Stabilité + support matériel |

## 📦 Compatibilité applications

### Applications Linux (100%)
- Support natif complet
- Flatpak pré-configuré
- AppImage support

### Applications Windows (~85%)
- **Wine 9.0** - Couche de compatibilité Windows
- **Winetricks** - Installation facile des dépendances
- **Bottles** - Gestionnaire graphique pour Wine
- **Proton-GE** - Pour le gaming via Steam

### Applications Android (~90%)
- **Waydroid** - Conteneur Android complet
- Google Play Store optionnel
- Support ARM via traduction

## 🔒 Sécurité renforcée

### Chiffrement
- LUKS2 pour le chiffrement complet du disque
- Swap chiffré
- Home chiffré séparément (optionnel)

### Pare-feu
- UFW (Uncomplicated Firewall) activé par défaut
- Règles strictes : tout bloqué en entrée sauf SSH (optionnel)
- Fail2ban pour la protection anti-bruteforce

### Vie privée
- Aucune télémétrie
- DNS over HTTPS (DoH) pré-configuré
- VPN intégré (WireGuard + OpenVPN)

### Durcissement système
- AppArmor activé
- Kernel hardening (sysctl)
- Mises à jour de sécurité automatiques

## 🎮 Gaming

- Steam pré-installé
- Proton/Proton-GE pour les jeux Windows
- MangoHud pour monitoring FPS
- GameMode pour optimisation performances
- Lutris pour les jeux non-Steam

## 🛠️ Développement

- Git, curl, wget
- Build-essential
- Node.js LTS
- Python 3.11+
- Docker (optionnel)
- VS Code (Flatpak)

## 🖼️ Multimédia

- VLC Media Player
- GIMP
- Kdenlive (édition vidéo)
- OBS Studio
- Audacity

## 📂 Structure du projet

```
RizzoOS/
├── README.md                   # Ce fichier
├── BUILD.md                    # Instructions de construction
├── GUIDE-TELEPHONE.md          # Guide construction via GitHub
├── .github/
│   └── workflows/
│       └── build-iso.yml       # Construction automatique GitHub
├── config/
│   ├── packages.list           # Liste des paquets à installer
│   ├── flatpak.list            # Applications Flatpak
│   ├── sysctl.conf             # Durcissement kernel
│   ├── ufw-rules.sh            # Règles pare-feu
│   └── calamares/              # Configuration installateur
├── scripts/
│   ├── build-iso.sh            # Script principal de construction
│   ├── configure-system.sh     # Configuration post-install
│   ├── install-wine.sh         # Installation Wine
│   ├── install-waydroid.sh     # Installation Waydroid
│   └── install-gaming.sh       # Outils gaming
├── branding/
│   ├── logo.png                # Logo RizzoOS
│   ├── wallpaper.png           # Fond d'écran
│   └── plymouth-theme/         # Animation de démarrage
└── iso/
    └── (ISO générée ici)
```

## 🚀 Construction

### Option 1 : GitHub Actions (depuis téléphone/navigateur) 📱

Pas besoin de PC Linux ! GitHub construit l'ISO pour toi gratuitement.

1. Crée un compte sur https://github.com
2. Upload ce projet dans un nouveau dépôt
3. Va dans **Actions** → **Build RizzoOS ISO** → **Run workflow**
4. Attends ~45-60 min
5. Télécharge l'ISO dans **Artifacts**

👉 Voir le guide complet : [GUIDE-TELEPHONE.md](GUIDE-TELEPHONE.md)

### Option 2 : Construction locale (PC Linux)

#### Prérequis
- Machine Debian/Ubuntu avec 50 Go d'espace libre
- 8 Go RAM minimum
- Connexion internet

#### Commandes
```bash
# Cloner le projet
cd RizzoOS

# Rendre les scripts exécutables
chmod +x scripts/*.sh

# Construire l'ISO (en root)
sudo ./scripts/build-iso.sh
```

L'ISO sera générée dans `iso/RizzoOS-1.0.iso`

## 📝 Licence

RizzoOS est distribué sous licence GPL v3.
Les composants individuels conservent leurs licences respectives.

---
**RizzoOS** - Créé par Arnaud | Valais, Suisse 🇨🇭
