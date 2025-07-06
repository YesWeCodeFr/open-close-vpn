const SSHConnection = require('../services/sshService');

const ssh = new SSHConnection();
const containerName = process.env.VPN_CONTAINER_NAME || 'openvpn-server';

const vpnController = {
  // Obtenir le statut du container OpenVPN
  async getStatus(req, res) {
    try {
      const result = await ssh.checkContainerStatus(containerName);
      
      if (result.code !== 0) {
        return res.status(500).json({
          error: 'Erreur lors de la vérification du statut',
          details: result.stderr
        });
      }

      const lines = result.stdout.split('\n');
      let status = 'unknown';
      let ports = '';

      if (lines.length > 1) {
        const statusLine = lines[1];
        if (statusLine.includes('Up')) {
          status = 'running';
        } else if (statusLine.includes('Exited')) {
          status = 'stopped';
        }
        
        // Extraire les ports
        const parts = statusLine.split('\t');
        if (parts.length >= 3) {
          ports = parts[2] || '';
        }
      } else {
        status = 'not_found';
      }

      res.json({
        status,
        ports,
        containerName,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Erreur SSH:', error);
      res.status(500).json({
        error: 'Impossible de se connecter au serveur VPN',
        details: error.message
      });
    }
  },

  // Démarrer le container OpenVPN
  async start(req, res) {
    try {
      const result = await ssh.startContainer(containerName);
      
      if (result.code !== 0) {
        return res.status(500).json({
          error: 'Erreur lors du démarrage',
          details: result.stderr
        });
      }

      res.json({
        success: true,
        message: 'Container OpenVPN démarré avec succès',
        output: result.stdout
      });

    } catch (error) {
      console.error('Erreur lors du démarrage:', error);
      res.status(500).json({
        error: 'Impossible de démarrer le container',
        details: error.message
      });
    }
  },

  // Arrêter le container OpenVPN
  async stop(req, res) {
    try {
      const result = await ssh.stopContainer(containerName);
      
      if (result.code !== 0) {
        return res.status(500).json({
          error: 'Erreur lors de l\'arrêt',
          details: result.stderr
        });
      }

      res.json({
        success: true,
        message: 'Container OpenVPN arrêté avec succès',
        output: result.stdout
      });

    } catch (error) {
      console.error('Erreur lors de l\'arrêt:', error);
      res.status(500).json({
        error: 'Impossible d\'arrêter le container',
        details: error.message
      });
    }
  },

  // Redémarrer le container OpenVPN
  async restart(req, res) {
    try {
      const result = await ssh.restartContainer(containerName);
      
      if (result.code !== 0) {
        return res.status(500).json({
          error: 'Erreur lors du redémarrage',
          details: result.stderr
        });
      }

      res.json({
        success: true,
        message: 'Container OpenVPN redémarré avec succès',
        output: result.stdout
      });

    } catch (error) {
      console.error('Erreur lors du redémarrage:', error);
      res.status(500).json({
        error: 'Impossible de redémarrer le container',
        details: error.message
      });
    }
  },

  // Obtenir les logs du container
  async getLogs(req, res) {
    try {
      const lines = req.query.lines || 50;
      const result = await ssh.getContainerLogs(containerName, lines);
      
      res.json({
        logs: result.stdout,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Erreur lors de la récupération des logs:', error);
      res.status(500).json({
        error: 'Impossible de récupérer les logs',
        details: error.message
      });
    }
  }
};

module.exports = vpnController;
