# New-CleanArchitectureSolution.ps1
# Script modular para criação de Solution .NET com Clean Architecture
# Versão 2.0 - Completamente refatorada e modular

[CmdletBinding()]
param(
    [string]$SolutionName,
    [string]$SolutionPath,
    [switch]$InitGit,
    [ValidateRange(1,11)][int]$DbChoice,
    [string]$ConnectionName,
    [string]$ConnectionString,
    [string[]]$Schemas,
    [string[]]$Tables,
    [switch]$IncludeTables,
    [switch]$Minimal,
    [switch]$SkipScaffolding
)

# ================================
# CONFIGURAÇÕES E CONSTANTES
# ================================

$script:LogPrefix = @{
    Info    = "[INFO]"
    Success = "[OK]"
    Warning = "[WARN]"
    Error   = "[ERRO]"
}

$script:RelationalDbs = @(1, 2, 3, 4, 5, 7)

$script:DbProviders = @{
    1  = @{ Provider = "Microsoft.EntityFrameworkCore.SqlServer"; Name = "SQL Server"; Context = "SqlServerDbContext" }
    2  = @{ Provider = "Npgsql.EntityFrameworkCore.PostgreSQL"; Name = "PostgreSQL"; Context = "PostgreSqlDbContext" }
    3  = @{ Provider = "Pomelo.EntityFrameworkCore.MySql"; Name = "MySQL"; Context = "MySqlDbContext" }
    4  = @{ Provider = "Oracle.EntityFrameworkCore"; Name = "Oracle"; Context = "OracleDbContext" }
    5  = @{ Provider = "Microsoft.EntityFrameworkCore.Sqlite"; Name = "SQLite"; Context = "SqliteDbContext" }
    6  = @{ Provider = "MongoDB.Driver"; Name = "MongoDB"; Context = "MongoDbContext" }
    7  = @{ Provider = "Microsoft.EntityFrameworkCore.SqlServer"; Name = "Azure SQL Database"; Context = "AzureSqlDbContext" }
    8  = @{ Provider = "Microsoft.Azure.Cosmos"; Name = "Azure Cosmos DB"; Context = "CosmosDbContext" }
    9  = @{ Provider = "StackExchange.Redis"; Name = "Redis"; Context = "RedisContext" }
    10 = @{ Provider = "AWSSDK.DynamoDBv2"; Name = "Amazon DynamoDB"; Context = "DynamoDbContext" }
    11 = @{ Provider = "NEST"; Name = "Elasticsearch"; Context = "ElasticsearchContext" }
}

$script:ProjectTemplates = @(
    @{ Name = "Api"; Type = "webapi"; Args = "--use-controllers" },
    @{ Name = "Application"; Type = "classlib"; Args = "" },
    @{ Name = "Domain"; Type = "classlib"; Args = "" },
    @{ Name = "Infrastructure"; Type = "classlib"; Args = "" },
    @{ Name = "Api.Contracts"; Type = "classlib"; Args = "" },
    @{ Name = "Tests"; Type = "xunit"; Args = "" }
)

$script:Dependencies = @{
    "Api" = @("Application", "Api.Contracts")
    "Application" = @("Domain", "Api.Contracts")
    "Infrastructure" = @("Domain")
    "Tests" = @("Api", "Application", "Domain", "Infrastructure", "Api.Contracts")
}

$script:BasePackages = @{
    "Api" = @(
        "MediatR",
        "Microsoft.AspNetCore.OpenApi",
        "Serilog.AspNetCore",
        "Swashbuckle.AspNetCore"
    )
    "Application" = @(
        "AutoMapper",
        "AutoMapper.Extensions.Microsoft.DependencyInjection",
        "FluentValidation",
        "MediatR"
    )
    "Infrastructure" = @(
        "Microsoft.EntityFrameworkCore.Design"
    )
    "Tests" = @(
        "xunit",
        "xunit.runner.visualstudio",
        "coverlet.collector",
        "Microsoft.AspNetCore.Mvc.Testing"
    )
}

