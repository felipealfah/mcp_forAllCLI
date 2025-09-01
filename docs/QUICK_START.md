# 🚀 MCP Hub - Guia de Início Rápido

Este guia te ajudará a começar rapidamente com o MCP Servers Hub.

## 📋 Pré-requisitos

- **Node.js 18+** e **npm**
- **Git** para clonar o repositório
- **CLIs** que você quer configurar (Cursor, VS Code, etc.)

## 🚀 Instalação Rápida

### 1. Clone e Setup Inicial

```bash
# Clone o repositório
git clone <seu-repositorio> MCP_servers
cd MCP_servers

# Execute o setup automático
./install.sh
```

### 2. Configure suas Variáveis de Ambiente

```bash
# Edite o arquivo .env
nano configs/env/.env

# Configure pelo menos:
# - CURSOR_ENABLED=true
# - CURSOR_PATH=/caminho/para/cursor
# - Suas chaves de API
```

### 3. Conecte suas CLIs

```bash
# Conectar CLIs via symlinks
npm run connect-cli

# Ou use o script direto
./scripts/setup/connect-cli.js
```

## 🔧 Adicionando Novos Servidores MCP

### Método 1: Script Automatizado (Recomendado)

```bash
# Adicionar servidor com configuração automática
./scripts/install-server.sh meu-servidor -c ai -t node -d "Descrição" -e "API_KEY" -i -s

# Opções disponíveis:
# -c: categoria (ai, development, database, cloud, custom)
# -t: tipo (node, python, go, rust, other)
# -d: descrição
# -e: variáveis de ambiente (separadas por vírgula)
# -i: instalar dependências automaticamente
# -s: sincronizar com CLIs
# -f: forçar (sobrescrever se existir)
```

### Método 2: Script Interativo

```bash
# Adicionar servidor interativamente
npm run add-server
```

### Exemplos Práticos

```bash
# Servidor de IA (Claude/GPT)
./scripts/install-server.sh claude-server -c ai -t node -d "Servidor Claude MCP" -e "ANTHROPIC_API_KEY" -i -s

# Servidor de Git
./scripts/install-server.sh git-server -c development -t node -d "Servidor Git MCP" -e "GITHUB_TOKEN,GITLAB_TOKEN" -i -s

# Servidor de Banco de Dados
./scripts/install-server.sh postgres-server -c database -t python -d "Servidor PostgreSQL MCP" -e "POSTGRES_URL,POSTGRES_PASSWORD" -s
```

## 🔗 Configurando CLIs Automaticamente

### Configurar Todas as CLIs

```bash
# Configurar todas as CLIs com todos os servidores
./scripts/configure-cli-simple.sh -a -s
```

### Configurar CLI Específica

```bash
# Apenas Cursor
./scripts/configure-cli-simple.sh cursor -s

# Apenas VS Code
./scripts/configure-cli-simple.sh vscode -s
```

## 📊 Monitoramento e Status

### Verificar Status do Sistema

```bash
# Status completo
npm run status

# Verificar sincronização
npm run sync

# Listar servidores
npm run list-servers

# Listar CLIs
npm run list-clis
```

## 🔄 Sincronização Automática

### Sincronizar Manualmente

```bash
# Sincronizar todos os servidores com todas as CLIs
npm run sync
```

### Configurar Sincronização Automática

```bash
# Adicionar ao crontab (sincronizar a cada hora)
0 * * * * cd /caminho/para/MCP_servers && npm run sync

# Ou usar o script de sincronização
./scripts/sync/sync-all.js
```

## 🧪 Testando Servidores

### 1. Testar Servidor Individual

```bash
# Navegar para o servidor
cd servers/ai/context7-server

# Instalar dependências (se necessário)
npm install

# Testar servidor
npm start
```

### 2. Testar em CLIs

1. **Reinicie sua CLI** (Cursor, VS Code, etc.)
2. **Verifique os logs** da CLI para erros MCP
3. **Teste as ferramentas** disponíveis

### 3. Verificar Logs

```bash
# Logs de sincronização
cat logs/latest-sync-report.json

# Logs do sistema
npm run status
```

## 🚨 Solução de Problemas

### Problemas Comuns

#### 1. Servidor não aparece na CLI

```bash
# Verificar se está sincronizado
npm run sync

# Verificar status
npm run status

# Verificar configuração da CLI
cat ~/.cursor/User/settings.json
```

#### 2. Erro de dependências

```bash
# Instalar dependências do servidor
cd servers/ai/meu-servidor
npm install

# Verificar versão do Node.js
node --version  # Deve ser 18+
```

#### 3. Problemas de permissão

```bash
# Verificar permissões dos scripts
chmod +x scripts/*.sh

# Verificar permissões do diretório
ls -la
```

### Logs de Debug

```bash
# Habilitar debug
export DEBUG=true
export LOG_LEVEL=debug

# Executar comando
npm run sync
```

## 📚 Próximos Passos

### 1. Personalizar Servidores

- Edite `server.js` para implementar suas ferramentas
- Configure variáveis de ambiente específicas
- Adicione documentação em `README.md`

### 2. Criar Novos Servidores

- Use o script automatizado para novos servidores
- Siga o padrão de estrutura de diretórios
- Mantenha `config.json` atualizado

### 3. Integrar com Workflows

- Configure CI/CD para deploy automático
- Use branches para desenvolvimento
- Mantenha backup das configurações

## 🔗 Recursos Adicionais

- **Documentação Completa**: `docs/CONFIGURATION.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`
- **Exemplos**: `servers/ai/example-server/`
- **Templates**: `configs/templates/`

## 💡 Dicas Importantes

1. **Sempre execute `npm run status`** após mudanças
2. **Use `-s` nos scripts** para sincronização automática
3. **Configure variáveis de ambiente** antes de testar
4. **Reinicie CLIs** após mudanças de configuração
5. **Mantenha backups** das configurações existentes

---

**🎯 Objetivo**: Com este guia, você deve conseguir configurar e usar o MCP Hub em menos de 10 minutos!

**🔧 Suporte**: Se encontrar problemas, consulte `docs/TROUBLESHOOTING.md` ou execute `npm run status` para diagnóstico.
