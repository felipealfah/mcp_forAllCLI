#!/usr/bin/env node

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs-extra';
import chalk from 'chalk';
import ora from 'ora';
import inquirer from 'inquirer';
import { execSync } from 'child_process';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '../../');

class CLIConnector {
  constructor() {
    this.config = null;
    this.env = {};
    this.spinner = null;
    this.selectedCLIs = [];
  }

  async init() {
    console.log(chalk.blue.bold('\n🔗 MCP Servers Hub - Conectar CLIs\n'));
    
    try {
      await this.loadConfig();
      await this.selectCLIs();
      await this.createSymlinks();
      await this.updateCLIProfiles();
      await this.validateConnections();
      
      console.log(chalk.green.bold('\n✅ CLIs conectadas com sucesso!\n'));
      this.showConnectionStatus();
      
    } catch (error) {
      console.error(chalk.red.bold('\n❌ Erro ao conectar CLIs:'), error.message);
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

  async selectCLIs() {
    const availableCLIs = this.config.clis.supported.filter(cli => {
      const envKey = `${cli.toUpperCase()}_ENABLED`;
      return this.env[envKey] === 'true';
    });

    if (availableCLIs.length === 0) {
      console.log(chalk.yellow('\n⚠️  Nenhuma CLI habilitada nas variáveis de ambiente.'));
      console.log(chalk.white('Habilite as CLIs desejadas em configs/env/.env\n'));
      
      const { enableCLIs } = await inquirer.prompt([
        {
          type: 'confirm',
          name: 'enableCLIs',
          message: 'Deseja configurar as CLIs agora?',
          default: true
        }
      ]);
      
      if (enableCLIs) {
        await this.enableCLIs();
        return;
      } else {
        throw new Error('Nenhuma CLI habilitada para conectar');
      }
    }

    const { selectedCLIs } = await inquirer.prompt([
      {
        type: 'checkbox',
        name: 'selectedCLIs',
        message: 'Selecione as CLIs que deseja conectar:',
        choices: availableCLIs.map(cli => ({
          name: `${cli} (${this.config.clis.config_paths[cli]})`,
          value: cli,
          checked: true
        }))
      }
    ]);

    this.selectedCLIs = selectedCLIs;
    
    if (this.selectedCLIs.length === 0) {
      throw new Error('Nenhuma CLI selecionada');
    }
  }

  async enableCLIs() {
    console.log(chalk.cyan('\n🔧 Configurando CLIs...\n'));
    
    const cliChoices = this.config.clis.supported.map(cli => ({
      name: cli,
      value: cli
    }));

    const { clisToEnable } = await inquirer.prompt([
      {
        type: 'checkbox',
        name: 'clisToEnable',
        message: 'Selecione as CLIs que você usa:',
        choices: cliChoices
      }
    ]);

    if (clisToEnable.length === 0) {
      throw new Error('Nenhuma CLI selecionada');
    }

    // Atualizar arquivo .env
    const envPath = join(rootDir, 'configs/env/.env');
    let envContent = await fs.readFile(envPath, 'utf8');
    
    for (const cli of this.config.clis.supported) {
      const envKey = `${cli.toUpperCase()}_ENABLED`;
      const isEnabled = clisToEnable.includes(cli);
      const newValue = `${envKey}=${isEnabled}\n`;
      
      if (envContent.includes(envKey)) {
        envContent = envContent.replace(new RegExp(`${envKey}=.*\n`), newValue);
      } else {
        envContent += newValue;
      }
    }
    
    await fs.writeFile(envPath, envContent);
    
    this.selectedCLIs = clisToEnable;
    console.log(chalk.green('✅ CLIs habilitadas no arquivo .env\n'));
  }

  async createSymlinks() {
    this.spinner = ora('Criando symlinks para as CLIs...').start();
    
    try {
      for (const cli of this.selectedCLIs) {
        await this.createSymlinkForCLI(cli);
      }
      
      this.spinner.succeed('Symlinks criados');
    } catch (error) {
      this.spinner.fail('Erro ao criar symlinks');
      throw error;
    }
  }

  async createSymlinkForCLI(cli) {
    const cliConfigPath = this.config.clis.config_paths[cli];
    const expandedPath = this.expandPath(cliConfigPath);
    
    // Criar diretório pai se não existir
    await fs.ensureDir(expandedPath);
    
    // Remover symlink existente se houver
    const symlinkPath = join(expandedPath, 'mcp_servers');
    if (await fs.pathExists(symlinkPath)) {
      await fs.remove(symlinkPath);
    }
    
    // Criar symlink para o diretório servers
    const targetPath = join(rootDir, 'servers');
    await fs.symlink(targetPath, symlinkPath);
    
    console.log(chalk.gray(`   ${cli}: ${symlinkPath} → ${targetPath}`));
  }

  expandPath(path) {
    if (path.startsWith('~')) {
      return path.replace('~', process.env.HOME);
    }
    return path;
  }

  async updateCLIProfiles() {
    this.spinner = ora('Atualizando perfis das CLIs...').start();
    
    try {
      const cliProfilesDir = join(rootDir, 'cli-profiles');
      
      for (const cli of this.selectedCLIs) {
        const cliProfilePath = join(cliProfilesDir, `${cli}.json`);
        
        if (await fs.pathExists(cliProfilePath)) {
          const profile = await fs.readJson(cliProfilePath);
          profile.enabled = true;
          profile.status = 'connected';
          profile.last_sync = new Date().toISOString();
          
          await fs.writeJson(cliProfilePath, profile, { spaces: 2 });
        }
      }
      
      this.spinner.succeed('Perfis atualizados');
    } catch (error) {
      this.spinner.fail('Erro ao atualizar perfis');
      throw error;
    }
  }

  async validateConnections() {
    this.spinner = ora('Validando conexões...').start();
    
    try {
      for (const cli of this.selectedCLIs) {
        const cliConfigPath = this.config.clis.config_paths[cli];
        const expandedPath = this.expandPath(cliConfigPath);
        const symlinkPath = join(expandedPath, 'mcp_servers');
        
        if (!(await fs.pathExists(symlinkPath))) {
          throw new Error(`Symlink não encontrado para ${cli}: ${symlinkPath}`);
        }
        
        // Verificar se o symlink aponta para o diretório correto
        const realPath = await fs.realpath(symlinkPath);
        const expectedPath = join(rootDir, 'servers');
        
        if (realPath !== expectedPath) {
          throw new Error(`Symlink incorreto para ${cli}: ${realPath} ≠ ${expectedPath}`);
        }
      }
      
      this.spinner.succeed('Conexões validadas');
    } catch (error) {
      this.spinner.fail('Erro na validação');
      throw error;
    }
  }

  showConnectionStatus() {
    console.log(chalk.cyan.bold('\n📊 Status das Conexões:\n'));
    
    for (const cli of this.selectedCLIs) {
      const cliConfigPath = this.config.clis.config_paths[cli];
      const expandedPath = this.expandPath(cliConfigPath);
      const symlinkPath = join(expandedPath, 'mcp_servers');
      
      console.log(chalk.green(`✅ ${cli}`));
      console.log(chalk.gray(`   Config: ${cliConfigPath}`));
      console.log(chalk.gray(`   Symlink: ${symlinkPath}`));
      console.log(chalk.gray(`   Status: Conectado\n`));
    }
    
    console.log(chalk.cyan.bold('🔧 Próximos Passos:\n'));
    console.log(chalk.white('1. Adicione seus servidores MCP:'));
    console.log(chalk.gray('   npm run add-server\n'));
    
    console.log(chalk.white('2. Sincronize as configurações:'));
    console.log(chalk.gray('   npm run sync\n'));
    
    console.log(chalk.white('3. Verifique o status:'));
    console.log(chalk.gray('   npm run status\n'));
    
    console.log(chalk.white('4. Teste em suas CLIs:\n'));
    console.log(chalk.gray('   - Cursor: Reinicie o Cursor'));
    console.log(chalk.gray('   - VS Code: Recarregue a janela'));
    console.log(chalk.gray('   - Neovim: Recarregue o Neovim\n'));
  }
}

// Executar se chamado diretamente
if (import.meta.url === `file://${process.argv[1]}`) {
  const connector = new CLIConnector();
  connector.init().catch(console.error);
}

export default CLIConnector;
