# 🚀 MCP Servers Hub

Centralizador inteligente de servidores MCP para múltiplas CLIs de desenvolvimento. Este repositório permite gerenciar todos os seus servidores MCP em um local central, compartilhando configurações e facilitando a manutenção.

## 🎯 Objetivos

- **Centralização**: Todos os servidores MCP em um local único
- **Consistência**: Configurações padronizadas para todas as CLIs
- **Manutenção Simplificada**: Atualize uma vez, aplique em todos os lugares
- **Setup Automatizado**: Scripts para configuração rápida de novos ambientes
- **Flexibilidade**: Fácil adição/remoção de servidores
- **Sincronização Automática**: Instale um servidor e ele aparece em todos os CLIs

## 🛠️ Stack Tecnológica

- **Shell Scripts**: Bash/Zsh para automação
- **Node.js**: Para scripts de configuração avançados
- **Python**: Para utilitários de configuração (opcional)
- **Docker**: Para containerização de servidores (opcional)
- **Git**: Para versionamento e sincronização
- **jq**: Para manipulação de JSON
- **npx**: Para execução de pacotes npm

## 🏗️ Arquitetura

**Padrão**: Hub-and-Spoke com sincronização automática
- **Hub**: Este repositório central
- **Spokes**: CLIs individuais conectadas via configuração automática
- **Sincronização**: Scripts que detectam e configuram automaticamente todos os servidores

## 📁 Estrutura do Projeto

```
MCP_servers/
├── servers/           # Servidores MCP organizados por categoria
│   ├── ai/           # Servidores de IA (Context7, Claude, GPT, etc.)
│   ├── development/  # Servidores de desenvolvimento (Git, Docker, etc.)
│   ├── database/     # Servidores de banco de dados
│   ├── cloud/        # Servidores de cloud (AWS, GCP, etc.)
│   └── custom/       # Servidores personalizados
├── configs/          # Configurações compartilhadas
│   ├── templates/    # Templates de configuração
│   ├── env/          # Variáveis de ambiente
│   └── profiles/     # Perfis de configuração por CLI
├── scripts/          # Scripts de automação
│   ├── setup/        # Scripts de configuração
│   ├── sync/         # Scripts de sincronização
│   └── utils/        # Utilitários
├── workflows/        # Workflows e guias detalhados
├── docs/             # Documentação detalhada
├── tests/            # Testes de integração
└── cli-profiles/     # Configurações específicas por CLI
```

## 🚀 Configuração do Ambiente

### Pré-requisitos

- **macOS/Linux**: Bash ou Zsh
- **Node.js**: v18+ (para scripts avançados)
- **Git**: Para clonar e sincronizar
- **jq**: Para manipulação de JSON (`brew install jq`)
- **Permissões**: Acesso para criar configurações de CLIs

### Instalação Rápida

```bash
# Clone o repositório
git clone <seu-repo> MCP_servers
cd MCP_servers

# Execute o setup automático
./install.sh

# Configure suas variáveis de ambiente
cp configs/env/env.example configs/env/.env
# Edite o arquivo .env com suas configurações

# Sincronize com todos os CLIs
./scripts/sync-all-clis-universal.sh
```

### Configuração Manual

```bash
# 1. Instalar dependências
npm install

# 2. Configurar variáveis de ambiente
cp configs/env/env.example configs/env/.env

# 3. Executar setup
npm run setup

# 4. Sincronizar com todos os CLIs
npm run sync
```

## 🔧 Desenvolvimento

### Scripts Disponíveis

```bash
npm run setup          # Configuração inicial
npm run sync           # Sincronizar configurações
npm run test           # Executar testes
npm run docs           # Gerar documentação
npm run clean          # Limpar arquivos temporários
```

### Scripts Principais

```bash
# Sincronização universal (recomendado)
./scripts/sync-all-clis-universal.sh

# Instalação e sincronização automática
./scripts/install-and-sync.sh <tipo> [opções]

# Teste de todos os CLIs
./scripts/test-all-clis.sh
```

## 🌐 Instalação de Servidores MCP

### Método Principal (Recomendado)

