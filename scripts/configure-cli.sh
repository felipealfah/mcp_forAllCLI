#!/bin/bash

# ========================================
# MCP Hub - Configurador Automático de CLIs
# ========================================
# Este script configura automaticamente CLIs para usar
# servidores MCP do hub

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_message() {
    echo -e "${BLUE}[MCP Hub]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Variáveis globais
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SERVERS_DIR="$ROOT_DIR/servers"
CONFIGS_DIR="$ROOT_DIR/configs"
CLI_PROFILES_DIR="$ROOT_DIR/cli-profiles"
TEMPLATES_DIR="$ROOT_DIR/configs/templates"

# Função para mostrar ajuda
show_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🔧 MCP Hub - Configurador de CLIs${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Uso: $0 [OPÇÕES] <CLI_NAME>"
    echo ""
    echo "OPÇÕES:"
    echo "  -a, --all                    Configurar todas as CLIs habilitadas"
    echo "  -s, --servers                Incluir todos os servidores disponíveis"
    echo "  -f, --force                  Forçar reconfiguração (sobrescrever)"
    echo "  -t, --template               Usar template padrão da CLI"
    echo "  -c, --custom                 Configuração personalizada"
    echo "  -h, --help                   Mostrar esta ajuda"
    echo ""
    echo "CLIs SUPORTADAS:"
    echo "  cursor                       Cursor Editor"
    echo "  vscode                       Visual Studio Code"
    echo "  neovim                       Neovim"
    echo "  emacs                        Emacs"
    echo "  sublime                      Sublime Text"
    echo "  intellij                     IntelliJ IDEA"
    echo ""
    echo "EXEMPLOS:"
    echo "  $0 cursor                    # Configurar apenas Cursor"
    echo "  $0 -a                        # Configurar todas as CLIs"
    echo "  $0 -a -s                     # Configurar todas as CLIs com todos os servidores"
    echo "  $0 cursor -f                 # Forçar reconfiguração do Cursor"
    echo ""
}

# Função para detectar servidores disponíveis
detect_servers() {
    local servers=()
    
    for category in ai development database cloud custom; do
        local category_path="$SERVERS_DIR/$category"
        if [[ -d "$category_path" ]]; then
            for server in "$category_path"/*; do
                if [[ -d "$server" ]]; then
                    local server_name=$(basename "$server")
                    local config_file="$server/config.json"
                    
                    if [[ -f "$config_file" ]]; then
                        # Verificar se o servidor está habilitado
                        if command -v jq &> /dev/null; then
                            if jq -e '.enabled == true' "$config_file" > /dev/null 2>&1; then
                                servers+=("$category/$server_name")
                            fi
                        else
                            # Fallback se jq não estiver disponível
                            if grep -q '"enabled": true' "$config_file" 2>/dev/null; then
                                servers+=("$category/$server_name")
                            fi
                        fi
                    fi
                fi
            done
        fi
    done
    
    echo "${servers[@]}"
}

# Função para gerar configuração do Cursor
generate_cursor_config() {
    local servers=("$@")
    local config_file="$HOME/.cursor/User/settings.json"
    local config_dir="$HOME/.cursor/User"
    
    print_message "Gerando configuração para Cursor..."
    
    # Criar diretório se não existir
    mkdir -p "$config_dir"
    
    # Configuração base
    local mcp_config='{
  "mcpServers": {'
    
    # Adicionar servidores
    local first=true
    for server in "${servers[@]}"; do
        local category=$(echo "$server" | cut -d'/' -f1)
        local server_name=$(echo "$server" | cut -d'/' -f2)
        local server_path="$ROOT_DIR/servers/$server"
        local config_json="$server_path/config.json"
        
        if [[ -f "$config_json" ]]; then
            # Determinar comando baseado no tipo
            local server_type=""
            if command -v jq &> /dev/null; then
                server_type=$(jq -r '.type' "$config_json" 2>/dev/null || echo "node")
            else
                server_type=$(grep '"type"' "$config_json" | head -1 | sed 's/.*"type": *"\([^"]*\)".*/\1/' || echo "node")
            fi
            
            # Determinar comando e argumentos
            local command=""
            local args=""
            case "$server_type" in
                "node")
                    command="node"
                    args="[\"$server_path/server.js\"]"
                    ;;
                "python")
                    command="python3"
                    args="[\"$server_path/server.py\"]"
                    ;;
                "go")
                    command="go"
                    args="[\"run\", \"$server_path/main.go\"]"
                    ;;
                "rust")
                    command="cargo"
                    args="[\"run\", \"--manifest-path\", \"$server_path/Cargo.toml\"]"
                    ;;
                *)
                    command="echo"
                    args="[\"Servidor $server_name não implementado\"]"
                    ;;
            esac
            
            # Adicionar vírgula se não for o primeiro
            if [[ "$first" == "true" ]]; then
                first=false
            else
                mcp_config+=","
            fi
            
            # Adicionar servidor
            mcp_config+="
    \"$server_name\": {
      \"command\": \"$command\",
      \"args\": $args"
            
            # Adicionar variáveis de ambiente se existirem
            if [[ -f "$server_path/env.example" ]]; then
                mcp_config+=",
      \"env\": {"
                
                local env_first=true
                while IFS= read -r line; do
                    if [[ "$line" =~ ^[A-Z_]+= ]]; then
                        local env_var=$(echo "$line" | cut -d'=' -f1)
                        if [[ "$env_first" == "true" ]]; then
                            env_first=false
                        else
                            mcp_config+=","
                        fi
                        mcp_config+="
        \"$env_var\": \"your_${env_var,,}_here\""
                    fi
                done < "$server_path/env.example"
                
                mcp_config+="
      }"
            fi
            
            mcp_config+="
    }"
        fi
    done
    
    mcp_config+="
  },
  "mcp": {
    "enabled": true,
    "autoStart": true,
    "logLevel": "info"
  }
}'
    
    # Verificar se arquivo de configuração já existe
    if [[ -f "$config_file" ]]; then
        # Fazer backup
        cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backup criado: $config_file.backup.*"
        
        # Mesclar configuração MCP com configuração existente
        if command -v jq &> /dev/null; then
            # Usar jq para mesclar
            local temp_config=$(mktemp)
            echo "$mcp_config" > "$temp_config"
            
            if jq -s '.[0] * .[1]' "$config_file" "$temp_config" > "$config_file.new" 2>/dev/null; then
                mv "$config_file.new" "$config_file"
            else
                echo "$mcp_config" > "$config_file.new"
                mv "$config_file.new" "$config_file"
            fi
            rm "$temp_config"
        else
            # Fallback: adicionar ao final do arquivo
            echo "$mcp_config" >> "$config_file"
            print_warning "Configuração MCP adicionada ao final do arquivo. Verifique se está correto."
        fi
    else
        # Criar novo arquivo
        echo "$mcp_config" > "$config_file"
    fi
    
    print_success "Configuração do Cursor criada: $config_file"
}

