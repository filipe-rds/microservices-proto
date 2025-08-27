# Microservices Proto

Este diretório contém as definições Protocol Buffers (protobuf) para os microsserviços.

## Estrutura

```
microservices-proto/
├── order/
│   └── order.proto         # Definições do serviço Order
├── payment/
│   └── payment.proto       # Definições do serviço Payment
├── shipping/
│   └── shipping.proto      # Definições do serviço Shipping
├── run.sh                  # Script original (simples)
├── generate.sh             # Script avançado (flexível)
└── golang/                 # Arquivos Go gerados (gitignored)
    ├── order/
    ├── payment/
    └── shipping/
```

## Scripts Disponíveis

### 1. `run.sh` (Script Original)

Script simples que gera código para um serviço específico (padrão: payment).

```bash
# Tornar executável
chmod +x run.sh

# Para usar com payment (padrão)
./run.sh

# Para outros serviços, edite a variável SERVICE_NAME no script
```

### 2. `generate.sh` (Script Flexível) 

Script avançado com mais funcionalidades e flexibilidade.

#### Uso:

```bash
# Tornar executável
chmod +x generate.sh

# Gerar para todos os serviços
./generate.sh
./generate.sh all

# Gerar para um serviço específico
./generate.sh order
./generate.sh payment
./generate.sh shipping

# Limpar arquivos gerados
./generate.sh clean

# Mostrar ajuda
./generate.sh help
```

#### Funcionalidades:

- ✅ Geração para todos os serviços ou serviços específicos
- ✅ Verificação de pré-requisitos (protoc, go)
- ✅ Limpeza de arquivos gerados
- ✅ Mensagens de status coloridas e informativas
- ✅ Tratamento de erros robusto
- ✅ Contagem de sucessos/falhas
- ✅ Resumo da estrutura gerada

## Pré-requisitos

### Instalar Protocol Buffers Compiler

**Ubuntu/Debian:**
```bash
sudo apt install protobuf-compiler
```

**macOS:**
```bash
brew install protobuf
```

**Alpine Linux:**
```bash
apk add protobuf protobuf-dev
```

### Verificar Instalação

```bash
protoc --version
go version
```

## Como Usar no Desenvolvimento

### Para Desenvolvimento Local

1. **Gerar todos os protobuf:**
   ```bash
   cd microservices-proto
   ./generate.sh all
   ```

2. **Os microsserviços referenciam os arquivos gerados via:**
   ```go
   replace github.com/filipe-rds/microservices-proto/golang/[service] => ../../microservices-proto/golang/[service]
   ```

### Para Docker Build

Os Dockerfiles dos microsserviços geram os arquivos protobuf durante o build para garantir consistência de versões:

```dockerfile
# Gera protobuf no container
RUN protoc --go_out=../microservices-proto/golang \
    --go_opt=paths=source_relative \
    --go-grpc_out=../microservices-proto/golang \
    --go-grpc_opt=paths=source_relative \
    --proto_path=../microservices-proto \
    ../microservices-proto/[service]/*.proto
```

## Definições dos Serviços

### Order Service
- `CreateOrderRequest` / `CreateOrderResponse`
- Valida produtos e coordena com Payment e Shipping

### Payment Service  
- `CreatePaymentRequest` / `CreatePaymentResponse`
- Processa pagamentos

### Shipping Service
- `CreateShippingRequest` / `CreateShippingResponse`
- Calcula prazos de entrega baseado na quantidade

## Troubleshooting

### Erro: "protoc: command not found"
Instale o Protocol Buffers compiler conforme as instruções acima.

### Erro: "plugin not found"
Execute o script que instala os plugins automaticamente:
```bash
./generate.sh
```

### Arquivos não atualizando
Limpe e regenere:
```bash
./generate.sh clean
./generate.sh all
```

### Para debug
Use o script com verbose:
```bash
bash -x ./generate.sh all
```
