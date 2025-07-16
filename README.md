
<img width=100% src="https://capsule-render.vercel.app/api?type=waving&color=4C89F8&height=120&section=header"/>

<img width="1584" height="396" alt="LinkedIn cover - 29" src="https://github.com/user-attachments/assets/1a289448-2b68-4e72-9c32-90d1663cf5d2" />

# Script de Limpeza Windows PowerShell

Um script robusto e abrangente para limpeza automática do sistema Windows, desenvolvido em PowerShell com logging detalhado e tratamento de erros.

## 🚀 Características

- **Múltiplos modos de execução**: Básico, Completo e Personalizado
- **Detecção automática de privilégios**: Adapta-se a usuários comuns ou administradores
- **Logging detalhado**: Registra todas as operações realizadas
- **Tratamento robusto de erros**: Continua a execução mesmo com falhas pontuais
- **Relatório final**: Exibe estatísticas completas da limpeza
- **Segurança**: Exclusões inteligentes e filtros de idade para arquivos

## 📋 Pré-requisitos

- Windows 10/11 ou Windows Server 2016+
- PowerShell 5.1 ou superior
- Permissões de leitura/escrita no diretório do script

## 🛠️ Instalação

1. **Download do Script**
   ```bash
   # Clone o repositório ou baixe o arquivo diretamente
   git clone https://github.com/seu-usuario/limpar-windows.git
   cd limpar-windows
   ```

2. **Configuração de Política de Execução** (se necessário)
   ```powershell
   # Execute como Administrador
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## 🎯 Uso

<img width="811" height="1325" alt="image" src="https://github.com/user-attachments/assets/0820e3fa-02e9-473d-aa24-48ce329d0ccc" />


### Execução Básica
```powershell
# Modo completo com confirmação
.\limpar-windows.ps1

# Modo básico sem confirmação
.\limpar-windows.ps1 -Modo Basico -SemConfirmacao

# Modo completo com log personalizado
.\limpar-windows.ps1 -Modo Completo -CaminhoLog "C:\Logs\limpeza.txt"
```

### Parâmetros Disponíveis

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `-Modo` | String | `Completo` | Define o modo de execução (`Completo`, `Basico`, `Personalizado`) |
| `-SemConfirmacao` | Switch | `$false` | Executa sem solicitar confirmação |
| `-CaminhoLog` | String | Auto | Caminho personalizado para o arquivo de log |

### Exemplos de Uso

```powershell
# Limpeza completa silenciosa
.\limpar-windows.ps1 -Modo Completo -SemConfirmacao

# Limpeza básica com log específico
.\limpar-windows.ps1 -Modo Basico -CaminhoLog "D:\manutencao\log.txt"

