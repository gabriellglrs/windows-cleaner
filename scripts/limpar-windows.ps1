#Requires -Version 5.1
# Funciona tanto como usuário comum quanto administrador

<#
.SYNOPSIS
Script melhorado para limpeza completa do sistema Windows

.DESCRIPTION
Realiza limpeza de arquivos temporários, cache, lixeira e otimizações do sistema
com logging detalhado e tratamento robusto de erros.

.PARAMETER Modo
Especifica o modo de execução: 'Completo', 'Basico' ou 'Personalizado'

.PARAMETER SemConfirmacao
Executa sem solicitar confirmação do usuário

.EXAMPLE
.\LimpezaSistema.ps1 -Modo Completo -SemConfirmacao
#>

param(
    [ValidateSet('Completo', 'Basico', 'Personalizado')]
    [string]$Modo = 'Completo',
    
    [switch]$SemConfirmacao,
    
    [string]$CaminhoLog = $null
)

# Configurações globais
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# Verificar privilégios de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Inicialização do log
function Inicializar-Log {
    $dataHora = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $pastaLogs = Join-Path $PSScriptRoot "logs"
    
    if (-not (Test-Path $pastaLogs)) {
        New-Item -ItemType Directory -Path $pastaLogs -Force | Out-Null
    }
    
    $logPath = if ($CaminhoLog) { $CaminhoLog } else { Join-Path $pastaLogs "log_limpeza_$dataHora.txt" }
    
    try {
        Start-Transcript -Path $logPath -Append -Force
        Write-Host "=== LIMPEZA DO SISTEMA INICIADA ===" -ForegroundColor Cyan
        Write-Host "Data/Hora: $(Get-Date)" -ForegroundColor Gray
        Write-Host "Usuario: $env:USERNAME" -ForegroundColor Gray
        Write-Host "Computador: $env:COMPUTERNAME" -ForegroundColor Gray
        Write-Host "Privilegios: $(if ($isAdmin) { 'Administrador' } else { 'Usuario Comum' })" -ForegroundColor $(if ($isAdmin) { 'Green' } else { 'Yellow' })
        Write-Host "Modo: $Modo" -ForegroundColor Gray
        Write-Host "Log: $logPath" -ForegroundColor Gray
        Write-Host "=" * 50 -ForegroundColor Gray
        return $logPath
    }
    catch {
        Write-Error "Erro ao inicializar log: $($_.Exception.Message)"
        return $null
    }
}

# Função melhorada para limpeza de pastas
function Limpar-Pasta {
    param(
        [string]$Caminho,
        [string]$Descricao,
        [string[]]$Exclusoes = @(),
        [int]$IdadeMinimaDias = 0,
        [switch]$ApenasArquivos
    )
    
    Write-Host "`n[$((Get-Date).ToString('HH:mm:ss'))] Processando: $Descricao" -ForegroundColor Cyan
    
    if (-not (Test-Path $Caminho)) {
        Write-Host "  [AVISO] Pasta nao encontrada: $Caminho" -ForegroundColor Yellow
        return @{ Sucesso = $false; Itens = 0; TamanhoMB = 0 }
    }
    
    try {
        $filtroIdade = if ($IdadeMinimaDias -gt 0) { 
            (Get-Date).AddDays(-$IdadeMinimaDias)
        } else { 
            Get-Date -Year 1900 
        }
        
        $parametros = @{
            Path = $Caminho
            Recurse = $true
            Force = $true
            ErrorAction = 'SilentlyContinue'
        }
        
        if ($ApenasArquivos) {
            $parametros.File = $true
        }
        
        $itens = Get-ChildItem @parametros | Where-Object {
            $_.LastWriteTime -lt $filtroIdade -and
            $_.Name -notin $Exclusoes
        }
        
        $quantidade = $itens.Count
        $tamanhoMB = if ($itens) { [math]::Round(($itens | Measure-Object -Property Length -Sum).Sum / 1MB, 2) } else { 0 }
        
        Write-Host "  [INFO] Encontrados: $quantidade itens ($tamanhoMB MB)" -ForegroundColor White
        
        if ($quantidade -eq 0) {
            Write-Host "  [OK] Nenhum item para limpar" -ForegroundColor Green
            return @{ Sucesso = $true; Itens = 0; TamanhoMB = 0 }
        }
        
        $removidos = 0
        $erros = 0
        
        foreach ($item in $itens) {
            try {
                Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction Stop
                $removidos++
            }
            catch {
                $erros++
                Write-Host "  [AVISO] Erro ao remover: $($item.Name)" -ForegroundColor Yellow
            }
        }
        
        Write-Host "  [OK] Removidos: $removidos itens | Erros: $erros" -ForegroundColor Green
        return @{ Sucesso = $true; Itens = $removidos; TamanhoMB = $tamanhoMB; Erros = $erros }
    }
    catch {
        Write-Host "  [ERRO] $($_.Exception.Message)" -ForegroundColor Red
        return @{ Sucesso = $false; Itens = 0; TamanhoMB = 0; Erro = $_.Exception.Message }
    }
}

