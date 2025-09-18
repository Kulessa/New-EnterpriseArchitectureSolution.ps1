# 🚀 New-EnterpriseArchitectureSolution

> **Script PowerShell enterprise para criação automatizada de solutions .NET 8 com Clean Architecture**

[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?style=flat&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

## 📋 Visão Geral

Transforme **horas de configuração manual** em **minutos de automação**! Este script cria uma solution .NET 8 enterprise-grade completa com Clean Architecture, incluindo projetos, dependências, pacotes NuGet, scaffolding de banco de dados, scripts de build e documentação.

### ✨ Principais Recursos

- 🏗️ **Clean Architecture** com 6 projetos estruturados
- 🗄️ **11 bancos de dados suportados** (SQL Server, PostgreSQL, MySQL, Oracle, SQLite, MongoDB, Azure SQL, Cosmos DB, Redis, DynamoDB, Elasticsearch)
- ⚡ **Scaffolding automático** do Entity Framework
- 📦 **Pacotes NuGet inteligentes** por camada
- 🔧 **Scripts de build e desenvolvimento** prontos
- 📚 **Documentação completa** gerada automaticamente
- 🔄 **Configuração Git** com .gitignore oficial
- 🌍 **Multi-ambiente** (Development, Production)
- 🧪 **Estrutura de testes** configurada

## 🚀 Início Rápido

### Pré-requisitos

```powershell
# Verificar se possui .NET 8 SDK
dotnet --version

# Instalar Entity Framework CLI (opcional - para scaffolding)
dotnet tool install --global dotnet-ef
```

### Instalação

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/New-EnterpriseArchitectureSolution.git

# Navegue para o diretório
cd New-EnterpriseArchitectureSolution

# Execute o script
./New-EnterpriseArchitectureSolution.ps1
```

### Uso Básico

```powershell
# Execução interativa (recomendado para primeiro uso)
./New-EnterpriseArchitectureSolution.ps1

# Execução automatizada
./New-EnterpriseArchitectureSolution.ps1 `
  -SolutionName "MinhaAPI" `
  -SolutionPath "C:\Projetos" `
  -InitGit `
  -DbChoice 1 `
  -ConnectionString "Server=(localdb)\mssqllocaldb;Database=MinhaAPI;Trusted_Connection=true"
```

## 🏗️ Estrutura Criada

O script gera a seguinte estrutura de projeto:

```
MinhaAPI/
├── 📁 docs/                          # Documentação
├── 📁 scripts/                       # Scripts de build e desenvolvimento
├── 📁 MinhaAPI.Api/                  # 🌐 Camada de Apresentação
│   ├── Controllers/
│   ├── Middlewares/
│   ├── Filters/
│   └── Configurations/
├── 📁 MinhaAPI.Application/          # 🧠 Lógica de Aplicação
│   ├── CQRS/
│   │   ├── Commands/
│   │   ├── Queries/
│   │   └── Handlers/
│   ├── Services/
│   └── Validators/
├── 📁 MinhaAPI.Domain/               # 💼 Regras de Negócio
│   ├── Entities/
│   ├── ValueObjects/
│   ├── Aggregates/
│   └── Events/
├── 📁 MinhaAPI.Infrastructure/       # 🔧 Infraestrutura
│   ├── Data/
│   │   ├── Contexts/
│   │   └── Repositories/
│   ├── Auth/
│   └── Models/                       # 🗄️ Models do EF (scaffolded)
├── 📁 MinhaAPI.Api.Contracts/        # 📋 Contratos da API
│   └── DTOs/
└── 📁 MinhaAPI.Tests/                # 🧪 Testes
    ├── Unit/
    └── Integration/
```

## 🗄️ Bancos Suportados

| # | Banco de Dados | Provider | Scaffolding |
|---|---------------|----------|-------------|
| 1 | SQL Server | Microsoft.EntityFrameworkCore.SqlServer | ✅ |
| 2 | PostgreSQL | Npgsql.EntityFrameworkCore.PostgreSQL | ✅ |
| 3 | MySQL | Pomelo.EntityFrameworkCore.MySql | ✅ |
| 4 | Oracle | Oracle.EntityFrameworkCore | ✅ |
| 5 | SQLite | Microsoft.EntityFrameworkCore.Sqlite | ✅ |
| 6 | MongoDB | MongoDB.Driver | ❌ |
| 7 | Azure SQL Database | Microsoft.EntityFrameworkCore.SqlServer | ✅ |
| 8 | Azure Cosmos DB | Microsoft.Azure.Cosmos | ❌ |
| 9 | Redis | StackExchange.Redis | ❌ |
| 10 | Amazon DynamoDB | AWSSDK.DynamoDBv2 | ❌ |
| 11 | Elasticsearch | NEST | ❌ |

## 📦 Pacotes Incluídos

### 🌐 API Layer
```xml
<PackageReference Include="MediatR" />
<PackageReference Include="Swashbuckle.AspNetCore" />
<PackageReference Include="Serilog.AspNetCore" />
<PackageReference Include="FluentValidation.AspNetCore" />
<PackageReference Include="AspNetCoreRateLimit" />
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" />
```

### 🧠 Application Layer
```xml
<PackageReference Include="MediatR" />
<PackageReference Include="AutoMapper" />
<PackageReference Include="FluentValidation" />
```

### 🔧 Infrastructure Layer
```xml
<PackageReference Include="Microsoft.EntityFrameworkCore" />
<PackageReference Include="Polly" />
```

### 🧪 Tests
```xml
<PackageReference Include="xUnit" />
<PackageReference Include="Moq" />
<PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" />
```

## 🎛️ Parâmetros do Script

| Parâmetro | Tipo | Descrição | Exemplo |
|-----------|------|-----------|---------|
| `-SolutionName` | string | Nome da solution | `"MinhaAPI"` |
| `-SolutionPath` | string | Caminho de criação | `"C:\Projetos"` |
| `-InitGit` | switch | Inicializar Git | `-InitGit` |
| `-DbChoice` | int | Banco (1-11) | `-DbChoice 1` |
| `-ConnectionString` | string | String de conexão | `"Server=..."` |
| `-Minimal` | switch | Pacotes mínimos | `-Minimal` |
| `-SkipScaffolding` | switch | Pular scaffolding | `-SkipScaffolding` |

## 🔧 Scripts Gerados

### Build Script (`./scripts/build.ps1`)
```powershell
# Build simples
./scripts/build.ps1

# Build com limpeza e testes
./scripts/build.ps1 -Clean -Test

# Build completo com empacotamento
./scripts/build.ps1 -Clean -Test -Pack
```

### Development Script (`./scripts/dev.ps1`)
```powershell
# Executar aplicação
./scripts/dev.ps1 run

# Modo watch (hot reload)
./scripts/dev.ps1 watch

# Testes em modo watch
./scripts/dev.ps1 test

# Aplicar migrações
./scripts/dev.ps1 migrate
```

## 📊 Exemplos de Uso

### Exemplo 1: API com SQL Server
```powershell
./New-EnterpriseArchitectureSolution.ps1 `
  -SolutionName "LojaAPI" `
  -SolutionPath "C:\Projetos" `
  -InitGit `
  -DbChoice 1 `
  -ConnectionString "Server=(localdb)\mssqllocaldb;Database=LojaDB;Trusted_Connection=true" `
  -ConnectionName "DefaultConnection"
```

### Exemplo 2: Microserviço com PostgreSQL
```powershell
./New-EnterpriseArchitectureSolution.ps1 `
  -SolutionName "PedidosMicroservice" `
  -DbChoice 2 `
  -ConnectionString "Host=localhost;Database=pedidos;Username=postgres;Password=123456" `
  -Minimal
```

### Exemplo 3: API com Oracle e Schemas Específicos
```powershell
./New-EnterpriseArchitectureSolution.ps1 `
  -SolutionName "ERP_API" `
  -DbChoice 4 `
  -ConnectionString "Data Source=localhost:1521/XE;User Id=hr;Password=123456;" `
  -Schemas @("HR", "SALES") `
  -Tables @("EMPLOYEES", "ORDERS", "CUSTOMERS")
```

## 🏆 Benefícios

| Antes | Depois |
|-------|--------|
| ⏰ **2-4 horas** configurando manualmente | ⚡ **2-5 minutos** totalmente automatizado |
| 🤔 Estrutura inconsistente entre projetos | 🎯 Padrão enterprise sempre igual |
| 📦 Esquecimento de pacotes importantes | 🔄 Todos pacotes necessários instalados |
| 📝 Documentação inexistente | 📚 README e docs gerados automaticamente |
| 🔧 Scripts de build inexistentes | 🚀 Scripts de produtividade prontos |

## 🤝 Contribuição

Contribuições são muito bem-vindas! Por favor:

1. 🍴 Fork o projeto
2. 🌿 Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. 💾 Commit suas mudanças (`git commit -m 'Add: nova funcionalidade'`)
4. 📤 Push para a branch (`git push origin feature/nova-funcionalidade`)
5. 🔄 Abra um Pull Request

### 📋 Roadmap

- [ ] Suporte a Docker/Docker Compose
- [ ] Templates personalizados
- [ ] Integração com Azure DevOps
- [ ] Support para .NET 9
- [ ] Geração de APIs GraphQL
- [ ] Templates para Blazor

## 📄 Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🙏 Reconhecimentos

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) por Robert C. Martin
- [.NET Templates](https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-new) pela Microsoft
- Comunidade .NET pelo feedback e sugestões

---

<div align="center">

**⭐ Se este projeto te ajudou, considere dar uma estrela!**

[🐛 Reportar Bug](https://github.com/seu-usuario/New-EnterpriseArchitectureSolution/issues) • [💡 Solicitar Recurso](https://github.com/seu-usuario/New-EnterpriseArchitectureSolution/issues) • [💬 Discussões](https://github.com/seu-usuario/New-EnterpriseArchitectureSolution/discussions)

</div>
