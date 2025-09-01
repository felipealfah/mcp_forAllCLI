#!/usr/bin/env node

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs-extra';
import chalk from 'chalk';
import ora from 'ora';
import inquirer from 'inquirer';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '../../');

class ServerAdder {
  constructor() {
    this.config = null;
    this.spinner = null;
    this.serverInfo = {};
  }

  async init() {
    console.log(chalk.blue.bold('\n➕ MCP Servers Hub - Adicionar Servidor\n'));
    
    try {
      await this.loadConfig();
      await this.collectServerInfo();
      await this.createServerStructure();
      await this.createServerFiles();
      await this.updateCLIProfiles();
      
      console.log(chalk.green.bold('\n✅ Servidor adicionado com sucesso!\n'));
      this.showNextSteps();
      
    } catch (error) {
      console.error(chalk.red.bold('\n❌ Erro ao adicionar servidor:'), error.message);
      process.exit(1);
    }
  }

  async loadConfig() {
    this.spinner = ora('Carregando configurações...').start();
    
    try {
      const configPath = join(rootDir, 'configs/config.json');
      this.config = await fs.readJson(configPath);
      this.spinner.succeed('Configurações carregadas');
    } catch (error) {
      this.spinner.fail('Erro ao carregar configurações');
      throw error;
    }
  }

