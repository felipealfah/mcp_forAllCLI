# context7-server

Servidor MCP oficial para integração com Context7

## 📋 Configuração

- **Categoria**: ai
- **Tipo**: npx
- **Versão**: 1.0.0
- **Status**: Ativo

## 🚀 Instalação

```bash
# Instalar dependências
npm install

# Configurar variáveis de ambiente
cp env.example .env
# Edite o arquivo .env com sua CONTEXT7_API_KEY

# Iniciar servidor
npm start
```

## ⚙️ Configuração

O servidor usa o pacote oficial `@upstash/context7-mcp` e pode ser configurado através do arquivo `config.json`:

- `enabled`: Habilita/desabilita o servidor
- `auto_start`: Inicia automaticamente
- `restart_on_failure`: Reinicia em caso de falha
- `log_level`: Nível de log (error, warn, info, debug)

## 🔧 Variáveis de Ambiente

- `CONTEXT7_API_KEY`: Sua chave da API Context7 (obrigatória)

## 🛠️ Ferramentas Disponíveis

### 1. `resolve-library-id`
Resolve o nome de uma biblioteca para um ID compatível com Context7.

**Parâmetros:**
- `libraryName`: Nome da biblioteca (ex: "react", "next.js")

**Retorna:** Lista de bibliotecas correspondentes com IDs.

### 2. `get-library-docs`
Obtém documentação atualizada de uma biblioteca específica.

**Parâmetros:**
- `context7CompatibleLibraryID`: ID da biblioteca (ex: "/vercel/next.js")
- `topic`: Tópico específico (opcional)
- `tokens`: Número máximo de tokens (padrão: 10000)

**Retorna:** Documentação completa da biblioteca.

## 📚 Documentação

Consulte a documentação completa em `docs/`.

## 🧪 Testes

```bash
npm test
```

## 📝 Logs

Os logs são salvos em `logs/` com o nível configurado em `config.json`.

## 🔗 Integração

Este servidor se integra automaticamente com:
- **Cursor**: Via MCP Hub
- **VS Code**: Via MCP Hub
- **Neovim**: Via MCP Hub
- **Outras CLIs**: Via MCP Hub

## 📖 Exemplos de Uso

### Resolver biblioteca
```
resolve-library-id com libraryName "react"
```

### Obter documentação
```
get-library-docs com context7CompatibleLibraryID "/vercel/next.js" e topic "routing"
```

---

**Criado em**: 2025-09-01
**Categoria**: ai
**Fonte**: [Context7 MCP Official](https://github.com/upstash/context7)
