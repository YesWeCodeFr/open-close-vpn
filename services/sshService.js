const { Client } = require('ssh2');
const fs = require('fs');

class SSHConnection {
  constructor() {
    this.config = {
      host: process.env.VPN_SERVER_HOST,
      port: process.env.VPN_SERVER_PORT || 22,
      username: process.env.VPN_SERVER_USER,
    };

    // Configuration de l'authentification (mot de passe ou clé)
    if (process.env.VPN_SERVER_KEY_PATH && fs.existsSync(process.env.VPN_SERVER_KEY_PATH)) {
      this.config.privateKey = fs.readFileSync(process.env.VPN_SERVER_KEY_PATH);
    } else if (process.env.VPN_SERVER_PASSWORD) {
      this.config.password = process.env.VPN_SERVER_PASSWORD;
    }
  }

  async executeCommand(command) {
    return new Promise((resolve, reject) => {
      const conn = new Client();
      
      conn.on('ready', () => {
        conn.exec(command, (err, stream) => {
          if (err) {
            conn.end();
            return reject(err);
          }

          let stdout = '';
          let stderr = '';

          stream.on('close', (code, signal) => {
            conn.end();
            resolve({
              code,
              signal,
              stdout: stdout.trim(),
              stderr: stderr.trim()
            });
          });

          stream.on('data', (data) => {
            stdout += data;
          });

          stream.stderr.on('data', (data) => {
            stderr += data;
          });
        });
      });

      conn.on('error', (err) => {
        reject(err);
      });

      conn.connect(this.config);
    });
  }

  async checkContainerStatus(containerName) {
    const command = `docker ps -a --filter "name=${containerName}" --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"`;
    return await this.executeCommand(command);
  }

  async startContainer(containerName) {
    const command = `docker start ${containerName}`;
    return await this.executeCommand(command);
  }

  async stopContainer(containerName) {
    const command = `docker stop ${containerName}`;
    return await this.executeCommand(command);
  }

  async restartContainer(containerName) {
    const command = `docker restart ${containerName}`;
    return await this.executeCommand(command);
  }

  async getContainerLogs(containerName, lines = 50) {
    const command = `docker logs --tail ${lines} ${containerName}`;
    return await this.executeCommand(command);
  }
}

module.exports = SSHConnection;