# Função para gerar configuração do VS Code
generate_vscode_config() {
    local servers=("$@")
    local config_file="$HOME/.vscode/settings.json"
    local config_dir="$HOME/.vscode"
    
    print_message "Gerando configuração para VS Code..."
    
    # Criar diretório se não existir
    mkdir -p "$config_dir"
    
    # Configuração base (similar ao Cursor)
    local mcp_config='{
  "mcpServers": {'
    
    # Adicionar servidores (mesma lógica do Cursor)
    local first=true
    for server in "${servers[@]}"; do
        local category=$(echo "$server" | cut -d'/' -f1)
        local server_name=$(echo "$server" | cut -d'/' -f2)
        local server_path="$ROOT_DIR/servers/$server"
        local config_json="$server_path/config.json"
        
        if [[ -f "$config_json" ]]; then
            # Determinar comando baseado no tipo
            local server_type=""
            if command -v jq &> /dev/null; then
                server_type=$(jq -r '.type' "$config_json" 2>/dev/null || echo "node")
            else
                server_type=$(grep '"type"' "$config_json" | head -1 | sed 's/.*"type": *"\([^"]*\)".*/\1/' || echo "node")
            fi
            
            # Determinar comando e argumentos
            local command=""
            local args=""
            case "$server_type" in
                "node")
                    command="node"
                    args="[\"$server_path/server.js\"]"
                    ;;
                "python")
                    command="python3"
                    args="[\"$server_path/server.py\"]"
                    ;;
                "go")
                    command="go"
                    args="[\"run\", \"$server_path/main.go\"]"
                    ;;
                "rust")
                    command="cargo"
                    args="[\"run\", \"--manifest-path\", \"$server_path/Cargo.toml\"]"
                    ;;
                *)
                    command="echo"
                    args="[\"Servidor $server_name não implementado\"]"
                    ;;
            esac
            
            # Adicionar vírgula se não for o primeiro
            if [[ "$first" == "true" ]]; then
                first=false
            else
                mcp_config+=","
            fi
            
            # Adicionar servidor
            mcp_config+="
    \"$server_name\": {
      \"command\": \"$command\",
      \"args\": $args"
            
            # Adicionar variáveis de ambiente se existirem
            if [[ -f "$server_path/env.example" ]]; then
                mcp_config+=",
      \"env\": {"
                
                local env_first=true
                while IFS= read -r line; do
                    if [[ "$line" =~ ^[A-Z_]+= ]]; then
                        local env_var=$(echo "$line" | cut -d'=' -f1)
                        if [[ "$env_first" == "true" ]]; then
                            env_first=false
                        else
                            mcp_config+=","
                        fi
                        mcp_config+="
        \"$env_var\": \"your_${env_var,,}_here\""
                    fi
                done < "$server_path/env.example"
                
                mcp_config+="
      }"
            fi
            
            mcp_config+="
    }"
        fi
    done
    
    mcp_config+="
  },
  "mcp": {
    "enabled": true,
    "autoStart": true,
    "logLevel": "info"
  }
}'
    
    # Verificar se arquivo de configuração já existe
    if [[ -f "$config_file" ]]; then
        # Fazer backup
        cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backup criado: $config_file.backup.*"
        
        # Mesclar configuração MCP com configuração existente
        if command -v jq &> /dev/null; then
            # Usar jq para mesclar
            local temp_config=$(mktemp)
            echo "$mcp_config" > "$temp_config"
            
            if jq -s '.[0] * .[1]' "$config_file" "$temp_config" > "$config_file.new" 2>/dev/null; then
                mv "$config_file.new" "$config_file"
            else
                echo "$mcp_config" > "$config_file.new"
                mv "$config_file.new" "$config_file"
            fi
            rm "$temp_config"
        else
            # Fallback: adicionar ao final do arquivo
            echo "$mcp_config" >> "$config_file"
            print_warning "Configuração MCP adicionada ao final do arquivo. Verifique se está correto."
        fi
    else
        # Criar novo arquivo
        echo "$mcp_config" > "$config_file"
    fi
    
    print_success "Configuração do VS Code criada: $config_file"
}

