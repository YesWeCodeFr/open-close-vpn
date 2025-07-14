#!/bin/bash

# Script de déploiement automatisé pour OpenVPN Remote Controller
# Usage: ./deploy.sh [production|staging]

set -e

ENVIRONMENT=${1:-production}
PROJECT_DIR="/home/yeswecode/open-close-vpn"

echo "🚀 Déploiement OpenVPN Remote Controller - Environnement: $ENVIRONMENT"
echo "=================================================================="

# Fonction de vérification des prérequis
check_prerequisites() {
    echo "📋 Vérification des prérequis..."
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker n'est pas installé"
        echo "Installation de Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        echo "✅ Docker installé"
    else
        echo "✅ Docker déjà installé"
    fi
    
    # Vérifier l'espace disque
    AVAILABLE_SPACE=$(df / | awk 'NR==2{print $4}')
    if [ $AVAILABLE_SPACE -lt 2097152 ]; then # 2GB en KB
        echo "⚠️  Attention: Moins de 2GB d'espace disque disponible"
    else
        echo "✅ Espace disque suffisant"
    fi
}

# Configuration du firewall
setup_firewall() {
    echo "🔥 Configuration du firewall..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow 3000/tcp
        if [ "$ENVIRONMENT" = "production" ]; then
            sudo ufw allow 80/tcp
            sudo ufw allow 443/tcp
        fi
        echo "✅ Firewall configuré"
    else
        echo "⚠️  UFW non disponible, configuration manuelle du firewall nécessaire"
    fi
}

# Test de connectivité SSH
test_ssh_connection() {
    echo "🔗 Test de la connexion SSH vers le serveur OpenVPN..."
    
    if [ -f .env ]; then
        source .env
        
        if [ -n "$VPN_SERVER_KEY_PATH" ] && [ -f "$VPN_SERVER_KEY_PATH" ]; then
            echo "🔑 Test avec clé SSH: $VPN_SERVER_KEY_PATH"
            if ssh -i "$VPN_SERVER_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "echo 'Test SSH réussi'" &>/dev/null; then
                echo "✅ Connexion SSH OK"
                return 0
            else
                echo "❌ Échec de la connexion SSH avec clé"
                return 1
            fi
        elif [ -n "$VPN_SERVER_PASSWORD" ]; then
            echo "🔑 Test avec mot de passe"
            if command -v sshpass &> /dev/null; then
                if sshpass -p "$VPN_SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "echo 'Test SSH réussi'" &>/dev/null; then
                    echo "✅ Connexion SSH OK"
                    return 0
                else
                    echo "❌ Échec de la connexion SSH avec mot de passe"
                    return 1
                fi
            else
                echo "⚠️  sshpass non installé, installation..."
                sudo apt update && sudo apt install -y sshpass
            fi
        else
            echo "❌ Aucune méthode d'authentification SSH configurée"
            return 1
        fi
    else
        echo "❌ Fichier .env non trouvé"
        return 1
    fi
}

# Déploiement de l'application
deploy_application() {
    echo "🏗️  Déploiement de l'application..."
    
    # Arrêter les anciens containers s'ils existent
    if [ -f docker-compose.yml ]; then
        docker compose down || true
    fi
    
    # Construction et démarrage
    docker compose build --no-cache
    docker compose up -d
    
    # Attendre que l'application démarre
    echo "⏳ Attente du démarrage de l'application..."
    sleep 15
    
    # Vérifier que l'application répond
    if curl -f -s http://localhost:3000 > /dev/null; then
        echo "✅ Application démarrée avec succès"
    else
        echo "❌ L'application ne répond pas"
        echo "📋 Logs de débogage:"
        docker compose logs
        return 1
    fi
}

# Configuration NGINX pour la production
setup_nginx() {
    if [ "$ENVIRONMENT" = "production" ]; then
        echo "🌐 Configuration de NGINX..."
        
        if ! command -v nginx &> /dev/null; then
            echo "Installation de NGINX..."
            sudo apt update
            sudo apt install -y nginx
            sudo systemctl enable nginx
        fi
        
        # Créer la configuration NGINX
        sudo tee /etc/nginx/sites-available/vpn-controller > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    access_log /var/log/nginx/vpn-controller.access.log;
    error_log /var/log/nginx/vpn-controller.error.log;
}
EOF
        
        # Activer la configuration
        sudo ln -sf /etc/nginx/sites-available/vpn-controller /etc/nginx/sites-enabled/
        sudo rm -f /etc/nginx/sites-enabled/default
        
        # Tester et redémarrer NGINX
        if sudo nginx -t; then
            sudo systemctl restart nginx
            echo "✅ NGINX configuré et redémarré"
        else
            echo "❌ Erreur dans la configuration NGINX"
            return 1
        fi
    fi
}

