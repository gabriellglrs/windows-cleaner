# Ativa transcrição para gerar log
$dataHora = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logPath = "..\logs\log_limpeza_$dataHora.txt"
Start-Transcript -Path $logPath -Append

Write-Host "Iniciando limpeza do sistema..." -ForegroundColor Cyan

# Função para deletar arquivos de uma pasta
function Limpar-Pasta($caminho, $descricao) {
    Write-Host "`nLimpando ${descricao}: " -NoNewline
    if (Test-Path $caminho) {
        $arquivos = Get-ChildItem -Path $caminho -Recurse -Force -ErrorAction SilentlyContinue
        $quantidade = $arquivos.Count
        Write-Host "$quantidade itens encontrados..."
        try {
            $arquivos | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "$descricao limpa com sucesso!" -ForegroundColor Green
        } catch {
            Write-Host "Erro ao limpar $descricao" -ForegroundColor Red
        }
    } else {
        Write-Host "Pasta não encontrada: $caminho" -ForegroundColor Yellow
    }
}


# Limpar Temp do Sistema
$tempSistema = "$env:SystemRoot\Temp"
Limpar-Pasta -caminho $tempSistema -descricao "Temp do Sistema"

# Limpar Temp do Usuário
$tempUsuario = "$env:TEMP"
Limpar-Pasta -caminho $tempUsuario -descricao "Temp do Usuário"

# Limpar Cache de Atualizações do Windows
$windowsUpdateCache = "C:\Windows\SoftwareDistribution\Download"
Limpar-Pasta -caminho $windowsUpdateCache -descricao "Cache de Atualizações"

# Limpar Lixeira
Write-Host "`nLimpando Lixeira..."
try {
    $lixeira = New-Object -ComObject Shell.Application
    $lixeira.Namespace(0xA).Items() | ForEach-Object { $_.InvokeVerb("delete") }
    Write-Host "Lixeira limpa com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "Erro ao limpar a lixeira" -ForegroundColor Red
}

# Encerrar processos desnecessários
function Encerrar-Processo($nome) {
    Write-Host "`nEncerrando $nome (se estiver em execução)..."
    try {
        Get-Process -Name $nome -ErrorAction SilentlyContinue | Stop-Process -Force
    } catch {
        Write-Host "$nome não estava em execução." -ForegroundColor Yellow
    }
}

Encerrar-Processo "msedge"
Encerrar-Processo "Teams"
Encerrar-Processo "OneDrive"

Write-Host "`nLimpeza concluída. Log salvo em: $logPath" -ForegroundColor Cyan
Stop-Transcript