# Limpeza completa com confirmação (padrão)
.\limpar-windows.ps1
```

## 🔧 Modos de Operação

### Modo Básico
- **Foco**: Limpeza essencial para usuários comuns
- **Inclui**:
  - Pasta Temp do usuário (`%TEMP%`)
  - Pasta Temp local (`%USERPROFILE%\AppData\Local\Temp`)

### Modo Completo
- **Foco**: Limpeza abrangente do sistema
- **Inclui**:
  - Todas as operações do modo básico
  - Cache de navegadores (Edge, Chrome, Firefox)
  - Cache de atualizações do Windows (requer admin)
  - Logs do sistema (requer admin)
  - Limpeza da lixeira
  - Encerramento de processos específicos
  - Limpeza de registros
  - Otimizações do sistema

### Modo Personalizado
- **Status**: Em desenvolvimento
- **Propósito**: Permitir seleção granular de operações

## 🗂️ Estrutura de Pastas e Arquivos

```
projeto/
├── scripts/
│   └── limpar-windows.ps1          # Script principal
├── logs/                           # Logs gerados automaticamente
│   └── log_limpeza_YYYY-MM-DD_HH-mm-ss.txt
└── README.md                       # Esta documentação
```

## 🧹 Operações Realizadas

### Limpeza de Arquivos
- **Arquivos temporários**: Usuário e sistema
- **Cache de navegadores**: Edge, Chrome, Firefox
- **Cache de atualizações**: Windows Update
- **Logs antigos**: Sistema e aplicações
- **Lixeira**: Esvaziamento completo

### Gerenciamento de Processos
O script encerra automaticamente os seguintes processos:
- `msedge` - Microsoft Edge
- `chrome` - Google Chrome
- `firefox` - Mozilla Firefox
- `Teams` - Microsoft Teams
- `OneDrive` - Microsoft OneDrive
- `Spotify` - Spotify
- `Discord` - Discord

### Limpeza de Registros
- Histórico de execução (RunMRU)
- Caminhos digitados (TypedPaths)
- URLs digitadas (TypedURLs)

### Otimizações
- Limpeza de cache DNS
- Limpeza de cache de ícones
- Execução da limpeza de disco do Windows

## 📊 Relatório e Logging

### Arquivo de Log
- **Localização**: `logs/log_limpeza_YYYY-MM-DD_HH-mm-ss.txt`
- **Conteúdo**:
  - Informações do sistema e usuário
  - Detalhes de cada operação
  - Erros e avisos
  - Estatísticas finais

### Relatório Final
```
=====================================
RELATORIO FINAL DA LIMPEZA
=====================================
[INFO] Total de itens removidos: 1,234
[INFO] Espaco liberado: 2,456 MB
[INFO] Duracao: 02:34
[OK] Operacoes bem-sucedidas: 12
[ERRO] Operacoes com erro: 0
=====================================
```

## 🔒 Segurança e Privilégios

### Usuário Comum
- Limpeza de arquivos do perfil do usuário
- Operações básicas de cache
- Funcionalidade limitada mas segura

### Administrador
- Acesso completo ao sistema
- Limpeza de arquivos do sistema
- Otimizações avançadas

### Exclusões Inteligentes
- Arquivos essenciais do sistema
- Configurações importantes
- Dados de aplicações críticas

## ⚠️ Avisos e Limitações

### Avisos Importantes
- **Backup**: Sempre mantenha backups importantes antes da execução
- **Processos**: O script pode encerrar aplicações em execução
- **Privilégios**: Algumas operações requerem privilégios administrativos

### Limitações Conhecidas
- Modo personalizado ainda em desenvolvimento
- Algumas operações podem falhar em sistemas muito antigos
- Dependente da política de execução do PowerShell

## 🐛 Solução de Problemas

### Problemas Comuns

**Erro de Política de Execução**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Acesso Negado**
```powershell
# Execute como Administrador para operações completas
```

**Script não encontrado**
```powershell
# Verifique se está no diretório correto
Set-Location "C:\caminho\para\o\script"
```

### Logs de Erro
- Verifique o arquivo de log para detalhes específicos
- Erros não críticos são registrados mas não interrompem a execução

## 🔄 Agendamento Automático

### Agendador de Tarefas do Windows
```powershell
# Exemplo de comando para criar tarefa agendada
schtasks /create /tn "Limpeza Semanal" /tr "powershell.exe -File C:\scripts\limpar-windows.ps1 -Modo Completo -SemConfirmacao" /sc weekly /d SUN /st 02:00
```

### Script de Lote
```batch
@echo off
cd /d "C:\caminho\para\o\script"
powershell.exe -ExecutionPolicy Bypass -File "limpar-windows.ps1" -Modo Completo -SemConfirmacao
```

## 🤝 Contribuição

1. **Fork** o projeto
2. **Crie** uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. **Commit** suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. **Push** para a branch (`git push origin feature/nova-feature`)
5. **Abra** um Pull Request

## 📝 Changelog

### v1.0.0
- Lançamento inicial
- Modos Básico e Completo
- Sistema de logging
- Tratamento de erros robusto

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👥 Autor

- **Desenvolvedor**: Gabriel lucas rodrigues souza
- **Contato**: gabriellglrs@gmail.com
- **GitHub**: https://github.com/gabriellglrs
- **LinkedIn**: https://www.linkedin.com/in/gabriellglrs/

## 🙏 Agradecimentos

- Comunidade PowerShell
- Feedback dos usuários
- Contribuidores do projeto

---

**⚡ Dica**: Para melhores resultados, execute o script regularmente (semanal ou mensalmente) para manter o sistema otimizado.
 <br>

 <br>
<div align="center">
  <img src="https://github.com/user-attachments/assets/ed7208b8-6bdc-4c82-98aa-8c8cb9c1428f" height="150"/>
</div>

<img width=100% src="https://capsule-render.vercel.app/api?type=waving&color=4C89F8&height=120&section=footer"/>
