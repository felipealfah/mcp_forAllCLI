#!/usr/bin/env node

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs-extra';
import chalk from 'chalk';
import ora from 'ora';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '../../');

class StatusChecker {
  constructor() {
    this.config = null;
    this.env = {};
    this.spinner = null;
    this.status = {};
  }

  async init() {
    console.log(chalk.blue.bold('\n📊 MCP Servers Hub - Status do Sistema\n'));
    
    try {
      await this.loadConfig();
      await this.checkSystemStatus();
      await this.checkCLIStatus();
      await this.checkServerStatus();
      await this.checkSyncStatus();
      await this.displayStatus();
      
    } catch (error) {
      console.error(chalk.red.bold('\n❌ Erro ao verificar status:'), error.message);
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

  async checkSystemStatus() {
    this.spinner = ora('Verificando status do sistema...').start();
    
    try {
      this.status.system = {
        hub_root: rootDir,
        config_loaded: !!this.config,
        env_loaded: Object.keys(this.env).length > 0,
        setup_complete: await fs.pathExists(join(rootDir, '.setup-complete')),
        last_check: new Date().toISOString()
      };
      
      this.spinner.succeed('Status do sistema verificado');
    } catch (error) {
      this.spinner.fail('Erro ao verificar status do sistema');
      throw error;
    }
  }

  async checkCLIStatus() {
    this.spinner = ora('Verificando status das CLIs...').start();
    
    try {
      this.status.clis = [];
      const cliProfilesDir = join(rootDir, 'cli-profiles');
      
      for (const cli of this.config.clis.supported) {
        const envKey = `${cli.toUpperCase()}_ENABLED`;
        const isEnabled = this.env[envKey] === 'true';
        
        let cliStatus = {
          name: cli,
          enabled: isEnabled,
          connected: false,
          config_path: this.config.clis.config_paths[cli],
          symlink_exists: false,
          symlink_valid: false,
          last_sync: null,
          servers_count: 0
        };
        
        if (isEnabled) {
          const cliProfilePath = join(cliProfilesDir, `${cli}.json`);
          
          if (await fs.pathExists(cliProfilePath)) {
            const profile = await fs.readJson(cliProfilePath);
            cliStatus.connected = profile.enabled && profile.status === 'connected';
            cliStatus.last_sync = profile.last_sync;
            cliStatus.servers_count = profile.servers?.length || 0;
          }
          
          // Verificar symlink
          const expandedPath = this.expandPath(cli.configPath);
          const symlinkPath = join(expandedPath, 'mcp_servers');
          
          cliStatus.symlink_exists = await fs.pathExists(symlinkPath);
          
          if (cliStatus.symlink_exists) {
            try {
              const realPath = await fs.realpath(symlinkPath);
              const expectedPath = join(rootDir, 'servers');
              cliStatus.symlink_valid = realPath === expectedPath;
            } catch (error) {
              cliStatus.symlink_valid = false;
            }
          }
        }
        
        this.status.clis.push(cliStatus);
      }
      
      this.spinner.succeed('Status das CLIs verificado');
    } catch (error) {
      this.spinner.fail('Erro ao verificar status das CLIs');
      throw error;
    }
  }

  async checkServerStatus() {
    this.spinner = ora('Verificando status dos servidores...').start();
    
    try {
      this.status.servers = [];
      const serversDir = join(rootDir, 'servers');
      
      for (const category of this.config.servers.categories) {
        const categoryPath = join(serversDir, category);
        
        if (await fs.pathExists(categoryPath)) {
          const categoryServers = await fs.readdir(categoryPath);
          
          for (const server of categoryServers) {
            const serverPath = join(categoryPath, server);
            const stats = await fs.stat(serverPath);
            
            if (stats.isDirectory()) {
              let serverStatus = {
                name: server,
                category,
                path: serverPath,
                enabled: true,
                has_config: false,
                has_server_file: false,
                has_readme: false,
                has_env_example: false,
                dependencies_installed: false,
                last_modified: stats.mtime
              };
              
              // Verificar arquivos
              const configPath = join(serverPath, 'config.json');
              const serverFilePath = join(serverPath, 'server.js');
              const readmePath = join(serverPath, 'README.md');
              const envExamplePath = join(serverPath, '.env.example');
              const packageJsonPath = join(serverPath, 'package.json');
              
              serverStatus.has_config = await fs.pathExists(configPath);
              serverStatus.has_server_file = await fs.pathExists(serverFilePath);
              serverStatus.has_readme = await fs.pathExists(readmePath);
              serverStatus.has_env_example = await fs.pathExists(envExamplePath);
              
              if (serverStatus.has_config) {
                try {
                  const config = await fs.readJson(configPath);
                  serverStatus.enabled = config.enabled !== false;
                } catch (error) {
                  serverStatus.enabled = false;
                }
              }
              
              // Verificar dependências (se Node.js)
              if (await fs.pathExists(packageJsonPath)) {
                const nodeModulesPath = join(serverPath, 'node_modules');
                serverStatus.dependencies_installed = await fs.pathExists(nodeModulesPath);
              }
              
              this.status.servers.push(serverStatus);
            }
          }
        }
      }
      
      this.spinner.succeed('Status dos servidores verificado');
    } catch (error) {
      this.spinner.fail('Erro ao verificar status dos servidores');
      throw error;
    }
  }

  async checkSyncStatus() {
    this.spinner = ora('Verificando status de sincronização...').start();
    
    try {
      this.status.sync = {
        last_sync_report: null,
        sync_history: [],
        auto_sync_enabled: this.env.AUTO_SYNC === 'true',
        sync_interval: this.env.SYNC_INTERVAL || '300000'
      };
      
      // Verificar relatório mais recente
      const latestReportPath = join(rootDir, 'logs', 'latest-sync-report.json');
      if (await fs.pathExists(latestReportPath)) {
        try {
          const report = await fs.readJson(latestReportPath);
          this.status.sync.last_sync_report = report;
        } catch (error) {
          console.warn(chalk.yellow('⚠️  Erro ao ler relatório de sincronização'));
        }
      }
      
      // Verificar histórico de sincronização
      const logsDir = join(rootDir, 'logs');
      if (await fs.pathExists(logsDir)) {
        const logFiles = await fs.readdir(logsDir);
        const syncReports = logFiles.filter(f => f.startsWith('sync-report-') && f.endsWith('.json'));
        
        for (const reportFile of syncReports.slice(-5)) { // Últimos 5 relatórios
          try {
            const reportPath = join(logsDir, reportFile);
            const report = await fs.readJson(reportPath);
            this.status.sync.sync_history.push({
              file: reportFile,
              timestamp: report.timestamp,
              summary: report.summary
            });
          } catch (error) {
            // Ignorar arquivos corrompidos
          }
        }
      }
      
      this.spinner.succeed('Status de sincronização verificado');
    } catch (error) {
      this.spinner.fail('Erro ao verificar status de sincronização');
      throw error;
    }
  }

  expandPath(path) {
    if (path.startsWith('~')) {
      return path.replace('~', process.env.HOME);
    }
    return path;
  }

  async displayStatus() {
    console.log(chalk.cyan.bold('\n🏗️  Status do Sistema\n'));
    
    // Status geral
    const system = this.status.system;
    console.log(chalk.white(`Hub Root: ${chalk.blue(system.hub_root)}`));
    console.log(chalk.white(`Configuração: ${system.config_loaded ? chalk.green('✅') : chalk.red('❌')}`));
    console.log(chalk.white(`Variáveis de Ambiente: ${system.env_loaded ? chalk.green('✅') : chalk.red('❌')}`));
    console.log(chalk.white(`Setup Completo: ${system.setup_complete ? chalk.green('✅') : chalk.red('❌')}`));
    console.log(chalk.white(`Última Verificação: ${chalk.gray(new Date(system.last_check).toLocaleString('pt-BR'))}\n`));
    
    // Status das CLIs
    console.log(chalk.cyan.bold('🔗 Status das CLIs\n'));
    
    for (const cli of this.status.clis) {
      const statusIcon = cli.enabled ? (cli.connected ? chalk.green('✅') : chalk.yellow('⚠️')) : chalk.gray('⭕');
      const connectionStatus = cli.enabled ? (cli.connected ? 'Conectada' : 'Desconectada') : 'Desabilitada';
      
      console.log(`${statusIcon} ${chalk.white(cli.name)} - ${connectionStatus}`);
      
      if (cli.enabled) {
        console.log(chalk.gray(`   Config: ${cli.config_path}`));
        console.log(chalk.gray(`   Symlink: ${cli.symlink_exists ? (cli.symlink_valid ? '✅ Válido' : '❌ Inválido') : '❌ Não existe'}`));
        console.log(chalk.gray(`   Servidores: ${cli.servers_count}`));
        
        if (cli.last_sync) {
          console.log(chalk.gray(`   Última Sincronização: ${new Date(cli.last_sync).toLocaleString('pt-BR')}`));
        }
      }
      console.log('');
    }
    
    // Status dos servidores
    console.log(chalk.cyan.bold('🚀 Status dos Servidores\n'));
    
    const enabledServers = this.status.servers.filter(s => s.enabled);
    const disabledServers = this.status.servers.filter(s => !s.enabled);
    
    console.log(chalk.white(`Total: ${chalk.blue(this.status.servers.length)}`));
    console.log(chalk.white(`Habilitados: ${chalk.green(enabledServers.length)}`));
    console.log(chalk.white(`Desabilitados: ${chalk.red(disabledServers.length)}\n`));
    
    // Servidores habilitados
    if (enabledServers.length > 0) {
      console.log(chalk.green('✅ Servidores Habilitados:\n'));
      
      for (const server of enabledServers) {
        const configIcon = server.has_config ? chalk.green('✅') : chalk.red('❌');
        const serverIcon = server.has_server_file ? chalk.green('✅') : chalk.red('❌');
        const readmeIcon = server.has_readme ? chalk.green('✅') : chalk.red('❌');
        const depsIcon = server.dependencies_installed ? chalk.green('✅') : chalk.red('❌');
        
        console.log(`${chalk.white(server.name)} (${chalk.blue(server.category)})`);
        console.log(chalk.gray(`   Config: ${configIcon} Server: ${serverIcon} README: ${readmeIcon} Dependências: ${depsIcon}`));
        console.log(chalk.gray(`   Última Modificação: ${server.last_modified.toLocaleString('pt-BR')}\n`));
      }
    }
    
    // Servidores desabilitados
    if (disabledServers.length > 0) {
      console.log(chalk.red('❌ Servidores Desabilitados:\n'));
      
      for (const server of disabledServers) {
        console.log(chalk.gray(`${server.name} (${server.category})`));
      }
      console.log('');
    }
    
    // Status de sincronização
    console.log(chalk.cyan.bold('🔄 Status de Sincronização\n'));
    
    const sync = this.status.sync;
    console.log(chalk.white(`Sincronização Automática: ${sync.auto_sync_enabled ? chalk.green('✅') : chalk.red('❌')}`));
    console.log(chalk.white(`Intervalo: ${chalk.blue(sync.sync_interval)}ms`));
    
    if (sync.last_sync_report) {
      const report = sync.last_sync_report;
      console.log(chalk.white(`Última Sincronização: ${chalk.blue(new Date(report.timestamp).toLocaleString('pt-BR'))}`));
      console.log(chalk.white(`CLIs Sincronizadas: ${chalk.green(report.summary.total_clis)}`));
      console.log(chalk.white(`Servidores Sincronizados: ${chalk.green(report.summary.enabled_servers)}`));
    } else {
      console.log(chalk.yellow('⚠️  Nenhuma sincronização realizada ainda'));
    }
    
    // Histórico de sincronização
    if (sync.sync_history.length > 0) {
      console.log(chalk.cyan.bold('\n📊 Histórico de Sincronização\n'));
      
      for (const history of sync.sync_history.slice(-3)) { // Últimos 3
        const date = new Date(history.timestamp).toLocaleString('pt-BR');
        const success = history.summary.successful_syncs;
        const total = history.summary.total_clis;
        
        console.log(chalk.gray(`${date} - ${success}/${total} CLIs sincronizadas`));
      }
    }
    
    // Recomendações
    this.showRecommendations();
  }

  showRecommendations() {
    console.log(chalk.cyan.bold('\n💡 Recomendações\n'));
    
    const recommendations = [];
    
    // Verificar CLIs não conectadas
    const disconnectedCLIs = this.status.clis.filter(c => c.enabled && !c.connected);
    if (disconnectedCLIs.length > 0) {
      recommendations.push(`Conectar CLIs: ${disconnectedCLIs.map(c => c.name).join(', ')}`);
    }
    
    // Verificar servidores sem configuração
    const serversWithoutConfig = this.status.servers.filter(s => s.enabled && !s.has_config);
    if (serversWithoutConfig.length > 0) {
      recommendations.push(`Configurar servidores: ${serversWithoutConfig.map(s => s.name).join(', ')}`);
    }
    
    // Verificar dependências não instaladas
    const serversWithoutDeps = this.status.servers.filter(s => s.enabled && !s.dependencies_installed && s.has_config);
    if (serversWithoutDeps.length > 0) {
      recommendations.push(`Instalar dependências: ${serversWithoutDeps.map(s => s.name).join(', ')}`);
    }
    
    if (recommendations.length === 0) {
      console.log(chalk.green('✅ Sistema funcionando perfeitamente!'));
    } else {
      for (const rec of recommendations) {
        console.log(chalk.yellow(`⚠️  ${rec}`));
      }
    }
    
    console.log(chalk.cyan.bold('\n🔧 Comandos Úteis\n'));
    console.log(chalk.gray('   npm run connect-cli    # Conectar CLIs'));
    console.log(chalk.gray('   npm run sync           # Sincronizar servidores'));
    console.log(chalk.gray('   npm run add-server     # Adicionar servidor'));
    console.log(chalk.gray('   npm run status         # Verificar status novamente\n'));
  }
}

// Executar se chamado diretamente
if (import.meta.url === `file://${process.argv[1]}`) {
  const checker = new StatusChecker();
  checker.init().catch(console.error);
}

export default StatusChecker;
