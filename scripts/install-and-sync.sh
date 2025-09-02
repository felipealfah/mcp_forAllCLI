#!/bin/bash

# ========================================
# SCRIPT DE INSTALAÇÃO E SINCRONIZAÇÃO AUTOMÁTICA
# Instala servidores MCP e sincroniza automaticamente com todos os CLIs
# ========================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

# Função para mostrar ajuda
show_help() {
    echo -e "${PURPLE}🚀 INSTALADOR E SINCRONIZADOR AUTOMÁTICO MCP${NC}"
    echo "====================================================="
    echo ""
    echo "Este script instala servidores MCP e sincroniza automaticamente com todos os CLIs!"
    echo ""
    echo "Uso: $0 <tipo> [opções]"
    echo ""
    echo "Tipos de instalação:"
    echo "  smithery <nome-do-servidor> [categoria]  - Instala do Smithery.ai"
    echo "  github <url-do-repo> [categoria]         - Instala do GitHub"
    echo "  local <caminho-local> [categoria]        - Instala de caminho local"
    echo "  zip <arquivo-zip> [categoria]            - Instala de arquivo ZIP"
    echo "  sync                                      - Apenas sincroniza CLIs existentes"
    echo ""
    echo "Exemplos:"
    echo "  $0 smithery @smithery/web-search ai"
    echo "  $0 github https://github.com/user/mcp-server development"
    echo "  $0 local ./meu-servidor custom"
    echo "  $0 zip servidor.zip database"
    echo "  $0 sync"
    echo ""
    echo "📚 Categorias disponíveis:"
    echo "   ai          - Inteligência Artificial e ML"
    echo "   development - Ferramentas de desenvolvimento"
    echo "   database    - Bancos de dados e ORMs"
    echo "   cloud       - Serviços em nuvem (AWS, GCP, Azure)"
    echo "   custom      - Servidores personalizados"
    echo ""
    echo "🔄 Após a instalação, todos os CLIs são sincronizados automaticamente!"
}

# Função para instalar do Smithery.ai
install_smithery() {
    local server_name="$1"
    local category="${2:-ai}"
    
    info "🌐 Instalando do Smithery.ai: $server_name"
    ./scripts/install-smithery-server.sh "$server_name" "$category"
}

# Função para instalar do GitHub
install_github() {
    local repo_url="$1"
    local category="${2:-custom}"
    local server_name=$(basename "$repo_url" .git)

    info "📥 Instalando do GitHub: $repo_url"
    ./scripts/install-existing-server.sh "$server_name" --source github --url "$repo_url" --category "$category" --install-deps --force
}

# Função para instalar de caminho local
install_local() {
    local local_path="$1"
    local category="${2:-custom}"
    local server_name=$(basename "$local_path")

    info "📁 Instalando de caminho local: $local_path"
    ./scripts/install-existing-server.sh "$server_name" --source local --path "$local_path" --category "$category" --install-deps --force
}

# Função para instalar de ZIP
install_zip() {
    local zip_file="$1"
    local category="${2:-custom}"
    local server_name=$(basename "$zip_file" .zip)

    info "📦 Instalando de arquivo ZIP: $zip_file"
    ./scripts/install-existing-server.sh "$server_name" --source zip --url "$zip_file" --category "$category" --install-deps --force
}

# Função para sincronizar todos os CLIs
sync_all_clis() {
    info "🔄 Sincronizando todos os CLIs..."
    ./scripts/sync-all-clis-universal.sh
}

# Função principal
main() {
    # Verificar argumentos
    if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    local install_type="$1"
    shift
    
    case "$install_type" in
        "smithery")
            if [[ $# -lt 1 ]]; then
                error "❌ Nome do servidor é obrigatório para instalação do Smithery!"
                echo ""
                show_help
                exit 1
            fi
            install_smithery "$@"
            ;;
            
        "github")
            if [[ $# -lt 1 ]]; then
                error "❌ URL do repositório é obrigatória para instalação do GitHub!"
                echo ""
                show_help
                exit 1
            fi
            install_github "$@"
            ;;
            
        "local")
            if [[ $# -lt 1 ]]; then
                error "❌ Caminho local é obrigatório!"
                echo ""
                show_help
                exit 1
            fi
            install_local "$@"
            ;;
            
        "zip")
            if [[ $# -lt 1 ]]; then
                error "❌ Arquivo ZIP é obrigatório!"
                echo ""
                show_help
                exit 1
            fi
            install_zip "$@"
            ;;
            
        "sync")
            sync_all_clis
            ;;
            
        *)
            error "❌ Tipo de instalação inválido: $install_type"
            echo ""
            show_help
            exit 1
            ;;
    esac
    
    # Sincronizar automaticamente após qualquer instalação
    if [[ "$install_type" != "sync" ]]; then
        echo ""
        info "🔄 Sincronizando automaticamente com todos os CLIs..."
        sync_all_clis
        
        echo ""
        success "🎉 Instalação e sincronização concluídas com sucesso!"
        echo ""
        echo "📋 Próximos passos:"
        echo "   1. Reinicie os CLIs para carregar as novas configurações"
        echo "   2. Teste os novos servidores MCP"
        echo "   3. Use: ./scripts/test-all-clis.sh para verificar status"
    fi
}

# Executar função principal
main "$@"
