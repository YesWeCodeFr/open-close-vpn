#!/bin/bash

# Script de test de la configuration des ports
# Usage: ./test-ports.sh

echo "🌐 Test de la configuration des ports - OpenVPN Remote Controller"
echo "================================================================"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour les messages
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "ℹ️  $1"
}

echo ""
echo "📋 1. Vérification de la configuration Docker"
echo "---------------------------------------------"

# Vérifier docker-compose.yml
if [ -f docker-compose.yml ]; then
    success "Fichier docker-compose.yml présent"
    
    # Vérifier la configuration des ports
    PORT_CONFIG=$(grep -A 2 "ports:" docker-compose.yml | grep "3001:3000" || true)
    if [ -n "$PORT_CONFIG" ]; then
        success "Configuration des ports : 3001:3000"
    else
        error "Configuration des ports incorrecte dans docker-compose.yml"
        info "Configuration attendue : - \"3001:3000\" ou - \"\${WEB_HOST_PORT:-3001}:3000\""
    fi
else
    error "Fichier docker-compose.yml manquant"
fi

# Vérifier .env
echo ""
echo "📁 2. Vérification du fichier .env"
echo "----------------------------------"

if [ -f .env ]; then
    success "Fichier .env présent"
    
    # Charger les variables
    source .env
    
    if [ -n "$WEB_HOST_PORT" ]; then
        success "WEB_HOST_PORT configuré : $WEB_HOST_PORT"
    else
        warning "WEB_HOST_PORT non défini, utilisation du port par défaut 3001"
        WEB_HOST_PORT=3001
    fi
    
    if [ -n "$WEB_PORT" ]; then
        success "WEB_PORT configuré : $WEB_PORT"
    else
        warning "WEB_PORT non défini"
    fi
else
    error "Fichier .env manquant"
    WEB_HOST_PORT=3001
fi

echo ""
echo "🔍 3. Vérification des ports système"
echo "-----------------------------------"

# Vérifier si le port hôte est libre
PORT_CHECK=$(netstat -tlnp 2>/dev/null | grep ":$WEB_HOST_PORT " || true)
if [ -z "$PORT_CHECK" ]; then
    success "Port $WEB_HOST_PORT disponible"
else
    warning "Port $WEB_HOST_PORT déjà utilisé :"
    echo "   $PORT_CHECK"
fi

# Vérifier si Docker tourne
echo ""
echo "🐳 4. Vérification de Docker"
echo "---------------------------"

if systemctl is-active --quiet docker; then
    success "Service Docker actif"
    
    # Vérifier si l'application tourne
    if docker compose ps | grep -q "Up"; then
        success "Application Docker en cours d'exécution"
        
        # Test de connectivité
        echo ""
        echo "🧪 5. Test de connectivité"
        echo "-------------------------"
        
        # Test du port hôte
        if curl -s -f http://localhost:$WEB_HOST_PORT > /dev/null; then
            success "Application accessible sur http://localhost:$WEB_HOST_PORT"
        else
            error "Application inaccessible sur le port $WEB_HOST_PORT"
            info "Vérifiez que l'application est démarrée et que la redirection de port fonctionne"
        fi
        
        # Test de l'API
        API_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$WEB_HOST_PORT/api/vpn/status 2>/dev/null || echo "000")
        if [ "$API_TEST" = "401" ]; then
            success "API accessible (code 401 = authentification requise)"
        elif [ "$API_TEST" = "200" ]; then
            warning "API accessible sans authentification (vérifiez la configuration)"
        else
            error "API inaccessible (code HTTP: $API_TEST)"
        fi
        
    else
        warning "Application Docker non démarrée"
        info "Exécutez : docker compose up -d"
    fi
else
    error "Service Docker inactif"
    info "Démarrez Docker : sudo systemctl start docker"
fi

echo ""
echo "🔥 6. Vérification du firewall"
echo "-----------------------------"

if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | grep "$WEB_HOST_PORT/tcp" || true)
    if [ -n "$UFW_STATUS" ]; then
        success "Port $WEB_HOST_PORT autorisé dans UFW"
    else
        warning "Port $WEB_HOST_PORT non autorisé dans UFW"
        info "Autorisez le port : sudo ufw allow $WEB_HOST_PORT/tcp"
    fi
else
    info "UFW non installé, vérifiez votre firewall manuellement"
fi

echo ""
echo "🌐 7. Configuration NGINX (si présent)"
echo "-------------------------------------"

if command -v nginx &> /dev/null; then
    success "NGINX installé"
    
    # Vérifier la configuration pour notre application
    NGINX_CONFIG=$(sudo grep -r "localhost:$WEB_HOST_PORT" /etc/nginx/sites-enabled/ 2>/dev/null || true)
    if [ -n "$NGINX_CONFIG" ]; then
        success "NGINX configuré pour rediriger vers localhost:$WEB_HOST_PORT"
    else
        warning "NGINX non configuré pour l'application"
        info "Configurez NGINX pour rediriger vers localhost:$WEB_HOST_PORT"
    fi
else
    info "NGINX non installé"
fi

echo ""
echo "📊 RÉSUMÉ"
echo "========="
echo "Port hôte configuré    : $WEB_HOST_PORT"
echo "Port container         : 3000"
echo "URL d'accès           : http://localhost:$WEB_HOST_PORT"
echo ""

# Commandes utiles
echo "🛠️  COMMANDES UTILES"
echo "==================="
echo "# Tester l'application"
echo "curl http://localhost:$WEB_HOST_PORT"
echo ""
echo "# Voir les logs"
echo "docker compose logs -f"
echo ""
echo "# Redémarrer l'application"
echo "docker compose restart"
echo ""
echo "# Changer le port (éditez .env puis)"
echo "docker compose down && docker compose up -d"

echo ""
echo "✅ Test terminé !"
