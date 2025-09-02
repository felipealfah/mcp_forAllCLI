#!/bin/bash

# ========================================
# SCRIPT DE SINCRONIZAÇÃO UNIVERSAL
# Sincroniza TODOS os servidores MCP com TODOS os CLIs
# ========================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Função para detectar todos os servidores MCP
detect_all_servers() {
    declare -a servers
    
    # Procurar por servidores em todas as categorias
    for category in servers/*/; do
        if [[ -d "$category" ]]; then
            for server_dir in "$category"*/; do
                if [[ -d "$server_dir" ]] && [[ "$(basename "$server_dir")" != "*" ]]; then
                    local server_name=$(basename "$server_dir")
                    local config_file="$server_dir/config.json"
                    
                    if [[ -f "$config_file" ]]; then
                        # Extrair informações do config.json
                        local server_type=$(jq -r '.type // "unknown"' "$config_file" 2>/dev/null || echo "unknown")
                        
                        # Verificar se é um servidor válido
                        if [[ "$server_type" != "unknown" ]] && [[ -n "$server_name" ]] && [[ "$server_name" != "context7-server" ]]; then
                            servers+=("$server_name|$server_type|$config_file")
                        fi
                    fi
                fi
            done
        fi
    done
    
    # Adicionar o Context7 manualmente (já que sabemos que funciona)
    servers+=("context7|npx|manual")
    
    printf "%s\n" "${servers[@]}"
}

# Função para configurar um CLI com todos os servidores
configure_cli_universal() {
    local cli_name="$1"
    local config_path="$2"
    local settings_file="$3"
    local servers_info="$4"
    
    info "🔧 Configurando $cli_name com todos os servidores..."
    
    if [[ ! -d "$config_path" ]]; then
        warn "Diretório $config_path não existe, criando..."
        mkdir -p "$config_path"
    fi
    
    # Fazer backup da configuração existente
    if [[ -f "$settings_file" ]]; then
        local backup_file="${settings_file}.backup.$(date +%Y%m%d_%H%M%S)"
        log "Fazendo backup: $backup_file"
        cp "$settings_file" "$backup_file"
    fi
    
    # Criar configuração MCP base
    cat > "$settings_file" << EOF
{
  "mcpServers": {
EOF
    
    # Adicionar cada servidor
    local first_server=true
    while IFS= read -r server_info; do
        [[ -z "$server_info" ]] && continue
        IFS='|' read -r server_name server_type config_file <<< "$server_info"
        
        if [[ "$server_type" == "npx" ]]; then
            # Servidor npx (como Context7)
            if $first_server; then
                echo "    \"$server_name\": {" >> "$settings_file"
                first_server=false
            else
                echo "    ," >> "$settings_file"
                echo "    \"$server_name\": {" >> "$settings_file"
            fi
            
            if [[ "$server_name" == "context7" ]]; then
                # Context7 com configuração hardcoded
                echo "      \"command\": \"npx\"," >> "$settings_file"
                echo "      \"args\": [\"-y\", \"@upstash/context7-mcp\", \"--api-key\", \"ctx7sk-dffbb00c-6537-44b3-8d1d-0d67edca9d22\"]" >> "$settings_file"
            else
                # Extrair argumentos do config.json
                local args=$(jq -r '.args | map("\"" + . + "\"") | join(", ")' "$config_file" 2>/dev/null || echo "\"-y\", \"$server_name\"")
                echo "      \"command\": \"npx\"," >> "$settings_file"
                echo "      \"args\": [$args]" >> "$settings_file"
            fi
            echo "    }" >> "$settings_file"
            
        elif [[ "$server_type" == "node" ]]; then
            # Servidor Node.js local
            if $first_server; then
                echo "    \"$server_name\": {" >> "$settings_file"
                first_server=false
            else
                echo "    ," >> "$settings_file"
                echo "    \"$server_name\": {" >> "$settings_file"
            fi
            
            # Primeiro, tentar ler o path do config.json
            local server_path=$(jq -r '.path // ""' "$config_file" 2>/dev/null || echo "")
            
            # Se não encontrar, tentar construir o caminho baseado na estrutura do projeto
            if [[ -z "$server_path" ]] || [[ "$server_path" == "null" ]]; then
                # Extrair o diretório base do config_file
                local server_base_dir=$(dirname "$config_file")
                local abs_server_dir=$(cd "$server_base_dir" && pwd)
                
                # Verificar se existe dist/index.js (padrão TypeScript)
                if [[ -f "$abs_server_dir/dist/index.js" ]]; then
                    server_path="$abs_server_dir/dist/index.js"
                elif [[ -f "$abs_server_dir/index.js" ]]; then
                    server_path="$abs_server_dir/index.js"
                elif [[ -f "$abs_server_dir/server.js" ]]; then
                    server_path="$abs_server_dir/server.js"
                else
                    server_path="$abs_server_dir/dist/index.js"  # fallback
                fi
            fi
            
            echo "      \"command\": \"node\"," >> "$settings_file"
            echo "      \"args\": [\"$server_path\"]" >> "$settings_file"
            echo "    }" >> "$settings_file"
            
        else
            # Servidor genérico
            if $first_server; then
                echo "    \"$server_name\": {" >> "$settings_file"
                first_server=false
            else
                echo "    ," >> "$settings_file"
                echo "    \"$server_name\": {" >> "$settings_file"
            fi
            
            echo "      \"command\": \"$server_command\"," >> "$settings_file"
            echo "      \"args\": $server_args" >> "$settings_file"
            echo "    }" >> "$settings_file"
        fi
        
        log "   ✅ Adicionado: $server_name ($server_type)"
    done <<< "$servers_info"
    
    # Finalizar configuração
    cat >> "$settings_file" << EOF
  },
  "mcp": {
    "enabled": true,
    "autoStart": true,
    "logLevel": "info"
  }
}
EOF
    
    success "✅ $cli_name configurado com sucesso!"
}

