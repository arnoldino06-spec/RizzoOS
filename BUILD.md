# RizzoOS - Guide de Construction

## Prérequis

### Matériel
- **Espace disque** : 50 Go minimum
- **RAM** : 8 Go minimum (16 Go recommandé)
- **Processeur** : x86_64, 4 cœurs minimum
- **Connexion internet** : Requise pour télécharger les paquets

### Système hôte
Tu dois construire RizzoOS depuis une machine Debian/Ubuntu :
- Debian 11/12
- Ubuntu 22.04/24.04
- Linux Mint 21+

## Construction de l'ISO

### Étape 1 : Préparation

```bash
# Cloner ou copier le projet RizzoOS
cd RizzoOS

# Rendre les scripts exécutables
chmod +x scripts/*.sh
chmod +x config/*.sh
```

### Étape 2 : Construire l'ISO

```bash
# Lancer la construction (en root)
sudo ./scripts/build-iso.sh
```

⏱️ **Durée estimée** : 30-60 minutes selon ta connexion internet

### Étape 3 : Résultat

L'ISO sera créée dans :
```
iso/RizzoOS-1.0.iso
```

## Test de l'ISO

### Avec QEMU (recommandé pour tester)

```bash
# Installer QEMU si nécessaire
sudo apt install qemu-system-x86 qemu-kvm

# Lancer RizzoOS en machine virtuelle
qemu-system-x86_64 \
    -m 4G \
    -enable-kvm \
    -cpu host \
    -smp 4 \
    -cdrom iso/RizzoOS-1.0.iso \
    -boot d
```

### Avec VirtualBox

1. Créer une nouvelle VM (Type: Linux, Version: Debian 64-bit)
2. RAM : 4096 Mo
3. Créer un disque virtuel de 40 Go
4. Paramètres > Stockage > Ajouter l'ISO comme CD
5. Démarrer la VM

## Création d'une clé USB bootable

### Méthode dd (Linux)

```bash
# Identifier ta clé USB
lsblk

# Créer la clé bootable (remplace sdX par ta clé)
sudo dd if=iso/RizzoOS-1.0.iso of=/dev/sdX bs=4M status=progress sync
```

⚠️ **ATTENTION** : `dd` efface tout le contenu de la clé !

### Avec Ventoy (recommandé)

1. Installer Ventoy sur une clé USB : https://ventoy.net
2. Copier simplement `RizzoOS-1.0.iso` sur la clé
3. Tu peux avoir plusieurs ISOs sur la même clé !

### Avec Balena Etcher (Windows/Mac/Linux)

1. Télécharger Etcher : https://etcher.balena.io
2. Sélectionner l'ISO RizzoOS
3. Sélectionner ta clé USB
4. Cliquer sur "Flash!"

## Installation sur disque dur

### Depuis le Live

1. Démarrer sur la clé USB RizzoOS
2. Utiliser l'installateur Calamares (sera ajouté)
3. Suivre les instructions à l'écran

### Installation manuelle (avancé)

```bash
# Depuis le live, ouvrir un terminal

# Partitionner le disque (exemple avec /dev/sda)
sudo cfdisk /dev/sda
# Créer : 512M EFI, reste pour /

# Formater
sudo mkfs.fat -F32 /dev/sda1
sudo mkfs.ext4 /dev/sda2

# Monter
sudo mount /dev/sda2 /mnt
sudo mkdir -p /mnt/boot/efi
sudo mount /dev/sda1 /mnt/boot/efi

# Copier le système
sudo unsquashfs -f -d /mnt /run/live/medium/live/filesystem.squashfs

# Installer GRUB
sudo grub-install --target=x86_64-efi --efi-directory=/mnt/boot/efi --boot-directory=/mnt/boot --removable
sudo chroot /mnt update-grub

# Configurer fstab
# ... (à compléter selon ta config)
```

## Post-Installation

### Installer les applications Android (Waydroid)

```bash
sudo ./scripts/install-waydroid.sh
```

### Installer la suite Gaming

```bash
sudo ./scripts/install-gaming.sh
```

### Configurer le pare-feu

```bash
sudo ./config/ufw-rules.sh
```

## Personnalisation

### Changer le fond d'écran
Remplacer le fichier dans `branding/wallpaper.png` avant la construction.

### Ajouter des paquets
Éditer `config/packages.list` pour ajouter des paquets Debian.

### Ajouter des Flatpaks
Éditer `config/flatpak.list` pour ajouter des applications Flatpak.

## Dépannage

### L'ISO ne boote pas
- Vérifier que Secure Boot est désactivé dans le BIOS
- Essayer le mode Legacy/CSM au lieu d'UEFI

### Écran noir au démarrage
- Au boot GRUB, éditer la ligne et ajouter `nomodeset`
- Installer les pilotes graphiques appropriés après l'installation

### Waydroid ne démarre pas
- S'assurer que tu es en session Wayland (pas X11)
- Vérifier que le CPU supporte la virtualisation (VT-x/AMD-V)

## Support

Pour toute question ou problème, créer une issue sur le dépôt GitHub.

---
**RizzoOS** - Construit avec ❤️ par Arnaud
