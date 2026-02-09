#!/bin/bash

# Installation des dépendances

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INSTALL]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Charger les infos OS
source .os_info

# Installer Go 1.23.4
install_go() {
    if [[ "$GO_INSTALLED" == "true" ]]; then
        log "Go déjà installé, passage..."
        return
    fi
    
    log "Installation de Go 1.23.4..."
    
    # Télécharger Go
    GO_VERSION="1.23.4"
    GO_ARCH="linux-amd64"
    GO_URL="https://go.dev/dl/go${GO_VERSION}.${GO_ARCH}.tar.gz"
    
    cd /tmp
    wget -q --show-progress "$GO_URL" -O go.tar.gz
    
    # Supprimer l'ancienne installation
    rm -rf /usr/local/go
    
    # Extraire
    tar -C /usr/local -xzf go.tar.gz
    
    # Configurer PATH
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi
    
    export PATH=$PATH:/usr/local/go/bin
    
    # Vérifier
    if /usr/local/go/bin/go version; then
        log "✓ Go installé avec succès"
    else
        error "Échec de l'installation de Go"
    fi
    
    rm -f go.tar.gz
}

# Installer Nginx
install_nginx() {
    if [[ "$NGINX_INSTALLED" == "true" ]]; then
        log "Nginx déjà installé, passage..."
        return
    fi
    
    log "Installation de Nginx..."
    
    case "$OS" in
        ubuntu|debian)
            apt-get update
            apt-get install -y nginx
            ;;
        centos|rhel|fedora)
            yum install -y nginx || dnf install -y nginx
            ;;
        *)
            error "OS non supporté pour l'installation automatique"
            ;;
    esac
    
    # Vérifier
    if command -v nginx &> /dev/null; then
        log "✓ Nginx installé avec succès"
    else
        error "Échec de l'installation de Nginx"
    fi
}

# Installer les outils système
install_system_tools() {
    log "Installation des outils système..."
    
    case "$OS" in
        ubuntu|debian)
            apt-get install -y curl wget net-tools
            ;;
        centos|rhel|fedora)
            yum install -y curl wget net-tools || dnf install -y curl wget net-tools
            ;;
    esac
    
    log "✓ Outils système installés"
}

# Fonction principale
main() {
    install_system_tools
    install_go
    install_nginx
    
    log "Installation des dépendances terminée"
}

main