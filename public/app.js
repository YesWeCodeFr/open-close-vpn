// Configuration et variables globales
const API_BASE = '/api';
let authToken = localStorage.getItem('vpn_auth_token');
let statusRefreshInterval;

// Éléments DOM
const loginScreen = document.getElementById('loginScreen');
const dashboard = document.getElementById('dashboard');
const loginForm = document.getElementById('loginForm');
const loginError = document.getElementById('loginError');

// Éléments du dashboard
const statusIndicator = document.getElementById('statusIndicator');
const statusText = document.getElementById('statusText');
const containerName = document.getElementById('containerName');
const containerPorts = document.getElementById('containerPorts');
const lastCheck = document.getElementById('lastCheck');
const lastUpdate = document.getElementById('lastUpdate');

// Boutons
const refreshBtn = document.getElementById('refreshBtn');
const logoutBtn = document.getElementById('logoutBtn');
const startBtn = document.getElementById('startBtn');
const stopBtn = document.getElementById('stopBtn');
const restartBtn = document.getElementById('restartBtn');
const refreshLogsBtn = document.getElementById('refreshLogsBtn');

// Logs
const logsContent = document.getElementById('logsContent');
const logLines = document.getElementById('logLines');

// Notifications
const notification = document.getElementById('notification');
const notificationText = document.getElementById('notificationText');
const closeNotification = document.getElementById('closeNotification');

// Initialisation
document.addEventListener('DOMContentLoaded', function() {
    if (authToken) {
        showDashboard();
    } else {
        showLogin();
    }
    
    setupEventListeners();
});

// Configuration des événements
function setupEventListeners() {
    // Connexion
    loginForm.addEventListener('submit', handleLogin);
    
    // Dashboard
    refreshBtn.addEventListener('click', refreshStatus);
    logoutBtn.addEventListener('click', handleLogout);
    
    // Actions VPN
    startBtn.addEventListener('click', () => handleVpnAction('start'));
    stopBtn.addEventListener('click', () => handleVpnAction('stop'));
    restartBtn.addEventListener('click', () => handleVpnAction('restart'));
    
    // Logs
    refreshLogsBtn.addEventListener('click', refreshLogs);
    logLines.addEventListener('change', refreshLogs);
    
    // Notifications
    closeNotification.addEventListener('click', hideNotification);
}

// Gestion de la connexion
async function handleLogin(e) {
    e.preventDefault();
    
    const formData = new FormData(loginForm);
    const credentials = {
        username: formData.get('username'),
        password: formData.get('password')
    };
    
    try {
        const response = await fetch(`${API_BASE}/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(credentials)
        });
        
        const data = await response.json();
        
        if (response.ok) {
            authToken = data.token;
            localStorage.setItem('vpn_auth_token', authToken);
            showDashboard();
            hideLoginError();
        } else {
            showLoginError(data.error);
        }
    } catch (error) {
        showLoginError('Erreur de connexion au serveur');
    }
}

// Déconnexion
function handleLogout() {
    authToken = null;
    localStorage.removeItem('vpn_auth_token');
    clearInterval(statusRefreshInterval);
    showLogin();
}

// Afficher l'écran de connexion
function showLogin() {
    loginScreen.style.display = 'flex';
    dashboard.style.display = 'none';
}

// Afficher le dashboard
function showDashboard() {
    loginScreen.style.display = 'none';
    dashboard.style.display = 'block';
    
    // Démarrer la surveillance du statut
    refreshStatus();
    startStatusMonitoring();
    refreshLogs();
}

// Afficher/masquer les erreurs de connexion
function showLoginError(message) {
    loginError.textContent = message;
    loginError.style.display = 'block';
}

function hideLoginError() {
    loginError.style.display = 'none';
}

// Requête API avec authentification
async function apiRequest(endpoint, options = {}) {
    const config = {
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`
        },
        ...options
    };
    
    try {
        const response = await fetch(`${API_BASE}${endpoint}`, config);
        
        if (response.status === 401) {
            handleLogout();
            throw new Error('Session expirée');
        }
        
        return await response.json();
    } catch (error) {
        console.error('Erreur API:', error);
        throw error;
    }
}

// Actualiser le statut du serveur VPN
async function refreshStatus() {
    try {
        const data = await apiRequest('/vpn/status');
        updateStatusDisplay(data);
        updateLastCheck();
    } catch (error) {
        showNotification('Erreur lors de la vérification du statut', 'error');
        console.error('Erreur de statut:', error);
    }
}

