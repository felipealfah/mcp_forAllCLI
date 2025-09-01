#!/bin/bash

# ========================================
# MCP Hub - Instalador Automatizado de Servidores
# ========================================
# Este script instala automaticamente novos servidores MCP
# e os configura em todas as CLIs conectadas

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
LOGS_DIR="$ROOT_DIR/logs"

# Função para mostrar ajuda
show_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🚀 MCP Hub - Instalador de Servidores${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Uso: $0 [OPÇÕES] <NOME_DO_SERVIDOR>"
    echo ""
    echo "OPÇÕES:"
    echo "  -c, --category CATEGORIA    Categoria do servidor (ai, development, database, cloud, custom)"
    echo "  -t, --type TIPO             Tipo do servidor (node, python, go, rust, other)"
    echo "  -d, --description DESC      Descrição do servidor"
    echo "  -e, --env-vars VARS         Variáveis de ambiente (separadas por vírgula)"
    echo "  -a, --auto-start            Iniciar automaticamente"
    echo "  -r, --restart-on-failure    Reiniciar em caso de falha"
    echo "  -l, --log-level LEVEL       Nível de log (error, warn, info, debug)"
    echo "  -i, --install-deps          Instalar dependências automaticamente"
    echo "  -s, --sync-clis             Sincronizar com CLIs após instalação"
    echo "  -f, --force                 Forçar instalação (sobrescrever se existir)"
    echo "  -h, --help                  Mostrar esta ajuda"
    echo ""
    echo "EXEMPLOS:"
    echo "  $0 my-ai-server -c ai -t node -d 'Servidor de IA personalizado'"
    echo "  $0 git-server -c development -t node -e 'GITHUB_TOKEN,GITLAB_TOKEN' -i -s"
    echo "  $0 postgres-server -c database -t python -a -r"
    echo ""
    echo "CATEGORIAS DISPONÍVEIS:"
    echo "  ai          - Inteligência Artificial (Claude, GPT, Ollama)"
    echo "  development - Desenvolvimento (Git, Docker, Kubernetes)"
    echo "  database    - Banco de Dados (PostgreSQL, MongoDB, Redis)"
    echo "  cloud       - Cloud (AWS, GCP, Azure)"
    echo "  custom      - Personalizado"
    echo ""
    echo "TIPOS DISPONÍVEIS:"
    echo "  node        - Node.js/JavaScript"
    echo "  python      - Python"
    echo "  go          - Go"
    echo "  rust        - Rust"
    echo "  other       - Outro"
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

# Função para validar tipo
validate_type() {
    local type="$1"
    local valid_types=("node" "python" "go" "rust" "other")
    
    for valid in "${valid_types[@]}"; do
        if [[ "$type" == "$valid" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Função para validar nome do servidor
validate_server_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        return 1
    fi
    
    if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
        return 1
    fi
    
    return 0
}

# Função para criar estrutura do servidor
create_server_structure() {
    local server_name="$1"
    local category="$2"
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    print_message "Criando estrutura do servidor..."
    
    # Criar diretórios
    mkdir -p "$server_path"/{src,docs,tests}
    
    print_success "Estrutura criada: $server_path"
}

# Função para criar arquivo de configuração
create_config_file() {
    local server_name="$1"
    local category="$2"
    local server_type="$3"
    local description="$4"
    local auto_start="$5"
    local restart_on_failure="$6"
    local log_level="$7"
    local env_vars="$8"
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    print_message "Criando arquivo de configuração..."
    
    # Converter array de env_vars para JSON
    local env_vars_json="[]"
    if [[ -n "$env_vars" ]]; then
        IFS=',' read -ra VARS <<< "$env_vars"
        local vars_array="["
        for i in "${!VARS[@]}"; do
            if [[ $i -gt 0 ]]; then
                vars_array+=","
            fi
            vars_array+="\"${VARS[$i]}\""
        done
        vars_array+="]"
        env_vars_json="$vars_array"
    fi
    
    cat > "$server_path/config.json" << EOF
{
  "name": "$server_name",
  "description": "$description",
  "version": "1.0.0",
  "category": "$category",
  "type": "$server_type",
  "enabled": true,
  "auto_start": $auto_start,
  "restart_on_failure": $restart_on_failure,
  "log_level": "$log_level",
  "env_vars": $env_vars_json,
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"
}
EOF
    
    print_success "Configuração criada: $server_path/config.json"
}

# Função para criar README
create_readme() {
    local server_name="$1"
    local category="$2"
    local server_type="$3"
    local description="$4"
    local env_vars="$5"
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    print_message "Criando README..."
    
    # Gerar lista de variáveis de ambiente
    local env_vars_section=""
    if [[ -n "$env_vars" ]]; then
        IFS=',' read -ra VARS <<< "$env_vars"
        env_vars_section="\n## 🔧 Variáveis de Ambiente\n\n"
        for var in "${VARS[@]}"; do
            env_vars_section+="- \`$var\`: Descrição da variável\n"
        done
    else
        env_vars_section="\n## 🔧 Variáveis de Ambiente\n\nNenhuma variável de ambiente necessária."
    fi
    
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
# Instalar dependências
npm install

# Configurar variáveis de ambiente
cp env.example .env
# Edite o arquivo .env com suas configurações

# Iniciar servidor
npm start
\`\`\`

## ⚙️ Configuração

O servidor pode ser configurado através do arquivo \`config.json\`:

- \`enabled\`: Habilita/desabilita o servidor
- \`auto_start\`: Inicia automaticamente
- \`restart_on_failure\`: Reinicia em caso de falha
- \`log_level\`: Nível de log (error, warn, info, debug)

$env_vars_section

## 📚 Documentação

Consulte a documentação completa em \`docs/\`.

## 🧪 Testes

\`\`\`bash
npm test
\`\`\`

## 📝 Logs

Os logs são salvos em \`logs/\` com o nível configurado em \`config.json\`.

---

**Criado em**: $(date '+%Y-%m-%d')
**Categoria**: $category
EOF
    
    print_success "README criado: $server_path/README.md"
}

# Função para criar arquivo de variáveis de ambiente
create_env_example() {
    local server_name="$1"
    local env_vars="$2"
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    if [[ -z "$env_vars" ]]; then
        return
    fi
    
    print_message "Criando arquivo de variáveis de ambiente..."
    
    cat > "$server_path/env.example" << EOF
# ========================================
# $(echo "$server_name" | tr '[:lower:]' '[:upper:]') - Variáveis de Ambiente
# ========================================

EOF
    
    IFS=',' read -ra VARS <<< "$env_vars"
    for var in "${VARS[@]}"; do
        echo "# $var" >> "$server_path/env.example"
        echo "$var=your_$(echo "$var" | tr '[:upper:]' '[:lower:]')_here" >> "$server_path/env.example"
        echo "" >> "$server_path/env.example"
    done
    
    print_success "Arquivo de ambiente criado: $server_path/env.example"
}

# Função para criar arquivo principal do servidor
create_server_file() {
    local server_name="$1"
    local server_type="$2"
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    print_message "Criando arquivo principal do servidor..."
    
    case "$server_type" in
        "node")
            cat > "$server_path/server.js" << 'EOF'
#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

// Configuração do servidor
const config = {
  name: 'SERVER_NAME',
  version: '1.0.0'
};

// Criar servidor MCP
const server = new Server(
  {
    name: config.name,
    version: config.version,
  },
  {
    capabilities: {
      tools: {
        listChanged: true
      }
    }
  }
);

// Configurar handlers
server.setRequestHandler('tools/list', async () => {
  // Implementar listagem de ferramentas
  return [];
});

server.setRequestHandler('tools/call', async (request) => {
  // Implementar chamada de ferramentas
  return {
    content: [
      {
        type: 'text',
        text: 'Ferramenta executada com sucesso'
      }
    ]
  };
});

// Iniciar servidor
const transport = new StdioServerTransport();
await server.connect(transport);

console.log(`🚀 ${config.name} iniciado`);
EOF
            # Substituir SERVER_NAME pelo nome real
            sed -i.bak "s/SERVER_NAME/$server_name/g" "$server_path/server.js"
            rm "$server_path/server.js.bak"
            ;;
            
        "python")
            cat > "$server_path/server.py" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
SERVER_NAME - Servidor MCP
Implemente seu servidor MCP aqui
"""

import sys
import json
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    """Função principal do servidor"""
    print(f"🚀 SERVER_NAME iniciado")
    print("📋 Versão: 1.0.0")
    print("🔧 Implemente seu servidor MCP aqui")
    print("📡 Aguardando conexões...")
    
    # Loop principal do servidor
    try:
        while True:
            # Implementar lógica do servidor MCP
            pass
    except KeyboardInterrupt:
        print("\n👋 Servidor encerrado")

if __name__ == "__main__":
    main()
EOF
            # Substituir SERVER_NAME pelo nome real
            sed -i.bak "s/SERVER_NAME/$server_name/g" "$server_path/server.py"
            rm "$server_path/server.py.bak"
            ;;
            
        "go")
            cat > "$server_path/main.go" << 'EOF'
package main

import (
    "fmt"
    "log"
)

func main() {
    fmt.Println("🚀 SERVER_NAME iniciado")
    fmt.Println("📋 Versão: 1.0.0")
    fmt.Println("🔧 Implemente seu servidor MCP aqui")
    fmt.Println("📡 Aguardando conexões...");
    
    // Implementar lógica do servidor MCP
    log.Fatal("Servidor não implementado ainda")
}
EOF
            # Substituir SERVER_NAME pelo nome real
            sed -i.bak "s/SERVER_NAME/$server_name/g" "$server_path/main.go"
            rm "$server_path/main.go.bak"
            ;;
            
        "rust")
            cat > "$server_path/src/main.rs" << 'EOF'
fn main() {
    println!("🚀 SERVER_NAME iniciado");
    println!("📋 Versão: 1.0.0");
    println!("🔧 Implemente seu servidor MCP aqui");
    println!("📡 Aguardando conexões...");
    
    // Implementar lógica do servidor MCP
    eprintln!("Servidor não implementado ainda");
    std::process::exit(1);
}
EOF
            # Substituir SERVER_NAME pelo nome real
            sed -i.bak "s/SERVER_NAME/$server_name/g" "$server_path/src/main.rs"
            rm "$server_path/src/main.rs.bak"
            
            # Criar Cargo.toml para Rust
            cat > "$server_path/Cargo.toml" << EOF
[package]
name = "$server_name"
version = "1.0.0"
edition = "2021"

[dependencies]
# Adicione suas dependências aqui
EOF
            ;;
            
        *)
            cat > "$server_path/server.txt" << EOF
# $server_name - Servidor MCP
# Implemente seu servidor MCP aqui

# Para mais informações sobre MCP:
# https://modelcontextprotocol.io/

echo "🚀 $server_name iniciado"
echo "📋 Versão: 1.0.0"
echo "🔧 Implemente seu servidor MCP aqui"
echo "📡 Aguardando conexões..."
EOF
            ;;
    esac
    
    print_success "Arquivo principal criado para tipo $server_type"
}

# Função para criar package.json (se Node.js)
create_package_json() {
    local server_name="$1"
    local description="$2"
    local category="$3"
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    if [[ "$server_type" != "node" ]]; then
        return
    fi
    
    print_message "Criando package.json..."
    
    cat > "$server_path/package.json" << EOF
{
  "name": "$server_name",
  "version": "1.0.0",
  "description": "$description",
  "main": "server.js",
  "type": "module",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest",
    "lint": "eslint ."
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.4.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.0",
    "jest": "^29.0.0"
  },
  "keywords": ["mcp", "server", "$category"],
  "author": "MCP Hub",
  "license": "MIT"
}
EOF
    
    print_success "package.json criado: $server_path/package.json"
}

# Função para instalar dependências
install_dependencies() {
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    if [[ "$server_type" != "node" ]]; then
        print_info "Instalação automática de dependências só é suportada para Node.js"
        return
    fi
    
    if [[ "$install_deps" != "true" ]]; then
        print_info "Pule a instalação automática de dependências. Use -i para habilitar."
        return
    fi
    
    print_message "Instalando dependências..."
    
    cd "$server_path"
    if npm install; then
        print_success "Dependências instaladas com sucesso"
    else
        print_warning "Falha ao instalar dependências. Execute manualmente: cd $server_path && npm install"
    fi
    
    cd "$ROOT_DIR"
}

# Função para atualizar perfis das CLIs
update_cli_profiles() {
    local server_name="$1"
    local category="$2"
    
    print_message "Atualizando perfis das CLIs..."
    
    # Atualizar todos os perfis de CLI para incluir o novo servidor
    for profile_file in "$CLI_PROFILES_DIR"/*.json; do
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

# Função para sincronizar com CLIs
sync_with_clis() {
    if [[ "$sync_clis" != "true" ]]; then
        print_info "Pule a sincronização automática. Use -s para habilitar."
        return
    fi
    
    print_message "Sincronizando com CLIs..."
    
    if [[ -f "$ROOT_DIR/package.json" ]]; then
        cd "$ROOT_DIR"
        if npm run sync; then
            print_success "Sincronização concluída com sucesso"
        else
            print_warning "Falha na sincronização. Execute manualmente: npm run sync"
        fi
    else
        print_warning "package.json não encontrado. Execute manualmente: npm run sync"
    fi
}

# Função para mostrar resumo da instalação
show_installation_summary() {
    local server_path="$SERVERS_DIR/$category/$server_name"
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🎉 Servidor Instalado com Sucesso! 🎉${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}📋 Resumo da Instalação:${NC}"
    echo ""
    echo -e "${WHITE}Nome:${NC} $server_name"
    echo -e "${WHITE}Categoria:${NC} $category"
    echo -e "${WHITE}Tipo:${NC} $server_type"
    echo -e "${WHITE}Descrição:${NC} $description"
    echo -e "${WHITE}Localização:${NC} $server_path"
    echo ""
    echo -e "${CYAN}📁 Arquivos Criados:${NC}"
    echo "   $server_path/"
    echo "   ├── config.json"
    echo "   ├── README.md"
    
    case "$server_type" in
        "node")
            echo "   ├── server.js"
            echo "   └── package.json"
            ;;
        "python")
            echo "   └── server.py"
            ;;
        "go")
            echo "   ├── main.go"
            echo "   └── go.mod"
            ;;
        "rust")
            echo "   ├── src/main.rs"
            echo "   └── Cargo.toml"
            ;;
        *)
            echo "   └── server.txt"
            ;;
    esac
    
    if [[ -n "$env_vars" ]]; then
        echo "   └── env.example"
    fi
    
    echo ""
    echo -e "${CYAN}🔧 Próximos Passos:${NC}"
    echo ""
    echo "1. Configure as variáveis de ambiente:"
    echo "   nano $server_path/env.example"
    echo ""
    echo "2. Personalize o servidor:"
    case "$server_type" in
        "node")
            echo "   nano $server_path/server.js"
            ;;
        "python")
            echo "   nano $server_path/server.py"
            ;;
        "go")
            echo "   nano $server_path/main.go"
            ;;
        "rust")
            echo "   nano $server_path/src/main.rs"
            ;;
        *)
            echo "   nano $server_path/server.txt"
            ;;
    esac
    
    if [[ "$server_type" == "node" && "$install_deps" != "true" ]]; then
        echo ""
        echo "3. Instale as dependências:"
        echo "   cd $server_path && npm install"
    fi
    
    if [[ "$sync_clis" != "true" ]]; then
        echo ""
        echo "4. Sincronize com suas CLIs:"
        echo "   npm run sync"
    fi
    
    echo ""
    echo "5. Teste o servidor:"
    case "$server_type" in
        "node")
            echo "   cd $server_path && npm start"
            ;;
        "python")
            echo "   cd $server_path && python3 server.py"
            ;;
        "go")
            echo "   cd $server_path && go run main.go"
            ;;
        "rust")
            echo "   cd $server_path && cargo run"
            ;;
        *)
            echo "   cd $server_path && cat server.txt"
            ;;
    esac
    
    echo ""
    echo -e "${CYAN}🔗 Integração Automática:${NC}"
    echo "✅ Servidor adicionado ao MCP Hub"
    echo "✅ Perfis das CLIs atualizados"
    if [[ "$sync_clis" == "true" ]]; then
        echo "✅ CLIs sincronizadas automaticamente"
    fi
    if [[ "$install_deps" == "true" && "$server_type" == "node" ]]; then
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
    local server_type="node"
    local description="Servidor MCP personalizado"
    local env_vars=""
    local auto_start="false"
    local restart_on_failure="true"
    local log_level="info"
    local install_deps="false"
    local sync_clis="false"
    local force="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--category)
                category="$2"
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
            -a|--auto-start)
                auto_start="true"
                shift
                ;;
            -r|--restart-on-failure)
                restart_on_failure="true"
                shift
                ;;
            -l|--log-level)
                log_level="$2"
                shift 2
                ;;
            -i|--install-deps)
                install_deps="true"
                shift
                ;;
            -s|--sync-clis)
                sync_clis="true"
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
    
    if ! validate_server_name "$server_name"; then
        print_error "Nome do servidor inválido. Use apenas letras minúsculas, números e hífens"
        exit 1
    fi
    
    if ! validate_category "$category"; then
        print_error "Categoria inválida: $category"
        show_help
        exit 1
    fi
    
    if ! validate_type "$server_type"; then
        print_error "Tipo inválido: $server_type"
        show_help
        exit 1
    fi
    
    # Verificar se o servidor já existe
    local server_path="$SERVERS_DIR/$category/$server_name"
    if [[ -d "$server_path" && "$force" != "true" ]]; then
        print_error "Servidor já existe: $server_path"
        print_info "Use -f para forçar a instalação (sobrescrever)"
        exit 1
    fi
    
    # Mostrar resumo da instalação
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🚀 MCP Hub - Instalador de Servidores${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${CYAN}📋 Configuração do Servidor:${NC}"
    echo "   Nome: $server_name"
    echo "   Categoria: $category"
    echo "   Tipo: $server_type"
    echo "   Descrição: $description"
    echo "   Variáveis de Ambiente: ${env_vars:-Nenhuma}"
    echo "   Auto-start: $auto_start"
    echo "   Restart on Failure: $restart_on_failure"
    echo "   Log Level: $log_level"
    echo "   Instalar Dependências: $install_deps"
    echo "   Sincronizar CLIs: $sync_clis"
    echo ""
    
    # Confirmar instalação
    read -p "Continuar com a instalação? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Instalação cancelada"
        exit 0
    fi
    
    # Executar instalação
    print_message "Iniciando instalação do servidor $server_name..."
    
    create_server_structure "$server_name" "$category"
    create_config_file "$server_name" "$category" "$server_type" "$description" "$auto_start" "$restart_on_failure" "$log_level" "$env_vars"
    create_readme "$server_name" "$category" "$server_type" "$description" "$env_vars"
    create_env_example "$server_name" "$env_vars"
    create_server_file "$server_name" "$server_type"
    create_package_json "$server_name" "$description" "$category"
    install_dependencies
    update_cli_profiles "$server_name" "$category"
    sync_with_clis
    
    # Mostrar resumo final
    show_installation_summary
    
    print_success "Instalação concluída com sucesso!"
}

# Executar função principal
main "$@"
