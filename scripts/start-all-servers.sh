#!/bin/bash

# Script para iniciar todos os servidores MCP instalados

echo "Iniciando todos os servidores MCP instalados..."

# Encontra todos os arquivos package.json dentro do diretório servers/
find /Users/felipefull/Documents/MCP_servers/servers/ -name "package.json" | while read package_json_path; do
    server_dir=$(dirname "$package_json_path")
    server_name=$(basename "$server_dir")

    echo "Verificando servidor em: $server_dir"

    # Verifica se o package.json contém um script "start"
    if grep -q '"start":' "$package_json_path"; then
        echo "  -> Encontrado script 'start' para $server_name. Preparando para iniciar..."
        (
            cd "$server_dir" || { echo "Erro: Não foi possível mudar para o diretório $server_dir"; exit 1; }
            # Garante que as dependências estão instaladas e o projeto está compilado antes de iniciar
            echo "    -> Instalando dependências e compilando $server_name..."
            pnpm install --frozen-lockfile || { echo "Erro ao instalar dependências para $server_name"; exit 1; }
            pnpm build || { echo "Erro ao compilar $server_name"; exit 1; }
            echo "    -> Iniciando $server_name em segundo plano..."
            pnpm start &
            echo "    -> $server_name iniciado (PID: $!)"
        ) & # Executa o bloco inteiro em um subshell em segundo plano
    else
        echo "  -> Script 'start' não encontrado em $package_json_path. Pulando $server_name."
    fi
done

echo "Processo de inicialização de servidores concluído. Verifique os logs individuais para o status."
echo "Para parar os servidores, você precisará identificar e encerrar seus processos manualmente (ex: 'kill <PID>')."
