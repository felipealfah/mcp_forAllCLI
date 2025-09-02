# 🚀 Guia Detalhado de Instalação de Servidores MCP

Este guia fornece instruções passo a passo para agentes e desenvolvedores instalarem servidores MCP no MCP Servers Hub.

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Instalação do Smithery.ai](#instalação-do-smitheryai)
3. [Instalação do GitHub](#instalação-do-github)
4. [Instalação Local](#instalação-local)
5. [Instalação via ZIP](#instalação-via-zip)
6. [Verificação de Instalação](#verificação-de-instalação)
7. [Troubleshooting](#troubleshooting)
8. [Exemplos Práticos](#exemplos-práticos)

## 🔧 Pré-requisitos

### Verificar Dependências

```bash
# Verificar se jq está instalado
which jq
# Se não estiver: brew install jq (macOS) ou apt-get install jq (Linux)

# Verificar se Node.js está instalado
node --version
# Deve ser v18 ou superior

# Verificar se npm está funcionando
npm --version

# Verificar se npx está disponível
npx --version

# Verificar se PM2 está instalado (será instalado automaticamente se não estiver)
pm2 --version
# PM2 é usado para gerenciamento de processos e auto-inicialização
```

### Verificar Estrutura do Projeto

```bash
# Verificar se estamos no diretório correto
pwd
# Deve mostrar: /path/to/MCP_servers

# Verificar se os scripts existem
ls -la scripts/
# Deve mostrar: install-and-sync.sh, sync-all-clis-universal.sh, etc.

# Verificar se a estrutura de pastas existe
ls -la servers/
# Deve mostrar: ai/, development/, database/, cloud/, custom/
```

## 🌐 Instalação do Smithery.ai

### Passo a Passo Detalhado

#### 1. Identificar o Servidor

Primeiro, identifique o servidor que deseja instalar no [Smithery.ai](https://smithery.ai/):

```bash
# Listar servidores populares
./scripts/install-smithery-server.sh list
```

#### 2. Escolher a Categoria

Categorias disponíveis:
- `ai` - Inteligência Artificial e ML
- `development` - Ferramentas de desenvolvimento
- `database` - Bancos de dados e ORMs
- `cloud` - Serviços em nuvem
- `custom` - Servidores personalizados

#### 3. Executar Instalação

```bash
# Formato: ./scripts/install-and-sync.sh smithery <nome-do-pacote> <categoria>
./scripts/install-and-sync.sh smithery @smithery/web-search ai
```

#### 4. Verificar Instalação

```bash
# Verificar se o servidor foi criado
ls -la servers/ai/@smithery/web-search/

# Verificar config.json
cat servers/ai/@smithery/web-search/config.json

# Verificar README.md
cat servers/ai/@smithery/web-search/README.md
```

### Exemplos de Instalação Smithery.ai

```bash
# Web Search & Browser
./scripts/install-and-sync.sh smithery @smithery/web-search ai
./scripts/install-and-sync.sh smithery @smithery/browser-automation ai

# AI & ML
./scripts/install-and-sync.sh smithery @smithery/ai-tools ai
./scripts/install-and-sync.sh smithery @smithery/llm-tools ai

# Development
./scripts/install-and-sync.sh smithery @smithery/github-tools development
./scripts/install-and-sync.sh smithery @smithery/docker-tools development

# Database
./scripts/install-and-sync.sh smithery @smithery/supabase-tools database
./scripts/install-and-sync.sh smithery @smithery/mongodb-tools database

# Cloud
./scripts/install-and-sync.sh smithery @smithery/aws-tools cloud
./scripts/install-and-sync.sh smithery @smithery/gcp-tools cloud
```

## 📥 Instalação do GitHub

### Passo a Passo Detalhado

#### 1. Identificar o Repositório

Encontre o repositório GitHub que contém o servidor MCP:

```bash
# Exemplo: https://github.com/upstash/context7-mcp
# Exemplo: https://github.com/supabase/mcp-server-supabase
```

#### 2. Escolher a Categoria

```bash
# Para servidores de IA
./scripts/install-and-sync.sh github https://github.com/upstash/context7-mcp ai

# Para servidores de desenvolvimento
./scripts/install-and-sync.sh github https://github.com/supabase/mcp-server-supabase development

# Para servidores de banco de dados
./scripts/install-and-sync.sh github https://github.com/user/database-mcp database
```

#### 3. Verificar Instalação

```bash
# O script irá:
# 1. Clonar o repositório
# 2. Criar config.json se não existir
# 3. Criar README.md se não existir
# 4. Instalar dependências (Node.js, Python, Go, Rust)
# 5. Sincronizar com todos os CLIs

# Verificar se foi criado
ls -la servers/ai/context7-mcp/
ls -la servers/development/mcp-server-supabase/
```

### Exemplos de Instalação GitHub

```bash
# Context7 (IA)
./scripts/install-and-sync.sh github https://github.com/upstash/context7-mcp ai

# Supabase (Database)
./scripts/install-and-sync.sh github https://github.com/supabase/mcp-server-supabase database

# GitHub Tools (Development)
./scripts/install-and-sync.sh github https://github.com/user/github-mcp development

# Custom Server (Custom)
./scripts/install-and-sync.sh github https://github.com/user/custom-mcp custom
```

## 📁 Instalação Local

### Passo a Passo Detalhado

#### 1. Preparar o Servidor Local

```bash
# Estrutura mínima necessária:
meu-servidor/
├── config.json       # OBRIGATÓRIO
├── server.js         # OPCIONAL (se for Node.js)
├── README.md         # OPCIONAL
└── package.json      # OPCIONAL (se for Node.js)
```

#### 2. Criar config.json Mínimo

```json
{
  "name": "meu-servidor",
  "type": "node",
  "description": "Meu servidor MCP personalizado",
  "command": "node",
  "args": ["server.js"],
  "capabilities": ["tools"],
  "category": "custom"
}
```

#### 3. Executar Instalação

```bash
# Formato: ./scripts/install-and-sync.sh local <caminho-local> <categoria>
./scripts/install-and-sync.sh local ./meu-servidor custom
```

#### 4. Verificar Instalação

```bash
# Verificar se foi copiado
ls -la servers/custom/meu-servidor/

# Verificar se os arquivos estão corretos
cat servers/custom/meu-servidor/config.json
```

### Exemplos de Instalação Local

```bash
# Servidor Node.js
./scripts/install-and-sync.sh local ./node-server development

# Servidor Python
./scripts/install-and-sync.sh local ./python-server ai

# Servidor Go
./scripts/install-and-sync.sh local ./go-server custom

# Servidor Rust
./scripts/install-and-sync.sh local ./rust-server development
```

## 🔄 Configuração do PM2 (Gerenciamento de Processos)

### O que é PM2?

O PM2 é um gerenciador de processos para aplicações Node.js que permite:
- **Auto-inicialização**: Servidores iniciam automaticamente após reinicialização do sistema
- **Monitoramento**: Acompanhar status, logs e performance dos servidores
- **Recuperação automática**: Reiniciar servidores que falharam automaticamente

### Configuração Automática

O script `install.sh` configura o PM2 automaticamente:

```bash
# Executar instalação completa com PM2
./install.sh

# O script irá:
# 1. Verificar se PM2 está instalado (instala se necessário)
# 2. Configurar servidores MCP no PM2
# 3. Salvar configuração PM2
# 4. Mostrar comando para auto-inicialização
```

### Comandos Úteis do PM2

```bash
# Ver status dos servidores
pm2 status

# Ver logs em tempo real
pm2 logs mcp-servers

# Reiniciar todos os servidores
pm2 restart mcp-servers

# Parar todos os servidores
pm2 stop mcp-servers

# Deletar configuração PM2
pm2 delete mcp-servers

# Salvar configuração atual
pm2 save

# Configurar auto-inicialização (requer sudo)
pm2 startup
# Execute o comando sudo que será exibido

# Ver monitoramento visual
pm2 monit
```

### Configuração Manual do PM2

Se precisar configurar manualmente:

```bash
# 1. Instalar PM2 globalmente
npm install -g pm2

# 2. Tornar script executável
chmod +x scripts/start-all-servers.sh

# 3. Iniciar com PM2
pm2 start scripts/start-all-servers.sh --name mcp-servers

# 4. Salvar configuração
pm2 save

# 5. Configurar auto-inicialização
pm2 startup
# Execute o comando sudo mostrado
```

### Verificar Configuração PM2

```bash
# Verificar se servidores estão rodando
pm2 status

# Ver detalhes do processo
pm2 show mcp-servers

# Ver últimos logs
pm2 logs mcp-servers --lines 50

# Verificar se auto-inicialização está configurada
pm2 startup --help
```

## 📦 Instalação via ZIP

### Passo a Passo Detalhado

#### 1. Preparar o Arquivo ZIP

```bash
# O ZIP deve conter a estrutura do servidor na raiz:
# servidor.zip
# └── meu-servidor/
#     ├── config.json
#     ├── server.js
#     └── README.md
```

#### 2. Executar Instalação

```bash
# Formato: ./scripts/install-and-sync.sh zip <arquivo-zip> <categoria>
./scripts/install-and-sync.sh zip servidor.zip custom
```

#### 3. Verificar Instalação

```bash
# Verificar se foi extraído
ls -la servers/custom/meu-servidor/

# Verificar arquivos
cat servers/custom/meu-servidor/config.json
```

### Exemplos de Instalação ZIP

```bash
# Servidor de IA
./scripts/install-and-sync.sh zip ai-server.zip ai

# Servidor de desenvolvimento
./scripts/install-and-sync.sh zip dev-server.zip development

# Servidor de banco de dados
./scripts/install-and-sync.sh zip db-server.zip database
```

## ✅ Verificação de Instalação

### 1. Verificar Estrutura do Servidor

```bash
# Verificar se o servidor foi criado na categoria correta
ls -la servers/ai/@smithery/web-search/
ls -la servers/development/github-mcp/
ls -la servers/custom/meu-servidor/

# Verificar arquivos obrigatórios
ls -la servers/ai/@smithery/web-search/config.json
ls -la servers/ai/@smithery/web-search/README.md
```

### 2. Verificar Configuração

```bash
# Verificar se config.json é válido
cat servers/ai/@smithery/web-search/config.json | jq .

# Verificar se tem os campos obrigatórios
cat servers/ai/@smithery/web-search/config.json | jq '.name, .type, .command'
```

### 3. Verificar Sincronização com CLIs

```bash
# Verificar se foi sincronizado com Cursor
cat ~/.cursor/mcp.json | jq '.mcpServers'

# Verificar se foi sincronizado com VS Code
cat ~/.vscode/settings.json | jq '.mcpServers'

# Verificar se foi sincronizado com Claude
cat ~/.claude/settings.json | jq '.mcpServers'

# Verificar se foi sincronizado com Gemini
cat ~/.gemini/settings.json | jq '.mcpServers'
```

### 4. Verificar PM2 (se configurado)

```bash
# Verificar se servidores estão rodando no PM2
pm2 status

# Verificar logs dos servidores
pm2 logs mcp-servers --lines 20

# Verificar se auto-inicialização está configurada
pm2 list

# Se PM2 não estiver configurado, configurar
pm2 start scripts/start-all-servers.sh --name mcp-servers
pm2 save
```

### 5. Testar o Servidor

```bash
# Executar teste universal
./scripts/test-all-clis.sh

# Testar servidor específico (se for npx)
npx -y @smithery/web-search --help

# Testar servidor específico (se for node)
cd servers/ai/@smithery/web-search/
node server.js --help
```

## 🔧 Troubleshooting

### Problema: "jq não está instalado"

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq

# Verificar instalação
jq --version
```

### Problema: "Pacote npm não encontrado"

```bash
# Verificar se o pacote existe
npm view @smithery/web-search

# Se não existir, verificar nome correto
npm search smithery web-search

# Verificar no site do Smithery.ai
# https://smithery.ai/
```

### Problema: "Repositório GitHub não encontrado"

```bash
# Verificar se a URL está correta
curl -I https://github.com/user/repo

# Verificar se é um repositório público
# Se for privado, configure autenticação

# Testar clone manual
git clone https://github.com/user/repo temp-test
rm -rf temp-test
```

### Problema: "Erro de permissão"

```bash
# Verificar permissões
ls -la scripts/
ls -la servers/

# Tornar scripts executáveis
chmod +x scripts/*.sh

# Verificar permissões de escrita
ls -la ~/.cursor/
ls -la ~/.vscode/
ls -la ~/.claude/
ls -la ~/.gemini/
```

### Problema: "JSON inválido"

```bash
# Verificar se config.json é válido
cat servers/ai/servidor/config.json | jq .

# Se houver erro, corrigir o JSON
# Verificar aspas, vírgulas, colchetes

# Exemplo de JSON válido:
{
  "name": "servidor",
  "type": "npx",
  "command": "npx",
  "args": ["-y", "package-name"]
}
```

### Problema: "CLI não reconhece o servidor"

```bash
# Verificar se a sincronização foi executada
./scripts/sync-all-clis-universal.sh

# Verificar configuração do CLI
cat ~/.cursor/mcp.json | jq .

# Reiniciar o CLI
# Fechar e abrir novamente Cursor, VS Code, etc.

# Verificar logs do CLI (se disponível)
tail -f ~/.cursor/logs/*.log
```

### Problema: "PM2 não inicia automaticamente"

```bash
# Verificar se PM2 está instalado
pm2 --version

# Se não estiver, instalar
npm install -g pm2

# Verificar se processo está rodando
pm2 status

# Se não estiver, iniciar
pm2 start scripts/start-all-servers.sh --name mcp-servers
pm2 save

# Configurar auto-inicialização
pm2 startup
# Execute o comando sudo mostrado
```

### Problema: "Servidores PM2 ficam reiniciando"

```bash
# Verificar logs para identificar erros
pm2 logs mcp-servers

# Verificar se dependências estão instaladas
cd servers/categoria/servidor/
npm install

# Verificar se script de build funcionou
npm run build

# Parar e reiniciar limpo
pm2 delete mcp-servers
pm2 start scripts/start-all-servers.sh --name mcp-servers
pm2 save
```

### Problema: "PM2 não encontra script start-all-servers.sh"

```bash
# Verificar se script existe
ls -la scripts/start-all-servers.sh

# Se não existir, criar
cat > scripts/start-all-servers.sh << 'EOF'
#!/bin/bash
echo "Iniciando todos os servidores MCP instalados..."
find "$PWD/servers/" -name "package.json" | while read package_json_path; do
    server_dir=$(dirname "$package_json_path")
    server_name=$(basename "$server_dir")
    echo "Verificando servidor em: $server_dir"
    if grep -q '"start":' "$package_json_path"; then
        echo "  -> Iniciando $server_name..."
        (cd "$server_dir" && npm start &)
    fi
done
EOF

# Tornar executável
chmod +x scripts/start-all-servers.sh
```

## 📝 Exemplos Práticos

### Exemplo 1: Instalar Context7

```bash
# 1. Instalar do GitHub
./scripts/install-and-sync.sh github https://github.com/upstash/context7-mcp ai

# 2. Verificar instalação
ls -la servers/ai/context7-mcp/

# 3. Configurar API key
cp servers/ai/context7-mcp/.env.example servers/ai/context7-mcp/.env
# Editar .env com sua API key

# 4. Testar
./scripts/test-all-clis.sh
```

### Exemplo 2: Instalar Web Search do Smithery

```bash
# 1. Instalar
./scripts/install-and-sync.sh smithery @smithery/web-search ai

# 2. Verificar
ls -la servers/ai/@smithery/web-search/

# 3. Testar
npx -y @smithery/web-search --help

# 4. Verificar sincronização
cat ~/.cursor/mcp.json | jq '.mcpServers'
```

### Exemplo 3: Instalar Servidor Personalizado

```bash
# 1. Criar servidor local
mkdir -p meu-servidor
cat > meu-servidor/config.json << 'EOF'
{
  "name": "meu-servidor",
  "type": "node",
  "description": "Servidor personalizado",
  "command": "node",
  "args": ["server.js"],
  "capabilities": ["tools"],
  "category": "custom"
}
EOF

# 2. Instalar
./scripts/install-and-sync.sh local ./meu-servidor custom

# 3. Verificar
ls -la servers/custom/meu-servidor/
cat servers/custom/meu-servidor/config.json
```

## 🎯 Checklist de Verificação

Após cada instalação, verifique:

- [ ] Servidor criado na pasta correta
- [ ] config.json existe e é válido
- [ ] README.md existe
- [ ] Sincronização executada com sucesso
- [ ] CLIs configurados corretamente
- [ ] **PM2 configurado e rodando** 🆕
- [ ] **Auto-inicialização configurada** 🆕
- [ ] Servidor testado e funcionando
- [ ] Logs sem erros

## 📞 Suporte

Se encontrar problemas:

1. Execute `./scripts/test-all-clis.sh` para diagnóstico
2. Verifique os logs em `logs/`
3. Consulte o [Troubleshooting](./../docs/TROUBLESHOOTING.md)
4. Abra uma issue no repositório

---

**💡 Dica**: Sempre execute `./scripts/sync-all-clis-universal.sh` após instalar novos servidores para garantir que todos os CLIs sejam atualizados.

**🚀 Dica**: Use `./scripts/install-and-sync.sh` para instalação e sincronização automática em um único comando!
