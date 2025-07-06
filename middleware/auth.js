const authMiddleware = {
  // Authentification basique
  login(req, res) {
    const { username, password } = req.body;
    
    const validUsername = process.env.WEB_USERNAME || 'admin';
    const validPassword = process.env.WEB_PASSWORD || 'admin';
    
    if (username === validUsername && password === validPassword) {
      // Dans un vrai projet, utilisez JWT ou des sessions
      const token = Buffer.from(`${username}:${password}`).toString('base64');
      
      res.json({
        success: true,
        token,
        message: 'Authentification réussie'
      });
    } else {
      res.status(401).json({
        error: 'Nom d\'utilisateur ou mot de passe incorrect'
      });
    }
  },

  // Middleware de vérification d'authentification
  authenticate(req, res, next) {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Token d\'authentification requis'
      });
    }
    
    const token = authHeader.substring(7);
    
    try {
      const decoded = Buffer.from(token, 'base64').toString('utf-8');
      const [username, password] = decoded.split(':');
      
      const validUsername = process.env.WEB_USERNAME || 'admin';
      const validPassword = process.env.WEB_PASSWORD || 'admin';
      
      if (username === validUsername && password === validPassword) {
        req.user = { username };
        next();
      } else {
        res.status(401).json({
          error: 'Token invalide'
        });
      }
    } catch (error) {
      res.status(401).json({
        error: 'Token malformé'
      });
    }
  }
};

module.exports = authMiddleware;
