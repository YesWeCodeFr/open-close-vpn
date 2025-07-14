# Guide de déploiement - OpenVPN Remote Controller

## 🚀 Déploiement sur serveur de production

### Phase 1 : Préparation du serveur A (serveur de déploiement)

#### 1.1 Vérification des prérequis système
```bash
# Vérifier l'OS et la version
cat /etc/os-release

# Vérifier l'espace disque disponible (minimum 2GB)
df -h

# Vérifier la RAM disponible (minimum 512MB)
free -h

# Vérifier que les ports sont disponibles
netstat -tlnp | grep :3000
```

#### 1.2 Installation de Docker et Docker Compose
```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation de Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER

# Installation de Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Redémarrer la session pour prendre en compte les groupes
newgrp docker

# Vérifier les installations
docker --version
docker-compose --version
```

#### 1.3 Configuration du firewall
```bash
# Ouvrir le port 3000 (ou votre port choisi)
sudo ufw allow 3000/tcp

# Si vous utilisez NGINX en proxy (recommandé)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Activer le firewall si pas déjà fait
sudo ufw enable
sudo ufw status
```

### Phase 2 : Transfert et configuration de l'application

#### 2.1 Transfert des fichiers
```bash
# Option A : Via Git (recommandé)
git clone https://github.com/YesWeCodeFr/open-close-vpn.git
cd open-close-vpn

# Option B : Via SCP depuis votre machine locale
# scp -r ./open-close-vpn user@serveur-a:/home/user/

# Option C : Via rsync
# rsync -avz --exclude node_modules ./open-close-vpn/ user@serveur-a:/home/user/open-close-vpn/
```

#### 2.2 Configuration de l'environnement
```bash
# Copier et éditer le fichier .env
cp .env.example .env
nano .env

# Vérifier les permissions sur la clé SSH
chmod 600 /home/yeswecode/.ssh/id_rsa
```

#### 2.3 Test de connectivité SSH
```bash
# Tester la connexion vers le serveur OpenVPN
./test-ssh.sh

# Si le test échoue, vérifier :
# - La clé SSH est-elle présente et accessible ?
# - Le serveur OpenVPN est-il accessible ?
# - L'utilisateur a-t-il les droits Docker ?
```

### Phase 3 : Déploiement Docker

#### 3.1 Construction et démarrage
```bash
# Méthode automatique
./install.sh

# Ou méthode manuelle :
docker-compose build
docker-compose up -d
```

#### 3.2 Vérification du déploiement
```bash
# Vérifier que les containers tournent
docker-compose ps

# Voir les logs
docker-compose logs -f

# Tester l'accès web
curl -I http://localhost:3000

# Vérifier les processus
docker-compose top
```

### Phase 4 : Configuration de production avec NGINX

#### 4.1 Installation de NGINX
```bash
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
```

#### 4.2 Configuration NGINX
```bash
# Créer la configuration
sudo nano /etc/nginx/sites-available/vpn-controller
```

#### 4.3 Contenu de la configuration NGINX
```nginx
server {
    listen 80;
    server_name votre-domaine.com;  # Remplacez par votre domaine

    # Redirection HTTPS (optionnel)
    # return 301 https://$server_name$request_uri;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Logs
    access_log /var/log/nginx/vpn-controller.access.log;
    error_log /var/log/nginx/vpn-controller.error.log;
}
```

#### 4.4 Activation de la configuration
```bash
# Activer le site
sudo ln -s /etc/nginx/sites-available/vpn-controller /etc/nginx/sites-enabled/

# Désactiver le site par défaut
sudo rm /etc/nginx/sites-enabled/default

# Tester la configuration
sudo nginx -t

# Redémarrer NGINX
sudo systemctl restart nginx
```

### Phase 5 : Sécurisation SSL (optionnel mais recommandé)

#### 5.1 Installation de Certbot
```bash
sudo apt install certbot python3-certbot-nginx -y
```

#### 5.2 Obtention du certificat SSL
```bash
# Remplacez par votre domaine
sudo certbot --nginx -d votre-domaine.com

# Tester le renouvellement automatique
sudo certbot renew --dry-run
```

### Phase 6 : Configuration du démarrage automatique

#### 6.1 Service systemd pour l'application
```bash
sudo nano /etc/systemd/system/vpn-controller.service
```

#### 6.2 Contenu du service
```ini
[Unit]
Description=VPN Controller Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/yeswecode/open-close-vpn
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

#### 6.3 Activation du service
```bash
sudo systemctl daemon-reload
sudo systemctl enable vpn-controller.service
sudo systemctl start vpn-controller.service
sudo systemctl status vpn-controller.service
```

### Phase 7 : Monitoring et maintenance

#### 7.1 Scripts de monitoring
```bash
# Créer un script de vérification
nano ~/check-vpn-controller.sh
```

#### 7.2 Contenu du script de monitoring
```bash
#!/bin/bash
# Script de vérification de l'état du service

echo "=== État du service VPN Controller ==="
echo "Date: $(date)"
echo