# Função para limpeza da lixeira
function Limpar-Lixeira {
    Write-Host "`n[$((Get-Date).ToString('HH:mm:ss'))] Processando: Lixeira" -ForegroundColor Cyan
    
    try {
        # Método 1: Via Shell.Application
        $shell = New-Object -ComObject Shell.Application
        $lixeira = $shell.Namespace(0xA)
        $itens = $lixeira.Items()
        $quantidade = $itens.Count
        
        if ($quantidade -eq 0) {
            Write-Host "  [OK] Lixeira ja esta vazia" -ForegroundColor Green
            return @{ Sucesso = $true; Itens = 0 }
        }
        
        Write-Host "  [INFO] Encontrados: $quantidade itens na lixeira" -ForegroundColor White
        
        # Esvaziar lixeira
        $itens | ForEach-Object { $_.InvokeVerb("delete") }
        
        # Método 2: Via linha de comando (backup)
        & rd /s /q "$env:SystemDrive\`$Recycle.Bin" 2>$null
        
        Write-Host "  [OK] Lixeira limpa com sucesso!" -ForegroundColor Green
        return @{ Sucesso = $true; Itens = $quantidade }
    }
    catch {
        Write-Host "  [ERRO] $($_.Exception.Message)" -ForegroundColor Red
        return @{ Sucesso = $false; Itens = 0; Erro = $_.Exception.Message }
    }
}

# Função para gerenciar processos
function Gerenciar-Processos {
    param([string[]]$NomesProcessos)
    
    Write-Host "`n[$((Get-Date).ToString('HH:mm:ss'))] Gerenciando processos..." -ForegroundColor Cyan
    
    $resultados = @()
    
    foreach ($nome in $NomesProcessos) {
        try {
            $processos = Get-Process -Name $nome -ErrorAction SilentlyContinue
            
            if ($processos) {
                Write-Host "  [INFO] Encerrando: $nome ($($processos.Count) instancia(s))" -ForegroundColor Yellow
                $processos | Stop-Process -Force -ErrorAction SilentlyContinue
                $resultados += @{ Processo = $nome; Sucesso = $true; Instancias = $processos.Count }
            } else {
                Write-Host "  [INFO] $nome nao esta em execucao" -ForegroundColor Gray
                $resultados += @{ Processo = $nome; Sucesso = $true; Instancias = 0 }
            }
        }
        catch {
            Write-Host "  [ERRO] Erro ao encerrar $nome" -ForegroundColor Red
            $resultados += @{ Processo = $nome; Sucesso = $false; Erro = $_.Exception.Message }
        }
    }
    
    return $resultados
}

# Função para limpeza de registros
function Limpar-Registros {
    Write-Host "`n[$((Get-Date).ToString('HH:mm:ss'))] Limpando registros do sistema..." -ForegroundColor Cyan
    
    $chaves = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths',
        'HKCU:\Software\Microsoft\Internet Explorer\TypedURLs'
    )
    
    $limpas = 0
    
    foreach ($chave in $chaves) {
        try {
            if (Test-Path $chave) {
                Remove-Item -Path $chave -Recurse -Force -ErrorAction SilentlyContinue
                $limpas++
                Write-Host "  [OK] Limpa: $chave" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  [AVISO] Erro: $chave" -ForegroundColor Yellow
        }
    }
    
    Write-Host "  [INFO] Registros limpos: $limpas" -ForegroundColor White
    return $limpas
}