// Mettre à jour l'affichage du statut
function updateStatusDisplay(data) {
    // Indicateur de statut
    statusIndicator.className = `status-indicator ${data.status}`;
    
    // Icône et texte selon le statut
    let icon, text;
    switch (data.status) {
        case 'running':
            icon = 'fa-check-circle';
            text = 'En fonctionnement';
            break;
        case 'stopped':
            icon = 'fa-times-circle';
            text = 'Arrêté';
            break;
        case 'not_found':
            icon = 'fa-exclamation-triangle';
            text = 'Container non trouvé';
            break;
        default:
            icon = 'fa-question-circle';
            text = 'Statut inconnu';
    }
    
    statusIndicator.querySelector('i').className = `fas ${icon}`;
    statusText.textContent = text;
    
    // Détails du serveur
    containerName.textContent = data.containerName || '-';
    containerPorts.textContent = data.ports || 'Aucun port exposé';
    
    // Mise à jour des boutons
    updateControlButtons(data.status);
}

// Mettre à jour l'état des boutons de contrôle
function updateControlButtons(status) {
    const isRunning = status === 'running';
    const isStopped = status === 'stopped';
    const isFound = status !== 'not_found';
    
    startBtn.disabled = !isStopped || !isFound;
    stopBtn.disabled = !isRunning;
    restartBtn.disabled = !isRunning;
}

// Mettre à jour la dernière vérification
function updateLastCheck() {
    const now = new Date().toLocaleString('fr-FR');
    lastCheck.textContent = now;
    lastUpdate.textContent = `Dernière mise à jour: ${now}`;
}

// Démarrer la surveillance automatique du statut
function startStatusMonitoring() {
    // Actualiser toutes les 30 secondes
    statusRefreshInterval = setInterval(refreshStatus, 30000);
}

// Gérer les actions VPN (start, stop, restart)
async function handleVpnAction(action) {
    const button = document.getElementById(`${action}Btn`);
    const originalText = button.innerHTML;
    
    // Affichage du loading
    button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Traitement...';
    button.disabled = true;
    
    try {
        const data = await apiRequest(`/vpn/${action}`, {
            method: 'POST'
        });
        
        if (data.success) {
            showNotification(data.message, 'success');
            // Actualiser le statut après l'action
            setTimeout(refreshStatus, 2000);
        } else {
            showNotification(data.error || 'Erreur lors de l\'opération', 'error');
        }
    } catch (error) {
        showNotification(`Erreur lors de l'${action}`, 'error');
    } finally {
        // Restaurer le bouton
        button.innerHTML = originalText;
        setTimeout(refreshStatus, 1000); // Rafraîchir le statut pour réactiver les boutons
    }
}

// Actualiser les logs
async function refreshLogs() {
    const lines = logLines.value;
    
    try {
        logsContent.textContent = 'Chargement des logs...';
        
        const data = await apiRequest(`/vpn/logs?lines=${lines}`);
        
        if (data.logs) {
            logsContent.textContent = data.logs || 'Aucun log disponible';
        } else {
            logsContent.textContent = 'Erreur lors du chargement des logs';
        }
        
        // Faire défiler vers le bas
        logsContent.scrollTop = logsContent.scrollHeight;
        
    } catch (error) {
        logsContent.textContent = 'Erreur lors du chargement des logs';
        showNotification('Erreur lors du chargement des logs', 'error');
    }
}

// Afficher une notification
function showNotification(message, type = 'info') {
    notificationText.textContent = message;
    notification.className = `notification ${type}`;
    notification.style.display = 'block';
    
    // Masquer automatiquement après 5 secondes
    setTimeout(hideNotification, 5000);
}

// Masquer la notification
function hideNotification() {
    notification.style.display = 'none';
}

// Gestion des erreurs globales
window.addEventListener('error', function(e) {
    console.error('Erreur JavaScript:', e.error);
    showNotification('Une erreur inattendue s\'est produite', 'error');
});

// Gestion de la perte de connexion
window.addEventListener('online', function() {
    showNotification('Connexion rétablie', 'success');
    refreshStatus();
});

window.addEventListener('offline', function() {
    showNotification('Connexion perdue', 'error');
});