$script:EnterprisePackages = @{
    "Api" = @(
        "AspNetCoreRateLimit",
        "AspNetCore.HealthChecks.UI",
        "FluentValidation.AspNetCore",
        "Microsoft.AspNetCore.Authentication.JwtBearer",
        "Serilog.Sinks.Console",
        "Serilog.Sinks.File",
        "Swashbuckle.AspNetCore.Filters"
    )
    "Infrastructure" = @(
        "Polly",
        "Polly.Extensions.Http",
        "Microsoft.AspNetCore.Authentication.JwtBearer"
    )
    "Tests" = @(
        "Moq",
        "WireMock.Net"
    )
}

$script:FolderStructure = @{
    "Api" = @("Controllers", "Filters", "Middlewares", "Configurations", "Extensions")
    "Application" = @("CQRS\Commands", "CQRS\Queries", "CQRS\Handlers", "Validators", "Mappings", "Services", "Interfaces")
    "Domain" = @("Entities", "ValueObjects", "Aggregates", "Interfaces", "Contracts", "Exceptions", "Events")
    "Infrastructure" = @("Data\Contexts", "Data\Repositories", "Data\UnitOfWork", "Auth", "Resilience", "Extensions", "Models")
    "Api.Contracts" = @("DTOs\Requests", "DTOs\Responses", "Examples", "Annotations")
    "Tests" = @("Unit\Application", "Unit\Domain", "Unit\Infrastructure", "Integration\Api", "Integration\Infrastructure", "Mocks\ExternalApis", "Helpers", "Fixtures")
}

# ================================
# FUNÇÕES DE UTILIDADE
# ================================

function Write-LogMessage {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]$Type = "Info",
        [ConsoleColor]$Color = "White"
    )
    
    $colors = @{
        Info    = "Cyan"
        Success = "Green" 
        Warning = "Yellow"
        Error   = "Red"
    }
    
    Write-Host "$($script:LogPrefix[$Type]) $Message" -ForegroundColor $colors[$Type]
}

