#!/bin/bash

# ========================================
# SCRIPT DE SINCRONIZAÇÃO CONTEXT7
# Sincroniza o Context7 com todos os CLIs
# ========================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuração do Context7
CONTEXT7_CONFIG='{
  "command": "npx",
  "args": [
    "-y",
    "@upstash/context7-mcp",
    "--api-key",
    "ctx7sk-dffbb00c-6537-44b3-8d1d-0d67edca9d22"
  ]
}'

# Função para configurar um CLI
configure_cli() {
    local cli_name="$1"
    local config_path="$2"
    local settings_file="$3"
    
    log "Configurando $cli_name..."
    
    if [[ ! -d "$config_path" ]]; then
        warn "Diretório $config_path não existe, criando..."
        mkdir -p "$config_path"
    fi
    
    # Verificar se o arquivo de configuração existe
    if [[ -f "$settings_file" ]]; then
        log "Arquivo de configuração existente encontrado, fazendo backup..."
        cp "$settings_file" "${settings_file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Criar nova configuração
    if [[ "$cli_name" == "Cursor" ]]; then
        cat > "$settings_file" << EOF
{
  "mcpServers": {
    "context7": $CONTEXT7_CONFIG
  },
  "mcp": {
    "enabled": true,
    "autoStart": true,
    "logLevel": "info"
  }
}
EOF
    else
        # Para outros CLIs, tentar preservar configurações existentes
        if [[ -f "$settings_file" ]]; then
            # Tentar usar jq para mesclar, se disponível
            if command -v jq &> /dev/null; then
                log "Usando jq para mesclar configurações..."
                jq --argjson context7 "$CONTEXT7_CONFIG" '
                    .mcpServers.context7 = $context7 |
                    .mcp = (.mcp // {}) |
                    .mcp.enabled = true |
                    .mcp.autoStart = true |
                    .mcp.logLevel = "info"
                ' "$settings_file" > "${settings_file}.tmp" && mv "${settings_file}.tmp" "$settings_file"
            else
                warn "jq não encontrado, criando configuração básica..."
                cat > "$settings_file" << EOF
{
  "mcpServers": {
    "context7": $CONTEXT7_CONFIG
  },
  "mcp": {
    "enabled": true,
    "autoStart": true,
    "logLevel": "info"
  }
}
EOF
            fi
        else
            # Criar arquivo do zero
            cat > "$settings_file" << EOF
{
  "mcpServers": {
    "context7": $CONTEXT7_CONFIG
  },
  "mcp": {
    "enabled": true,
    "autoStart": true,
    "logLevel": "info"
  }
}
EOF
        fi
    fi
    
    log "✅ $cli_name configurado com sucesso!"
}

# Função principal
main() {
    log "🚀 Iniciando sincronização do Context7 com todos os CLIs..."
    
    # Verificar se a API key está configurada
    if [[ ! -f "servers/ai/context7-server/.env" ]]; then
        error "Arquivo .env do Context7 não encontrado!"
        error "Execute primeiro: npm run setup"
        exit 1
    fi
    
    # Configurar Cursor
    configure_cli "Cursor" "$HOME/.cursor" "$HOME/.cursor/mcp.json"
    
    # Configurar VS Code
    configure_cli "VS Code" "$HOME/.vscode" "$HOME/.vscode/settings.json"
    
    # Configurar Claude Desktop
    configure_cli "Claude Desktop" "$HOME/.claude" "$HOME/.claude/settings.json"
    
    # Configurar Gemini CLI
    configure_cli "Gemini CLI" "$HOME/.gemini" "$HOME/.gemini/settings.json"
    
    log "🎉 Sincronização concluída com sucesso!"
    log ""
    log "📋 Resumo da configuração:"
    log "   ✅ Cursor: ~/.cursor/mcp.json"
    log "   ✅ VS Code: ~/.vscode/settings.json"
    log "   ✅ Claude Desktop: ~/.claude/settings.json"
    log "   ✅ Gemini CLI: ~/.gemini/settings.json"
    log ""
    log "🔄 Para testar:"
    log "   1. Reinicie cada CLI"
    log "   2. Teste com: 'resolve-library-id com libraryName \"react\"'"
    log "   3. Verifique se o Context7 aparece nas ferramentas disponíveis"
}

# Executar função principal
main "$@"
