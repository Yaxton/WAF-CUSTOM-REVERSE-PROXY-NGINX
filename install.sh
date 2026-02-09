## 2. install.sh (Script principal)

```bash
#!/bin/bash

# ============================================
# WAF + Nginx - Installation automatisée
# ============================================
# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.waf_config"
LOG_FILE="$SCRIPT_DIR/install.log"

# Fonctions utilitaires
log() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"
}

# Vérifier les permissions root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Ce script doit être exécuté en tant que root (sudo)"
    fi
}

# Bannière
show_banner() {
    clear
    cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║   WAF + Nginx Reverse Proxy Installer                ║
║                                                      ║
║   Déploiement automatisé et sécurisé                 ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
    echo ""
}

# Fonction principale
main() {
    check_root
    show_banner
    
    log "Début de l'installation..."
    
    # Étape 1 : Vérification des prérequis
    header "ÉTAPE 1/6 : Vérification des prérequis"
    bash "$SCRIPT_DIR/scripts/check_requirements.sh"
    
    # Étape 2 : Installation des dépendances
    header "ÉTAPE 2/6 : Installation des dépendances"
    bash "$SCRIPT_DIR/scripts/install_dependencies.sh"
    
    # Étape 3 : Configuration
    header "ÉTAPE 3/6 : Configuration du WAF et Nginx"
    bash "$SCRIPT_DIR/scripts/configure.sh"
    
    # Étape 4 : Compilation du WAF
    header "ÉTAPE 4/6 : Compilation du WAF"
    compile_waf
    
    # Étape 5 : Configuration des services
    header "ÉTAPE 5/6 : Configuration des services"
    setup_services
    
    # Étape 6 : Tests
    header "ÉTAPE 6/6 : Tests de configuration"
    bash "$SCRIPT_DIR/scripts/test_config.sh"
    
    # Résumé final
    show_summary
}

# Compilation du WAF
compile_waf() {
    log "Compilation du WAF en Go..."
    
    cd "$SCRIPT_DIR/config"
    
    if ! /usr/local/go/bin/go build -o /usr/local/bin/waf waf.go; then
        error "Échec de la compilation du WAF"
    fi
    
    chmod +x /usr/local/bin/waf
    log "WAF compilé avec succès : /usr/local/bin/waf"
}

# Configuration des services systemd
setup_services() {
    log "Configuration du service systemd pour le WAF..."
    
    # Copier le service WAF
    cp "$SCRIPT_DIR/config/waf.service" /etc/systemd/system/waf.service
    
    # Recharger systemd
    systemctl daemon-reload
    
    # Activer les services
    systemctl enable nginx
    
    # Démarrer les services
    log "Démarrage du WAF..."
    
    log "Démarrage de Nginx..."
    systemctl restart nginx
    
    # Vérifier le statut
    print("WAF correctement installé")
    
    if systemctl is-active --quiet nginx; then
        log "✓ Service Nginx démarré avec succès"
    else
        error "✗ Échec du démarrage de Nginx"
    fi
}

# Résumé final
show_summary() {
    source "$CONFIG_FILE"
    
    header "INSTALLATION TERMINÉE"
    
    cat << EOF
╔══════════════════════════════════════════════════════╗
║              RÉSUMÉ DE LA CONFIGURATION              ║
╚══════════════════════════════════════════════════════╝

 Configuration réseau :
   • WAF écoute sur        : 0.0.0.0:${WAF_PORT}
   • Backend cible         : ${BACKEND_URL}
   • Nginx écoute sur      : ${NGINX_PORT}

  Sécurité :
   • Anti SQL Injection    : ${ENABLE_SQL_PROTECTION}
   • Anti XSS              : ${ENABLE_XSS_PROTECTION}
   • Anti Path Traversal   : ${ENABLE_PATH_TRAVERSAL}
   • Quantités négatives   : ${ENABLE_NEGATIVE_QTY}

 Services :
   • WAF Status    : $(systemctl is-active waf)
   • Nginx Status  : $(systemctl is-active nginx)

 Fichiers importants :
   • WAF binaire   : /usr/local/bin/waf
   • Config Nginx  : /etc/nginx/nginx.conf
   • Logs WAF      : journalctl -u waf -f
   • Logs Nginx    : /var/log/nginx/

 Commandes utiles :
   • Redémarrer WAF   : sudo systemctl restart waf
   • Redémarrer Nginx : sudo systemctl restart nginx
   • Voir logs WAF    : sudo journalctl -u waf -f
   • Tester config    : sudo bash $SCRIPT_DIR/scripts/test_config.sh

╔══════════════════════════════════════════════════════╗
║   Votre WAF est maintenant opérationnel !            ║
╚══════════════════════════════════════════════════════╝

EOF
}

# Lancer le script
main

exit 0

