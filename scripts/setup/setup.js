#!/usr/bin/env node

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs-extra';
import chalk from 'chalk';
import ora from 'ora';
import inquirer from 'inquirer';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '../../');

class MCPSetup {
  constructor() {
    this.config = null;
    this.env = {};
    this.spinner = null;
  }

  async init() {
    console.log(chalk.blue.bold('\n🚀 MCP Servers Hub - Setup\n'));
    
    try {
      await this.loadConfig();
      await this.checkPrerequisites();
      await this.setupEnvironment();
      await this.createDirectories();
      await this.setupCLIs();
      await this.installDependencies();
      await this.finalizeSetup();
      
      console.log(chalk.green.bold('\n✅ Setup concluído com sucesso!\n'));
      this.showNextSteps();
      
    } catch (error) {
      console.error(chalk.red.bold('\n❌ Erro durante o setup:'), error.message);
      process.exit(1);
    }
  }

  async loadConfig() {
    this.spinner = ora('Carregando configurações...').start();
    
    try {
      const configPath = join(rootDir, 'configs/config.json');
      this.config = await fs.readJson(configPath);
      
      // Carregar variáveis de ambiente
      const envPath = join(rootDir, 'configs/env/.env');
      if (await fs.pathExists(envPath)) {
        this.env = dotenv.parse(await fs.readFile(envPath, 'utf8'));
      }
      
      this.spinner.succeed('Configurações carregadas');
    } catch (error) {
      this.spinner.fail('Erro ao carregar configurações');
      throw error;
    }
  }

  async checkPrerequisites() {
    this.spinner = ora('Verificando pré-requisitos...').start();
    
    try {
      // Verificar Node.js
      const nodeVersion = process.version;
      const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
      
      if (majorVersion < 18) {
        throw new Error(`Node.js 18+ é necessário. Versão atual: ${nodeVersion}`);
      }
      
      // Verificar permissões para criar symlinks
      const testDir = join(rootDir, 'test-symlink');
      try {
        await fs.ensureDir(testDir);
        await fs.symlink(testDir, join(rootDir, 'test-symlink-link'));
        await fs.remove(join(rootDir, 'test-symlink-link'));
        await fs.remove(testDir);
      } catch (error) {
        throw new Error('Sem permissão para criar symlinks. Execute com privilégios adequados.');
      }
      
      this.spinner.succeed('Pré-requisitos verificados');
    } catch (error) {
      this.spinner.fail('Erro nos pré-requisitos');
      throw error;
    }
  }

  async setupEnvironment() {
    this.spinner = ora('Configurando ambiente...').start();
    
    try {
      // Criar arquivo .env se não existir
      const envPath = join(rootDir, 'configs/env/.env');
      const envExamplePath = join(rootDir, 'configs/env/env.example');
      
      if (!(await fs.pathExists(envPath)) && await fs.pathExists(envExamplePath)) {
        await fs.copy(envExamplePath, envPath);
        
        // Substituir valores padrão
        let envContent = await fs.readFile(envPath, 'utf8');
        envContent = envContent.replace(
          'MCP_HUB_ROOT=/Users/felipefull/Documents/MCP_servers',
          `MCP_HUB_ROOT=${rootDir}`
        );
        
        await fs.writeFile(envPath, envContent);
      }
      
      this.spinner.succeed('Ambiente configurado');
    } catch (error) {
      this.spinner.fail('Erro ao configurar ambiente');
      throw error;
    }
  }

  async createDirectories() {
    this.spinner = ora('Criando estrutura de diretórios...').start();
    
    try {
      const dirs = [
        'servers/ai',
        'servers/development',
        'servers/database',
        'servers/cloud',
        'servers/custom',
        'configs/templates',
        'configs/profiles',
        'scripts/setup',
        'scripts/sync',
        'scripts/utils',
        'docs',
        'tests',
        'cli-profiles',
        'logs'
      ];
      
      for (const dir of dirs) {
        await fs.ensureDir(join(rootDir, dir));
      }
      
      this.spinner.succeed('Estrutura de diretórios criada');
    } catch (error) {
      this.spinner.fail('Erro ao criar diretórios');
      throw error;
    }
  }

  async setupCLIs() {
    this.spinner = ora('Configurando CLIs...').start();
    
    try {
      const cliProfilesDir = join(rootDir, 'cli-profiles');
      
      // Criar perfis para cada CLI suportada
      for (const cli of this.config.clis.supported) {
        const cliProfilePath = join(cliProfilesDir, `${cli}.json`);
        
        if (!(await fs.pathExists(cliProfilePath))) {
          const cliProfile = {
            name: cli,
            enabled: false,
            config_path: this.config.clis.config_paths[cli],
            servers: [],
            last_sync: null,
            status: 'disconnected'
          };
          
          await fs.writeJson(cliProfilePath, cliProfile, { spaces: 2 });
        }
      }
      
      this.spinner.succeed('CLIs configuradas');
    } catch (error) {
      this.spinner.fail('Erro ao configurar CLIs');
      throw error;
    }
  }

  async installDependencies() {
    this.spinner = ora('Instalando dependências...').start();
    
    try {
      const packageJsonPath = join(rootDir, 'package.json');
      
      if (await fs.pathExists(packageJsonPath)) {
        const { execSync } = await import('child_process');
        execSync('npm install', { cwd: rootDir, stdio: 'pipe' });
      }
      
      this.spinner.succeed('Dependências instaladas');
    } catch (error) {
      this.spinner.fail('Erro ao instalar dependências');
      console.warn(chalk.yellow('⚠️  Dependências não puderam ser instaladas automaticamente. Execute "npm install" manualmente.'));
    }
  }

  async finalizeSetup() {
    this.spinner = ora('Finalizando setup...').start();
    
    try {
      // Criar arquivo de status
      const statusFile = join(rootDir, '.setup-complete');
      await fs.writeFile(statusFile, new Date().toISOString());
      
      // Criar arquivo de log inicial
      const logFile = join(rootDir, 'logs/setup.log');
      await fs.ensureFile(logFile);
      await fs.appendFile(logFile, `Setup concluído em: ${new Date().toISOString()}\n`);
      
      this.spinner.succeed('Setup finalizado');
    } catch (error) {
      this.spinner.fail('Erro ao finalizar setup');
      throw error;
    }
  }

  showNextSteps() {
    console.log(chalk.cyan.bold('\n📋 Próximos Passos:\n'));
    console.log(chalk.white('1. Configure suas variáveis de ambiente:'));
    console.log(chalk.gray('   nano configs/env/.env\n'));
    
    console.log(chalk.white('2. Conecte suas CLIs:'));
    console.log(chalk.gray('   npm run connect-cli\n'));
    
    console.log(chalk.white('3. Adicione seus servidores MCP:'));
    console.log(chalk.gray('   npm run add-server\n'));
    
    console.log(chalk.white('4. Sincronize com suas CLIs:'));
    console.log(chalk.gray('   npm run sync\n'));
    
    console.log(chalk.white('\n📚 Documentação:'));
    console.log(chalk.gray('   docs/CONFIGURATION.md\n'));
    
    console.log(chalk.white('🔧 Comandos úteis:'));
    console.log(chalk.gray('   npm run status      # Ver status do sistema'));
    console.log(chalk.gray('   npm run list-servers # Listar servidores'));
    console.log(chalk.gray('   npm run list-clis   # Listar CLIs conectadas\n'));
  }
}

// Executar setup se chamado diretamente
if (import.meta.url === `file://${process.argv[1]}`) {
  const setup = new MCPSetup();
  setup.init().catch(console.error);
}

export default MCPSetup;