```bash
# Instalar do Smithery.ai (sincronização automática)
./scripts/install-and-sync.sh smithery @smithery/web-search ai

# Instalar do GitHub (sincronização automática)
./scripts/install-and-sync.sh github https://github.com/user/mcp-server development

# Instalar de caminho local (sincronização automática)
./scripts/install-and-sync.sh local ./meu-servidor custom

# Instalar de arquivo ZIP (sincronização automática)
./scripts/install-and-sync.sh zip servidor.zip database
```

### Métodos Específicos

```bash
# Apenas instalar do Smithery.ai
./scripts/install-smithery-server.sh @smithery/web-search ai

# Apenas instalar servidor existente
./scripts/install-existing-server.sh github https://github.com/user/mcp-server

# Apenas sincronizar CLIs existentes
./scripts/sync-all-clis-universal.sh
```

### Servidores Populares do Smithery.ai

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

## 📋 Regras Específicas do Projeto

### Padrões de Nomenclatura

- **Servidores**: `kebab-case` (ex: `context7-server`)
- **CLIs**: `snake_case` (ex: `cursor`, `vscode`)
- **Configurações**: `UPPER_SNAKE_CASE` (ex: `MCP_SERVER_PATH`)

### Estrutura de Servidor

Cada servidor deve conter:
```
servidor/
├── config.json       # Configuração principal
├── server.js         # Código do servidor (se aplicável)
├── README.md         # Documentação específica
├── package.json      # Dependências (se aplicável)
└── .env.example      # Variáveis de exemplo
```

### Regras de Configuração

- **Nunca** commitar arquivos `.env` reais
- **Sempre** usar `.env.example` como template
- **Sempre** documentar novas variáveis de ambiente
- **Sempre** testar em ambiente de desenvolvimento primeiro
- **Sempre** sincronizar após instalar novos servidores

## 🚀 Deploy e Produção

### Sincronização Automática

```bash
# Sincronizar com todas as CLIs conectadas
./scripts/sync-all-clis-universal.sh

# Verificar status de todos os CLIs
./scripts/test-all-clis.sh
```

### Backup e Restauração

```bash
# Backup das configurações
npm run backup

# Restaurar configurações
npm run restore
```

### Monitoramento

- Logs de sincronização em `logs/sync.log`
- Status das CLIs conectadas em `logs/cli-status.log`
- Erros de configuração em `logs/errors.log`

## 🔗 Integrações Suportadas

### CLIs Principais
- **Cursor**: Configuração automática via `~/.cursor/mcp.json`
- **VS Code**: Configuração automática via `~/.vscode/settings.json`
- **Claude Desktop**: Configuração automática via `~/.claude/settings.json`
- **Gemini CLI**: Configuração automática via `~/.gemini/settings.json`

### Servidores MCP
- **AI**: Context7, Claude, GPT, Ollama, LocalAI
- **Development**: Git, Docker, Kubernetes
- **Database**: PostgreSQL, MongoDB, Redis, Supabase
- **Cloud**: AWS, GCP, Azure, DigitalOcean
- **Smithery.ai**: 6366+ skills e extensões disponíveis

## 📚 Documentação Adicional

- [Guia de Configuração](./docs/CONFIGURATION.md)
- [Troubleshooting](./docs/TROUBLESHOOTING.md)
- [Workflow de Instalação](./workflows/install.md)
- [API Reference](./docs/API.md)
- [Contribuindo](./docs/CONTRIBUTING.md)

## 🎯 Workflow de Instalação

Para agentes e desenvolvedores que precisam instalar servidores MCP, consulte o [guia detalhado](./workflows/install.md) que contém:

- Passo a passo detalhado para cada tipo de instalação
- Exemplos práticos com comandos específicos
- Troubleshooting para problemas comuns
- Verificação de instalação bem-sucedida

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

**💡 Dica**: Execute `./scripts/test-all-clis.sh` para verificar se todos os CLIs estão funcionando corretamente após instalar novos servidores.

**🚀 Dica**: Use `./scripts/install-and-sync.sh` para instalar qualquer servidor MCP e sincronizar automaticamente com todos os CLIs!
