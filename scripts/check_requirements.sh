#!/bin/bash

# Vérification des prérequis

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[CHECK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Détecter l'OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        error "OS non supporté"
        exit 1
    fi
    
    log "OS détecté : $OS $OS_VERSION"
    echo "OS=$OS" > .os_info
    echo "OS_VERSION=$OS_VERSION" >> .os_info
}

# Vérifier les commandes essentielles
check_commands() {
    local missing=()
    
    for cmd in curl wget tar gzip; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        warn "Commandes manquantes : ${missing[*]}"
        echo "MISSING_COMMANDS=${missing[*]}" >> .os_info
    else
        log "✓ Toutes les commandes essentielles sont présentes"
    fi
}

# Vérifier Nginx
check_nginx() {
    if command -v nginx &> /dev/null; then
        NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2)
        log "✓ Nginx déjà installé : version $NGINX_VERSION"
        echo "NGINX_INSTALLED=true" >> .os_info
    else
        warn "✗ Nginx non installé"
        echo "NGINX_INSTALLED=false" >> .os_info
    fi
}

# Vérifier Go
check_go() {
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}')
        log "✓ Go déjà installé : $GO_VERSION"
        
        # Vérifier si c'est la bonne version
        if [[ "$GO_VERSION" == "go1.23.4" ]]; then
            log "✓ Version Go correcte"
            echo "GO_INSTALLED=true" >> .os_info
        else
            warn "Version Go différente de 1.23.4"
            echo "GO_INSTALLED=upgrade" >> .os_info
        fi
    else
        warn "✗ Go non installé"
        echo "GO_INSTALLED=false" >> .os_info
    fi
}

# Vérifier les ports disponibles
check_ports() {
    log "Vérification des ports..."
    
    for port in 80 443 8080; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            warn "Port $port déjà utilisé"
        else
            log "✓ Port $port disponible"
        fi
    done
}

# Vérifier l'espace disque
check_disk_space() {
    AVAILABLE=$(df / | tail -1 | awk '{print $4}')
    AVAILABLE_GB=$((AVAILABLE / 1024 / 1024))
    
    if [ $AVAILABLE_GB -lt 1 ]; then
        error "Espace disque insuffisant : ${AVAILABLE_GB}GB disponible"
        exit 1
    else
        log "✓ Espace disque suffisant : ${AVAILABLE_GB}GB disponible"
    fi
}

# Vérifier la RAM
check_memory() {
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    
    if [ $TOTAL_RAM -lt 512 ]; then
        warn "RAM faible : ${TOTAL_RAM}MB (recommandé : 1GB+)"
    else
        log "✓ RAM suffisante : ${TOTAL_RAM}MB"
    fi
}

# Vérifier la connexion internet
check_internet() {
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log "✓ Connexion internet OK"
    else
        error "✗ Pas de connexion internet"
        exit 1
    fi
}

# Fonction principale
main() {
    echo "CHECKING=true" > .os_info
    
    detect_os
    check_commands
    check_nginx
    check_go
    check_ports
    check_disk_space
    check_memory
    check_internet
    
    log "Vérification des prérequis terminée"
}

main