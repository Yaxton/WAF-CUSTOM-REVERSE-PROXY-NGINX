#!/bin/bash

# Tests de configuration

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Charger la config
source .waf_config

# Test 1 : Vérifier que Nginx démarre
test_nginx() {
    log "Test de la configuration Nginx..."
    
    if nginx -t 2>/dev/null; then
        log "✓ Configuration Nginx valide"
    else
        error "✗ Configuration Nginx invalide"
        exit 1
    fi
}

# Test 2 : Vérifier que le WAF démarre
test_waf() {
    log "Test du service WAF..."
    
    if systemctl is-active --quiet waf; then
        log "✓ WAF actif"
    else
        error "✗ WAF non actif"
        journalctl -u waf -n 20 --no-pager
        exit 1
    fi
}

# Test 3 : Test de connectivité
test_connectivity() {
    log "Test de connectivité..."
    
    sleep 2
    
    # Test HTTP
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:${NGINX_PORT}/ | grep -q "200\|301\|302"; then
        log "✓ Connectivité HTTP OK"
    else
        warn "✗ Échec de connexion HTTP"
    fi
}

# Test 4 : Test du blocage SQL Injection
test_sql_injection() {
    if [[ "$ENABLE_SQL_PROTECTION" =~ ^[Oo]$ ]]; then
        log "Test de blocage SQL Injection..."
        
        response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${NGINX_PORT}/?id=1' OR '1'='1")
        
        if [ "$response" == "403" ]; then
            log "✓ SQL Injection correctement bloquée"
        else
            warn "✗ SQL Injection non bloquée (code: $response)"
        fi
    fi
}

# Test 5 : Test du blocage XSS
test_xss() {
    if [[ "$ENABLE_XSS_PROTECTION" =~ ^[Oo]$ ]]; then
        log "Test de blocage XSS..."
        
        response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${NGINX_PORT}/?q=<script>alert(1)</script>")
        
        if [ "$response" == "403" ]; then
            log "✓ XSS correctement bloqué"
        else
            warn "✗ XSS non bloqué (code: $response)"
        fi
    fi
}

# Test 6 : Vérifier les logs
test_logs() {
    log "Vérification des logs..."
    
    if journalctl -u waf -n 5 --no-pager | grep -q "WAF running"; then
        log "✓ Logs WAF accessibles"
    else
        warn "✗ Problème avec les logs WAF"
    fi
}

# Résumé des tests
show_test_summary() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       TESTS DE CONFIGURATION          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# Fonction principale
main() {
    show_test_summary
    
    test_nginx
    test_waf
    test_connectivity
    test_sql_injection
    test_xss
    test_logs
    
    echo ""
    log "Tous les tests sont terminés !"
}

main
