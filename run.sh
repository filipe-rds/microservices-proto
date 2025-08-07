#!/bin/bash

set -e  # para parar em caso de erro

# Configurações
GITHUB_USERNAME=filipe-rds
GITHUB_EMAIL=filipe.rds.dev@gmail.com

SERVICE_NAME=order
RELEASE_VERSION=v1.2.3

# Instala os plugins necessários
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest 
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Garante que o PATH está certo
export PATH="$PATH:$(go env GOPATH)/bin"

echo "Generating Go source code"

# Cria pastas
mkdir -p golang/${SERVICE_NAME}

# Verifica se há arquivos .proto
if compgen -G "./${SERVICE_NAME}/*.proto" > /dev/null; then
  # Gera o código
  protoc --go_out=./golang \
    --go_opt=paths=source_relative \
    --go-grpc_out=./golang \
    --go-grpc_opt=paths=source_relative \
    ./${SERVICE_NAME}/*.proto
else
  echo "Nenhum arquivo .proto encontrado em ./${SERVICE_NAME}/"
  exit 1
fi

echo "Generated Go source code files"
ls -al ./golang/${SERVICE_NAME}

# Inicializa o módulo Go
cd golang/${SERVICE_NAME}
go mod init github.com/${GITHUB_USERNAME}/microservices-proto/golang/${SERVICE_NAME} || true
go mod tidy || true