function Test-ToolInstalled {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Test-DotNetToolInstalled {
    param([string]$ToolName)
    try {
        $installedTools = dotnet tool list -g 2>$null
        return $installedTools -match $ToolName
    }
    catch {
        return $false
    }
}

function New-DirectorySafe {
    param([string]$Path)
    try {
        if (!(Test-Path -Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-LogMessage "Diretório criado: $Path" -Type Success
            return $true
        }
        return $true
    }
    catch {
        Write-LogMessage "Erro ao criar diretório $Path : $($_.Exception.Message)" -Type Error
        return $false
    }
}

function Invoke-DotNetCommand {
    param([string]$Command, [switch]$SuppressOutput)
    try {
        if (!$SuppressOutput) {
            Write-LogMessage "Executando: dotnet $Command" -Type Info
        }
        
        $output = & dotnet $Command.Split() 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Comando falhou: dotnet $Command"
        }
        return $output
    }
    catch {
        Write-LogMessage "Erro ao executar 'dotnet $Command': $($_.Exception.Message)" -Type Error
        throw
    }
}

function Test-Prerequisites {
    Write-LogMessage "Verificando pré-requisitos..." -Type Info
    
    $requiredTools = @('dotnet', 'git')
    $missingTools = @()
    
    foreach ($tool in $requiredTools) {
        if (!(Test-ToolInstalled $tool)) {
            $missingTools += $tool
        }
    }
    
    if ($missingTools.Count -gt 0) {
        Write-LogMessage "Ferramentas ausentes: $($missingTools -join ', ')" -Type Error
        return $false
    }
    
    # Verificar EF CLI apenas para bancos relacionais
    if ($script:DbChoice -in $script:RelationalDbs -and !(Test-DotNetToolInstalled "dotnet-ef")) {
        Write-LogMessage "Entity Framework CLI não encontrado. Instale com: dotnet tool install --global dotnet-ef" -Type Warning
        $script:SkipScaffolding = $true
    }
    
    Write-LogMessage "Pré-requisitos validados com sucesso" -Type Success
    return $true
}

# ================================
# FUNÇÕES DE ENTRADA
# ================================

function Get-SolutionParameters {
    if (-not $script:SolutionName) {
        do {
            $script:SolutionName = Read-Host "Digite o nome da solution"
        } while ([string]::IsNullOrWhiteSpace($script:SolutionName))
    }

    if (-not $script:SolutionPath) {
        $script:SolutionPath = Read-Host "Digite o caminho da solution (Enter para pasta atual)"
        if ([string]::IsNullOrWhiteSpace($script:SolutionPath)) {
            $script:SolutionPath = Get-Location
        }
    }

    Write-LogMessage "Solution: $script:SolutionName" -Type Info
    Write-LogMessage "Caminho: $script:SolutionPath" -Type Info
}

function Get-GitConfiguration {
    if (-not $PSBoundParameters.ContainsKey('InitGit')) {
        $gitResponse = Read-Host "Gostaria de inicializar o Git? (S/N)"
        $script:InitGit = $gitResponse -match '^[Ss]$'
    }
}

function Get-DatabaseConfiguration {
    if (-not $script:DbChoice) {
        Write-Host "`nEscolha o banco de dados:" -ForegroundColor Cyan
        foreach ($key in $script:DbProviders.Keys | Sort-Object) {
            $db = $script:DbProviders[$key]
            Write-Host "$key".PadLeft(2) + " - $($db.Name)"
        }
        
        do {
            $script:DbChoice = Read-Host "Digite sua escolha (1-11)"
        } while ($script:DbChoice -notmatch '^([1-9]|1[01])$')
        $script:DbChoice = [int]$script:DbChoice
    }

    $script:SelectedDb = $script:DbProviders[$script:DbChoice]
    if (-not $script:SelectedDb) {
        Write-LogMessage "Opção inválida. Usando SQL Server por padrão." -Type Warning
        $script:SelectedDb = $script:DbProviders[1]
        $script:DbChoice = 1
    }

    Write-LogMessage "Banco selecionado: $($script:SelectedDb.Name)" -Type Success
    
    # Configurações específicas para bancos relacionais
    if ($script:DbChoice -in $script:RelationalDbs) {
        Get-EntityFrameworkConfiguration
    }
}

function Get-EntityFrameworkConfiguration {
    if (-not $script:ConnectionName) {
        $script:ConnectionName = Read-Host "Digite o nome da conexão para o scaffolding do Entity Framework"
    }
    
    if (-not $script:ConnectionString) {
        $script:ConnectionString = Read-Host "Digite a string de conexão"
    }
    
    if (-not $PSBoundParameters.ContainsKey('IncludeTables')) {
        $tablesResponse = Read-Host "Quer informar as tabelas juntamente com os schemas/owners? (S/N)"
        $script:IncludeTables = $tablesResponse -match '^[Ss]$'
    }
    
    if ($script:IncludeTables) {
        if (-not $script:Schemas -or -not $script:Tables) {
            $schemasInput = Read-Host "Digite os nomes dos schemas/owners.tabelas separados por vírgula (Ex: SCHEMA1.TABELA1,SCHEMA2.TABELA2)"
            $schemaTablePairs = $schemasInput -split ","
            $script:Schemas = @()
            $script:Tables = @()
            
            foreach ($pair in $schemaTablePairs) {
                $parts = $pair.Trim() -split "\."
                if ($parts.Length -eq 2) {
                    $script:Schemas += $parts[0].Trim()
                    $script:Tables += $parts[1].Trim()
                }
            }
        }
    } else {
        if (-not $script:Schemas) {
            $schemasInput = Read-Host "Digite os nomes dos schemas/owners separados por vírgula"
            $script:Schemas = ($schemasInput -split ",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }
        if (-not $script:Tables) {
            $tablesInput = Read-Host "Digite os nomes das tabelas separados por vírgula"
            $script:Tables = ($tablesInput -split ",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }
    }
}

# ================================
# FUNÇÕES DE CRIAÇÃO
# ================================

function New-SolutionStructure {
    Write-LogMessage "Criando estrutura da solution..." -Type Info
    
    $solutionFullPath = Join-Path $script:SolutionPath $script:SolutionName
    
    if (!(New-DirectorySafe -Path $solutionFullPath)) {
        throw "Falha ao criar diretório da solution"
    }
    
    try {
        Set-Location -Path $solutionFullPath
        $script:SolutionFullPath = $solutionFullPath
        Write-LogMessage "Navegado para: $solutionFullPath" -Type Success
    }
    catch {
        throw "Erro ao navegar para $solutionFullPath : $($_.Exception.Message)"
    }

    # Criar pastas auxiliares
    New-DirectorySafe -Path "docs" | Out-Null
    New-DirectorySafe -Path "scripts" | Out-Null
}

function Initialize-Git {
    if (-not $script:InitGit) { return }
    
    Write-LogMessage "Configurando Git..." -Type Info
    
    try {
        # Download do .gitignore com fallback
        try {
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/github/gitignore/main/VisualStudio.gitignore" -OutFile ".gitignore" -ErrorAction Stop -TimeoutSec 10
            Write-LogMessage ".gitignore baixado do GitHub" -Type Success
        }
        catch {
            Write-LogMessage "Não foi possível baixar .gitignore. Criando um básico..." -Type Warning
            $basicGitIgnore = @"
# Build results
[Dd]ebug/
[Dd]ebugPublic/
[Rr]elease/
[Rr]eleases/
x64/
x86/
[Aa][Rr][Mm]/
[Aa][Rr][Mm]64/
bld/
[Bb]in/
[Oo]bj/
[Ll]og/

# Visual Studio files
.vs/
*.user
*.userosscache
*.sln.docstates

# User-specific files (MonoDevelop/Xamarin Studio)
*.userprefs

# Build results
[Dd]ebug/
[Dd]ebugPublic/
[Rr]elease/
[Rr]eleases/
x64/
x86/
[Ww][Ii][Nn]32/
[Aa][Rr][Mm]/
[Aa][Rr][Mm]64/
bld/
[Bb]in/
[Oo]bj/
[Ll]og/
[Ll]ogs/
"@
            $basicGitIgnore | Out-File -FilePath ".gitignore" -Encoding UTF8
        }
        
        git init 2>&1 | Out-Null
        git add . 2>&1 | Out-Null
        git commit -m "Initial commit" 2>&1 | Out-Null
        Write-LogMessage "Git inicializado com sucesso" -Type Success
    }
    catch {
        Write-LogMessage "Erro ao configurar Git: $($_.Exception.Message)" -Type Warning
    }
}

function Add-Projects {
    Write-LogMessage "Criando solution e projetos..." -Type Info
    
    # Criar solution
    Invoke-DotNetCommand "new sln -n $script:SolutionName" -SuppressOutput
    Write-LogMessage "Solution $script:SolutionName criada" -Type Success
    
    $script:CreatedProjects = @()
    
    # Criar projetos
    foreach ($template in $script:ProjectTemplates) {
        $projectName = "$script:SolutionName.$($template.Name)"
        $command = "new $($template.Type) -n `"$projectName`" --framework net8.0 $($template.Args)".Trim()
        
        try {
            Invoke-DotNetCommand $command -SuppressOutput
            Invoke-DotNetCommand "sln $script:SolutionName.sln add .\$projectName\$projectName.csproj" -SuppressOutput
            $script:CreatedProjects += $projectName
            Write-LogMessage "Projeto $projectName criado e adicionado à solution" -Type Success
        }
        catch {
            Write-LogMessage "Erro ao criar projeto $projectName" -Type Error
            throw
        }
    }
}

function Add-Dependencies {
    Write-LogMessage "Configurando dependências entre projetos..." -Type Info
    
    foreach ($projectKey in $script:Dependencies.Keys) {
        $projectName = "$script:SolutionName.$projectKey"
        
        try {
            Set-Location ".\$projectName"
            
            foreach ($dependency in $script:Dependencies[$projectKey]) {
                $dependencyName = "$script:SolutionName.$dependency"
                Invoke-DotNetCommand "add reference ..\$dependencyName\$dependencyName.csproj" -SuppressOutput
            }
            
            Write-LogMessage "Dependências configuradas para $projectName" -Type Success
            Set-Location ".."
        }
        catch {
            Write-LogMessage "Erro ao configurar dependências para $projectName" -Type Error
            Set-Location ".."
            throw
        }
    }
}

function Install-Packages {
    Write-LogMessage "Instalando pacotes NuGet..." -Type Info
    
    $packagesToInstall = if ($script:Minimal) { $script:BasePackages } else { 
        # Merge base packages with enterprise packages
        $merged = @{}
        foreach ($key in $script:BasePackages.Keys) {
            $merged[$key] = $script:BasePackages[$key] + ($script:EnterprisePackages[$key] ?? @())
        }
        $merged
    }
    
    # Adicionar pacote do banco de dados específico
    if ($script:DbChoice -in $script:RelationalDbs) {
        $packagesToInstall["Infrastructure"] += $script:SelectedDb.Provider
    } elseif ($script:DbChoice -eq 6) { # MongoDB
        $packagesToInstall["Infrastructure"] += "MongoDB.Driver"
    }
    
    foreach ($projectKey in $packagesToInstall.Keys) {
        $projectName = "$script:SolutionName.$projectKey"
        
        try {
            Set-Location ".\$projectName"
            
            foreach ($package in $packagesToInstall[$projectKey]) {
                try {
                    Invoke-DotNetCommand "add package $package" -SuppressOutput
                }
                catch {
                    Write-LogMessage "Falha ao instalar pacote $package no projeto $projectName" -Type Warning
                }
            }
            
            Write-LogMessage "Pacotes instalados para $projectName" -Type Success
            Set-Location ".."
        }
        catch {
            Write-LogMessage "Erro ao instalar pacotes para $projectName" -Type Warning
            Set-Location ".."
        }
    }
}

function New-FolderStructure {
    Write-LogMessage "Criando estrutura de pastas..." -Type Info
    
    foreach ($projectKey in $script:FolderStructure.Keys) {
        $projectName = "$script:SolutionName.$projectKey"
        
        foreach ($folder in $script:FolderStructure[$projectKey]) {
            $fullPath = Join-Path ".\$projectName" $folder
            New-DirectorySafe -Path $fullPath | Out-Null
        }
        
        Write-LogMessage "Estrutura de pastas criada para $projectName" -Type Success
    }
    
    # Criar pastas específicas para schemas (apenas para bancos relacionais)
    if ($script:DbChoice -in $script:RelationalDbs -and $script:Schemas) {
        foreach ($schema in $script:Schemas) {
            if (![string]::IsNullOrWhiteSpace($schema)) {
                $schemaPath = Join-Path ".\$script:SolutionName.Infrastructure\Models" $schema.Trim()
                New-DirectorySafe -Path $schemaPath | Out-Null
            }
        }
        Write-LogMessage "Pastas de schemas criadas" -Type Success
    }
}

function Initialize-Database {
    if ($script:DbChoice -notin $script:RelationalDbs -or !$script:ConnectionString) {
        return
    }
    
    Write-LogMessage "Configurando banco de dados..." -Type Info
    
    # Criar appsettings para diferentes ambientes
    $environments = @("", "Development", "Production")
    
    foreach ($env in $environments) {
        $suffix = if ($env) { ".$env" } else { "" }
        $appSettingsPath = ".\$script:SolutionName.Api\appsettings$suffix.json"
        
        try {
            if (Test-Path $appSettingsPath) {
                $appSettings = Get-Content -Path $appSettingsPath -Raw | ConvertFrom-Json
            } else {
                $appSettings = [PSCustomObject]@{}
            }
            
            if (-not $appSettings.ConnectionStrings) {
                $appSettings | Add-Member -Type NoteProperty -Name ConnectionStrings -Value @{}
            }
            
            $connectionValue = if ($env -eq "Production") { 
                "CONFIGURE_IN_PRODUCTION" 
            } else { 
                $script:ConnectionString 
            }
            
            $appSettings.ConnectionStrings | Add-Member -Type NoteProperty -Name $script:ConnectionName -Value $connectionValue -Force
            $appSettings | ConvertTo-Json -Depth 32 | Set-Content -Path $appSettingsPath
            
            Write-LogMessage "Connection string adicionada ao appsettings$suffix.json" -Type Success
        }
        catch {
            Write-LogMessage "Erro ao atualizar appsettings$suffix.json: $($_.Exception.Message)" -Type Warning
        }
    }
}

function Invoke-EntityFrameworkScaffold {
    if ($script:SkipScaffolding -or $script:DbChoice -notin $script:RelationalDbs -or !$script:ConnectionString) {
        return
    }
    
    Write-LogMessage "Executando scaffolding do Entity Framework..." -Type Info
    
    try {
        Set-Location ".\$script:SolutionName.Infrastructure"
        
        $contextName = $script:SelectedDb.Context -replace "DbContext", "" + "DbContext"
        $scaffoldCommand = "ef dbcontext scaffold `"$script:ConnectionString`" $($script:SelectedDb.Provider) -o Models -c $contextName --force"
        
        if ($script:Schemas) {
            $schemaParam = ($script:Schemas -join ",")
            $scaffoldCommand += " --schema $schemaParam"
        }
        
        if ($script:Tables) {
            $tableParam = ($script:Tables -join ",")
            $scaffoldCommand += " --table $tableParam"
        }
        
        Invoke-DotNetCommand $scaffoldCommand
        Write-LogMessage "Scaffolding do Entity Framework concluído" -Type Success
        
        Set-Location ".."
    }
    catch {
        Write-LogMessage "Erro durante o scaffolding: $($_.Exception.Message)" -Type Warning
        Set-Location ".."
    }
}

function New-BuildScripts {
    Write-LogMessage "Criando scripts de build..." -Type Info
    
    # Script de build
    $buildScript = @"
#!/usr/bin/env pwsh
# build.ps1 - Script de build para $script:SolutionName

param(
    [switch]`$Clean,
    [switch]`$Test,
    [switch]`$Pack,
    [string]`$Configuration = "Release"
)

Write-Host "🔨 Iniciando build da solution $script:SolutionName..." -ForegroundColor Cyan

if (`$Clean) {
    Write-Host "🧹 Limpando solution..." -ForegroundColor Yellow
    dotnet clean
}

Write-Host "📦 Restaurando pacotes..." -ForegroundColor Yellow
dotnet restore

Write-Host "🔨 Compilando solution..." -ForegroundColor Yellow
dotnet build --configuration `$Configuration --no-restore

if (`$Test) {
    Write-Host "🧪 Executando testes..." -ForegroundColor Yellow
    dotnet test --configuration `$Configuration --no-build --verbosity normal
}

if (`$Pack) {
    Write-Host "📦 Criando pacotes..." -ForegroundColor Yellow
    dotnet pack --configuration `$Configuration --no-build
}

Write-Host "✅ Build concluído!" -ForegroundColor Green
"@

    $buildScript | Out-File -FilePath ".\scripts\build.ps1" -Encoding UTF8
    
    # Script de desenvolvimento
    $devScript = @"
#!/usr/bin/env pwsh
# dev.ps1 - Script de desenvolvimento para $script:SolutionName

param(
    [ValidateSet("run", "watch", "test", "migrate", "seed")]
    [string]`$Command = "run"
)

switch (`$Command) {
    "run" {
        Write-Host "🚀 Executando aplicação..." -ForegroundColor Green
        Set-Location "$script:SolutionName.Api"
        dotnet run
    }
    "watch" {
        Write-Host "👀 Executando em modo watch..." -ForegroundColor Green  
        Set-Location "$script:SolutionName.Api"
        dotnet watch run
    }
    "test" {
        Write-Host "🧪 Executando testes em modo watch..." -ForegroundColor Green
        Set-Location "$script:SolutionName.Tests"
        dotnet watch test
    }
    "migrate" {
        Write-Host "🗄️ Aplicando migrações..." -ForegroundColor Green
        Set-Location "$script:SolutionName.Infrastructure"
        dotnet ef database update
    }
    "seed" {
        Write-Host "🌱 Executando seed de dados..." -ForegroundColor Green
        # Implementar conforme necessário
        Write-Host "Seed não implementado ainda" -ForegroundColor Yellow
    }
}
"@

    $devScript | Out-File -FilePath ".\scripts\dev.ps1" -Encoding UTF8
    Write-LogMessage "Scripts de build criados em ./scripts/" -Type Success
}

function New-DocumentationFiles {
    Write-LogMessage "Criando arquivos de documentação..." -Type Info
    
    # README.md
    $readmeContent = @"
# $script:SolutionName

## 📋 Sobre o Projeto

Este projeto foi gerado usando Clean Architecture com as seguintes tecnologias e padrões:

## 🏗️ Arquitetura

### Camadas

- **$script:SolutionName.Api**: Camada de apresentação (Controllers, Middlewares, Filters)
- **$script:SolutionName.Application**: Camada de aplicação (CQRS, Services, Validators)  
- **$script:SolutionName.Domain**: Camada de domínio (Entities, Value Objects, Aggregates)
- **$script:SolutionName.Infrastructure**: Camada de infraestrutura (Data Access, External Services)
- **$script:SolutionName.Api.Contracts**: Contratos da API (DTOs, Examples)
- **$script:SolutionName.Tests**: Testes unitários e de integração

### Padrões Implementados

- Clean Architecture
- CQRS (Command Query Responsibility Segregation)
- Repository Pattern
- Unit of Work Pattern
- Dependency Injection
- Domain Events

## 🛠️ Tecnologias

- **.NET 8**: Framework principal
- **Entity Framework Core**: ORM para acesso a dados
- **$($script:SelectedDb.Name)**: Banco de dados principal
- **MediatR**: Implementação de CQRS e Mediator Pattern
- **AutoMapper**: Mapeamento entre objetos
- **FluentValidation**: Validação de dados
- **Serilog**: Logging estruturado
- **xUnit**: Framework de testes
- **Swagger/OpenAPI**: Documentação da API

## 🚀 Como executar

### Pré-requisitos

- .NET 8 SDK
- $($script:SelectedDb.Name) (configurado e rodando)

### Configuração

1. Configure a string de conexão no appsettings.Development.json
2. Execute as migrações (se aplicável):
   ```bash
   ./scripts/dev.ps1 migrate
   ```

### Execução

```bash
# Modo desenvolvimento
./scripts/dev.ps1 run

# Modo watch (hot reload)
./scripts/dev.ps1 watch

# Executar testes
./scripts/dev.ps1 test
```

### Build

```bash
# Build simples
./scripts/build.ps1

# Build com testes
./scripts/build.ps1 -Test

# Build completo (clean + build + test + pack)
./scripts/build.ps1 -Clean -Test -Pack
```

## 📚 Documentação da API

A documentação da API estará disponível em:
- **Swagger UI**: https://localhost:5001/swagger (desenvolvimento)
- **OpenAPI**: https://localhost:5001/swagger/v1/swagger.json

## 🗂️ Estrutura de Pastas

```
$script:SolutionName/
├── docs/                          # Documentação
├── scripts/                       # Scripts de build e desenvolvimento
├── $script:SolutionName.Api/      # Camada de apresentação
├── $script:SolutionName.Application/ # Lógica de aplicação
├── $script:SolutionName.Domain/   # Regras de negócio
├── $script:SolutionName.Infrastructure/ # Acesso a dados
├── $script:SolutionName.Api.Contracts/ # Contratos da API
└── $script:SolutionName.Tests/    # Testes
```

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a licença MIT.
"@

    $readmeContent | Out-File -FilePath "README.md" -Encoding UTF8
    Write-LogMessage "README.md criado" -Type Success
}