# Função para otimizações do sistema
function Otimizar-Sistema {
    Write-Host "`n[$((Get-Date).ToString('HH:mm:ss'))] Executando otimizacoes..." -ForegroundColor Cyan
    
    # Limpar cache DNS
    try {
        & ipconfig /flushdns | Out-Null
        Write-Host "  [OK] Cache DNS limpo" -ForegroundColor Green
    }
    catch {
        Write-Host "  [AVISO] Erro ao limpar cache DNS" -ForegroundColor Yellow
    }
    
    # Limpar cache de ícones
    try {
        & ie4uinit.exe -ClearIconCache | Out-Null
        Write-Host "  [OK] Cache de icones limpo" -ForegroundColor Green
    }
    catch {
        Write-Host "  [AVISO] Erro ao limpar cache de icones" -ForegroundColor Yellow
    }
    
    # Executar limpeza de disco (apenas se disponível)
    if (Get-Command cleanmgr -ErrorAction SilentlyContinue) {
        try {
            Write-Host "  [INFO] Executando limpeza de disco..." -ForegroundColor Yellow
            & cleanmgr /sagerun:1 | Out-Null
            Write-Host "  [OK] Limpeza de disco concluida" -ForegroundColor Green
        }
        catch {
            Write-Host "  [AVISO] Erro na limpeza de disco" -ForegroundColor Yellow
        }
    }
}