# Função para gerar configuração do Neovim
generate_neovim_config() {
    local servers=("$@")
    local config_file="$HOME/.config/nvim/init.lua"
    local config_dir="$HOME/.config/nvim"
    
    print_message "Gerando configuração para Neovim..."
    
    # Criar diretório se não existir
    mkdir -p "$config_dir"
    
    # Configuração Lua para Neovim
    local mcp_config='
-- MCP Servers Configuration
local mcp_servers = {'
    
    # Adicionar servidores
    for server in "${servers[@]}"; do
        local category=$(echo "$server" | cut -d'/' -f1)
        local server_name=$(echo "$server" | cut -d'/' -f2)
        local server_path="$ROOT_DIR/servers/$server"
        local config_json="$server_path/config.json"
        
        if [[ -f "$config_json" ]]; then
            # Determinar comando baseado no tipo
            local server_type=""
            if command -v jq &> /dev/null; then
                server_type=$(jq -r '.type' "$config_json" 2>/dev/null || echo "node")
            else
                server_type=$(grep '"type"' "$config_json" | head -1 | sed 's/.*"type": *"\([^"]*\)".*/\1/' || echo "node")
            fi
            
            # Determinar comando e argumentos
            local command=""
            local args=""
            case "$server_type" in
                "node")
                    command="node"
                    args="\"$server_path/server.js\""
                    ;;
                "python")
                    command="python3"
                    args="\"$server_path/server.py\""
                    ;;
                "go")
                    command="go"
                    args="\"run\", \"$server_path/main.go\""
                    ;;
                "rust")
                    command="cargo"
                    args="\"run\", \"--manifest-path\", \"$server_path/Cargo.toml\""
                    ;;
                *)
                    command="echo"
                    args="\"Servidor $server_name não implementado\""
                    ;;
            esac
            
            mcp_config+="
  {
    name = \"$server_name\",
    cmd = \"$command\",
    args = { $args }
  },"
        fi
    done
    
    mcp_config+="
}

