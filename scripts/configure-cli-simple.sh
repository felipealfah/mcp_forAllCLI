#!/bin/bash

# ========================================
# MCP Hub - Configurador Simples de CLIs
# ========================================
# Este script configura CLIs para usar servidores MCP do hub

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
    echo "  -h, --help                   Mostrar esta ajuda"
    echo ""
    echo "CLIs SUPORTADAS:"
    echo "  cursor                       Cursor Editor"
    echo "  vscode                       Visual Studio Code"
    echo "  neovim                       Neovim"
    echo ""
    echo "EXEMPLOS:"
    echo "  $0 cursor                    # Configurar apenas Cursor"
    echo "  $0 -a                        # Configurar todas as CLIs"
    echo "  $0 -a -s                     # Configurar todas as CLIs com todos os servidores"
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
                        if grep -q '"enabled": true' "$config_file" 2>/dev/null; then
                            servers+=("$category/$server_name")
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
        
        # Adicionar vírgula se não for o primeiro
        if [[ "$first" == "true" ]]; then
            first=false
        else
            mcp_config+=","
        fi
        
        # Adicionar servidor
        mcp_config+="
    \"$server_name\": {
      \"command\": \"node\",
      \"args\": [\"$server_path/server.js\"]
    }"
    done
    
    mcp_config+="
  },
  \"mcp\": {
    \"enabled\": true,
    \"autoStart\": true,
    \"logLevel\": \"info\"
  }
}"
    
    # Criar novo arquivo (sobrescrever se existir)
    echo "$mcp_config" > "$config_file"
    
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
    
    # Adicionar servidores
    local first=true
    for server in "${servers[@]}"; do
        local category=$(echo "$server" | cut -d'/' -f1)
        local server_name=$(echo "$server" | cut -d'/' -f2)
        local server_path="$ROOT_DIR/servers/$server"
        
        # Adicionar vírgula se não for o primeiro
        if [[ "$first" == "true" ]]; then
            first=false
        else
            mcp_config+=","
        fi
        
        # Adicionar servidor
        mcp_config+="
    \"$server_name\": {
      \"command\": \"node\",
      \"args\": [\"$server_path/server.js\"]
    }"
    done
    
    mcp_config+="
  },
  \"mcp\": {
    \"enabled\": true,
    \"autoStart\": true,
    \"logLevel\": \"info\"
  }
}"
    
    # Criar novo arquivo (sobrescrever se existir)
    echo "$mcp_config" > "$config_file"
    
    print_success "Configuração do VS Code criada: $config_file"
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
            print_warning "Configuração automática para Neovim não implementada ainda"
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
        # Usar método compatível com macOS
        IFS=' ' read -ra servers <<< "$(detect_servers)"
        print_success "${#servers[@]} servidores detectados"
        
        if [[ ${#servers[@]} -gt 0 ]]; then
            print_info "Servidores: ${servers[*]}"
        fi
    fi
    
    # Configurar CLIs
    if [[ "$configure_all" == "true" ]]; then
        print_message "Configurando CLIs principais..."
        
        # Configurar Cursor
        print_info "Configurando CLI: cursor"
        if configure_cli "cursor" "${servers[@]}"; then
            print_success "CLI cursor configurada com sucesso"
        else
            print_warning "Falha ao configurar CLI cursor"
        fi
        
        # Configurar VS Code
        print_info "Configurando CLI: vscode"
        if configure_cli "vscode" "${servers[@]}"; then
            print_success "CLI vscode configurada com sucesso"
        else
            print_warning "Falha ao configurar CLI vscode"
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
