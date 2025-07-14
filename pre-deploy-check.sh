#!/bin/bash

# Script de pré-validation avant déploiement
# Usage: ./pre-deploy-check.sh

echo "🔍 Validation pré-déploiement OpenVPN Remote Controller"
echo "======================================================"

ERRORS=0
WARNINGS=0

# Fonction pour signaler une erreur
error() {
    echo "❌ ERREUR: $1"
    ERRORS=$((ERRORS + 1))
}

# Fonction pour signaler un avertissement
warning() {
    echo "⚠️  ATTENTION: $1"
    WARNINGS=$((WARNINGS + 1))
}

# Fonction pour signaler un succès
success() {
    echo "✅ $1"
}

echo ""
echo "📋 1. Vérification de l'environnement système"
echo "--------------------------------------------"

# Vérifier l'OS
if [ -f /etc/os-release ]; then
    OS_NAME=$(grep ^NAME= /etc/os-release | cut -d'"' -f2)
    success "Système d'exploitation: $OS_NAME"
else
    warning "Impossible de déterminer l'OS"
fi

# Vérifier l'architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
    success "Architecture supportée: $ARCH"
else
    warning "Architecture non testée: $ARCH"
fi

# Vérifier l'espace disque
AVAILABLE_SPACE_GB=$(df / | awk 'NR==2{printf "%.1f", $4/1024/1024}')
if (( $(echo "$AVAILABLE_SPACE_GB > 2.0" | bc -l) )); then
    success "Espace disque disponible: ${AVAILABLE_SPACE_GB}GB"
else
    error "Espace disque insuffisant: ${AVAILABLE_SPACE_GB}GB (minimum 2GB requis)"
fi

# Vérifier la RAM
TOTAL_RAM_GB=$(free -h | awk 'NR==2{print $2}' | sed 's/Gi//')
if (( $(echo "$TOTAL_RAM_GB > 0.5" | bc -l) )); then
    success "RAM disponible: ${TOTAL_RAM_GB}GB"
else
    warning "RAM limitée: ${TOTAL_RAM_GB}GB (minimum 512MB recommandé)"
fi

echo ""
echo "🐳 2. Vérification de Docker"
echo "----------------------------"

# Docker installé
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//')
    success "Docker installé: version $DOCKER_VERSION"
    
    # Docker en cours d'exécution
    if systemctl is-active --quiet docker; then
        success "Service Docker actif"
    else
        error "Service Docker inactif"
    fi
    
    # Permissions Docker
    if groups $USER | grep -q docker; then
        success "Utilisateur dans le groupe docker"
    else
        error "Utilisateur $USER pas dans le groupe docker"
    fi
else
    error "Docker non installé"
fi

# Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | sed 's/,//')
    success "Docker Compose installé: version $COMPOSE_VERSION"
else
    error "Docker Compose non installé"
fi

echo ""
echo "🌐 3. Vérification réseau"
echo "------------------------"

# Vérifier les ports
PORT_3000=$(netstat -tlnp 2>/dev/null | grep :3000 || true)
if [ -z "$PORT_3000" ]; then
    success "Port 3000 disponible"
else
    warning "Port 3000 déjà utilisé: $PORT_3000"
fi

# Connectivité Internet
if ping -c 1 8.8.8.8 &> /dev/null; then
    success "Connectivité Internet OK"
else
    error "Pas de connectivité Internet"
fi

echo ""
echo "📁 4. Vérification des fichiers projet"
echo "-------------------------------------"

# Fichiers requis
REQUIRED_FILES=("docker-compose.yml" "Dockerfile" "package.json" "server.js" ".env")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        success "Fichier présent: $file"
    else
        error "Fichier manquant: $file"
    fi
done