# Função principal
function Executar-Limpeza {
    param([string]$Modo)
    
    $relatorio = @{
        TotalItens = 0
        TotalTamanhoMB = 0
        Operacoes = @()
        Inicio = Get-Date
    }
    
    # Definir locais para limpeza baseado no modo
    $locaisLimpeza = switch ($Modo) {
        'Basico' {
            @(
                @{ Caminho = "$env:TEMP"; Descricao = "Temp do Usuario"; IdadeMinimaDias = 0 },
                @{ Caminho = "$env:USERPROFILE\AppData\Local\Temp"; Descricao = "Temp Local do Usuario"; IdadeMinimaDias = 0 }
            )
        }
        'Completo' {
            $locaisBase = @(
                @{ Caminho = "$env:TEMP"; Descricao = "Temp do Usuario"; IdadeMinimaDias = 0 },
                @{ Caminho = "$env:USERPROFILE\AppData\Local\Temp"; Descricao = "Temp Local do Usuario"; IdadeMinimaDias = 0 },
                @{ Caminho = "$env:LOCALAPPDATA\Microsoft\Windows\WebCache"; Descricao = "Cache do Edge/IE"; IdadeMinimaDias = 0 },
                @{ Caminho = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"; Descricao = "Cache do Chrome"; IdadeMinimaDias = 0 },
                @{ Caminho = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"; Descricao = "Cache do Firefox"; IdadeMinimaDias = 0; ApenasArquivos = $true }
            )
            
            # Adicionar locais que requerem privilégios administrativos
            if ($isAdmin) {
                $locaisBase += @(
                    @{ Caminho = "$env:SystemRoot\Temp"; Descricao = "Temp do Sistema"; IdadeMinimaDias = 0 },
                    @{ Caminho = "C:\Windows\SoftwareDistribution\Download"; Descricao = "Cache de Atualizacoes"; IdadeMinimaDias = 7 },
                    @{ Caminho = "$env:SystemRoot\Logs"; Descricao = "Logs do Sistema"; IdadeMinimaDias = 30; ApenasArquivos = $true }
                )
            } else {
                Write-Host "[INFO] Algumas operacoes foram omitidas (requer privilegios administrativos)" -ForegroundColor Yellow
            }
            
            $locaisBase
        }
        'Personalizado' {
            # Solicitar ao usuário quais locais limpar
            Write-Host "Modo personalizado nao implementado nesta versao" -ForegroundColor Yellow
            return
        }
    }
    
    # Executar limpeza dos locais
    foreach ($local in $locaisLimpeza) {
        $parametros = @{
            Caminho = $local.Caminho
            Descricao = $local.Descricao
            IdadeMinimaDias = $local.IdadeMinimaDias
        }
        
        if ($local.ApenasArquivos) {
            $parametros.ApenasArquivos = $true
        }
        
        $resultado = Limpar-Pasta @parametros
        $relatorio.Operacoes += $resultado
        $relatorio.TotalItens += $resultado.Itens
        $relatorio.TotalTamanhoMB += $resultado.TamanhoMB
    }
    
    # Limpeza da lixeira
    if ($Modo -eq 'Completo') {
        $resultadoLixeira = Limpar-Lixeira
        $relatorio.Operacoes += $resultadoLixeira
        $relatorio.TotalItens += $resultadoLixeira.Itens
    }
    
    # Gerenciar processos
    $processosParaEncerrar = @('msedge', 'chrome', 'firefox', 'Teams', 'OneDrive', 'Spotify', 'Discord')
    $resultadosProcessos = Gerenciar-Processos -NomesProcessos $processosParaEncerrar
    $relatorio.Operacoes += $resultadosProcessos
    
    # Limpeza de registros e otimizações (apenas no modo completo)
    if ($Modo -eq 'Completo') {
        $registrosLimpos = Limpar-Registros
        $relatorio.RegistrosLimpos = $registrosLimpos
        
        # Otimizações do sistema (algumas requerem admin)
        if ($isAdmin) {
            Otimizar-Sistema
        } else {
            Write-Host "`n[INFO] Algumas otimizacoes foram omitidas (requer privilegios administrativos)" -ForegroundColor Yellow
        }
    }
    
    return $relatorio
}

# Função para exibir relatório final
function Exibir-Relatorio {
    param($Relatorio)
    
    $duracao = (Get-Date) - $Relatorio.Inicio
    
    Write-Host "`n" + "=" * 50 -ForegroundColor Cyan
    Write-Host "RELATORIO FINAL DA LIMPEZA" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "[INFO] Total de itens removidos: $($Relatorio.TotalItens)" -ForegroundColor White
    Write-Host "[INFO] Espaco liberado: $($Relatorio.TotalTamanhoMB) MB" -ForegroundColor White
    Write-Host "[INFO] Duracao: $($duracao.ToString('mm\:ss'))" -ForegroundColor White
    Write-Host "[OK] Operacoes bem-sucedidas: $($Relatorio.Operacoes.Where({$_.Sucesso}).Count)" -ForegroundColor Green
    Write-Host "[ERRO] Operacoes com erro: $($Relatorio.Operacoes.Where({-not $_.Sucesso}).Count)" -ForegroundColor Red
    Write-Host "=" * 50 -ForegroundColor Cyan
}

# EXECUÇÃO PRINCIPAL
try {
    # Inicializar logging
    $logPath = Inicializar-Log
    
    # Informar sobre privilégios se não for administrador
    if (-not $isAdmin) {
        Write-Host "`n[AVISO] Executando como usuario comum" -ForegroundColor Yellow
        Write-Host "Algumas operacoes podem ser limitadas. Para limpeza completa, execute como Administrador." -ForegroundColor Yellow
    }
    
    # Solicitar confirmação se necessário
    if (-not $SemConfirmacao) {
        Write-Host "`n[AVISO] Este script ira executar limpeza no modo '$Modo'" -ForegroundColor Yellow
        Write-Host "Isso pode remover arquivos temporarios e encerrar processos." -ForegroundColor Yellow
        $confirmacao = Read-Host "`nDeseja continuar? (s/N)"
        
        if ($confirmacao -ne 's' -and $confirmacao -ne 'S') {
            Write-Host "Operacao cancelada pelo usuario." -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Executar limpeza
    $relatorio = Executar-Limpeza -Modo $Modo
    
    # Exibir relatório
    Exibir-Relatorio -Relatorio $relatorio
    
    Write-Host "`n[OK] Limpeza concluida com sucesso!" -ForegroundColor Green
    if ($logPath) {
        Write-Host "[INFO] Log salvo em: $logPath" -ForegroundColor Cyan
    }
}
catch {
    Write-Host "`n[ERRO] Erro critico durante a execucao:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}
finally {
    # Parar transcription se estiver ativa
    try {
        Stop-Transcript -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorar erros ao parar transcript
    }
}