  async collectServerInfo() {
    console.log(chalk.cyan('\n📝 Informações do Servidor\n'));
    
    // Nome do servidor
    const { serverName } = await inquirer.prompt([
      {
        type: 'input',
        name: 'serverName',
        message: 'Nome do servidor (kebab-case):',
        validate: (input) => {
          if (!input.trim()) return 'Nome é obrigatório';
          if (!/^[a-z0-9-]+$/.test(input)) {
            return 'Use apenas letras minúsculas, números e hífens';
          }
          return true;
        }
      }
    ]);

    // Categoria
    const { category } = await inquirer.prompt([
      {
        type: 'list',
        name: 'category',
        message: 'Categoria do servidor:',
        choices: this.config.servers.categories.map(cat => ({
          name: `${cat} - ${this.getCategoryDescription(cat)}`,
          value: cat
        }))
      }
    ]);

    // Descrição
    const { description } = await inquirer.prompt([
      {
        type: 'input',
        name: 'description',
        message: 'Descrição do servidor:',
        default: `Servidor MCP para ${serverName}`
      }
    ]);

    // Tipo de servidor
    const { serverType } = await inquirer.prompt([
      {
        type: 'list',
        name: 'serverType',
        message: 'Tipo de servidor:',
        choices: [
          { name: 'Node.js', value: 'node' },
          { name: 'Python', value: 'python' },
          { name: 'Go', value: 'go' },
          { name: 'Rust', value: 'rust' },
          { name: 'Outro', value: 'other' }
        ]
      }
    ]);

    // Configurações adicionais
    const { autoStart, restartOnFailure, logLevel } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'autoStart',
        message: 'Iniciar automaticamente?',
        default: false
      },
      {
        type: 'confirm',
        name: 'restartOnFailure',
        message: 'Reiniciar em caso de falha?',
        default: true
      },
      {
        type: 'list',
        name: 'logLevel',
        message: 'Nível de log:',
        choices: [
          { name: 'Error', value: 'error' },
          { name: 'Warn', value: 'warn' },
          { name: 'Info', value: 'info' },
          { name: 'Debug', value: 'debug' }
        ],
        default: 'info'
      }
    ]);

    // Variáveis de ambiente
    const { hasEnvVars } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'hasEnvVars',
        message: 'O servidor precisa de variáveis de ambiente?',
        default: false
      }
    ]);

    let envVars = [];
    if (hasEnvVars) {
      const { envVarsInput } = await inquirer.prompt([
        {
          type: 'input',
          name: 'envVarsInput',
          message: 'Variáveis de ambiente (separadas por vírgula):',
          default: 'API_KEY,API_URL',
          filter: (input) => input.split(',').map(v => v.trim()).filter(v => v)
        }
      ]);
      envVars = envVarsInput;
    }

    this.serverInfo = {
      name: serverName,
      category,
      description,
      serverType,
      config: {
        enabled: true,
        auto_start: autoStart,
        restart_on_failure: restartOnFailure,
        log_level: logLevel
      },
      envVars
    };
  }

  getCategoryDescription(category) {
    const descriptions = {
      ai: 'Inteligência Artificial (Claude, GPT, Ollama)',
      development: 'Desenvolvimento (Git, Docker, Kubernetes)',
      database: 'Banco de Dados (PostgreSQL, MongoDB, Redis)',
      cloud: 'Cloud (AWS, GCP, Azure)',
      custom: 'Personalizado'
    };
    return descriptions[category] || 'Sem descrição';
  }

  async createServerStructure() {
    this.spinner = ora('Criando estrutura do servidor...').start();
    
    try {
      const serverPath = join(rootDir, 'servers', this.serverInfo.category, this.serverInfo.name);
      
      // Criar diretório do servidor
      await fs.ensureDir(serverPath);
      
      // Criar subdiretórios
      const subdirs = ['src', 'docs', 'tests'];
      for (const subdir of subdirs) {
        await fs.ensureDir(join(serverPath, subdir));
      }
      
      this.spinner.succeed('Estrutura criada');
    } catch (error) {
      this.spinner.fail('Erro ao criar estrutura');
      throw error;
    }
  }

  async createServerFiles() {
    this.spinner = ora('Criando arquivos do servidor...').start();
    
    try {
      const serverPath = join(rootDir, 'servers', this.serverInfo.category, this.serverInfo.name);
      
      // config.json
      const configContent = {
        name: this.serverInfo.name,
        description: this.serverInfo.description,
        version: "1.0.0",
        category: this.serverInfo.category,
        type: this.serverInfo.serverType,
        ...this.serverInfo.config,
        env_vars: this.serverInfo.envVars,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      
      await fs.writeJson(join(serverPath, 'config.json'), configContent, { spaces: 2 });
      
      // README.md
      const readmeContent = this.generateREADME();
      await fs.writeFile(join(serverPath, 'README.md'), readmeContent);
      
      // .env.example
      if (this.serverInfo.envVars.length > 0) {
        const envExampleContent = this.generateEnvExample();
        await fs.writeFile(join(serverPath, '.env.example'), envExampleContent);
      }
      
      // Arquivo principal do servidor
      const serverFileContent = this.generateServerFile();
      await fs.writeFile(join(serverPath, 'server.js'), serverFileContent);
      
      // package.json (se for Node.js)
      if (this.serverInfo.serverType === 'node') {
        const packageJsonContent = this.generatePackageJson();
        await fs.writeJson(join(serverPath, 'package.json'), packageJsonContent, { spaces: 2 });
      }
      
      this.spinner.succeed('Arquivos criados');
    } catch (error) {
      this.spinner.fail('Erro ao criar arquivos');
      throw error;
    }
  }

  generateREADME() {
    return `# ${this.serverInfo.name}

${this.serverInfo.description}

## 📋 Configuração

- **Categoria**: ${this.serverInfo.category}
- **Tipo**: ${this.serverInfo.serverType}
- **Versão**: 1.0.0
- **Status**: ${this.serverInfo.config.enabled ? 'Ativo' : 'Inativo'}

## 🚀 Instalação

\`\`\`bash
# Instalar dependências
npm install

# Configurar variáveis de ambiente
cp .env.example .env
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

## 🔧 Variáveis de Ambiente

${this.serverInfo.envVars.length > 0 ? 
  this.serverInfo.envVars.map(varName => `- \`${varName}\`: Descrição da variável`).join('\n') :
  'Nenhuma variável de ambiente necessária.'
}

## 📚 Documentação