# Configuration du service systemd
setup_systemd_service() {
    echo "⚙️  Configuration du service systemd..."
    
    sudo tee /etc/systemd/system/vpn-controller.service > /dev/null <<EOF
[Unit]
Description=VPN Controller Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$USER
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable vpn-controller.service
    echo "✅ Service systemd configuré"
}

# Création des scripts de maintenance
create_maintenance_scripts() {
    echo "🔧 Création des scripts de maintenance..."
    
    # Script de vérification
    cat > check-status.sh <<'EOF'
#!/bin/bash
echo "=== État du VPN Controller - $(date) ==="
echo
echo "1. Containers Docker:"
docker compose ps
echo
echo "2. Test HTTP:"
curl -s -o /dev/null -w "Code de réponse: %{http_code}\n" http://localhost:3000
echo
echo "3. Utilisation ressources:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
echo
echo "4. Logs récents:"
docker compose logs --tail=5
EOF
    
    # Script de sauvegarde
    cat > backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

tar -czf $BACKUP_DIR/vpn-controller-$DATE.tar.gz \
    .env docker-compose.yml

echo "Sauvegarde créée: $BACKUP_DIR/vpn-controller-$DATE.tar.gz"

# Garder seulement les 7 dernières sauvegardes
find $BACKUP_DIR -name "vpn-controller-*.tar.gz" -mtime +7 -delete
EOF
    
    # Script de mise à jour
    cat > update.sh <<'EOF'
#!/bin/bash
echo "=== Mise à jour VPN Controller ==="

# Sauvegarde avant mise à jour
./backup.sh

# Mise à jour via git si disponible
if [ -d .git ]; then
    git pull origin main
fi

# Reconstruction et redémarrage
docker compose down
docker compose build --no-cache
docker compose up -d

echo "Mise à jour terminée!"
./check-status.sh
EOF
    
    chmod +x check-status.sh backup.sh update.sh
    echo "✅ Scripts de maintenance créés"
}

# Fonction principale
main() {
    echo "Démarrage du déploiement dans 3 secondes..."
    sleep 3
    
    check_prerequisites
    setup_firewall
    
    if ! test_ssh_connection; then
        echo "❌ Impossible de continuer sans connexion SSH au serveur OpenVPN"
        echo "Vérifiez votre configuration dans le fichier .env"
        exit 1
    fi
    
    deploy_application
    setup_nginx
    setup_systemd_service
    create_maintenance_scripts
    
    echo ""
    echo "🎉 Déploiement terminé avec succès !"
    echo "=========================================="
    echo ""
    echo "📱 Interface web disponible sur :"
    if [ "$ENVIRONMENT" = "production" ]; then
        echo "   - http://$(hostname -I | awk '{print $1}') (via NGINX)"
    fi
    echo "   - http://$(hostname -I | awk '{print $1}'):3000 (direct)"
    echo ""
    echo "🔑 Identifiants de connexion :"
    source .env
    echo "   - Utilisateur: $WEB_USERNAME"
    echo "   - Mot de passe: $WEB_PASSWORD"
    echo ""
    echo "🔧 Scripts de maintenance créés :"
    echo "   - ./check-status.sh  : Vérifier l'état"
    echo "   - ./backup.sh        : Sauvegarder"
    echo "   - ./update.sh        : Mettre à jour"
    echo ""
    echo "📋 Commandes utiles :"
    echo "   - docker compose logs -f  : Voir les logs"
    echo "   - docker compose restart  : Redémarrer"
    echo "   - sudo systemctl status vpn-controller : État du service"
    echo ""
    
    # Test final
    echo "🧪 Test final de l'interface..."
    ./check-status.sh
}

# Vérifier que le script est exécuté depuis le bon répertoire
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Ce script doit être exécuté depuis le répertoire de l'application"
    echo "Utilisation: cd /path/to/open-close-vpn && ./deploy.sh"
    exit 1
fi

# Exécuter le déploiement
main
