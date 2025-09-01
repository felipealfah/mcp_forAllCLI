# 🎯 Configuração do Cursor com MCP Hub

Este guia específico mostra como configurar o Cursor para usar o MCP Servers Hub.

## 🚀 Setup Rápido

### 1. Habilitar Cursor no MCP Hub
```bash
# Editar arquivo .env
nano configs/env/.env

# Configurar:
CURSOR_ENABLED=true
CURSOR_PATH=~/.cursor/mcp_servers
```

### 2. Conectar Cursor
```bash
npm run connect-cli
```

### 3. Sincronizar Servidores
```bash
npm run sync
```

## ⚙️ Configuração Manual do Cursor

### 1. Localizar Diretório de Configuração
O Cursor armazena suas configurações em:
- **macOS**: `~/.cursor/`
- **Linux**: `~/.cursor/`
- **Windows**: `%APPDATA%\Cursor\`

### 2. Criar Diretório MCP
```bash
mkdir -p ~/.cursor/mcp_servers
```

### 3. Verificar Symlink
Após executar `npm run connect-cli`, verifique se o symlink foi criado:
```bash
ls -la ~/.cursor/mcp_servers
```

Deve mostrar algo como:
```
lrwxr-xr-x  1 user  staff  45 Dec 19 10:00 mcp_servers -> /path/to/MCP_servers/servers
```

## 🔧 Configuração do Cursor

### 1. Abrir Configurações
- **Cmd/Ctrl + ,** ou
- **Cursor → Preferences → Settings**

### 2. Configurar MCP
No arquivo de configurações do Cursor, adicione:

```json
{
  "mcpServers": {
    "ai": {
      "command": "node",
      "args": ["/path/to/MCP_servers/servers/ai/example-server/server.js"],
      "env": {
        "API_KEY": "your_api_key_here",
        "API_URL": "https://api.example.com/v1"
      }
    }
  }
}
```

### 3. Configuração Automática
O MCP Hub pode gerar automaticamente a configuração do Cursor:

```bash
# Gerar configuração para Cursor
npm run generate-cursor-config
```

## 🧪 Testando a Configuração

### 1. Reiniciar Cursor
Após configurar, reinicie o Cursor completamente.

### 2. Verificar Servidores
- Abra o Command Palette (`Cmd/Ctrl + Shift + P`)
- Digite "MCP" para ver comandos disponíveis
- Verifique se os servidores aparecem

### 3. Testar Ferramentas
- Use o comando "MCP: List Tools" para ver ferramentas disponíveis
- Teste uma ferramenta específica

## 📊 Monitoramento

### 1. Verificar Status
```bash
npm run status
```

### 2. Verificar Logs do Cursor
```bash
# Logs do Cursor
tail -f ~/.cursor/logs/main.log

# Logs do MCP Hub
tail -f logs/mcp-hub.log
```

### 3. Verificar Sincronização
```bash
cat logs/latest-sync-report.json
```

## 🔍 Troubleshooting Específico do Cursor

### 1. Servidores Não Aparecem
```bash
# Verificar symlink
ls -la ~/.cursor/mcp_servers

# Verificar permissões
ls -la ~/.cursor/

# Recriar symlink
npm run connect-cli
```

### 2. Erro de Permissão
```bash
# Verificar permissões
chmod 755 ~/.cursor/
chmod 755 ~/.cursor/mcp_servers

# Verificar proprietário
ls -la ~/.cursor/
```

### 3. Configuração Inválida
```bash
# Validar configuração
npm run validate

# Verificar sintaxe JSON
cat ~/.cursor/User/settings.json | jq .
```

### 4. Servidor Não Inicia
```bash
# Testar servidor diretamente
cd servers/ai/example-server
node server.js

# Verificar dependências
npm install

# Verificar variáveis de ambiente
cat .env
```

## 🎯 Configurações Avançadas

### 1. Múltiplos Servidores
```json
{
  "mcpServers": {
    "ai": {
      "command": "node",
      "args": ["/path/to/MCP_servers/servers/ai/example-server/server.js"]
    },
    "development": {
      "command": "node",
      "args": ["/path/to/MCP_servers/servers/development/git-server/server.js"]
    },
    "database": {
      "command": "python3",
      "args": ["/path/to/MCP_servers/servers/database/postgres-server/server.py"]
    }
  }
}
```

### 2. Variáveis de Ambiente
```json
{
  "mcpServers": {
    "ai": {
      "command": "node",
      "args": ["/path/to/MCP_servers/servers/ai/example-server/server.js"],
      "env": {
        "NODE_ENV": "production",
        "API_KEY": "your_production_key",
        "LOG_LEVEL": "info"
      }
    }
  }
}
```

### 3. Configuração por Workspace
Crie `.vscode/settings.json` no seu projeto:

```json
{
  "mcpServers": {
    "project-specific": {
      "command": "node",
      "args": ["/path/to/project-specific-server/server.js"]
    }
  }
}
```

## 🔄 Sincronização Automática

### 1. Habilitar Auto-sync
```bash
# Editar .env
AUTO_SYNC=true
SYNC_INTERVAL=300000  # 5 minutos
```

### 2. Monitorar Sincronização
```bash
# Ver logs em tempo real
tail -f logs/mcp-hub.log

# Ver relatórios
ls -la logs/sync-report-*.json
```

### 3. Forçar Sincronização
```bash
npm run sync
```

## 📚 Recursos Adicionais

### 1. Documentação
- [Guia de Configuração](../CONFIGURATION.md)
- [Troubleshooting](../TROUBLESHOOTING.md)
- [README](../README.md)

### 2. Comandos Úteis
```bash
npm run status          # Ver status do sistema
npm run list-servers    # Listar servidores
npm run list-clis       # Listar CLIs conectadas
npm run backup          # Backup das configurações
```

### 3. Suporte
- GitHub Issues para problemas
- Logs detalhados para debug
- Comando `npm run status` para diagnóstico

## 🎉 Próximos Passos

1. **Configure suas variáveis de ambiente**
2. **Conecte o Cursor** (`npm run connect-cli`)
3. **Adicione seus servidores** (`npm run add-server`)
4. **Sincronize** (`npm run sync`)
5. **Teste no Cursor**
6. **Configure sincronização automática**

---

**💡 Dica**: Execute `npm run status` regularmente para verificar a saúde do sistema e identificar problemas antes que afetem o Cursor.
