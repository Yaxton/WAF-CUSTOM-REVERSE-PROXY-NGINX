# WAF + Nginx Reverse Proxy - Déploiement Automatisé

Déployez automatiquement un Web Application Firewall (WAF) avec Nginx en reverse proxy.

### Installation rapide

```bash
git clone https://github.com/Yaxton/waf-custom-reverse-proxy-nginx.git
cd waf-nginx-deployment
sudo chmod +x install.sh
sudo ./install.sh

### Prérequis

Ubuntu/Debian ou CentOS/RHEL
Accès root (sudo)
Connexion internet

### Ce qui sera installé

Nginx
Go 1.23.4
Dépendances système

🔧 Configuration
Le script vous posera les questions suivantes :

IP/Domaine du backend
Port du backend
Port d'écoute du WAF
Règles de sécurité personnalisées

### Utilisation complète :

# 1. Cloner le repo
git clone https://github.com/votre-username/waf-nginx-deployment.git
cd waf-nginx-deployment

# 2. Rendre exécutable
chmod +x install.sh
chmod +x scripts/*.sh

# 3. Lancer l'installation
sudo ./install.sh

### Commandes de gestion post-installation :

# Redémarrer le WAF
sudo systemctl restart waf

# Voir les logs en temps réel
sudo journalctl -u waf -f

# Arrêter le WAF
sudo systemctl stop waf

# Tester la configuration
sudo bash scripts/test_config.sh

# Reconfigurer
sudo bash scripts/configure.sh

