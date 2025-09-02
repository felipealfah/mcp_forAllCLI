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
    
    # Verificar PM2
    if ! command -v pm2 &> /dev/null; then
        print_warning "PM2 não encontrado. Será instalado automaticamente para gerenciamento de processos."
        npm install -g pm2
        print_success "PM2 instalado com sucesso"
    else
        print_success "PM2 $(pm2 --version) encontrado"
    fi
    
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

# Função para configurar PM2
setup_pm2() {
    print_message "Configurando PM2 para auto-inicialização..."
    
    # Verificar se o script start-all-servers.sh existe
    if [ -f "scripts/start-all-servers.sh" ]; then
        chmod +x scripts/start-all-servers.sh
        print_success "Script start-all-servers.sh configurado como executável"
    else
        print_error "Script scripts/start-all-servers.sh não encontrado"
        print_message "Criando script de inicialização..."
        
        mkdir -p scripts
        cat > scripts/start-all-servers.sh << 'EOF'
#!/bin/bash

# Script para iniciar todos os servidores MCP instalados

echo "Iniciando todos os servidores MCP instalados..."

# Encontra todos os arquivos package.json dentro do diretório servers/
find "$PWD/servers/" -name "package.json" | while read package_json_path; do
    server_dir=$(dirname "$package_json_path")
    server_name=$(basename "$server_dir")

    echo "Verificando servidor em: $server_dir"

    # Verifica se o package.json contém um script "start"
    if grep -q '"start":' "$package_json_path"; then
        echo "  -> Encontrado script 'start' para $server_name. Preparando para iniciar..."
        (
            cd "$server_dir" || { echo "Erro: Não foi possível mudar para o diretório $server_dir"; exit 1; }
            echo "    -> Instalando dependências e compilando $server_name..."
            pnpm install --frozen-lockfile || npm install || { echo "Erro ao instalar dependências para $server_name"; exit 1; }
            pnpm build || npm run build || { echo "Aviso: Falha ao compilar $server_name, tentando iniciar mesmo assim..."; }
            echo "    -> Iniciando $server_name em segundo plano..."
            pnpm start &
            echo "    -> $server_name iniciado (PID: $!)"
        ) & 
    else
        echo "  -> Script 'start' não encontrado em $package_json_path. Pulando $server_name."
    fi
done

echo "Processo de inicialização de servidores concluído."
EOF
        chmod +x scripts/start-all-servers.sh
        print_success "Script start-all-servers.sh criado com sucesso"
    fi
    
    # Configurar PM2
    print_message "Configurando servidores no PM2..."
    
    # Parar processo existente se houver
    pm2 delete mcp-servers 2>/dev/null || true
    
    # Iniciar com PM2
    pm2 start scripts/start-all-servers.sh --name mcp-servers
    
    # Salvar configuração PM2
    pm2 save
    
    print_success "Servidores MCP configurados no PM2"
    
    # Instruções para startup automático
    echo ""
    print_warning "Para configurar inicialização automática após reinicialização:"
    echo "Execute o seguinte comando (requer senha de administrador):"
    echo ""
    pm2_startup_cmd=$(pm2 startup 2>&1 | grep "sudo env" | head -1)
    if [ -n "$pm2_startup_cmd" ]; then
        echo "$pm2_startup_cmd"
    else
        echo "pm2 startup"
        echo "(e execute o comando sudo que será exibido)"
    fi
    echo ""
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
    echo "4. Configure PM2 para auto-inicialização (opcional):"
    echo "   Execute o comando sudo mostrado acima"
    echo ""
    echo "5. Sincronize com suas CLIs:"
    echo "   npm run sync"
    echo ""
    echo "6. Verifique o status:"
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
    echo "   pm2 status             # Ver status dos servidores PM2"
    echo "   pm2 logs mcp-servers   # Ver logs dos servidores"
    echo "   pm2 restart mcp-servers # Reiniciar servidores"
    echo "   pm2 stop mcp-servers   # Parar servidores"
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
    
    # Configurar PM2
    setup_pm2
    
    # Mostrar próximos passos
    show_next_steps
}

# Executar função principal
main "$@"
