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

class MCPSync {
  constructor() {
    this.config = null;
    this.env = {};
    this.spinner = null;
    this.connectedCLIs = [];
    this.servers = [];
    this.syncResults = {};
  }

  async init() {
    console.log(chalk.blue.bold('\n🔄 MCP Servers Hub - Sincronização Completa\n'));
    
    try {
      await this.loadConfig();
      await this.discoverServers();
      await this.discoverConnectedCLIs();
      await this.performSync();
      await this.updateSyncStatus();
      await this.generateReport();
      
      console.log(chalk.green.bold('\n✅ Sincronização concluída com sucesso!\n'));
      this.showSyncSummary();
      
    } catch (error) {
      console.error(chalk.red.bold('\n❌ Erro durante a sincronização:'), error.message);
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

  async discoverServers() {
    this.spinner = ora('Descobrindo servidores MCP...').start();
    
    try {
      const serversDir = join(rootDir, 'servers');
      this.servers = [];
      
      for (const category of this.config.servers.categories) {
        const categoryPath = join(serversDir, category);
        
        if (await fs.pathExists(categoryPath)) {
          const categoryServers = await fs.readdir(categoryPath);
          
          for (const server of categoryServers) {
            const serverPath = join(categoryPath, server);
            const stats = await fs.stat(serverPath);
            
            if (stats.isDirectory()) {
              const configPath = join(serverPath, 'config.json');
              let serverConfig = { ...this.config.servers.default_config };
              
              if (await fs.pathExists(configPath)) {
                try {
                  const customConfig = await fs.readJson(configPath);
                  serverConfig = { ...serverConfig, ...customConfig };
                } catch (error) {
                  console.warn(chalk.yellow(`⚠️  Erro ao ler config.json de ${category}/${server}`));
                }
              }
              
              this.servers.push({
                name: server,
                category,
                path: serverPath,
                config: serverConfig,
                enabled: serverConfig.enabled
              });
            }
          }
        }
      }
      
      this.spinner.succeed(`${this.servers.length} servidores descobertos`);
    } catch (error) {
      this.spinner.fail('Erro ao descobrir servidores');
      throw error;
    }
  }

  async discoverConnectedCLIs() {
    this.spinner = ora('Descobrindo CLIs conectadas...').start();
    
    try {
      const cliProfilesDir = join(rootDir, 'cli-profiles');
      this.connectedCLIs = [];
      
      for (const cli of this.config.clis.supported) {
        const envKey = `${cli.toUpperCase()}_ENABLED`;
        const isEnabled = this.env[envKey] === 'true';
        
        if (isEnabled) {
          const cliProfilePath = join(cliProfilesDir, `${cli}.json`);
          
          if (await fs.pathExists(cliProfilePath)) {
            const profile = await fs.readJson(cliProfilePath);
            
            if (profile.enabled && profile.status === 'connected') {
              this.connectedCLIs.push({
                name: cli,
                profile,
                configPath: this.config.clis.config_paths[cli]
              });
            }
          }
        }
      }
      
      this.spinner.succeed(`${this.connectedCLIs.length} CLIs conectadas`);
    } catch (error) {
      this.spinner.fail('Erro ao descobrir CLIs');
      throw error;
    }
  }

  async performSync() {
    this.spinner = ora('Executando sincronização...').start();
    
    try {
      this.syncResults = {};
      
      for (const cli of this.connectedCLIs) {
        this.syncResults[cli.name] = {
          success: true,
          servers: [],
          errors: [],
          timestamp: new Date().toISOString()
        };
        
        try {
          await this.syncCLI(cli);
        } catch (error) {
          this.syncResults[cli.name].success = false;
          this.syncResults[cli.name].errors.push(error.message);
        }
      }
      
      this.spinner.succeed('Sincronização executada');
    } catch (error) {
      this.spinner.fail('Erro na sincronização');
      throw error;
    }
  }

  async syncCLI(cli) {
    const expandedPath = this.expandPath(cli.configPath);
    const symlinkPath = join(expandedPath, 'mcp_servers');
    
    // Verificar se o symlink existe e está correto
    if (!(await fs.pathExists(symlinkPath))) {
      throw new Error(`Symlink não encontrado: ${symlinkPath}`);
    }
    
    const realPath = await fs.realpath(symlinkPath);
    const expectedPath = join(rootDir, 'servers');
    
    if (realPath !== expectedPath) {
      throw new Error(`Symlink incorreto: ${realPath} ≠ ${expectedPath}`);
    }
    
    // Sincronizar servidores habilitados
    for (const server of this.servers) {
      if (server.enabled) {
        try {
          await this.syncServerToCLI(server, cli, symlinkPath);
          this.syncResults[cli.name].servers.push({
            name: server.name,
            category: server.category,
            status: 'synced'
          });
        } catch (error) {
          this.syncResults[cli.name].servers.push({
            name: server.name,
            category: server.category,
            status: 'error',
            error: error.message
          });
        }
      }
    }
  }

  async syncServerToCLI(server, cli, symlinkPath) {
    const serverSymlinkPath = join(symlinkPath, server.category, server.name);
    
    // Verificar se o servidor já está sincronizado
    if (await fs.pathExists(serverSymlinkPath)) {
      const realPath = await fs.realpath(serverSymlinkPath);
      if (realPath === server.path) {
        return; // Já sincronizado
      }
      // Remover symlink incorreto
      await fs.remove(serverSymlinkPath);
    }
    
    // Criar symlink para o servidor
    await fs.ensureDir(dirname(serverSymlinkPath));
    await fs.symlink(server.path, serverSymlinkPath);
  }

  expandPath(path) {
    if (path.startsWith('~')) {
      return path.replace('~', process.env.HOME);
    }
    return path;
  }

  async updateSyncStatus() {
    this.spinner = ora('Atualizando status de sincronização...').start();
    
    try {
      const cliProfilesDir = join(rootDir, 'cli-profiles');
      
      for (const cli of this.connectedCLIs) {
        const cliProfilePath = join(cliProfilesDir, `${cli.name}.json`);
        
        if (await fs.pathExists(cliProfilePath)) {
          const profile = await fs.readJson(cliProfilePath);
          profile.last_sync = new Date().toISOString();
          profile.sync_status = this.syncResults[cli.name].success ? 'success' : 'error';
          profile.synced_servers = this.syncResults[cli.name].servers.length;
          
          await fs.writeJson(cliProfilePath, profile, { spaces: 2 });
        }
      }
      
      this.spinner.succeed('Status atualizado');
    } catch (error) {
      this.spinner.fail('Erro ao atualizar status');
      throw error;
    }
  }

  async generateReport() {
    this.spinner = ora('Gerando relatório de sincronização...').start();
    
    try {
      const report = {
        timestamp: new Date().toISOString(),
        summary: {
          total_clis: this.connectedCLIs.length,
          total_servers: this.servers.length,
          enabled_servers: this.servers.filter(s => s.enabled).length,
          successful_syncs: Object.values(this.syncResults).filter(r => r.success).length,
          failed_syncs: Object.values(this.syncResults).filter(r => !r.success).length
        },
        cli_results: this.syncResults,
        servers: this.servers.map(s => ({
          name: s.name,
          category: s.category,
          enabled: s.enabled,
          path: s.path
        }))
      };
      
      const reportPath = join(rootDir, 'logs', `sync-report-${Date.now()}.json`);
      await fs.writeJson(reportPath, report, { spaces: 2 });
      
      // Atualizar relatório mais recente
      const latestReportPath = join(rootDir, 'logs', 'latest-sync-report.json');
      await fs.writeJson(latestReportPath, report, { spaces: 2 });
      
      this.spinner.succeed('Relatório gerado');
    } catch (error) {
      this.spinner.fail('Erro ao gerar relatório');
      throw error;
    }
  }

  showSyncSummary() {
    console.log(chalk.cyan.bold('\n📊 Resumo da Sincronização:\n'));
    
    const totalCLIs = this.connectedCLIs.length;
    const totalServers = this.servers.length;
    const enabledServers = this.servers.filter(s => s.enabled).length;
    const successfulSyncs = Object.values(this.syncResults).filter(r => r.success).length;
    
    console.log(chalk.white(`CLIs Conectadas: ${chalk.green(totalCLIs)}`));
    console.log(chalk.white(`Servidores Totais: ${chalk.blue(totalServers)}`));
    console.log(chalk.white(`Servidores Habilitados: ${chalk.blue(enabledServers)}`));
    console.log(chalk.white(`Sincronizações Bem-sucedidas: ${chalk.green(successfulSyncs)}`));
    
    console.log(chalk.cyan.bold('\n🔍 Detalhes por CLI:\n'));
    
    for (const cli of this.connectedCLIs) {
      const result = this.syncResults[cli.name];
      const status = result.success ? chalk.green('✅') : chalk.red('❌');
      
      console.log(`${status} ${cli.name}`);
      console.log(chalk.gray(`   Servidores sincronizados: ${result.servers.length}`));
      
      if (result.errors.length > 0) {
        console.log(chalk.red(`   Erros: ${result.errors.length}`));
        for (const error of result.errors) {
          console.log(chalk.gray(`     - ${error}`));
        }
      }
      console.log('');
    }
    
    console.log(chalk.cyan.bold('📁 Arquivos Gerados:\n'));
    console.log(chalk.gray('   logs/latest-sync-report.json'));
    console.log(chalk.gray('   logs/sync-report-[timestamp].json\n'));
    
    console.log(chalk.cyan.bold('🔧 Próximos Passos:\n'));
    console.log(chalk.white('1. Verifique o status detalhado:'));
    console.log(chalk.gray('   npm run status\n'));
    
    console.log(chalk.white('2. Teste os servidores em suas CLIs'));
    console.log(chalk.white('3. Configure sincronização automática se necessário\n'));
  }
}

// Executar se chamado diretamente
if (import.meta.url === `file://${process.argv[1]}`) {
  const sync = new MCPSync();
  sync.init().catch(console.error);
}

export default MCPSync;