# Vérifier .env
if [ -f .env ]; then
    source .env
    
    # Variables requises
    REQUIRED_VARS=("VPN_SERVER_HOST" "VPN_SERVER_USER" "VPN_CONTAINER_NAME" "WEB_USERNAME" "WEB_PASSWORD")
    for var in "${REQUIRED_VARS[@]}"; do
        if [ -n "${!var}" ]; then
            success "Variable configurée: $var"
        else
            error "Variable manquante ou vide: $var"
        fi
    done
    
    # Authentification SSH
    if [ -n "$VPN_SERVER_KEY_PATH" ]; then
        if [ -f "$VPN_SERVER_KEY_PATH" ]; then
            PERMISSIONS=$(stat -c %a "$VPN_SERVER_KEY_PATH")
            if [ "$PERMISSIONS" = "600" ]; then
                success "Clé SSH présente avec bonnes permissions: $VPN_SERVER_KEY_PATH"
            else
                warning "Permissions de la clé SSH incorrectes: $PERMISSIONS (devrait être 600)"
            fi
        else
            error "Clé SSH spécifiée mais introuvable: $VPN_SERVER_KEY_PATH"
        fi
    elif [ -n "$VPN_SERVER_PASSWORD" ]; then
        success "Authentification par mot de passe configurée"
    else
        error "Aucune méthode d'authentification SSH configurée"
    fi
fi

echo ""
echo "🔗 5. Test de connectivité SSH"
echo "------------------------------"

if [ -f .env ]; then
    source .env
    
    if [ -n "$VPN_SERVER_HOST" ] && [ -n "$VPN_SERVER_USER" ]; then
        echo "Test de connexion à $VPN_SERVER_USER@$VPN_SERVER_HOST..."
        
        if [ -n "$VPN_SERVER_KEY_PATH" ] && [ -f "$VPN_SERVER_KEY_PATH" ]; then
            if timeout 10 ssh -i "$VPN_SERVER_KEY_PATH" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "echo 'SSH OK'" &>/dev/null; then
                success "Connexion SSH avec clé réussie"
                
                # Test Docker sur le serveur distant
                if timeout 10 ssh -i "$VPN_SERVER_KEY_PATH" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "docker ps" &>/dev/null; then
                    success "Docker accessible sur le serveur distant"
                else
                    error "Docker inaccessible sur le serveur distant"
                fi
                
                # Test du container OpenVPN
                if timeout 10 ssh -i "$VPN_SERVER_KEY_PATH" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "docker ps -a | grep $VPN_CONTAINER_NAME" &>/dev/null; then
                    success "Container OpenVPN trouvé: $VPN_CONTAINER_NAME"
                else
                    warning "Container OpenVPN non trouvé: $VPN_CONTAINER_NAME"
                fi
            else
                error "Échec de la connexion SSH avec clé"
            fi
        elif [ -n "$VPN_SERVER_PASSWORD" ]; then
            if command -v sshpass &> /dev/null; then
                if timeout 10 sshpass -p "$VPN_SERVER_PASSWORD" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "echo 'SSH OK'" &>/dev/null; then
                    success "Connexion SSH avec mot de passe réussie"
                else
                    error "Échec de la connexion SSH avec mot de passe"
                fi
            else
                warning "sshpass non installé, test SSH impossible"
            fi
        fi
    fi
fi

echo ""
echo "🔒 6. Vérification sécurité"
echo "-------------------------"

# Firewall
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | grep Status | awk '{print $2}')
    success "UFW installé (statut: $UFW_STATUS)"
else
    warning "UFW non installé"
fi

# Mots de passe par défaut
if [ -f .env ]; then
    source .env
    if [ "$WEB_PASSWORD" = "admin" ] || [ "$WEB_PASSWORD" = "password" ]; then
        warning "Mot de passe web par défaut détecté, changez-le avant la production"
    else
        success "Mot de passe web personnalisé"
    fi
fi

echo ""
echo "📊 RÉSUMÉ DE LA VALIDATION"
echo "========================="
echo "Erreurs trouvées: $ERRORS"
echo "Avertissements: $WARNINGS"

if [ $ERRORS -eq 0 ]; then
    echo ""
    echo "🎉 VALIDATION RÉUSSIE !"
    echo "Le système est prêt pour le déploiement."
    echo ""
    echo "Pour déployer, exécutez:"
    echo "   ./deploy.sh"
    exit 0
else
    echo ""
    echo "❌ VALIDATION ÉCHOUÉE !"
    echo "Corrigez les erreurs avant de déployer."
    echo ""
    echo "Consultez le guide de déploiement:"
    echo "   cat deploy-guide.md"
    exit 1
fi
