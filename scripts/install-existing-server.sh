#!/bin/bash

# ========================================
# MCP Hub - Instalador de Servidores Existentes
# ========================================
# Este script instala servidores MCP que já existem
# (como Context7, Supabase, etc.)

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
    echo -e "${BLUE}📥 MCP Hub - Instalador de Servidores Existentes${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Uso: $0 [OPÇÕES] <NOME_DO_SERVIDOR>"
    echo ""
    echo "OPÇÕES:"
    echo "  -c, --category CATEGORIA    Categoria do servidor (ai, development, database, cloud, custom)"
    echo "  -s, --source SOURCE         Fonte do servidor (github, local, zip)"
    echo "  -u, --url URL               URL do repositório ou arquivo"
    echo "  -p, --path PATH             Caminho local do servidor"
    echo "  -t, --type TYPE             Tipo do servidor (node, python, go, rust, other)"
    echo "  -d, --description DESC      Descrição do servidor"
    echo "  -e, --env-vars VARS         Variáveis de ambiente (separadas por vírgula)"
    echo "  -i, --install-deps          Instalar dependências automaticamente"
    echo "  -f, --force                 Forçar instalação (sobrescrever se existir)"
    echo "  -h, --help                  Mostrar esta ajuda"
    echo ""
    echo "EXEMPLOS:"
    echo "  $0 context7 -c ai -s github -u https://github.com/upstash/context7.git"
    echo "  $0 supabase -c database -s local -p /caminho/para/supabase-mcp"
    echo "  $0 git-server -c development -s zip -u https://github.com/user/git-mcp/archive/main.zip"
    echo ""
    echo "CATEGORIAS DISPONÍVEIS:"
    echo "  ai          - Inteligência Artificial (Claude, GPT, Ollama)"
    echo "  development - Desenvolvimento (Git, Docker, Kubernetes)"
    echo "  database    - Banco de Dados (PostgreSQL, MongoDB, Redis)"
    echo "  cloud       - Cloud (AWS, GCP, Azure)"
    echo "  custom      - Personalizado"
    echo ""
    echo "FONTES SUPORTADAS:"
    echo "  github      - Clonar do GitHub"
    echo "  local       - Copiar de caminho local"
    echo "  zip         - Baixar e extrair ZIP"
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

