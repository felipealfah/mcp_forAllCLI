#!/bin/bash

# ========================================
# SCRIPT DE TESTE DE TODOS OS CLIs
# Verifica se o Context7 está configurado em todos os CLIs
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

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Função para verificar um CLI
check_cli() {
    local cli_name="$1"
    local config_path="$2"
    local settings_file="$3"
    
    echo -e "\n${BLUE}🔍 Verificando $cli_name...${NC}"
    
    if [[ ! -d "$config_path" ]]; then
        error "❌ Diretório $config_path não existe!"
        return 1
    fi
    
    if [[ ! -f "$settings_file" ]]; then
        error "❌ Arquivo de configuração $settings_file não existe!"
        return 1
    fi
    
    # Verificar se o Context7 está configurado
    if grep -q "context7" "$settings_file" && grep -q "@upstash/context7-mcp" "$settings_file"; then
        success "✅ $cli_name configurado corretamente!"
        echo "   📁 Config: $settings_file"
        echo "   🔧 Servidor: context7"
        echo "   📦 Pacote: @upstash/context7-mcp"
        return 0
    else
        error "❌ $cli_name não tem o Context7 configurado corretamente!"
        return 1
    fi
}

# Função para testar o servidor Context7
test_context7_server() {
    echo -e "\n${BLUE}🧪 Testando servidor Context7...${NC}"
    
    # Verificar se o arquivo .env existe
    if [[ ! -f "servers/ai/context7-server/.env" ]]; then
        error "❌ Arquivo .env do Context7 não encontrado!"
        return 1
    fi
    
    # Testar se o servidor responde
    log "Testando resposta do servidor..."
    local response
    response=$(echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' | npx -y @upstash/context7-mcp --api-key ctx7sk-dffbb00c-6537-44b3-8d1d-0d67edca9d22 2>/dev/null | head -c 200)
    
    if [[ $? -eq 0 ]] && [[ "$response" == *"resolve-library-id"* ]]; then
        success "✅ Servidor Context7 funcionando perfeitamente!"
        echo "   🚀 Resposta: $response"
        return 0
    else
        error "❌ Servidor Context7 não está respondendo corretamente!"
        return 1
    fi
}

# Função principal
main() {
    echo -e "${BLUE}🚀 VERIFICAÇÃO COMPLETA DOS CLIs${NC}"
    echo "=========================================="
    
    local all_success=true
    
    # Testar servidor Context7
    if ! test_context7_server; then
        all_success=false
    fi
    
    # Verificar Cursor
    if ! check_cli "Cursor" "$HOME/.cursor" "$HOME/.cursor/mcp.json"; then
        all_success=false
    fi
    
    # Verificar VS Code
    if ! check_cli "VS Code" "$HOME/.vscode" "$HOME/.vscode/settings.json"; then
        all_success=false
    fi
    
    # Verificar Claude Desktop
    if ! check_cli "Claude Desktop" "$HOME/.claude" "$HOME/.claude/settings.json"; then
        all_success=false
    fi
    
    # Verificar Gemini CLI
    if ! check_cli "Gemini CLI" "$HOME/.gemini" "$HOME/.gemini/settings.json"; then
        all_success=false
    fi
    
    echo -e "\n${BLUE}📊 RESUMO FINAL${NC}"
    echo "=================="
    
    if $all_success; then
        success "🎉 TODOS OS CLIs ESTÃO CONFIGURADOS CORRETAMENTE!"
        echo ""
        echo "🔄 Próximos passos:"
        echo "   1. Reinicie cada CLI"
        echo "   2. Teste o Context7 em cada um"
        echo "   3. Use: 'resolve-library-id com libraryName \"react\"'"
        echo ""
        echo "📋 CLIs configurados:"
        echo "   ✅ Cursor"
        echo "   ✅ VS Code"
        echo "   ✅ Claude Desktop"
        echo "   ✅ Gemini CLI"
    else
        error "❌ ALGUNS CLIs NÃO ESTÃO CONFIGURADOS CORRETAMENTE!"
        echo ""
        echo "🔧 Execute novamente: ./scripts/sync-context7-all-clis.sh"
    fi
}

# Executar função principal
main "$@"
