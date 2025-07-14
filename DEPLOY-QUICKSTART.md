# 🚀 Plan de déploiement étape par étape - OpenVPN Remote Controller

## RÉSUMÉ RAPIDE

Votre solution est prête ! Voici les étapes pour déployer sur votre serveur :

### ⚡ Déploiement rapide (méthode automatisée)

```bash
# 1. Transférer les fichiers sur votre serveur
scp -r . user@votre-serveur:/home/user/open-close-vpn

# 2. Se connecter au serveur
ssh user@votre-serveur

# 3. Aller dans le répertoire
cd /home/user/open-close-vpn

# 4. Valider l'environnement
./pre-deploy-check.sh

# 5. Déployer automatiquement
./deploy.sh production
```

### 📋 Étapes détaillées

## PHASE 1 : Préparation du serveur

### 1.1 Transférer l'application
```bash
# Option A : Via Git (recommandé)
git clone https://github.com/YesWeCodeFr/open-close-vpn.git
cd open-close-vpn

# Option B : Via SCP depuis votre machine locale
scp -r ./open-close-vpn user@serveur-a:/home/user/

# Option C : Via rsync
rsync -avz --exclude node_modules ./ user@serveur-a:/home/user/open-close-vpn/
```

### 1.2 Configuration initiale sur le serveur
```bash
# Se connecter au serveur
ssh user@serveur-a

# Aller dans le répertoire
cd /home/user/open-close-vpn

# Configurer les permissions
chmod +x *.sh

# Éditer la configuration si nécessaire
nano .env
```

## PHASE 2 : Validation pré-déploiement

### 2.1 Exécuter la validation
```bash
./pre-deploy-check.sh
```

Cette commande vérifie :
- ✅ Prérequis système (espace disque, RAM)
- ✅ Installation Docker/Docker Compose
- ✅ Disponibilité des ports
- ✅ Fichiers de configuration
- ✅ Connectivité SSH vers serveur OpenVPN
- ✅ Accès Docker sur serveur distant
- ✅ Présence du container OpenVPN

### 2.2 Corriger les erreurs éventuelles
Si des erreurs sont détectées :

**Docker manquant :**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

**Note :** Docker moderne inclut Docker Compose intégré. Si vous avez une version ancienne de Docker, mettez-la à jour.

**Problème SSH :**
```bash
# Tester manuellement
ssh -i /home/yeswecode/.ssh/id_rsa debian@ks32g-bhs

# Vérifier les permissions de la clé
chmod 600 /home/yeswecode/.ssh/id_rsa
```

## PHASE 3 : Déploiement automatisé

### 3.1 Lancer le déploiement
```bash
./deploy.sh production
```

Ce script fait automatiquement :
- 🔧 Installation des prérequis manquants
- 🔥 Configuration du firewall
- 🔗 Test de connectivité SSH
- 🏗️ Construction et démarrage Docker
- 🌐 Configuration NGINX (optionnel)
- ⚙️ Configuration du service systemd
- 🔧 Création des scripts de maintenance

### 3.2 Validation du déploiement
```bash
# Vérifier que l'application fonctionne
curl http://localhost:3000

# Voir les logs
docker compose logs -f

# Vérifier les containers
docker compose ps
```

## PHASE 4 : Accès et utilisation

### 4.1 URLs d'accès
- **Direct :** `http://votre-serveur:3000`
- **Via NGINX :** `http://votre-serveur` (port 80)

### 4.2 Identifiants
- **Utilisateur :** `admin`
- **Mot de passe :** `admin` (changez-le dans .env !)

### 4.3 Fonctionnalités disponibles
1. 📊 **Dashboard** : Statut en temps réel du serveur OpenVPN
2. 🎮 **Contrôles** : Start/Stop/Restart du container
3. 📝 **Logs** : Consultation des logs du container
4. 🔄 **Auto-refresh** : Mise à jour automatique du statut

## PHASE 5 : Maintenance

### 5.1 Scripts créés automatiquement
```bash
./check-status.sh    # Vérifier l'état complet
./backup.sh          # Sauvegarder la configuration
./update.sh          # Mettre à jour l'application
```

### 5.2 Commandes utiles
```bash
# Redémarrer l'application
docker compose restart

# Voir les logs en temps réel
docker compose logs -f

# Arrêter temporairement
docker compose stop

# Redémarrer avec reconstruction
docker compose up -d --build

# Vérifier l'état du service système
sudo systemctl status vpn-controller
```

## PHASE 6 : Sécurisation (production)

### 6.1 Changement du mot de passe
```bash
# Éditer .env
nano .env

# Modifier WEB_PASSWORD
WEB_PASSWORD=votre_mot_de_passe_securise

# Redémarrer
docker compose restart
```

### 6.2 Configuration SSL (optionnel)
```bash
# Installer Certbot
sudo apt install certbot python3-certbot-nginx

# Obtenir un certificat (remplacez votre-domaine.com)
sudo certbot --nginx -d votre-domaine.com
```

### 6.3 Restrictions firewall
```bash
# Limiter l'accès SSH par IP (optionnel)
sudo ufw allow from IP_AUTORISEE to any port 22

# Limiter l'accès web par IP (optionnel)
sudo ufw allow from IP_AUTORISEE to any port 80
sudo ufw allow from IP_AUTORISEE to any port 443
```

## 🚨 Dépannage

### Problème : Application inaccessible
```bash
# Vérifier les ports
netstat -tlnp | grep :3000

# Vérifier les logs
docker compose logs

# Redémarrer
docker compose restart
```

### Problème : Erreur SSH vers OpenVPN
```bash
# Tester manuellement
./test-ssh.sh

# Vérifier la clé SSH
ls -la /home/yeswecode/.ssh/id_rsa
chmod 600 /home/yeswecode/.ssh/id_rsa
```

### Problème : Container OpenVPN non trouvé
```bash
# Se connecter au serveur OpenVPN
ssh debian@ks32g-bhs

# Lister tous les containers
docker ps -a

# Vérifier le nom exact
docker ps -a | grep openvpn
```

## ✅ Checklist finale

- [ ] Application transférée sur le serveur
- [ ] Validation pré-déploiement réussie
- [ ] Déploiement automatisé terminé
- [ ] Interface web accessible
- [ ] Test de connexion SSH vers OpenVPN OK
- [ ] Test des contrôles Start/Stop/Restart
- [ ] Mot de passe changé (production)
- [ ] Scripts de maintenance testés
- [ ] Sauvegarde configurée

## 📞 Support

En cas de problème :

1. **Consulter les logs :** `docker compose logs -f`
2. **Vérifier l'état :** `./check-status.sh`
3. **Tester SSH :** `./test-ssh.sh`
4. **Consulter la documentation :** `cat deploy-guide.md`

---

🎉 **Votre application de contrôle OpenVPN est maintenant déployée et opérationnelle !**