# Vérifier Docker Compose
echo "1. État Docker Compose:"
cd /home/yeswecode/open-close-vpn
docker-compose ps

echo -e "\n2. État NGINX:"
sudo systemctl status nginx --no-pager

echo -e "\n3. Test de connectivité:"
curl -s -o /dev/null -w "Code HTTP: %{http_code}\n" http://localhost:3000

echo -e "\n4. Utilisation des ressources:"
docker stats --no-stream

echo -e "\n5. Logs récents:"
docker-compose logs --tail=10
```

#### 7.3 Automatisation des vérifications
```bash
# Rendre le script exécutable
chmod +x ~/check-vpn-controller.sh

# Ajouter au cron pour vérification quotidienne
crontab -e
# Ajouter cette ligne :
# 0 8 * * * /home/yeswecode/check-vpn-controller.sh >> /var/log/vpn-controller-check.log 2>&1
```

### Phase 8 : Sauvegarde et mise à jour

#### 8.1 Script de sauvegarde
```bash
nano ~/backup-vpn-controller.sh
```

#### 8.2 Contenu du script de sauvegarde
```bash
#!/bin/bash
BACKUP_DIR="/home/yeswecode/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Sauvegarder la configuration
tar -czf $BACKUP_DIR/vpn-controller-config-$DATE.tar.gz \
    /home/yeswecode/open-close-vpn/.env \
    /home/yeswecode/open-close-vpn/docker-compose.yml \
    /etc/nginx/sites-available/vpn-controller

echo "Sauvegarde créée: $BACKUP_DIR/vpn-controller-config-$DATE.tar.gz"

# Nettoyer les anciennes sauvegardes (garder 7 jours)
find $BACKUP_DIR -name "vpn-controller-config-*.tar.gz" -mtime +7 -delete
```

#### 8.3 Script de mise à jour
```bash
nano ~/update-vpn-controller.sh
```

#### 8.4 Contenu du script de mise à jour
```bash
#!/bin/bash
cd /home/yeswecode/open-close-vpn

echo "=== Mise à jour VPN Controller ==="

# Sauvegarder avant mise à jour
./backup-vpn-controller.sh

# Arrêter les services
docker-compose down

# Récupérer les mises à jour
git pull origin main

# Reconstruire et redémarrer
docker-compose build --no-cache
docker-compose up -d

# Vérifier que tout fonctionne
sleep 10
docker-compose ps

echo "Mise à jour terminée !"
```

### Phase 9 : Accès et utilisation

#### 9.1 URLs d'accès
- **Direct**: `http://serveur-a:3000`
- **Via NGINX**: `http://votre-domaine.com`
- **Avec SSL**: `https://votre-domaine.com`

#### 9.2 Identifiants de connexion
- **Utilisateur**: admin
- **Mot de passe**: admin (changez-le dans .env !)

#### 9.3 Fonctionnalités disponibles
1. Dashboard de statut en temps réel
2. Contrôles Start/Stop/Restart
3. Consultation des logs
4. Monitoring automatique

## 🔧 Commandes utiles pour la maintenance

```bash
# Redémarrer l'application
docker-compose restart

# Voir les logs en temps réel
docker-compose logs -f

# Mettre à jour l'application
./update-vpn-controller.sh

# Vérifier l'état complet
./check-vpn-controller.sh

# Sauvegarder la configuration
./backup-vpn-controller.sh

# Arrêter temporairement
docker-compose stop

# Arrêter et supprimer
docker-compose down

# Redémarrer avec reconstruction
docker-compose up -d --build
```

## 🚨 Dépannage courant

### Problème : Application inaccessible
```bash
# Vérifier les ports
netstat -tlnp | grep :3000
# Vérifier les logs
docker-compose logs
# Vérifier le firewall
sudo ufw status
```

### Problème : Erreur SSH vers serveur OpenVPN
```bash
# Tester manuellement
ssh -i /home/yeswecode/.ssh/id_rsa debian@ks32g-bhs
# Vérifier les permissions de la clé
ls -la /home/yeswecode/.ssh/id_rsa
```

### Problème : Docker ne démarre pas
```bash
# Vérifier l'espace disque
df -h
# Nettoyer Docker
docker system prune -f
# Redémarrer Docker
sudo systemctl restart docker
```

## ✅ Checklist de déploiement

- [ ] Serveur préparé avec Docker et Docker Compose
- [ ] Firewall configuré
- [ ] Application transférée et configurée
- [ ] Test SSH réussi vers serveur OpenVPN
- [ ] Application démarrée avec Docker
- [ ] NGINX configuré (optionnel)
- [ ] SSL configuré (optionnel)
- [ ] Service de démarrage automatique activé
- [ ] Scripts de monitoring en place
- [ ] Scripts de sauvegarde configurés
- [ ] Test complet de l'interface web
- [ ] Documentation utilisateur fournie

## 📞 Support

En cas de problème, vérifiez :
1. Les logs de l'application
2. La connectivité SSH
3. L'état des containers Docker
4. La configuration NGINX
5. Les permissions des fichiers
