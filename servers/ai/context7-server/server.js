#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

// Configuração do servidor
const config = {
  name: 'context7-server',
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
      tools: {
        listChanged: true
      }
    }
  }
);

// Configurar handlers
server.setRequestHandler('tools/list', async () => {
  return [
    {
      name: 'context7_resolve_library_id',
      description: 'Resolve o nome de uma biblioteca para um ID compatível com Context7',
      inputSchema: {
        type: 'object',
        properties: {
          libraryName: {
            type: 'string',
            description: 'Nome da biblioteca para resolver (ex: "react", "next.js")'
          }
        },
        required: ['libraryName']
      }
    },
    {
      name: 'context7_get_library_docs',
      description: 'Obtém documentação atualizada de uma biblioteca específica',
      inputSchema: {
        type: 'object',
        properties: {
          context7CompatibleLibraryID: {
            type: 'string',
            description: 'ID da biblioteca no formato /org/project (ex: "/vercel/next.js")'
          },
          topic: {
            type: 'string',
            description: 'Tópico específico para focar a documentação (opcional)'
          },
          tokens: {
            type: 'number',
            description: 'Número máximo de tokens de documentação (padrão: 10000)'
          }
        },
        required: ['context7CompatibleLibraryID']
      }
    }
  ];
});

server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;
  
  try {
    switch (name) {
      case 'context7_resolve_library_id':
        const { libraryName } = args;
        
        if (!libraryName || typeof libraryName !== 'string') {
          throw new Error('libraryName deve ser uma string válida');
        }
        
        console.log(`🔍 Resolvendo biblioteca: ${libraryName}`);
        
        // Simular chamada para a API Context7
        const mockResult = {
          libraries: [
            {
              id: `/example/${libraryName}`,
              name: libraryName,
              description: `Documentação para ${libraryName}`,
              version: 'latest'
            }
          ]
        };
        
        return {
          content: [
            {
              type: 'text',
              text: `✅ Biblioteca "${libraryName}" resolvida com sucesso!\n\n` +
                    `📚 Resultados encontrados: ${mockResult.libraries.length}\n\n` +
                    `🔗 IDs disponíveis:\n` +
                    mockResult.libraries.map(lib => 
                      `  - ${lib.id} (${lib.name} - ${lib.description})`
                    ).join('\n') +
                    `\n\n💡 Use o ID retornado com context7_get_library_docs para obter a documentação.`
            }
          ]
        };
        
      case 'context7_get_library_docs':
        const { context7CompatibleLibraryID, topic, tokens = 10000 } = args;
        
        if (!context7CompatibleLibraryID || typeof context7CompatibleLibraryID !== 'string') {
          throw new Error('context7CompatibleLibraryID deve ser uma string válida');
        }
        
        console.log(`📚 Obtendo documentação para: ${context7CompatibleLibraryID}`);
        if (topic) console.log(`🎯 Tópico: ${topic}`);
        console.log(`🔢 Tokens: ${tokens}`);
        
        // Simular chamada para a API Context7
        const mockDocs = {
          library: context7CompatibleLibraryID,
          topic: topic || 'geral',
          content: `📖 Documentação completa para ${context7CompatibleLibraryID}\n\n` +
                   `🎯 Tópico: ${topic || 'Visão geral da biblioteca'}\n` +
                   `🔢 Tokens utilizados: ${Math.min(tokens, 5000)}\n\n` +
                   `📋 Conteúdo da documentação:\n` +
                   `- Instalação e configuração\n` +
                   `- Exemplos de uso\n` +
                   `- API Reference\n` +
                   `- Melhores práticas\n\n` +
                   `💡 Esta é uma simulação. Em produção, você receberia a documentação real da Context7.`,
          timestamp: new Date().toISOString()
        };
        
        return {
          content: [
            {
              type: 'text',
              text: mockDocs.content
            }
          ]
        };
        
      default:
        throw new Error(`Ferramenta desconhecida: ${name}`);
    }
  } catch (error) {
    console.error(`❌ Erro na ferramenta ${name}:`, error.message);
    
    return {
      content: [
        {
          type: 'text',
          text: `❌ Erro ao executar ${name}: ${error.message}\n\n` +
                `🔧 Verifique:\n` +
                `- Parâmetros fornecidos\n` +
                `- Configuração da API Context7\n` +
                `- Logs do servidor para mais detalhes`
        }
      ]
    };
  }
});

// Iniciar servidor
const transport = new StdioServerTransport();
await server.connect(transport);

console.log(`🚀 ${config.name} iniciado`);
console.log(`📋 Versão: ${config.version}`);
console.log(`🔧 Ferramentas disponíveis:`);
console.log(`   - context7_resolve_library_id`);
console.log(`   - context7_get_library_docs`);
console.log(`📡 Aguardando conexões...`);
