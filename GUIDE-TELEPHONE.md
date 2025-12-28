# 📱 Construire RizzoOS depuis ton téléphone

Guide pas à pas pour créer ton ISO sans avoir de PC Linux.

## Étape 1 : Créer un compte GitHub

1. Va sur https://github.com
2. Clique **Sign up**
3. Entre ton email, mot de passe, pseudo
4. Confirme ton email

## Étape 2 : Créer un nouveau dépôt

1. Connecte-toi sur GitHub
2. Clique le **+** en haut à droite → **New repository**
3. Nom : `RizzoOS`
4. Laisse **Public** coché
5. Clique **Create repository**

## Étape 3 : Uploader les fichiers

### Option A : Depuis le navigateur (plus simple)

1. Sur ton dépôt vide, clique **uploading an existing file**
2. Décompresse d'abord le ZIP sur ton téléphone
3. Upload tous les fichiers et dossiers
4. Clique **Commit changes**

### Option B : Depuis l'app GitHub Mobile

1. Installe l'app GitHub sur ton téléphone
2. Connecte-toi
3. Va sur ton dépôt
4. Upload les fichiers

## Étape 4 : Lancer la construction

1. Va sur ton dépôt GitHub
2. Clique l'onglet **Actions** (en haut)
3. Clique **Build RizzoOS ISO** (à gauche)
4. Clique **Run workflow** (bouton vert à droite)
5. Laisse les valeurs par défaut
6. Clique **Run workflow**

## Étape 5 : Attendre (~45-60 min)

Tu peux suivre la progression :
- 🟡 En cours (jaune)
- ✅ Terminé (vert)
- ❌ Erreur (rouge)

## Étape 6 : Télécharger l'ISO

1. Une fois terminé (vert ✅), clique sur le job **Build ISO**
2. En bas, dans **Artifacts**, clique **RizzoOS-ISO**
3. Le téléchargement commence automatiquement

## Étape 7 : Créer ta clé USB

Tu auras besoin d'un PC (Windows, Mac ou Linux) pour :
1. Télécharger l'ISO depuis GitHub
2. Utiliser Balena Etcher ou Ventoy pour créer la clé USB bootable

---

## ❓ Problèmes fréquents

### "Actions" n'apparaît pas
→ Va dans Settings → Actions → General → Coche "Allow all actions"

### La construction échoue
→ Clique sur le job rouge pour voir l'erreur
→ Souvent c'est un problème d'espace disque ou timeout

### Je ne trouve pas l'ISO
→ Les artifacts expirent après 7 jours
→ Relance le workflow si besoin

---

## 📊 Limites GitHub Actions (gratuit)

| Ressource | Limite |
|-----------|--------|
| Temps par job | 6 heures max |
| Stockage artifacts | 500 Mo |
| Minutes/mois | 2000 min |

RizzoOS utilise ~45-60 min et ~2-3 Go, ça passe !

---

## 🎉 Résumé

```
📱 Téléphone
     │
     ▼
🌐 GitHub.com
     │
     ▼
🖥️ Serveur Linux GitHub (gratuit)
     │
     ▼
💿 RizzoOS-1.0.iso
     │
     ▼
📥 Télécharger sur PC
     │
     ▼
💾 Clé USB bootable
     │
     ▼
🚀 Installer RizzoOS !
```

C'est tout ! Tu peux créer ton propre OS depuis ton canapé avec juste ton téléphone 🎉
