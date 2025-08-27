#!/bin/bash

set -e  # para parar em caso de erro

# Configurações
GITHUB_USERNAME=filipe-rds
GITHUB_EMAIL=filipe.rds.dev@gmail.com
RELEASE_VERSION=v1.2.3

# Função para mostrar uso
show_usage() {
    echo "Uso: $0 [SERVICE_NAME]"
    echo ""
    echo "SERVICE_NAME: nome do serviço (order, payment, shipping) ou 'all' para todos"
    echo "Se não especificado, gera para todos os serviços"
    echo ""
    echo "Comandos especiais:"
    echo "  all           # Gera para todos os serviços"
    echo "  clean         # Remove todos os arquivos gerados"
    echo "  help          # Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 order      # Gera apenas para order"
    echo "  $0 all        # Gera para todos os serviços"
    echo "  $0 clean      # Limpa arquivos gerados"
    echo "  $0            # Gera para todos os serviços"
}

# Função para gerar protobuf para um serviço
generate_service() {
    local service_name=$1
    
    echo "=== Gerando arquivos para o serviço: $service_name ==="
    
    # Verifica se o diretório do serviço existe
    if [ ! -d "./${service_name}" ]; then
        echo "❌ Erro: Diretório ./${service_name} não encontrado"
        return 1
    fi
    
    # Verifica se há arquivos .proto
    if ! compgen -G "./${service_name}/*.proto" > /dev/null; then
        echo "❌ Erro: Nenhum arquivo .proto encontrado em ./${service_name}/"
        return 1
    fi
    
    # Cria pasta de saída
    mkdir -p golang/${service_name}
    
    # Gera o código
    echo "🔨 Gerando código Go para ${service_name}..."
    protoc --go_out=./golang \
        --go_opt=paths=source_relative \
        --go-grpc_out=./golang \
        --go-grpc_opt=paths=source_relative \
        --proto_path=. \
        ./${service_name}/*.proto
    
    echo "📄 Arquivos gerados:"
    ls -al ./golang/${service_name}
    
    # Inicializa o módulo Go
    echo "📦 Inicializando módulo Go para ${service_name}..."
    cd golang/${service_name}
    go mod init github.com/${GITHUB_USERNAME}/microservices-proto/golang/${service_name} || true
    go mod tidy || true
    cd ../..
    
    echo "✅ Serviço ${service_name} gerado com sucesso!"
    echo ""
}

# Função para limpar arquivos gerados
clean_generated() {
    echo "🧹 Limpando arquivos gerados..."
    if [ -d "golang" ]; then
        rm -rf golang/
        echo "✅ Diretório golang/ removido!"
    else
        echo "ℹ️  Nenhum arquivo para limpar (diretório golang/ não existe)"
    fi
}

# Função para verificar pré-requisitos
check_prerequisites() {
    echo "🔍 Verificando pré-requisitos..."
    
    # Verifica se protoc está instalado
    if ! command -v protoc &> /dev/null; then
        echo "❌ Erro: protoc não está instalado"
        echo "Instale o Protocol Buffers compiler:"
        echo "  - Ubuntu/Debian: sudo apt install protobuf-compiler"
        echo "  - macOS: brew install protobuf"
        echo "  - Alpine: apk add protobuf protobuf-dev"
        exit 1
    fi
    
    # Verifica se go está instalado
    if ! command -v go &> /dev/null; then
        echo "❌ Erro: Go não está instalado"
        exit 1
    fi
    
    echo "✅ Pré-requisitos verificados!"
}

# Verifica argumentos
SERVICE_NAME=${1:-"all"}

# Verifica se foi solicitada ajuda
if [ "$SERVICE_NAME" = "help" ] || [ "$SERVICE_NAME" = "-h" ] || [ "$SERVICE_NAME" = "--help" ]; then
    show_usage
    exit 0
fi

# Verifica se foi solicitada limpeza
if [ "$SERVICE_NAME" = "clean" ]; then
    clean_generated
    exit 0
fi

# Verifica pré-requisitos
check_prerequisites

# Instala os plugins necessários
echo "📦 Instalando/atualizando plugins protobuf..."
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest 
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Garante que o PATH está certo
export PATH="$PATH:$(go env GOPATH)/bin"

echo "🚀 Iniciando geração de código Go a partir dos arquivos .proto"
echo ""

# Lista de serviços disponíveis
AVAILABLE_SERVICES=("order" "payment" "shipping")

# Gera para todos os serviços
if [ "$SERVICE_NAME" = "all" ]; then
    echo "📋 Gerando para todos os serviços: ${AVAILABLE_SERVICES[*]}"
    echo ""
    
    success_count=0
    for service in "${AVAILABLE_SERVICES[@]}"; do
        if generate_service "$service"; then
            ((success_count++))
        else
            echo "❌ Falha ao gerar ${service}"
        fi
    done
    
    echo "🎉 ${success_count}/${#AVAILABLE_SERVICES[@]} serviços gerados com sucesso!"
    
# Gera para um serviço específico
elif [[ " ${AVAILABLE_SERVICES[*]} " =~ " ${SERVICE_NAME} " ]]; then
    generate_service "$SERVICE_NAME"
    echo "🎉 Serviço ${SERVICE_NAME} gerado com sucesso!"
    
else
    echo "❌ Erro: Serviço '${SERVICE_NAME}' não reconhecido"
    echo "Serviços disponíveis: ${AVAILABLE_SERVICES[*]}"
    echo ""
    show_usage
    exit 1
fi

echo ""
echo "📁 Estrutura gerada:"
if [ -d "golang" ]; then
    find golang -type f -name "*.go" | head -10
    echo ""
    echo "📊 Resumo:"
    echo "   Arquivos .go: $(find golang -name "*.go" | wc -l)"
    echo "   Serviços: $(ls golang 2>/dev/null | wc -l)"
else
    echo "   Nenhum arquivo gerado"
fi
