# 📚 Guia de Configuração - MCP Servers Hub

Este guia detalha como configurar e usar o MCP Servers Hub para centralizar todos os seus servidores MCP.

## 🎯 Visão Geral

O MCP Servers Hub é uma solução que permite:
- **Centralizar** todos os servidores MCP em um local único
- **Compartilhar** configurações entre múltiplas CLIs
- **Sincronizar** automaticamente servidores com todas as CLIs
- **Gerenciar** facilmente a adição/remoção de servidores

## 🏗️ Arquitetura

### Estrutura de Diretórios
```
MCP_servers/
├── servers/           # Servidores MCP organizados por categoria
│   ├── ai/           # Servidores de IA
│   ├── development/  # Servidores de desenvolvimento
│   ├── database/     # Servidores de banco de dados
│   ├── cloud/        # Servidores de cloud
│   └── custom/       # Servidores personalizados
├── configs/          # Configurações compartilhadas
├── scripts/          # Scripts de automação
├── cli-profiles/     # Perfis de configuração por CLI
└── logs/             # Logs e relatórios
```

### Como Funciona
1. **Hub Central**: Este repositório contém todos os servidores
2. **Symlinks**: Cada CLI é conectada via symlinks para o diretório `servers/`
3. **Sincronização**: Mudanças no hub são automaticamente refletidas em todas as CLIs
4. **Configuração Única**: Configure uma vez, use em todos os lugares

## 🚀 Configuração Inicial

### 1. Pré-requisitos
- **Node.js 18+**: Para scripts de automação
- **Git**: Para versionamento
- **Permissões**: Acesso para criar symlinks

### 2. Setup Automático
```bash
# Clone o repositório
git clone <seu-repo> MCP_servers
cd MCP_servers

# Execute o setup automático
npm run setup

# Configure variáveis de ambiente
cp configs/env/env.example configs/env/.env
# Edite o arquivo .env com suas configurações
```

### 3. Configuração Manual
Se preferir configurar manualmente:

```bash
# Instalar dependências
npm install

# Criar estrutura de diretórios
mkdir -p servers/{ai,development,database,cloud,custom}
mkdir -p configs/{templates,env,profiles}
mkdir -p scripts/{setup,sync,utils}
mkdir -p docs tests cli-profiles logs

# Copiar arquivo de exemplo
cp configs/env/env.example configs/env/.env
```

## ⚙️ Configuração das Variáveis de Ambiente

### Arquivo .env
O arquivo `.env` controla todo o comportamento do sistema:

```bash
# ========================================
# CONFIGURAÇÕES GLOBAIS
# ========================================
NODE_ENV=development
LOG_LEVEL=info
DEBUG=false

# ========================================
# PATHS E DIRETÓRIOS
# ========================================
MCP_HUB_ROOT=/caminho/para/seu/MCP_servers
MCP_SERVERS_PATH=${MCP_HUB_ROOT}/servers
MCP_CONFIGS_PATH=${MCP_HUB_ROOT}/configs
MCP_LOGS_PATH=${MCP_HUB_ROOT}/logs

# ========================================
# CLIs SUPORTADAS
# ========================================
CURSOR_ENABLED=true
CURSOR_PATH=~/.cursor/mcp_servers

VSCODE_ENABLED=false
VSCODE_PATH=~/.vscode/mcp_servers

NEOVIM_ENABLED=false
NEOVIM_PATH=~/.config/nvim/mcp_servers

# ========================================
# SERVIDORES MCP
# ========================================
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
OLLAMA_BASE_URL=http://localhost:11434

# ========================================
# CONFIGURAÇÕES DE SINCRONIZAÇÃO
# ========================================
AUTO_SYNC=true
SYNC_INTERVAL=300000
BACKUP_BEFORE_SYNC=true
MAX_BACKUPS=10
```

### Variáveis Importantes

#### CLIs
- **`{CLI}_ENABLED`**: Habilita/desabilita uma CLI específica
- **`{CLI}_PATH`**: Caminho de configuração da CLI

#### Servidores
- **`OPENAI_API_KEY`**: Chave da API OpenAI
- **`ANTHROPIC_API_KEY`**: Chave da API Anthropic
- **`OLLAMA_BASE_URL`**: URL do servidor Ollama local

#### Sistema
- **`AUTO_SYNC`**: Habilita sincronização automática
- **`SYNC_INTERVAL`**: Intervalo de sincronização em ms
- **`LOG_LEVEL`**: Nível de log (error, warn, info, debug)

## 🔗 Conectando CLIs

### 1. Habilitar CLIs
Edite o arquivo `.env` e defina as CLIs que você usa:

```bash
CURSOR_ENABLED=true
VSCODE_ENABLED=true
NEOVIM_ENABLED=false
```

### 2. Executar Conexão
```bash
npm run connect-cli
```

