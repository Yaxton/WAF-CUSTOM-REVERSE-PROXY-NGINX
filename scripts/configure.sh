#!/bin/bash

# Configuration interactive du WAF et Nginx

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.waf_config"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

prompt() {
    echo -e "${BLUE}[CONFIG]${NC} $1"
}

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Questions interactives
ask_questions() {
    prompt "Configuration du WAF et Nginx"
    echo ""
    
    # Backend URL
    read -p "➤ URL/IP du backend (ex: http://192.168.1.40:3000) : " BACKEND_URL
    BACKEND_URL=${BACKEND_URL:-http://localhost:3000}
    
    # Port WAF
    read -p "➤ Port d'écoute du WAF [80] : " WAF_PORT
    WAF_PORT=${WAF_PORT:-80}
    
    # Port Nginx
    read -p "➤ Port d'écoute de Nginx [8080] : " NGINX_PORT
    NGINX_PORT=${NGINX_PORT:-8080}
    
    echo ""
    prompt "Configuration des règles de sécurité"
    echo ""
    
    # Protection SQL Injection
    read -p "➤ Activer la protection SQL Injection ? [O/n] : " sql_prot
    ENABLE_SQL_PROTECTION=${sql_prot:-O}
    
    # Protection XSS
    read -p "➤ Activer la protection XSS ? [O/n] : " xss_prot
    ENABLE_XSS_PROTECTION=${xss_prot:-O}
    
    # Protection Path Traversal
    read -p "➤ Activer la protection Path Traversal ? [O/n] : " path_prot
    ENABLE_PATH_TRAVERSAL=${path_prot:-O}
    
    # Protection quantités négatives
    read -p "➤ Bloquer les quantités négatives ? [O/n] : " neg_qty
    ENABLE_NEGATIVE_QTY=${neg_qty:-O}
    
    # Protection directory listing
    read -p "➤ Bloquer le directory listing ? [O/n] : " dir_list
    ENABLE_DIR_LISTING=${dir_list:-O}
    
    # Fichiers sensibles
    read -p "➤ Bloquer l'accès aux fichiers sensibles (.bak, .old, etc) ? [O/n] : " sens_files
    ENABLE_SENSITIVE_FILES=${sens_files:-O}
    
    echo ""
    prompt "Configuration du logging"
    echo ""
    
    # Niveau de log
    echo "Niveaux disponibles : 1=Minimal, 2=Normal, 3=Verbeux"
    read -p "➤ Niveau de log [2] : " log_level
    LOG_LEVEL=${log_level:-2}
    
    # Sauvegarder la configuration
    save_config
}

# Sauvegarder la configuration
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Configuration WAF + Nginx
BACKEND_URL="$BACKEND_URL"
WAF_PORT="$WAF_PORT"
NGINX_PORT="$NGINX_PORT"
ENABLE_SQL_PROTECTION="$ENABLE_SQL_PROTECTION"
ENABLE_XSS_PROTECTION="$ENABLE_XSS_PROTECTION"
ENABLE_PATH_TRAVERSAL="$ENABLE_PATH_TRAVERSAL"
ENABLE_NEGATIVE_QTY="$ENABLE_NEGATIVE_QTY"
ENABLE_DIR_LISTING="$ENABLE_DIR_LISTING"
ENABLE_SENSITIVE_FILES="$ENABLE_SENSITIVE_FILES"
LOG_LEVEL="$LOG_LEVEL"
EOF
    
    log "Configuration sauvegardée dans $CONFIG_FILE"
}

# Générer le fichier WAF Go
generate_waf() {
    log "Génération du fichier WAF..."
    
    source "$CONFIG_FILE"
    
    # Construire les patterns dynamiquement
    local patterns=""
    
    if [[ "$ENABLE_SQL_PROTECTION" =~ ^[Oo]$ ]]; then
        patterns+='    regexp.MustCompile(`(?i)(union.*select|select.*from)`),
    regexp.MustCompile(`(?i)(\%27)|('"'"')|(\-\-)|(\%23)|(#)`),
'
    fi
    
    if [[ "$ENABLE_XSS_PROTECTION" =~ ^[Oo]$ ]]; then
        patterns+='    regexp.MustCompile(`(?i)(<script|javascript:|onerror=|onload=)`),
'
    fi
    
    if [[ "$ENABLE_PATH_TRAVERSAL" =~ ^[Oo]$ ]]; then
        patterns+='    regexp.MustCompile(`(?i)(\.\.\/|\.\.\\|%2e%2e%2f|%2e%2e%5c|%252e%252e%252f)`),
'
    fi
    
    if [[ "$ENABLE_NEGATIVE_QTY" =~ ^[Oo]$ ]]; then
        patterns+='    regexp.MustCompile(`"quantity"\s*:\s*-\d+`),
'
    fi
    
    # Remplacer dans le template
    sed -e "s|{{BACKEND_URL}}|$BACKEND_URL|g" \
        -e "s|{{WAF_PORT}}|$WAF_PORT|g" \
        -e "s|{{PATTERNS}}|$patterns|g" \
        "$SCRIPT_DIR/config/waf.go.template" > "$SCRIPT_DIR/config/waf.go"
    
    log "✓ Fichier WAF généré : $SCRIPT_DIR/config/waf.go"
}

# Générer la configuration Nginx
generate_nginx() {
    log "Génération de la configuration Nginx..."
    
    source "$CONFIG_FILE"
    
    sed -e "s|{{NGINX_PORT}}|$NGINX_PORT|g" \
        -e "s|{{WAF_PORT}}|$WAF_PORT|g" \
        "$SCRIPT_DIR/config/nginx.conf.template" > /etc/nginx/nginx.conf
    
    log "✓ Configuration Nginx générée"
}

# Générer le service systemd
generate_service() {
    log "Génération du service systemd..."
    
    source "$CONFIG_FILE"
    
    sed -e "s|{{WAF_PORT}}|$WAF_PORT|g" \
        "$SCRIPT_DIR/config/waf.service.template" > "$SCRIPT_DIR/config/waf.service"
    
    log "✓ Service systemd généré"
}

# Afficher un résumé
show_summary() {
    source "$CONFIG_FILE"
    
    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║     RÉSUMÉ DE LA CONFIGURATION        ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Backend           : $BACKEND_URL"
    echo "Port WAF          : $WAF_PORT"
    echo "Port Nginx        : $NGINX_PORT"
    echo ""
    echo "Protections activées :"
    [[ "$ENABLE_SQL_PROTECTION" =~ ^[Oo]$ ]] && echo "  ✓ SQL Injection"
    [[ "$ENABLE_XSS_PROTECTION" =~ ^[Oo]$ ]] && echo "  ✓ XSS"
    [[ "$ENABLE_PATH_TRAVERSAL" =~ ^[Oo]$ ]] && echo "  ✓ Path Traversal"
    [[ "$ENABLE_NEGATIVE_QTY" =~ ^[Oo]$ ]] && echo "  ✓ Quantités négatives"
    echo ""
    
    read -p "Confirmer cette configuration ? [O/n] : " confirm
    if [[ ! "$confirm" =~ ^[Oo]?$ ]]; then
        log "Configuration annulée"
        exit 1
    fi
}

# Fonction principale
main() {
    ask_questions
    show_summary
    generate_waf
    generate_nginx
    generate_service
    
    log "Configuration terminée"
}

main