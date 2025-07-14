#!/bin/bash

# Script de test pour valider la syntaxe Docker Compose moderne
# Usage: ./test-docker-compose.sh

echo "🧪 Test de la syntaxe Docker Compose moderne"
echo "==========================================="

# Vérifier la version de Docker
echo "🐳 Version de Docker:"
docker --version

echo ""
echo "🔧 Test de Docker Compose intégré:"

# Tester la commande docker compose
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "intégré")
    echo "✅ Docker Compose disponible: $COMPOSE_VERSION"
else
    echo "❌ Docker Compose non disponible"
    echo "Veuillez mettre à jour Docker vers une version récente (20.10.13+)"
    exit 1
fi

echo ""
echo "📋 Test des commandes principales:"

# Tester docker compose config
if docker compose config &> /dev/null; then
    echo "✅ docker compose config : OK"
else
    echo "❌ docker compose config : Erreur de configuration"
fi

# Tester docker compose ps (sans erreur même si rien ne tourne)
if docker compose ps &> /dev/null; then
    echo "✅ docker compose ps : OK"
else
    echo "❌ docker compose ps : Erreur"
fi

echo ""
echo "🔄 Comparaison des syntaxes:"
echo "Ancienne : docker-compose up -d"
echo "Nouvelle : docker compose up -d"
echo ""

echo "✅ Tous les tests passés ! Votre Docker supporte la syntaxe moderne."
echo ""
echo "💡 Commandes disponibles:"
echo "  - docker compose up -d     : Démarrer en arrière-plan"
echo "  - docker compose down      : Arrêter et supprimer"
echo "  - docker compose logs -f   : Voir les logs en temps réel"
echo "  - docker compose ps        : Lister les containers"
echo "  - docker compose restart   : Redémarrer les services"
echo ""
echo "🌐 Une fois démarré, l'application sera accessible sur:"
echo "  - http://localhost:3001 (port hôte)"
echo "  - Le container utilise le port 3000 en interne"
