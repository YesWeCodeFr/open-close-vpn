const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

const vpnController = require('./controllers/vpnController');
const authMiddleware = require('./middleware/auth');

const app = express();
const PORT = process.env.WEB_PORT || 3000;

// Middleware de sécurité
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:"],
    },
  },
}));

app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir les fichiers statiques
app.use(express.static(path.join(__dirname, 'public')));

// Routes d'authentification
app.post('/api/login', authMiddleware.login);

// Routes protégées pour le VPN
app.use('/api/vpn', authMiddleware.authenticate);
app.get('/api/vpn/status', vpnController.getStatus);
app.post('/api/vpn/start', vpnController.start);
app.post('/api/vpn/stop', vpnController.stop);
app.post('/api/vpn/restart', vpnController.restart);
app.get('/api/vpn/logs', vpnController.getLogs);

// Route par défaut
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Gestion des erreurs
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Erreur interne du serveur' });
});

// Route 404
app.use((req, res) => {
  res.status(404).json({ error: 'Route non trouvée' });
});

app.listen(PORT, () => {
  console.log(`🚀 Serveur démarré sur le port ${PORT}`);
  console.log(`📱 Interface web disponible sur http://localhost:${PORT}`);
});
