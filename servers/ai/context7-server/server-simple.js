#!/usr/bin/env node

// Servidor MCP simples para Context7
console.log('🚀 Context7 MCP Server iniciando...');

// Simular servidor MCP básico
process.stdin.setEncoding('utf8');

process.stdin.on('data', (data) => {
  try {
    const request = JSON.parse(data);
    
    if (request.method === 'tools/list') {
      const response = {
        jsonrpc: '2.0',
        id: request.id,
        result: [
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
        ]
      };
      
      console.log('📋 Ferramentas listadas');
      process.stdout.write(JSON.stringify(response) + '\n');
      
    } else if (request.method === 'tools/call') {
      const { name, arguments: args } = request.params;
      
      let result;
      
      if (name === 'context7_resolve_library_id') {
        const { libraryName } = args;
        result = {
          content: [
            {
              type: 'text',
              text: `✅ Biblioteca "${libraryName}" resolvida com sucesso!\n\n` +
                    `📚 Resultados encontrados: 1\n\n` +
                    `🔗 IDs disponíveis:\n` +
                    `  - /example/${libraryName} (${libraryName} - Documentação para ${libraryName})\n\n` +
                    `💡 Use o ID retornado com context7_get_library_docs para obter a documentação.`
            }
          ]
        };
      } else if (name === 'context7_get_library_docs') {
        const { context7CompatibleLibraryID, topic, tokens = 10000 } = args;
        result = {
          content: [
            {
              type: 'text',
              text: `📖 Documentação completa para ${context7CompatibleLibraryID}\n\n` +
                   `🎯 Tópico: ${topic || 'Visão geral da biblioteca'}\n` +
                   `🔢 Tokens utilizados: ${Math.min(tokens, 5000)}\n\n` +
                   `📋 Conteúdo da documentação:\n` +
                   `- Instalação e configuração\n` +
                   `- Exemplos de uso\n` +
                   `- API Reference\n` +
                   `- Melhores práticas\n\n` +
                   `💡 Esta é uma simulação. Em produção, você receberia a documentação real da Context7.`
            }
          ]
        };
      } else {
        result = {
          content: [
            {
              type: 'text',
              text: `❌ Ferramenta desconhecida: ${name}`
            }
          ]
        };
      }
      
      const response = {
        jsonrpc: '2.0',
        id: request.id,
        result
      };
      
      console.log(`🔧 Ferramenta executada: ${name}`);
      process.stdout.write(JSON.stringify(response) + '\n');
      
    } else {
      // Responder com erro para métodos não suportados
      const response = {
        jsonrpc: '2.0',
        id: request.id,
        error: {
          code: -32601,
          message: 'Method not found'
        }
      };
      
      process.stdout.write(JSON.stringify(response) + '\n');
    }
    
  } catch (error) {
    console.error('❌ Erro ao processar requisição:', error.message);
    
    const response = {
      jsonrpc: '2.0',
      id: request?.id || null,
      error: {
        code: -32700,
        message: 'Parse error'
      }
    };
    
    process.stdout.write(JSON.stringify(response) + '\n');
  }
});

console.log('📡 Context7 MCP Server pronto para conexões...');
console.log('🔧 Ferramentas disponíveis:');
console.log('   - context7_resolve_library_id');
console.log('   - context7_get_library_docs');
