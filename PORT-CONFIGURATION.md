# 🌐 Configuration des ports - OpenVPN Remote Controller

## 📋 Résumé de la configuration

### Ports utilisés

| Composant | Port interne | Port hôte | Description |
|-----------|-------------|-----------|-------------|
| **Application Node.js** | 3000 | 3001 | Interface web principale |
| **NGINX (optionnel)** | 80/443 | 80/443 | Proxy reverse |

## 🔧 Configuration Docker

### Docker Compose
```yaml
services:
  vpn-controller:
    ports:
      - "${WEB_HOST_PORT:-3001}:3000"
```

**Explication :**
- `3001` : Port sur l'hôte (votre serveur)
- `3000` : Port dans le container Docker
- La variable `WEB_HOST_PORT` permet de personnaliser le port hôte

### Variables d'environnement (.env)
```bash
# Port interne du container (ne pas changer)
WEB_PORT=3000

# Port exposé sur l'hôte (configurable)
WEB_HOST_PORT=3001
```

## 🌐 URLs d'accès

### Accès direct
- **URL** : `http://votre-serveur:3001`
- **Usage** : Accès direct à l'application
- **Firewall** : Port 3001/tcp doit être ouvert

### Accès via NGINX (recommandé en production)
- **URL** : `http://votre-serveur` ou `https://votre-serveur`
- **Configuration** : NGINX redirige vers `localhost:3001`
- **Firewall** : Ports 80/tcp et 443/tcp

## 🔥 Configuration firewall

### UFW (Ubuntu/Debian)
```bash
# Port de l'application
sudo ufw allow 3001/tcp

# Ports web (si NGINX)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# SSH (administration)
sudo ufw allow 22/tcp
```

### Autres firewalls
```bash
# Firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=3001/tcp
sudo firewall-cmd --reload

# iptables (manuel)
sudo iptables -A INPUT -p tcp --dport 3001 -j ACCEPT
```

## 🔧 Configuration NGINX

### Fichier de configuration
```nginx
server {
    listen 80;
    server_name votre-domaine.com;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 🧪 Tests de connectivité

### Vérifier que l'application répond
```bash
# Test direct
curl -I http://localhost:3001

# Test depuis l'extérieur
curl -I http://votre-serveur:3001

# Test des API
curl http://localhost:3001/api/vpn/status
```

### Vérifier les ports ouverts
```bash
# Ports en écoute
netstat -tlnp | grep :3001

# Status des containers
docker compose ps

# Logs de l'application
docker compose logs -f
```

## ⚙️ Personnalisation du port

### Changer le port hôte
```bash
# Éditer .env
nano .env

# Modifier la variable
WEB_HOST_PORT=8080

# Redémarrer
docker compose down
docker compose up -d
```

### Utiliser plusieurs instances
```bash
# Instance 1 - Port 3001
WEB_HOST_PORT=3001 docker compose -p vpn1 up -d

# Instance 2 - Port 3002  
WEB_HOST_PORT=3002 docker compose -p vpn2 up -d
```

## 🚨 Dépannage

### Port déjà utilisé
```bash
# Identifier le processus
sudo lsof -i :3001

# Arrêter le processus si nécessaire
sudo kill -9 <PID>

# Ou changer le port dans .env
WEB_HOST_PORT=3002
```

### Application inaccessible
```bash
# Vérifier que le container tourne
docker compose ps

# Vérifier les logs
docker compose logs

# Vérifier le firewall
sudo ufw status

# Tester en local
curl http://localhost:3001
```

### NGINX ne fonctionne pas
```bash
# Vérifier la configuration
sudo nginx -t

# Redémarrer NGINX
sudo systemctl restart nginx

# Vérifier les logs NGINX
sudo tail -f /var/log/nginx/error.log
```

## 📊 Monitoring des ports

### Script de surveillance
```bash
#!/bin/bash
echo "=== Surveillance des ports ==="
echo "Port 3001 (Application):"
netstat -tlnp | grep :3001 || echo "Port 3001 non en écoute"

echo "Port 80 (HTTP):"
netstat -tlnp | grep :80 || echo "Port 80 non en écoute"

echo "Port 443 (HTTPS):"
netstat -tlnp | grep :443 || echo "Port 443 non en écoute"

echo "=== Test de connectivité ==="
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:3001 || echo "Application inaccessible"
```

---

Cette configuration garantit que :
- ✅ L'application fonctionne sur le port 3001 de votre serveur
- ✅ Le container utilise le port 3000 en interne (standard)
- ✅ NGINX peut faire le proxy reverse vers 3001
- ✅ Le firewall est correctement configuré
- ✅ La configuration est facilement modifiable
