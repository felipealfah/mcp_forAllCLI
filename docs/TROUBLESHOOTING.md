# 🔧 Troubleshooting - MCP Servers Hub

Este guia ajuda a resolver problemas comuns que podem ocorrer ao usar o MCP Servers Hub.

## 🚨 Problemas Comuns

### 1. Symlinks Não Funcionam

#### Sintomas
- CLIs não conseguem acessar servidores MCP
- Erro "symlink not found" ou similar
- Servidores não aparecem nas CLIs

#### Soluções
```bash
# Verificar permissões
ls -la ~/.cursor/mcp_servers

# Verificar se o symlink existe
ls -la ~/.cursor/mcp_servers

# Recriar symlinks
npm run connect-cli

# Verificar status
npm run status
```

#### Causas Comuns
- **Permissões insuficientes**: Execute com privilégios adequados
- **Symlink corrompido**: Remova e recrie
- **Caminho incorreto**: Verifique as configurações no `.env`

### 2. Servidores Não Aparecem

#### Sintomas
- Servidores não são listados nas CLIs
- Erro "server not found"
- CLIs não reconhecem servidores MCP

#### Soluções
```bash
# Verificar status do sistema
npm run status

# Verificar se servidores estão habilitados
cat servers/ai/example-server/config.json

# Sincronizar manualmente
npm run sync

# Verificar logs
tail -f logs/mcp-hub.log
```

#### Causas Comuns
- **Servidor desabilitado**: Verifique `enabled: true` no `config.json`
- **Sincronização falhou**: Execute `npm run sync`
- **Configuração incorreta**: Verifique estrutura dos arquivos

### 3. Erros de Sincronização

#### Sintomas
- Falha ao sincronizar servidores
- Erro "sync failed"
- CLIs não são atualizadas

#### Soluções
```bash
# Verificar relatório de sincronização
cat logs/latest-sync-report.json

# Verificar logs de erro
tail -f logs/mcp-hub.log

# Forçar sincronização
npm run sync

# Verificar permissões de arquivo
ls -la servers/
```

#### Causas Comuns
- **Permissões de arquivo**: Verifique permissões de leitura/escrita
- **Arquivos corrompidos**: Verifique integridade dos arquivos
- **Configuração inválida**: Valide arquivos JSON

### 4. CLIs Não Conectam

#### Sintomas
- Falha ao conectar CLIs
- Erro "connection failed"
- Status "disconnected"

#### Soluções
```bash
# Verificar variáveis de ambiente
cat configs/env/.env

# Verificar se CLIs estão habilitadas
grep "_ENABLED" configs/env/.env

# Reconectar CLIs
npm run connect-cli

# Verificar status
npm run status
```

#### Causas Comuns
- **CLI não habilitada**: Configure `{CLI}_ENABLED=true` no `.env`
- **Caminho incorreto**: Verifique `{CLI}_PATH` no `.env`
- **Permissões insuficientes**: Verifique acesso aos diretórios

### 5. Dependências Não Instalam

#### Sintomas
- Erro "npm install failed"
- Módulos não encontrados
- Servidores não iniciam

#### Soluções
```bash
# Limpar cache npm
npm cache clean --force

# Remover node_modules
rm -rf node_modules package-lock.json

# Reinstalar dependências
npm install

# Verificar versão do Node.js
node --version
```

#### Causas Comuns
- **Node.js desatualizado**: Atualize para versão 18+
- **Cache corrompido**: Limpe cache npm
- **Conflito de versões**: Verifique compatibilidade

## 🔍 Diagnóstico

### 1. Verificar Status do Sistema
```bash
npm run status
```

Este comando verifica:
- Status das CLIs conectadas
- Status dos servidores
- Configurações do sistema
- Logs de erro

### 2. Verificar Logs
```bash
# Log principal
tail -f logs/mcp-hub.log

# Relatório de sincronização
cat logs/latest-sync-report.json

# Logs de setup
cat logs/setup.log
```

### 3. Verificar Configurações
```bash
# Configuração principal
cat configs/config.json

# Variáveis de ambiente
cat configs/env/.env

# Perfis das CLIs
ls -la cli-profiles/
```

### 4. Verificar Estrutura
```bash
# Estrutura de diretórios
tree -L 3

# Verificar symlinks
find . -type l -ls

# Verificar permissões
ls -la servers/
```

## 🛠️ Ferramentas de Debug

### 1. Modo Debug
Configure no arquivo `.env`:
```bash
DEBUG=true
LOG_LEVEL=debug
```

### 2. Validação de Configuração
```bash
npm run validate
```

### 3. Teste de Conectividade
```bash
# Testar symlinks
ls -la ~/.cursor/mcp_servers

# Testar servidores
cd servers/ai/example-server
npm start
```

## 📋 Checklist de Verificação

### Setup Inicial
- [ ] Node.js 18+ instalado
- [ ] Dependências instaladas (`npm install`)
- [ ] Setup executado (`npm run setup`)
- [ ] Variáveis de ambiente configuradas
- [ ] CLIs habilitadas no `.env`

### Conexão das CLIs
- [ ] CLIs selecionadas (`npm run connect-cli`)
- [ ] Symlinks criados corretamente
- [ ] Status "connected" nas CLIs
- [ ] Caminhos de configuração corretos

### Servidores
- [ ] Servidores adicionados (`npm run add-server`)
- [ ] Configurações válidas (`config.json`)
- [ ] Dependências instaladas
- [ ] Servidores habilitados

### Sincronização
- [ ] Sincronização executada (`npm run sync`)
- [ ] Relatórios gerados
- [ ] CLIs atualizadas
- [ ] Logs sem erros

## 🆘 Suporte Adicional

### 1. Verificar Documentação
- `docs/CONFIGURATION.md`: Guia completo de configuração
- `README.md`: Visão geral do projeto
- `docs/API.md`: Referência da API

### 2. Verificar Issues
- GitHub Issues para problemas conhecidos
- Soluções da comunidade
- Atualizações e correções

### 3. Logs Detalhados
Execute com debug habilitado:
```bash
DEBUG=true npm run sync
DEBUG=true npm run connect-cli
DEBUG=true npm run status
```

### 4. Verificar Sistema
```bash
# Verificar versões
node --version
npm --version
git --version

# Verificar permissões
ls -la ~/.cursor/
ls -la ~/.vscode/

# Verificar espaço em disco
df -h
```

## 🎯 Prevenção de Problemas

### 1. Manutenção Regular
- Execute `npm run status` regularmente
- Monitore logs de erro
- Mantenha dependências atualizadas

### 2. Backup
- Faça backup das configurações
- Versione mudanças importantes
- Teste em ambiente de desenvolvimento

### 3. Validação
- Valide configurações antes de aplicar
- Teste servidores individualmente
- Verifique compatibilidade de versões

---

**💡 Dica**: A maioria dos problemas pode ser resolvida executando `npm run status` para identificar a causa raiz e depois aplicando as soluções específicas.
