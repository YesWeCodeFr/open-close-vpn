# OpenVPN Remote Controller

Application web permettant de contrôler à distance un serveur OpenVPN déployé dans un container Docker.

## 🚀 Fonctionnalités

- **Dashboard en temps réel** : Surveillance du statut du serveur OpenVPN
- **Contrôle à distance** : Démarrer, arrêter et redémarrer le container OpenVPN
- **Logs en direct** : Consultation des logs du container
- **Interface sécurisée** : Authentification basique et connexion chiffrée
- **Responsive** : Compatible mobile et desktop

## 🏗️ Architecture

```
Serveur A (NGINX + App Web)  ←→  SSH  ←→  Serveur B (OpenVPN Docker)
```

- **Serveur A** : Héberge l'application web de contrôle
- **Serveur B** : Héberge le serveur OpenVPN dans un container Docker
- **Communication** : SSH pour exécuter les commandes Docker à distance

## 📋 Prérequis

### Serveur A (Application de contrôle)
- Docker et Docker Compose
- Accès SSH vers le serveur B

### Serveur B (Serveur OpenVPN)
- Docker avec container OpenVPN
- Serveur SSH actif
- Utilisateur avec droits Docker

## 🔧 Installation

### 1. Configuration initiale

```bash
# Cloner ou télécharger le projet
git clone <repo-url>
cd open-close-vpn

# Copier le fichier d'environnement
cp .env.example .env
```

### 2. Configuration du fichier .env

```bash
# Configuration du serveur OpenVPN (Serveur B)
VPN_SERVER_HOST=192.168.1.100
VPN_SERVER_PORT=22
VPN_SERVER_USER=your-username

# Authentification SSH (choisir l'une des options)
VPN_SERVER_PASSWORD=your-password
# OU
VPN_SERVER_KEY_PATH=/path/to/your/ssh/key

# Nom du container OpenVPN
VPN_CONTAINER_NAME=openvpn-server

# Configuration de l'application web
WEB_PORT=3000
WEB_USERNAME=admin
WEB_PASSWORD=your-secure-password
```

### 3. Déploiement avec Docker

```bash
# Construction et démarrage
docker-compose up -d

# Vérifier le statut
docker-compose ps

# Voir les logs
docker-compose logs -f
```

### 4. Déploiement manuel (sans Docker)

```bash
# Installer les dépendances
npm install

# Démarrer l'application
npm start

# Ou en mode développement
npm run dev
```

## 🔑 Configuration SSH

### Option 1 : Avec mot de passe
```bash
VPN_SERVER_PASSWORD=your-ssh-password
```

### Option 2 : Avec clé SSH (recommandé)
```bash
# Générer une paire de clés SSH (sur serveur A)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/vpn_control_key

# Copier la clé publique vers le serveur B
ssh-copy-id -i ~/.ssh/vpn_control_key.pub user@serveur-b

# Configurer dans .env
VPN_SERVER_KEY_PATH=/root/.ssh/vpn_control_key
```

## 🌐 Utilisation

1. **Accéder à l'interface** : `http://serveur-a:3000`
2. **Se connecter** avec les identifiants configurés
3. **Surveiller** le statut du serveur OpenVPN
4. **Contrôler** le container (Start/Stop/Restart)
5. **Consulter** les logs en temps réel

## 🔒 Sécurité

### Recommandations
- Utilisez HTTPS en production (proxy reverse avec NGINX)
- Configurez l'authentification par clé SSH
- Changez les mots de passe par défaut
- Limitez l'accès réseau avec un firewall
- Utilisez des certificats SSL valides

### Configuration NGINX (serveur A)
```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🐛 Dépannage

### Problèmes courants

1. **Erreur de connexion SSH**
   ```bash
   # Tester la connexion SSH manuellement
   ssh -i /path/to/key user@serveur-b
   ```

2. **Container non trouvé**
   ```bash
   # Vérifier le nom du container sur le serveur B
   docker ps -a | grep openvpn
   ```

3. **Permissions Docker**
   ```bash
   # Ajouter l'utilisateur au groupe docker
   sudo usermod -aG docker your-username
   ```

### Logs de débogage
```bash
# Logs de l'application
docker-compose logs vpn-controller

# Logs détaillés
docker-compose logs -f --tail=100 vpn-controller
```

## 📁 Structure du projet

```
open-close-vpn/
├── controllers/          # Logique métier
│   └── vpnController.js
├── middleware/           # Middleware d'authentification
│   └── auth.js
├── public/              # Interface web
│   ├── index.html
│   ├── styles.css
│   └── app.js
├── services/            # Services (SSH, etc.)
│   └── sshService.js
├── docker-compose.yml   # Configuration Docker
├── Dockerfile
├── package.json
├── server.js           # Point d'entrée
└── README.md
```

## 🔄 API REST

### Endpoints disponibles

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/login` | Authentification |
| GET | `/api/vpn/status` | Statut du container |
| POST | `/api/vpn/start` | Démarrer le container |
| POST | `/api/vpn/stop` | Arrêter le container |
| POST | `/api/vpn/restart` | Redémarrer le container |
| GET | `/api/vpn/logs` | Récupérer les logs |

### Exemples d'utilisation

```bash
# Authentification
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Statut du VPN
curl -X GET http://localhost:3000/api/vpn/status \
  -H "Authorization: Bearer <token>"

# Démarrer le VPN
curl -X POST http://localhost:3000/api/vpn/start \
  -H "Authorization: Bearer <token>"
```

## 📝 Todo / Améliorations

- [ ] Authentification JWT plus robuste
- [ ] Support de plusieurs serveurs OpenVPN
- [ ] Notifications en temps réel (WebSocket)
- [ ] Métriques et monitoring avancé
- [ ] Sauvegarde automatique des configurations
- [ ] Interface d'administration avancée
- [ ] Support Docker Swarm / Kubernetes

## 📄 Licence

MIT License - voir le fichier LICENSE pour plus de détails.

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou à proposer une pull request.

---

**Note** : Cette application est conçue pour des environnements de confiance. Assurez-vous de sécuriser correctement votre infrastructure avant la mise en production.