-- Configuração MCP
require(\"mcp\").setup({
  servers = mcp_servers,
  enabled = true,
  auto_start = true,
  log_level = \"info\"
})'
    
    # Verificar se arquivo de configuração já existe
    if [[ -f "$config_file" ]]; then
        # Fazer backup
        cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backup criado: $config_file.backup.*"
        
        # Adicionar configuração MCP ao final
        echo "$mcp_config" >> "$config_file"
    else
        # Criar novo arquivo
        echo "$mcp_config" > "$config_file"
    fi
    
    print_success "Configuração do Neovim criada: $config_file"
}

# Função para configurar CLI específica
configure_cli() {
    local cli_name="$1"
    local servers=("$@")
    shift # Remove o primeiro argumento (nome da CLI)
    servers=("$@") # Resto são os servidores
    
    case "$cli_name" in
        "cursor")
            generate_cursor_config "${servers[@]}"
            ;;
        "vscode")
            generate_vscode_config "${servers[@]}"
            ;;
        "neovim")
            generate_neovim_config "${servers[@]}"
            ;;
        "emacs")
            print_warning "Configuração automática para Emacs não implementada ainda"
            ;;
        "sublime")
            print_warning "Configuração automática para Sublime não implementada ainda"
            ;;
        "intellij")
            print_warning "Configuração automática para IntelliJ não implementada ainda"
            ;;
        *)
            print_error "CLI não suportada: $cli_name"
            return 1
            ;;
    esac
}

# Função principal
main() {
    # Verificar se estamos no diretório correto
    if [[ ! -f "$ROOT_DIR/package.json" ]]; then
        print_error "Execute este script no diretório raiz do MCP Servers Hub"
        exit 1
    fi
    
    # Processar argumentos
    local configure_all=false
    local include_servers=false
    local force=false
    local use_template=false
    local custom_config=false
    local cli_name=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                configure_all=true
                shift
                ;;
            -s|--servers)
                include_servers=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -t|--template)
                use_template=true
                shift
                ;;
            -c|--custom)
                custom_config=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                print_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$cli_name" ]]; then
                    cli_name="$1"
                else
                    print_error "Múltiplas CLIs especificadas"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Detectar servidores se solicitado
    local servers=()
    if [[ "$include_servers" == "true" ]]; then
        print_message "Detectando servidores disponíveis..."
        mapfile -t servers < <(detect_servers)
        print_success "${#servers[@]} servidores detectados"
        
        if [[ ${#servers[@]} -gt 0 ]]; then
            print_info "Servidores: ${servers[*]}"
        fi
    fi
    
    # Configurar CLIs
    if [[ "$configure_all" == "true" ]]; then
        print_message "Configurando todas as CLIs habilitadas..."
        
        # Ler CLIs habilitadas do arquivo .env
        local env_file="$ROOT_DIR/configs/env/.env"
        if [[ -f "$env_file" ]]; then
            while IFS= read -r line; do
                if [[ "$line" =~ ^([A-Z_]+)_ENABLED=true$ ]]; then
                    local cli_key="${BASH_REMATCH[1]}"
                    local cli_name_lower=$(echo "$cli_key" | tr '[:upper:]' '[:lower:]' | sed 's/_enabled//')
                    
                    print_info "Configurando CLI: $cli_name_lower"
                    if configure_cli "$cli_name_lower" "${servers[@]}"; then
                        print_success "CLI $cli_name_lower configurada com sucesso"
                    else
                        print_warning "Falha ao configurar CLI $cli_name_lower"
                    fi
                fi
            done < "$env_file"
        else
            print_warning "Arquivo .env não encontrado. Configure manualmente as CLIs."
        fi
    elif [[ -n "$cli_name" ]]; then
        print_message "Configurando CLI: $cli_name"
        if configure_cli "$cli_name" "${servers[@]}"; then
            print_success "CLI $cli_name configurada com sucesso"
        else
            print_error "Falha ao configurar CLI $cli_name"
            exit 1
        fi
    else
        print_error "Especifique uma CLI ou use -a para configurar todas"
        show_help
        exit 1
    fi
    
    print_success "Configuração concluída!"
    
    if [[ "$include_servers" == "true" ]]; then
        echo ""
        echo -e "${CYAN}🔧 Próximos Passos:${NC}"
        echo "1. Configure as variáveis de ambiente dos servidores"
        echo "2. Reinicie suas CLIs para aplicar as configurações"
        echo "3. Teste os servidores MCP"
        echo ""
        echo -e "${YELLOW}💡 Dica:${NC} Execute 'npm run status' para verificar a saúde do sistema"
    fi
}

# Executar função principal
main "$@"
