# Guide Docker Compose moderne

## 🆕 Migration vers Docker Compose intégré

Depuis Docker Desktop 3.4.0+ et Docker Engine 20.10.13+, Docker Compose est intégré directement dans Docker. Plus besoin d'installer `docker-compose` séparément !

### ✅ Nouvelle syntaxe (recommandée)
```bash
docker compose up -d
docker compose down
docker compose logs -f
docker compose ps
```

### ❌ Ancienne syntaxe (dépréciée)
```bash
docker-compose up -d
docker-compose down
docker-compose logs -f
docker-compose ps
```

## 🔄 Commandes équivalentes

| Ancienne commande | Nouvelle commande |
|-------------------|-------------------|
| `docker-compose up -d` | `docker compose up -d` |
| `docker-compose down` | `docker compose down` |
| `docker-compose build` | `docker compose build` |
| `docker-compose logs -f` | `docker compose logs -f` |
| `docker-compose ps` | `docker compose ps` |
| `docker-compose restart` | `docker compose restart` |
| `docker-compose exec service bash` | `docker compose exec service bash` |

## 📋 Vérification de votre version

Pour vérifier si vous avez la version moderne :

```bash
# Vérifier la version de Docker
docker --version

# Tester Docker Compose intégré
docker compose version
```

Si vous obtenez une erreur avec `docker compose`, mettez à jour Docker :

```bash
# Sur Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ou via le gestionnaire de paquets
sudo apt update && sudo apt upgrade docker-ce
```

## 🎯 Pourquoi migrer ?

1. **Performance** : Plus rapide car intégré
2. **Maintenance** : Une seule installation à gérer
3. **Compatibilité** : Support officiel à long terme
4. **Simplicité** : Plus besoin d'installer docker-compose séparément

## 📱 Notre application utilise maintenant

Tous nos scripts utilisent maintenant la syntaxe moderne `docker compose` :

- ✅ `deploy.sh` : Déploiement automatisé
- ✅ `pre-deploy-check.sh` : Validation pré-déploiement
- ✅ `install.sh` : Installation simplifiée
- ✅ `.vscode/tasks.json` : Tâches VS Code
- ✅ Documentation mise à jour

Cette migration garantit la compatibilité avec les versions récentes de Docker et améliore les performances de déploiement.
