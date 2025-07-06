#!/bin/bash

# Script d'installation et de configuration pour OpenVPN Remote Controller
# Usage: ./install.sh

set -e

echo "🚀 Installation d'OpenVPN Remote Controller"
echo "============================================"

# Vérifier les prérequis
echo "📋 Vérification des prérequis..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Installation..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installé"
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Installation..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installé"
fi

# Configuration du fichier .env
echo "⚙️  Configuration de l'environnement..."

if [ ! -f .env ]; then
    cp .env.example .env
    echo "📝 Fichier .env créé. Veuillez le configurer avec vos paramètres."
    echo ""
    echo "Variables importantes à configurer :"
    echo "  - VPN_SERVER_HOST: IP du serveur OpenVPN"
    echo "  - VPN_SERVER_USER: Utilisateur SSH"
    echo "  - VPN_SERVER_PASSWORD ou VPN_SERVER_KEY_PATH: Authentification SSH"
    echo "  - VPN_CONTAINER_NAME: Nom du container OpenVPN"
    echo "  - WEB_USERNAME/WEB_PASSWORD: Identifiants de l'interface web"
    echo ""
    read -p "Voulez-vous éditer le fichier .env maintenant ? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} .env
    fi
else
    echo "✅ Fichier .env déjà existant"
fi

# Construction et démarrage
echo "🔨 Construction de l'application..."
docker-compose build

echo "🚀 Démarrage de l'application..."
docker-compose up -d

# Vérification
echo "🔍 Vérification du déploiement..."
sleep 5

if docker-compose ps | grep -q "Up"; then
    echo "✅ Application démarrée avec succès !"
    echo ""
    echo "🌐 Interface web disponible sur : http://localhost:3000"
    echo "📚 Consultez le README.md pour plus d'informations"
    echo ""
    echo "🔧 Commandes utiles :"
    echo "  - Voir les logs : docker-compose logs -f"
    echo "  - Arrêter : docker-compose down"
    echo "  - Redémarrer : docker-compose restart"
else
    echo "❌ Erreur lors du démarrage"
    echo "📋 Logs :"
    docker-compose logs
    exit 1
fi

echo "🎉 Installation terminée !"
