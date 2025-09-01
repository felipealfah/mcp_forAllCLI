#!/bin/bash

# ========================================
# SCRIPT DE INSTALAÇÃO SMITHERY.AI
# Instala servidores MCP do Smithery.ai automaticamente
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
    echo -e "${CYAN}🌐 INSTALADOR DE SERVIDORES SMITHERY.AI${NC}"
    echo "=============================================="
    echo ""
    echo "Uso: $0 <nome-do-servidor> [categoria]"
    echo ""
    echo "Argumentos:"
    echo "  nome-do-servidor    Nome do pacote npm do servidor"
    echo "  categoria          Categoria do servidor (ai, development, database, cloud, custom)"
    echo ""
    echo "Exemplos:"
    echo "  $0 @smithery/web-search ai"
    echo "  $0 @smithery/weather-forecast ai"
    echo "  $0 @smithery/github-tools development"
    echo "  $0 @smithery/supabase-tools database"
    echo ""
    echo "📚 Categorias disponíveis:"
    echo "   ai          - Inteligência Artificial e ML"
    echo "   development - Ferramentas de desenvolvimento"
    echo "   database    - Bancos de dados e ORMs"
    echo "   cloud       - Serviços em nuvem (AWS, GCP, Azure)"
    echo "   custom      - Servidores personalizados"
    echo ""
    echo "🔗 Visite: https://smithery.ai/"
}

