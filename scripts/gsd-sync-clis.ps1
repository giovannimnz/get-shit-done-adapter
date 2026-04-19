#Requires -Version 5.1
<#
.SYNOPSIS
    GSD Sync CLIs script for Windows (PowerShell)
.DESCRIPTION
    Synchronizes GSD configuration across CLI tools (Qoder, iFlow, Qwen).
    Equivalent to gsd-sync-clis.sh for Windows environments.
.PARAMETER UpdateSource
    Update source GSD in .claude (local).
.PARAMETER Quiet
    Suppress output.
#>

[CmdletBinding()]
param(
    [switch]$UpdateSource,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

$ScriptPath = $MyInvocation.MyCommand.Definition
$RootDir = Resolve-Path (Join-Path (Split-Path -Parent $ScriptPath) '..')

function Write-Log {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message
    }
}

# Check for node
try {
    $null = Get-Command node -ErrorAction Stop
}
catch {
    Write-Error 'Erro: node nao encontrado no PATH.'
    exit 1
}

# Create lock directory
$iflowDir = Join-Path $RootDir '.iflow'
if (-not (Test-Path $iflowDir)) {
    New-Item -ItemType Directory -Path $iflowDir -Force | Out-Null
}

$LockDir = Join-Path $iflowDir '.gsd-sync.lock'
$acquired = $false

for ($i = 0; $i -lt 50; $i++) {
    try {
        if (-not (Test-Path $LockDir)) {
            New-Item -ItemType Directory -Path $LockDir -Force | Out-Null
            $acquired = $true
            break
        }
    }
    catch {
        Start-Sleep -Milliseconds 100
    }
}

if (-not $acquired) {
    Write-Error "Erro: nao consegui adquirir lock de sync em $LockDir"
    exit 1
}

$BridgeLogFile = ''

$cleanup = {
    if (Test-Path $LockDir) {
        Remove-Item -Path $LockDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($BridgeLogFile -and (Test-Path $BridgeLogFile)) {
        Remove-Item -Path $BridgeLogFile -Force -ErrorAction SilentlyContinue
    }
}

try {
    # Step 1: Update source or skip
    if ($UpdateSource) {
        Write-Log '[1/3] Atualizando GSD fonte em .claude (local)...'
        Push-Location $RootDir
        try {
            npx -y get-shit-done-cc@latest --claude --local
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Log '[1/3] Pulando update da fonte (.claude).'
    }

    # Step 2: Generate iFlow bridge
    Write-Log '[2/3] Gerando bridge iFlow (.iflow) a partir de .claude...'
    $tempFile = [System.IO.Path]::GetTempFileName()
    $BridgeLogFile = "$tempFile.log"

    Push-Location $RootDir
    try {
        $bridgeScript = Join-Path $RootDir 'scripts/gsd-iflow-bridge.mjs'
        $bridgeOutput = node $bridgeScript 2>&1
        $bridgeOutput | Out-File -FilePath $BridgeLogFile -Encoding UTF8
        if (-not $Quiet) {
            $bridgeOutput
        }
    }
    finally {
        Pop-Location
    }

    # Step 3: Qoder uses .claude directly
    Write-Log '[3/4] Qoder usa .claude diretamente com --with-claude-config'

    # Step 4: Sync GSD context to Qwen
    Write-Log '[4/4] Sincronizando contexto GSD -> Qwen...'
    $qwenBridge = Join-Path $RootDir 'scripts/gsd-qwen-bridge.mjs'
    if (Test-Path $qwenBridge) {
        try {
            Push-Location $RootDir
            node $qwenBridge 2>$null
            Pop-Location
        }
        catch {
            Write-Log '  (aviso: sincronizacao Qwen falhou, continuando)'
        }
    }
    else {
        Write-Log '  (bridge Qwen nao encontrado, pulando)'
    }

    Write-Log 'Pronto.'

    if (-not $Quiet) {
        Write-Host ''
        Write-Host 'Uso recomendado:'
        Write-Host '  - Qoder:  .\scripts\qoder-gsd.ps1 -WorkDir ''$RootDir'''
        Write-Host '  - iFlow:  .\scripts\iflow-gsd.ps1'
        Write-Host '  - Qwen:   .\scripts\qwen-gsd.ps1'
    }
}
finally {
    & $cleanup
}