# Função para sincronizar com todos os CLIs
sync_all_clis() {
    local servers_info="$1"
    
    log "🚀 Iniciando sincronização universal..."
    
    # Configurar Cursor
    configure_cli_universal "Cursor" "$HOME/.cursor" "$HOME/.cursor/mcp.json" "$servers_info"
    
    # Configurar VS Code
    configure_cli_universal "VS Code" "$HOME/.vscode" "$HOME/.vscode/settings.json" "$servers_info"
    
    # Configurar Claude Desktop
    configure_cli_universal "Claude Desktop" "$HOME/.claude" "$HOME/.claude/settings.json" "$servers_info"
    
    # Configurar Gemini CLI
    configure_cli_universal "Gemini CLI" "$HOME/.gemini" "$HOME/.gemini/settings.json" "$servers_info"
    
    # Verificar se há outros CLIs conhecidos
    if [[ -d "$HOME/.neovim" ]]; then
        configure_cli_universal "Neovim" "$HOME/.neovim" "$HOME/.neovim/init.lua" "$servers_info"
    fi
    
    if [[ -d "$HOME/.helix" ]]; then
        configure_cli_universal "Helix" "$HOME/.helix" "$HOME/.helix/config.toml" "$servers_info"
    fi
}

# Função para instalar servidor do Smithery.ai
install_smithery_server() {
    local server_name="$1"
    local category="$2"
    
    info "🌐 Instalando servidor do Smithery.ai: $server_name"
    
    # Criar diretório do servidor
    local server_dir="servers/$category/$server_name"
    mkdir -p "$server_dir"
    
    # Criar config.json para servidor Smithery
    cat > "$server_dir/config.json" << EOF
{
  "name": "$server_name",
  "type": "npx",
  "description": "Servidor MCP do Smithery.ai",
  "command": "npx",
  "args": ["-y", "$server_name"],
  "capabilities": ["tools"],
  "category": "$category",
  "source": "smithery.ai"
}
EOF
    
    # Criar README.md
    cat > "$server_dir/README.md" << EOF
# $server_name

Servidor MCP instalado do [Smithery.ai](https://smithery.ai/).

## Instalação

Este servidor foi instalado automaticamente e configurado para funcionar com todos os CLIs.

## Uso

O servidor estará disponível em todos os CLIs configurados após a sincronização.

## Fonte

- **Origem**: Smithery.ai
- **Categoria**: $category
- **Tipo**: npx package
EOF
    
    success "✅ Servidor $server_name instalado do Smithery.ai!"
}

# Função principal
main() {
    echo -e "${PURPLE}🚀 SISTEMA DE SINCRONIZAÇÃO UNIVERSAL MCP${NC}"
    echo "=================================================="
    
    # Verificar se jq está instalado
    if ! command -v jq &> /dev/null; then
        error "❌ jq não está instalado. Instale com: brew install jq"
        exit 1
    fi
    
    # Detectar todos os servidores
    log "🔍 Detectando todos os servidores MCP..."
    local servers_info=$(detect_all_servers)
    
    if [[ -z "$servers_info" ]]; then
        warn "⚠️  Nenhum servidor MCP encontrado!"
        log "Execute primeiro: npm run setup"
        exit 1
    fi
    
    # Mostrar servidores detectados
    log "📋 Servidores detectados:"
    while IFS= read -r server_info; do
        [[ -z "$server_info" ]] && continue
        IFS='|' read -r server_name server_type config_file <<< "$server_info"
        echo "   🔧 $server_name ($server_type)"
    done <<< "$servers_info"
    
    # Sincronizar com todos os CLIs
    sync_all_clis "$servers_info"
    
    echo -e "\n${PURPLE}🎉 SINCRONIZAÇÃO UNIVERSAL CONCLUÍDA!${NC}"
    echo "=========================================="
    echo ""
    echo "📋 CLIs sincronizados:"
    echo "   ✅ Cursor"
    echo "   ✅ VS Code"
    echo "   ✅ Claude Desktop"
    echo "   ✅ Gemini CLI"
    echo ""
    echo "🔄 Para sincronizar novamente:"
    echo "   ./scripts/sync-all-clis-universal.sh"
    echo ""
    echo "🌐 Para instalar do Smithery.ai:"
    echo "   ./scripts/install-smithery-server.sh <nome-do-servidor> <categoria>"
}

# Executar função principal
main "$@"