# Função para validar categoria
validate_category() {
    local category="$1"
    local valid_categories=("ai" "development" "database" "cloud" "custom")
    
    for valid in "${valid_categories[@]}"; do
        if [[ "$category" == "$valid" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Função para instalar servidor do Smithery.ai
install_smithery_server() {
    local server_name="$1"
    local category="$2"
    
    info "🌐 Instalando servidor do Smithery.ai: $server_name"
    
    # Verificar se o servidor já existe
    local server_dir="servers/$category/$server_name"
    if [[ -d "$server_dir" ]]; then
        warn "⚠️  Servidor $server_name já existe!"
        read -p "Deseja sobrescrever? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Instalação cancelada."
            exit 0
        fi
        log "Removendo instalação anterior..."
        rm -rf "$server_dir"
    fi
    
    # Criar diretório do servidor
    mkdir -p "$server_dir"
    
    # Testar se o pacote npm existe
    log "🔍 Verificando se o pacote $server_name existe..."
    if ! npm view "$server_name" &>/dev/null; then
        error "❌ Pacote npm $server_name não encontrado!"
        error "Verifique o nome do pacote em: https://smithery.ai/"
        exit 1
    fi
    
    # Obter informações do pacote
    local package_info=$(npm view "$server_name" --json)
    local description=$(echo "$package_info" | jq -r '.description // "Servidor MCP do Smithery.ai"')
    local version=$(echo "$package_info" | jq -r '.version // "latest"')
    local homepage=$(echo "$package_info" | jq -r '.homepage // "https://smithery.ai/"')
    
    # Criar config.json para servidor Smithery
    cat > "$server_dir/config.json" << EOF
{
  "name": "$server_name",
  "type": "npx",
  "description": "$description",
  "command": "npx",
  "args": ["-y", "$server_name"],
  "capabilities": ["tools"],
  "category": "$category",
  "source": "smithery.ai",
  "version": "$version",
  "homepage": "$homepage",
  "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    # Criar README.md
    cat > "$server_dir/README.md" << EOF
# $server_name

$description

## Instalação

Este servidor foi instalado automaticamente do [Smithery.ai](https://smithery.ai/) e configurado para funcionar com todos os CLIs.

## Uso

O servidor estará disponível em todos os CLIs configurados após a sincronização.

## Informações

- **Origem**: [Smithery.ai](https://smithery.ai/)
- **Categoria**: $category
- **Tipo**: npx package
- **Versão**: $version
- **Homepage**: $homepage
- **Instalado em**: $(date)

## Ferramentas Disponíveis

Este servidor MCP fornece ferramentas específicas que podem ser usadas pelos CLIs conectados.

## Sincronização

Para sincronizar com todos os CLIs, execute:
\`\`\`bash
./scripts/sync-all-clis-universal.sh
\`\`\`
EOF
    
    # Criar .env.example se necessário
    cat > "$server_dir/.env.example" << EOF
# ========================================
# $server_name - Variáveis de Ambiente
# ========================================

# Configure as variáveis necessárias para este servidor
# Copie este arquivo para .env e preencha os valores

# Exemplo de variáveis (ajuste conforme necessário):
# API_KEY=your_api_key_here
# BASE_URL=https://api.example.com
# DEBUG=false
EOF
    
    # Criar package.json básico
    cat > "$server_dir/package.json" << EOF
{
  "name": "$server_name",
  "version": "$version",
  "description": "$description",
  "main": "index.js",
  "scripts": {
    "start": "npx -y $server_name",
    "test": "echo \"No tests specified\" && exit 0"
  },
  "keywords": ["mcp", "smithery", "ai", "tools"],
  "author": "Smithery.ai",
  "license": "MIT",
  "dependencies": {
    "$server_name": "^$version"
  }
}
EOF
    
    success "✅ Servidor $server_name instalado do Smithery.ai!"
    echo "   📁 Localização: $server_dir"
    echo "   📦 Pacote: $server_name@$version"
    echo "   🌐 Fonte: https://smithery.ai/"
    
    # Perguntar se quer sincronizar automaticamente
    echo ""
    read -p "🔄 Deseja sincronizar automaticamente com todos os CLIs? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log "Sincronização manual necessária. Execute: ./scripts/sync-all-clis-universal.sh"
    else
        log "🚀 Sincronizando automaticamente..."
        ./scripts/sync-all-clis-universal.sh
    fi
}

# Função para listar servidores populares do Smithery
list_popular_servers() {
    echo -e "${CYAN}🔥 SERVIDORES POPULARES DO SMITHERY.AI${NC}"
    echo "=============================================="
    echo ""
    echo "🌐 Web Search & Browser:"
    echo "   @smithery/web-search"
    echo "   @smithery/browser-automation"
    echo ""
    echo "🤖 AI & ML:"
    echo "   @smithery/ai-tools"
    echo "   @smithery/llm-tools"
    echo ""
    echo "💻 Development:"
    echo "   @smithery/github-tools"
    echo "   @smithery/docker-tools"
    echo "   @smithery/kubernetes-tools"
    echo ""
    echo "🗄️  Database:"
    echo "   @smithery/supabase-tools"
    echo "   @smithery/mongodb-tools"
    echo "   @smithery/postgres-tools"
    echo ""
    echo "☁️  Cloud:"
    echo "   @smithery/aws-tools"
    echo "   @smithery/gcp-tools"
    echo "   @smithery/azure-tools"
    echo ""
    echo "🔗 Visite: https://smithery.ai/ para mais opções!"
}

# Função principal
main() {
    # Verificar argumentos
    if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    if [[ "$1" == "list" ]] || [[ "$1" == "popular" ]]; then
        list_popular_servers
        exit 0
    fi
    
    if [[ $# -lt 1 ]]; then
        error "❌ Nome do servidor é obrigatório!"
        echo ""
        show_help
        exit 1
    fi
    
    local server_name="$1"
    local category="${2:-ai}"  # Categoria padrão é "ai"
    
    # Validar categoria
    if ! validate_category "$category"; then
        error "❌ Categoria inválida: $category"
        echo ""
        show_help
        exit 1
    fi
    
    # Verificar se o script de sincronização existe
    if [[ ! -f "scripts/sync-all-clis-universal.sh" ]]; then
        error "❌ Script de sincronização não encontrado!"
        error "Execute primeiro: npm run setup"
        exit 1
    fi
    
    # Instalar servidor
    install_smithery_server "$server_name" "$category"
}

# Executar função principal
main "$@"
