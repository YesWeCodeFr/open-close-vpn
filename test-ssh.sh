# Script de test des fonctionnalités SSH
#!/bin/bash

echo "🧪 Test de connexion SSH vers le serveur OpenVPN"
echo "==============================================="

# Charger les variables d'environnement
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ Fichier .env non trouvé"
    exit 1
fi

# Vérifier les variables requises
if [ -z "$VPN_SERVER_HOST" ] || [ -z "$VPN_SERVER_USER" ]; then
    echo "❌ Variables VPN_SERVER_HOST et VPN_SERVER_USER requises dans .env"
    exit 1
fi

echo "🔗 Test de connexion à $VPN_SERVER_HOST..."

# Test de connexion SSH basique
if [ -n "$VPN_SERVER_KEY_PATH" ]; then
    echo "🔑 Utilisation de la clé SSH: $VPN_SERVER_KEY_PATH"
    ssh -i "$VPN_SERVER_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "echo 'Connexion SSH réussie !'"
else
    echo "🔑 Utilisation du mot de passe"
    sshpass -p "$VPN_SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "echo 'Connexion SSH réussie !'"
fi

if [ $? -eq 0 ]; then
    echo "✅ Connexion SSH OK"
else
    echo "❌ Erreur de connexion SSH"
    exit 1
fi

# Test de la commande Docker
echo "🐳 Test de la commande Docker..."
if [ -n "$VPN_SERVER_KEY_PATH" ]; then
    ssh -i "$VPN_SERVER_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "docker ps"
else
    sshpass -p "$VPN_SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "docker ps"
fi

if [ $? -eq 0 ]; then
    echo "✅ Commande Docker OK"
else
    echo "❌ Erreur avec Docker (vérifiez les permissions)"
fi

# Test du container OpenVPN spécifique
echo "🔍 Recherche du container OpenVPN: $VPN_CONTAINER_NAME"
if [ -n "$VPN_SERVER_KEY_PATH" ]; then
    ssh -i "$VPN_SERVER_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "docker ps -a | grep $VPN_CONTAINER_NAME"
else
    sshpass -p "$VPN_SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPN_SERVER_USER@$VPN_SERVER_HOST" "docker ps -a | grep $VPN_CONTAINER_NAME"
fi

if [ $? -eq 0 ]; then
    echo "✅ Container OpenVPN trouvé"
else
    echo "⚠️  Container OpenVPN non trouvé (vérifiez le nom)"
fi

echo "🎉 Tests terminés !"