### 3. Verificar Conexão
```bash
npm run status
```

## 🚀 Adicionando Servidores MCP

### 1. Adição Interativa
```bash
npm run add-server
```

O script irá guiá-lo através de:
- Nome do servidor
- Categoria
- Descrição
- Tipo (Node.js, Python, Go, etc.)
- Configurações específicas
- Variáveis de ambiente

### 2. Estrutura Criada
Para cada servidor, será criado:

```
servers/categoria/nome-servidor/
├── config.json       # Configuração do servidor
├── server.js         # Código do servidor
├── README.md         # Documentação
├── .env.example      # Variáveis de ambiente
├── package.json      # Dependências (se Node.js)
├── src/              # Código fonte
├── docs/             # Documentação adicional
└── tests/            # Testes
```

### 3. Configuração do Servidor
Cada servidor tem um `config.json`:

```json
{
  "name": "nome-servidor",
  "description": "Descrição do servidor",
  "version": "1.0.0",
  "category": "ai",
  "type": "node",
  "enabled": true,
  "auto_start": false,
  "restart_on_failure": true,
  "log_level": "info",
  "env_vars": ["API_KEY", "API_URL"]
}
```

## 🔄 Sincronização

### 1. Sincronização Manual
```bash
# Sincronizar todas as CLIs
npm run sync

# Sincronizar CLI específica
npm run sync:cli
```

### 2. Sincronização Automática
Configure no arquivo `.env`:

```bash
AUTO_SYNC=true
SYNC_INTERVAL=300000  # 5 minutos
```

### 3. O que é Sincronizado
- **Servidores**: Todos os servidores habilitados
- **Configurações**: Arquivos de configuração
- **Dependências**: Pacotes e bibliotecas
- **Documentação**: READMEs e docs

## 📊 Monitoramento e Status

### 1. Status do Sistema
```bash
npm run status
```

Mostra:
- Status das CLIs conectadas
- Status dos servidores
- Histórico de sincronização
- Recomendações de melhoria

### 2. Logs
Os logs são salvos em `logs/`:
- `setup.log`: Logs de configuração
- `sync-report-*.json`: Relatórios de sincronização
- `latest-sync-report.json`: Relatório mais recente

### 3. Relatórios
Cada sincronização gera um relatório com:
- Timestamp da sincronização
- CLIs sincronizadas
- Servidores sincronizados
- Erros encontrados
- Estatísticas gerais

## 🛠️ Manutenção

### 1. Atualizações
```bash
# Atualizar dependências
npm update

# Atualizar servidores
git pull origin main
npm run sync
```

### 2. Backup
```bash
# Backup das configurações
npm run backup

# Restaurar configurações
npm run restore
```

### 3. Limpeza
```bash
# Limpar arquivos temporários
npm run clean

# Limpar logs antigos
rm logs/sync-report-*.json
```

## 🔧 Troubleshooting

### Problemas Comuns

#### 1. Symlinks Não Funcionam
```bash
# Verificar permissões
ls -la ~/.cursor/mcp_servers

# Recriar symlinks
npm run connect-cli
```

#### 2. Servidores Não Aparecem
```bash
# Verificar status
npm run status

# Sincronizar manualmente
npm run sync

# Verificar configuração do servidor
cat servers/ai/nome-servidor/config.json
```

#### 3. Erros de Sincronização
```bash
# Verificar logs
tail -f logs/mcp-hub.log

# Verificar relatório de sincronização
cat logs/latest-sync-report.json
```

### Logs de Debug
Para debug detalhado, configure:

```bash
DEBUG=true
LOG_LEVEL=debug
```

## 📚 Comandos Úteis

### Setup e Configuração
```bash
npm run setup          # Configuração inicial
npm run connect-cli    # Conectar CLIs
npm run status         # Verificar status
```

### Gerenciamento de Servidores
```bash
npm run add-server     # Adicionar servidor
npm run remove-server  # Remover servidor
npm run list-servers   # Listar servidores
```

### Sincronização
```bash
npm run sync           # Sincronizar tudo
npm run sync:cli       # Sincronizar CLI específica
```

### Utilitários
```bash
npm run backup         # Backup
npm run restore        # Restaurar
npm run clean          # Limpeza
npm run docs           # Gerar documentação
```

## 🎯 Próximos Passos

1. **Configure suas variáveis de ambiente**
2. **Conecte suas CLIs preferidas**
3. **Adicione seus servidores MCP existentes**
4. **Teste a sincronização**
5. **Configure sincronização automática se necessário**

## 🤝 Suporte

- **Documentação**: `docs/`
- **Issues**: GitHub Issues
- **Logs**: `logs/`
- **Status**: `npm run status`

---

**💡 Dica**: Execute `npm run status` regularmente para verificar a saúde do sistema e identificar problemas antes que afetem suas CLIs.