Consulte a documentação completa em \`docs/\`.

## 🧪 Testes

\`\`\`bash
npm test
\`\`\`

## 📝 Logs

Os logs são salvos em \`logs/\` com o nível configurado em \`config.json\`.

---

**Criado em**: ${new Date().toLocaleDateString('pt-BR')}
**Categoria**: ${this.serverInfo.category}
`;
  }

  generateEnvExample() {
    let content = `# ========================================\n`;
    content += `# ${this.serverInfo.name.toUpperCase()} - Variáveis de Ambiente\n`;
    content += `# ========================================\n\n`;
    
    for (const envVar of this.serverInfo.envVars) {
      content += `${envVar}=your_${envVar.toLowerCase()}_here\n`;
    }
    
    return content;
  }

  generateServerFile() {
    if (this.serverInfo.serverType === 'node') {
      return `#!/usr/bin/env node

import { createServer } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { Server } from '@modelcontextprotocol/sdk/server/index.js';

// Configuração do servidor
const config = {
  name: '${this.serverInfo.name}',
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
      // Adicione as capacidades do seu servidor aqui
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

console.log(\`🚀 ${this.serverInfo.name} iniciado\`);
`;
    } else {
      return `# ${this.serverInfo.name} - Servidor MCP
# Implemente seu servidor MCP aqui

# Para mais informações sobre MCP:
# https://modelcontextprotocol.io/

print(f"🚀 {this.serverInfo.name} iniciado")
`;
    }
  }

  generatePackageJson() {
    return {
      name: this.serverInfo.name,
      version: "1.0.0",
      description: this.serverInfo.description,
      main: "server.js",
      type: "module",
      scripts: {
        start: "node server.js",
        dev: "nodemon server.js",
        test: "jest",
        lint: "eslint ."
      },
      dependencies: {
        "@modelcontextprotocol/sdk": "^0.4.0"
      },
      devDependencies: {
        "nodemon": "^3.0.0",
        "jest": "^29.0.0"
      },
      keywords: ["mcp", "server", this.serverInfo.category],
      author: "MCP Hub",
      license: "MIT"
    };
  }

  async updateCLIProfiles() {
    this.spinner = ora('Atualizando perfis das CLIs...').start();
    
    try {
      const cliProfilesDir = join(rootDir, 'cli-profiles');
      
      // Atualizar todos os perfis de CLI para incluir o novo servidor
      const cliProfiles = await fs.readdir(cliProfilesDir);
      
      for (const cliProfile of cliProfiles) {
        if (cliProfile.endsWith('.json')) {
          const profilePath = join(cliProfilesDir, cliProfile);
          const profile = await fs.readJson(profilePath);
          
          // Adicionar servidor se não existir
          const serverExists = profile.servers.some(s => 
            s.name === this.serverInfo.name && s.category === this.serverInfo.category
          );
          
          if (!serverExists) {
            profile.servers.push({
              name: this.serverInfo.name,
              category: this.serverInfo.category,
              added_at: new Date().toISOString(),
              status: 'pending_sync'
            });
            
            await fs.writeJson(profilePath, profile, { spaces: 2 });
          }
        }
      }
      
      this.spinner.succeed('Perfis atualizados');
    } catch (error) {
      this.spinner.fail('Erro ao atualizar perfis');
      throw error;
    }
  }

  showNextSteps() {
    console.log(chalk.cyan.bold('\n📋 Próximos Passos:\n'));
    
    console.log(chalk.white('1. Configure as variáveis de ambiente:'));
    console.log(chalk.gray(`   nano servers/${this.serverInfo.category}/${this.serverInfo.name}/.env.example\n`));
    
    console.log(chalk.white('2. Personalize o servidor:'));
    console.log(chalk.gray(`   nano servers/${this.serverInfo.category}/${this.serverInfo.name}/server.js\n`));
    
    console.log(chalk.white('3. Instale as dependências (se Node.js):'));
    console.log(chalk.gray(`   cd servers/${this.serverInfo.category}/${this.serverInfo.name}`));
    console.log(chalk.gray('   npm install\n'));
    
    console.log(chalk.white('4. Sincronize com suas CLIs:'));
    console.log(chalk.gray('   npm run sync\n'));
    
    console.log(chalk.white('5. Teste o servidor:'));
    console.log(chalk.gray(`   cd servers/${this.serverInfo.category}/${this.serverInfo.name}`));
    console.log(chalk.gray('   npm start\n'));
    
    console.log(chalk.cyan.bold('📁 Arquivos Criados:\n'));
    console.log(chalk.gray(`   servers/${this.serverInfo.category}/${this.serverInfo.name}/`));
    console.log(chalk.gray('   ├── config.json'));
    console.log(chalk.gray('   ├── README.md'));
    console.log(chalk.gray('   ├── server.js'));
    if (this.serverInfo.serverType === 'node') {
      console.log(chalk.gray('   ├── package.json'));
    }
    if (this.serverInfo.envVars.length > 0) {
      console.log(chalk.gray('   └── .env.example'));
    }
    console.log('');
  }
}

// Executar se chamado diretamente
if (import.meta.url === `file://${process.argv[1]}`) {
  const adder = new ServerAdder();
  adder.init().catch(console.error);
}

export default ServerAdder;
