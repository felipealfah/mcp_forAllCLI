#!/bin/bash

# ========================================
# MCP Servers Hub - Instalação Rápida
# ========================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Função para verificar pré-requisitos
check_prerequisites() {
    print_message "Verificando pré-requisitos..."
    
    # Verificar Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js não encontrado. Instale Node.js 18+ primeiro."
        print_message "Visite: https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js 18+ é necessário. Versão atual: $(node --version)"
        exit 1
    fi
    
    print_success "Node.js $(node --version) encontrado"
    
    # Verificar npm
    if ! command -v npm &> /dev/null; then
        print_error "npm não encontrado. Instale npm primeiro."
        exit 1
    fi
    
    print_success "npm $(npm --version) encontrado"
    
    # Verificar Git
    if ! command -v git &> /dev/null; then
        print_warning "Git não encontrado. A instalação continuará, mas você não poderá versionar suas configurações."
    else
        print_success "Git $(git --version | cut -d' ' -f3) encontrado"
    fi
}

# Função para instalar dependências
install_dependencies() {
    print_message "Instalando dependências..."
    
    if [ -f "package.json" ]; then
        npm install
        print_success "Dependências instaladas"
    else
        print_error "package.json não encontrado"
        exit 1
    fi
}

# Função para executar setup
run_setup() {
    print_message "Executando setup automático..."
    
    if [ -f "scripts/setup/setup.js" ]; then
        node scripts/setup/setup.js
        print_success "Setup concluído"
    else
        print_error "Script de setup não encontrado"
        exit 1
    fi
}

# Função para configurar variáveis de ambiente
setup_environment() {
    print_message "Configurando variáveis de ambiente..."
    
    if [ -f "configs/env/env.example" ]; then
        if [ ! -f "configs/env/.env" ]; then
            cp configs/env/env.example configs/env/.env
            print_success "Arquivo .env criado a partir do exemplo"
            print_warning "Edite configs/env/.env com suas configurações antes de continuar"
        else
            print_warning "Arquivo .env já existe. Verifique se está configurado corretamente"
        fi
    else
        print_error "Arquivo env.example não encontrado"
        exit 1
    fi
}

# Função para mostrar próximos passos
show_next_steps() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🎉 Instalação Concluída com Sucesso! 🎉${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}Próximos Passos:${NC}"
    echo ""
    echo "1. Configure suas variáveis de ambiente:"
    echo "   nano configs/env/.env"
    echo ""
    echo "2. Conecte suas CLIs:"
    echo "   npm run connect-cli"
    echo ""
    echo "3. Adicione seus servidores MCP:"
    echo "   npm run add-server"
    echo ""
    echo "4. Sincronize com suas CLIs:"
    echo "   npm run sync"
    echo ""
    echo "5. Verifique o status:"
    echo "   npm run status"
    echo ""
    echo -e "${BLUE}Documentação:${NC}"
    echo "   docs/CONFIGURATION.md"
    echo ""
    echo -e "${BLUE}Comandos Úteis:${NC}"
    echo "   npm run help          # Ver todos os comandos"
    echo "   npm run status        # Verificar status do sistema"
    echo "   npm run list-servers  # Listar servidores"
    echo "   npm run list-clis     # Listar CLIs conectadas"
    echo ""
    echo -e "${YELLOW}💡 Dica:${NC} Execute 'npm run status' para verificar a saúde do sistema"
    echo ""
}

# Função principal
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🚀 MCP Servers Hub - Instalação Rápida${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Verificar se estamos no diretório correto
    if [ ! -f "package.json" ]; then
        print_error "Execute este script no diretório raiz do MCP Servers Hub"
        exit 1
    fi
    
    # Verificar pré-requisitos
    check_prerequisites
    
    # Instalar dependências
    install_dependencies
    
    # Executar setup
    run_setup
    
    # Configurar ambiente
    setup_environment
    
    # Mostrar próximos passos
    show_next_steps
}

# Executar função principal
main "$@"