# Função para validar fonte
validate_source() {
    local source="$1"
    local valid_sources=("github" "local" "zip")
    
    for valid in "${valid_sources[@]}"; do
        if [[ "$source" == "$valid" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Função para instalar servidor do GitHub
install_from_github() {
    local server_name="$1"
    local category="$2"
    local url="$3"
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    print_message "Instalando servidor do GitHub: $url"
    
    if [[ -d "$server_path" ]]; then
        if [[ "$force" == "true" ]]; then
            print_warning "Removendo diretório existente: $server_path"
            rm -rf "$server_path"
        else
            print_error "Servidor já existe: $server_path"
            print_info "Use -f para forçar a instalação"
            return 1
        fi
    fi
    
    # Clonar repositório
    if git clone "$url" "$server_path"; then
        print_success "Servidor clonado com sucesso"
        
        # Remover .git se existir
        if [[ -d "$server_path/.git" ]]; then
            rm -rf "$server_path/.git"
            print_info "Diretório .git removido"
        fi
        
        return 0
    else
        print_error "Falha ao clonar repositório"
        return 1
    fi
}

# Função para instalar servidor local
install_from_local() {
    local server_name="$1"
    local category="$2"
    local source_path="$3"
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    print_message "Instalando servidor local: $source_path"
    
    if [[ ! -d "$source_path" ]]; then
        print_error "Caminho local não encontrado: $source_path"
        return 1
    fi
    
    if [[ -d "$server_path" ]]; then
        if [[ "$force" == "true" ]]; then
            print_warning "Removendo diretório existente: $server_path"
            rm -rf "$server_path"
        else
            print_error "Servidor já existe: $server_path"
            print_info "Use -f para forçar a instalação"
            return 1
        fi
    fi
    
    # Copiar diretório
    if cp -r "$source_path" "$server_path"; then
        print_success "Servidor copiado com sucesso"
        return 0
    else
        print_error "Falha ao copiar servidor"
        return 1
    fi
}

# Função para instalar servidor de ZIP
install_from_zip() {
    local server_name="$1"
    local category="$2"
    local url="$3"
    local server_path="$SERVERS_DIR/$category/$server_name"
    local temp_zip="/tmp/mcp-server-$.zip"
    
    print_message "Instalando servidor de ZIP: $url"
    
    if [[ -d "$server_path" ]]; then
        if [[ "$force" == "true" ]]; then
            print_warning "Removendo diretório existente: $server_path"
            rm -rf "$server_path"
        else
            print_error "Servidor já existe: $server_path"
            print_info "Use -f para forçar a instalação"
            return 1
        fi
    fi
    
    # Baixar ZIP
    if curl -L -o "$temp_zip" "$url"; then
        print_success "ZIP baixado com sucesso"
        
        # Criar diretório temporário
        local temp_dir="/tmp/mcp-server-$"
        mkdir -p "$temp_dir"
        
        # Extrair ZIP
        if unzip -q "$temp_zip" -d "$temp_dir"; then
            print_success "ZIP extraído com sucesso"
            
            # Mover conteúdo para o diretório final
            local extracted_content=$(find "$temp_dir" -maxdepth 1 -type d | grep -v "^$temp_dir$" | head -1)
            if [[ -n "$extracted_content" ]]; then
                mv "$extracted_content" "$server_path"
                print_success "Servidor instalado com sucesso"
            else
                print_error "Não foi possível encontrar o conteúdo extraído"
                return 1
            fi
            
            # Limpar arquivos temporários
            rm -rf "$temp_dir" "$temp_zip"
            return 0
        else
            print_error "Falha ao extrair ZIP"
            rm -f "$temp_zip"
            return 1
        fi
    else
        print_error "Falha ao baixar ZIP"
        return 1
    fi
}

# Função para criar configuração básica
create_basic_config() {
    local server_name="$1"
    local category="$2"
    local server_type="$3"
    local description="$4"
    local env_vars="$5"
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    print_message "Criando configuração básica..."
    
    # Criar config.json se não existir
    if [[ ! -f "$server_path/config.json" ]]; then
        cat > "$server_path/config.json" << EOF
{
  "name": "$server_name",
  "description": "$description",
  "version": "1.0.0",
  "category": "$category",
  "type": "$server_type",
  "enabled": true,
  "auto_start": false,
  "restart_on_failure": true,
  "log_level": "info",
  "env_vars": ["$env_vars"],
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"
}
EOF
        print_success "config.json criado"
    fi
    
    # Criar README.md se não existir
    if [[ ! -f "$server_path/README.md" ]]; then
        cat > "$server_path/README.md" << EOF
# $server_name

$description

## 📋 Configuração

- **Categoria**: $category
- **Tipo**: $server_type
- **Versão**: 1.0.0
- **Status**: Ativo

## 🚀 Instalação

\`\`\`bash
# Instalar dependências (se necessário)
npm install

# Configurar variáveis de ambiente
cp env.example .env
# Edite o arquivo .env com suas configurações

# Iniciar servidor
npm start
\`\`\`

## 🔧 Variáveis de Ambiente

$env_vars

## 📚 Documentação

Consulte a documentação completa em \`docs/\`.

---

**Criado em**: $(date '+%Y-%m-%d')
**Categoria**: $category
**Fonte**: Servidor existente instalado via MCP Hub
EOF
        print_success "README.md criado"
    fi
}

# Função para instalar dependências
install_dependencies() {
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    if [[ "$install_deps" != "true" ]]; then
        print_info "Pule a instalação automática de dependências. Use -i para habilitar."
        return
    fi
    
    print_message "Instalando dependências..."
    
    cd "$server_path"
    
    # Verificar se é um projeto Node.js
    if [[ -f "package.json" ]]; then
        if npm install; then
            print_success "Dependências Node.js instaladas com sucesso"
        else
            print_warning "Falha ao instalar dependências Node.js"
        fi
    fi
    
    # Verificar se é um projeto Python
    if [[ -f "requirements.txt" ]]; then
        if pip3 install -r requirements.txt; then
            print_success "Dependências Python instaladas com sucesso"
        else
            print_warning "Falha ao instalar dependências Python"
        fi
    fi
    
    # Verificar se é um projeto Go
    if [[ -f "go.mod" ]]; then
        if go mod download; then
            print_success "Dependências Go baixadas com sucesso"
        else
            print_warning "Falha ao baixar dependências Go"
        fi
    fi
    
    # Verificar se é um projeto Rust
    if [[ -f "Cargo.toml" ]]; then
        if cargo build; then
            print_success "Dependências Rust compiladas com sucesso"
        else
            print_warning "Falha ao compilar dependências Rust"
        fi
    fi
    
    cd "$ROOT_DIR"
}

# Função para atualizar perfis das CLIs
update_cli_profiles() {
    local server_name="$1"
    local category="$2"
    
    print_message "Atualizando perfis das CLIs..."
    
    # Atualizar todos os perfis de CLI para incluir o novo servidor
    for profile_file in "$ROOT_DIR/cli-profiles"/*.json; do
        if [[ -f "$profile_file" ]]; then
            local profile_name=$(basename "$profile_file" .json)
            print_info "Atualizando perfil: $profile_name"
            
            # Usar jq se disponível, senão usar sed
            if command -v jq &> /dev/null; then
                # Verificar se o servidor já existe
                if ! jq -e ".servers[] | select(.name == \"$server_name\" and .category == \"$category\")" "$profile_file" > /dev/null 2>&1; then
                    # Adicionar servidor
                    jq --arg name "$server_name" --arg category "$category" \
                       '.servers += [{"name": $name, "category": $category, "added_at": now | todateiso8601, "status": "pending_sync"}]' \
                       "$profile_file" > "$profile_file.tmp" && mv "$profile_file.tmp" "$profile_file"
                    print_success "Servidor adicionado ao perfil $profile_name"
                else
                    print_info "Servidor já existe no perfil $profile_name"
                fi
            else
                print_warning "jq não encontrado. Atualize manualmente o perfil $profile_name"
            fi
        fi
    done
    
    print_success "Perfis das CLIs atualizados"
}

# Função para mostrar resumo da instalação
show_installation_summary() {
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🎉 Servidor Existente Instalado! 🎉${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}📋 Resumo da Instalação:${NC}"
    echo ""
    echo -e "${WHITE}Nome:${NC} $server_name"
    echo -e "${WHITE}Categoria:${NC} $category"
    echo -e "${WHITE}Tipo:${NC} $server_type"
    echo -e "${WHITE}Descrição:${NC} $description"
    echo -e "${WHITE}Fonte:${NC} $source"
    echo -e "${WHITE}Localização:${NC} $server_path"
    echo ""
    echo -e "${CYAN}📁 Arquivos Criados/Atualizados:${NC}"
    echo "   $server_path/"
    echo "   ├── config.json"
    echo "   └── README.md"
    echo ""
    echo -e "${CYAN}🔧 Próximos Passos:${NC}"
    echo ""
    echo "1. Configure as variáveis de ambiente:"
    echo "   nano $server_path/.env"
    echo ""
    echo "2. Personalize o servidor conforme necessário"
    echo ""
    if [[ "$install_deps" == "true" ]]; then
        echo "3. Dependências já foram instaladas automaticamente"
    else
        echo "3. Instale as dependências manualmente:"
        echo "   cd $server_path"
        if [[ -f "$server_path/package.json" ]]; then
            echo "   npm install"
        elif [[ -f "$server_path/requirements.txt" ]]; then
            echo "   pip3 install -r requirements.txt"
        elif [[ -f "$server_path/go.mod" ]]; then
            echo "   go mod download"
        elif [[ -f "$server_path/Cargo.toml" ]]; then
            echo "   cargo build"
        fi
    fi
    
    echo ""
    echo "4. Sincronize com suas CLIs:"
    echo "   npm run sync"
    echo ""
    echo "5. Configure as CLIs:"
    echo "   ./scripts/configure-cli-simple.sh -a -s"
    echo ""
    echo -e "${CYAN}🔗 Integração Automática:${NC}"
    echo "✅ Servidor adicionado ao MCP Hub"
    echo "✅ Perfis das CLIs atualizados"
    if [[ "$install_deps" == "true" ]]; then
        echo "✅ Dependências instaladas automaticamente"
    fi
    echo ""
    echo -e "${YELLOW}💡 Dica:${NC} Execute 'npm run status' para verificar a saúde do sistema"
    echo ""
}

# Função principal
main() {
    # Verificar se estamos no diretório correto
    if [[ ! -f "$ROOT_DIR/package.json" ]]; then
        print_error "Execute este script no diretório raiz do MCP Servers Hub"
        exit 1
    fi
    
    # Verificar se o nome do servidor foi fornecido
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi
    
    # Processar argumentos
    local server_name=""
    local category="ai"
    local source="github"
    local url=""
    local local_path=""
    local server_type="other"
    local description="Servidor MCP existente"
    local env_vars=""
    local install_deps="false"
    local force="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--category)
                category="$2"
                shift 2
                ;; 
            -s|--source)
                source="$2"
                shift 2
                ;; 
            -u|--url)
                url="$2"
                shift 2
                ;; 
            -p|--path)
                local_path="$2"
                shift 2
                ;; 
            -t|--type)
                server_type="$2"
                shift 2
                ;; 
            -d|--description)
                description="$2"
                shift 2
                ;; 
            -e|--env-vars)
                env_vars="$2"
                shift 2
                ;; 
            -i|--install-deps)
                install_deps="true"
                shift
                ;; 
            -f|--force)
                force="true"
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
                if [[ -z "$server_name" ]]; then
                    server_name="$1"
                else
                    print_error "Múltiplos nomes de servidor fornecidos"
                    exit 1
                fi
                shift
                ;; 
        esac
    done
    
    # Validar argumentos
    if [[ -z "$server_name" ]]; then
        print_error "Nome do servidor é obrigatório"
        show_help
        exit 1
    fi
    
    if ! validate_category "$category"; then
        print_error "Categoria inválida: $category"
        show_help
        exit 1
    fi
    
    if ! validate_source "$source"; then
        print_error "Fonte inválida: $source"
        show_help
        exit 1
    fi
    
    # Validar parâmetros específicos da fonte
    case "$source" in
        "github")
            if [[ -z "$url" ]]; then
                print_error "URL é obrigatória para fonte github"
                exit 1
            fi
            ;; 
        "local")
            if [[ -z "$local_path" ]]; then
                print_error "Caminho local é obrigatório para fonte local"
                exit 1
            fi
            ;; 
        "zip")
            if [[ -z "$url" ]]; then
                print_error "URL é obrigatória para fonte zip"
                exit 1
            fi
            ;; 
    esac
    
    # Mostrar resumo da instalação
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}📥 MCP Hub - Instalador de Servidores Existentes${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${CYAN}📋 Configuração da Instalação:${NC}"
    echo "   Nome: $server_name"
    echo "   Categoria: $category"
    echo "   Fonte: $source"
    if [[ "$source" == "github" || "$source" == "zip" ]]; then
        echo "   URL: $url"
    elif [[ "$source" == "local" ]]; then
        echo "   Caminho Local: $local_path"
    fi
    echo "   Tipo: $server_type"
    echo "   Descrição: $description"
    echo "   Variáveis de Ambiente: ${env_vars:-Nenhuma}"
    echo "   Instalar Dependências: $install_deps"
    echo ""
    
    # Confirmar instalação (desativado para chamadas não interativas)
    # read -p "Continuar com a instalação? (y/N): " -n 1 -r
    # echo
    # if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    #     print_info "Instalação cancelada"
    #     exit 0
    # fi
    
    # Executar instalação
    print_message "Iniciando instalação do servidor $server_name..."
    
    # Instalar baseado na fonte
    case "$source" in
        "github")
            if ! install_from_github "$server_name" "$category" "$url"; then
                exit 1
            fi
            ;; 
        "local")
            if ! install_from_local "$server_name" "$category" "$local_path"; then
                exit 1
            fi
            ;; 
        "zip")
            if ! install_from_zip "$server_name" "$category" "$url"; then
                exit 1
            fi
            ;; 
    esac
    
    # Criar configuração básica
    create_basic_config "$server_name" "$category" "$server_type" "$description" "$env_vars"
    
    # Instalar dependências
    install_dependencies
    
    # Atualizar perfis das CLIs
    update_cli_profiles "$server_name" "$category"
    
    # Mostrar resumo final
    show_installation_summary
    
    print_success "Instalação concluída com sucesso!"
}

# Executar função principal
main "$@"
