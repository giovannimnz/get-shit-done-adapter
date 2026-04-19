#Requires -Version 5.1
<#
.SYNOPSIS
    GSD Auto Setup script for Windows (PowerShell)
.DESCRIPTION
    Sets up symlinks, git hooks, and optionally starts watch mode for GSD adapter.
    Equivalent to gsd-auto-setup.sh for Windows environments.
.PARAMETER NoHooks
    Skip git hook installation.
.PARAMETER NoLinks
    Skip symlink creation.
.PARAMETER StartWatch
    Start watch mode after setup.
.PARAMETER NoOverride
    Skip overriding base qoder/iflow commands.
.EXAMPLE
    .\gsd-auto-setup.ps1
    .\gsd-auto-setup.ps1 -StartWatch
    .\gsd-auto-setup.ps1 -NoHooks -NoOverride
#>

[CmdletBinding()]
param(
    [switch]$NoHooks,
    [switch]$NoLinks,
    [switch]$StartWatch,
    [switch]$NoOverride
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Resolve-Path (Join-Path $ScriptDir '..')
$InstallHooks = -not $NoHooks
$InstallLinks = -not $NoLinks
$OverrideBaseCmds = -not $NoOverride

function Ensure-HookBlock {
    param(
        [string]$HookFile
    )

    $markerStart = '# >>> gsd-iflow-qoder-sync >>>'
    $markerEnd = '# <<< gsd-iflow-qoder-sync <<<'

    $hookDir = Split-Path -Parent $HookFile
    if (-not (Test-Path $hookDir)) {
        New-Item -ItemType Directory -Path $hookDir -Force | Out-Null
    }

    $projectDir = $RootDir
    $blockLines = @(
        $markerStart
        "PROJECT_DIR=`"$projectDir`""
        'if (Test-Path "$PROJECT_DIR\scripts\gsd-sync-clis.ps1") {'
        '    Push-Location "$PROJECT_DIR"'
        '    $env:GSD_SKIP_SYNC = "1"'
        '    pwsh -NoProfile -File "$PROJECT_DIR\scripts\gsd-sync-clis.ps1" -Quiet 2>$null'
        '    Pop-Location'
        '}'
        $markerEnd
    )
    $block = $blockLines -join "`n"

    if (-not (Test-Path $HookFile)) {
        $content = @"
#!/usr/bin/env pwsh
`$ErrorActionPreference = 'Stop'

$block
"@
        Set-Content -Path $HookFile -Value $content -Encoding UTF8
        return
    }

    $content = Get-Content -Path $HookFile -Raw -Encoding UTF8

    # Remove existing block if present
    $pattern = "(?m)^[ \t]*$([regex]::Escape($markerStart)).*?$([regex]::Escape($markerEnd))[ \t]*`r?`n?"
    $content = [regex]::Replace($content, $pattern, '', [System.Text.RegularExpressions.RegexOptions]::Singleline)

    # Append new block
    $content += "`n$block`n"
    Set-Content -Path $HookFile -Value $content -Encoding UTF8
}

function New-SafeLink {
    param(
        [string]$Src,
        [string]$Dst
    )

    $dstDir = Split-Path -Parent $Dst
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    # Check if link already exists and points to correct target
    if (Test-Path $Dst) {
        $existingLink = Get-Item $Dst -ErrorAction SilentlyContinue
        if ($existingLink -and $existingLink.LinkType -eq 'Junction') {
            $currentTarget = $existingLink.Target
            $desiredTarget = $Src
            if ($currentTarget -eq $desiredTarget) {
                return
            }
        }
        elseif ($existingLink -and $existingLink.LinkType -eq 'SymbolicLink') {
            $currentTarget = (Get-Item $Dst).Target
            $desiredTarget = Resolve-Path $Src -ErrorAction SilentlyContinue
            if ($currentTarget -eq $desiredTarget) {
                return
            }
        }
        elseif ($existingLink -and -not $existingLink.LinkType) {
            # Regular file exists, back it up
            $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
            $backupPath = "$Dst.backup.$timestamp"
            Move-Item -Path $Dst -Destination $backupPath -Force
        }

        # Remove stale link
        Remove-Item -Path $Dst -Force -Recurse -ErrorAction SilentlyContinue
    }

    # Create symbolic link (requires admin or Developer Mode)
    $srcResolved = Resolve-Path $Src
    New-Item -ItemType SymbolicLink -Path $Dst -Target $srcResolved -Force | Out-Null
}

function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-SymlinkPermission {
    # Try to create a test symlink to check if Developer Mode is enabled or we have admin rights
    $testDir = [System.IO.Path]::GetTempPath()
    $testLink = Join-Path $testDir 'gsd_symlink_test'
    $testTarget = Join-Path $testDir 'gsd_symlink_target'

    try {
        New-Item -ItemType File -Path $testTarget -Force | Out-Null
        New-Item -ItemType SymbolicLink -Path $testLink -Target $testTarget -Force | Out-Null
        Remove-Item $testLink -Force -ErrorAction SilentlyContinue
        Remove-Item $testTarget -Force -ErrorAction SilentlyContinue
        return $true
    }
    catch {
        Remove-Item $testLink -Force -ErrorAction SilentlyContinue
        Remove-Item $testTarget -Force -ErrorAction SilentlyContinue
        return $false
    }
}

if ($InstallLinks) {
    # Check symlink permissions
    if (-not (Test-SymlinkPermission)) {
        Write-Warning 'Symlink creation requires Administrator privileges or Windows Developer Mode.'
        Write-Warning 'Run PowerShell as Administrator or enable Developer Mode in Windows Settings.'
        Write-Warning 'Alternatively, add the scripts directory to your PATH manually.'
        Write-Host ''

        # Fallback: add scripts directory to PATH permanently
        $scriptsDir = Join-Path $RootDir 'scripts'
        $currentPath = [Environment]::GetEnvironmentVariable('PATH', 'User')

        if ($currentPath -notlike "*$scriptsDir*") {
            $newPath = "$currentPath;$scriptsDir"
            [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
            $env:PATH = "$env:PATH;$scriptsDir"
            Write-Host "[ok] scripts directory adicionado ao PATH do usuario: $scriptsDir" -ForegroundColor Green
        }
        else {
            Write-Host "[ok] scripts directory ja esta no PATH: $scriptsDir" -ForegroundColor Cyan
        }

        # Create wrapper .cmd files in scripts dir for easy access
        $wrapperMappings = @{
            'qoder-gsd.cmd'       = 'qoder-gsd.sh'
            'iflow-gsd.cmd'       = 'iflow-gsd.sh'
            'iflow1.cmd'          = 'iflow1.sh'
            'iflow2.cmd'          = 'iflow2.sh'
            'iflow3.cmd'          = 'iflow3.sh'
            'gsd-sync-clis.cmd'   = 'gsd-sync-clis.sh'
            'gsd-watch-start.cmd' = 'gsd-watch-start.sh'
            'gsd-watch-stop.cmd'  = 'gsd-watch-stop.sh'
            'gsd-watch-status.cmd' = 'gsd-watch-status.sh'
            'gsd-browser.cmd'     = 'gsd-browser-headless.sh'
        }

        foreach ($wrapper in $wrapperMappings.Keys) {
            $target = $wrapperMappings[$wrapper]
            $wrapperPath = Join-Path $scriptsDir $wrapper
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($target)

            $cmdContent = @"
@echo off
REM Wrapper for $target
call bash "%scriptsDir%\$target" %*
"@
            if (-not (Test-Path $wrapperPath)) {
                Set-Content -Path $wrapperPath -Value $cmdContent -Encoding ASCII
            }
        }

        if ($OverrideBaseCmds) {
            Set-Content -Path (Join-Path $scriptsDir 'qoder.cmd') -Value @"
@echo off
call bash "%scriptsDir%\qoder-gsd.sh" %*
"@ -Encoding ASCII
            Set-Content -Path (Join-Path $scriptsDir 'iflow.cmd') -Value @"
@echo off
call bash "%scriptsDir%\iflow1.sh" %*
"@ -Encoding ASCII
            Write-Host '[ok] override automatico de qoder e iflow->iflow1 ativado via PATH' -ForegroundColor Green
        }
    }
    else {
        # Determine bin directory (prefer .local/bin if WSL/Git Bash available, else use a GSD bin dir)
        $localBin = Join-Path $HOME '.local/bin'
        $userBin = Join-Path $HOME 'bin'

        foreach ($binDir in @($localBin, $userBin)) {
            if (-not (Test-Path $binDir)) {
                New-Item -ItemType Directory -Path $binDir -Force | Out-Null
            }
        }

        $scripts = @(
            @{ Source = 'qoder-gsd.sh';           Links = @('qoder-gsd') }
            @{ Source = 'iflow-gsd.sh';           Links = @('iflow-gsd') }
            @{ Source = 'iflow1.sh';              Links = @('iflow1') }
            @{ Source = 'iflow2.sh';              Links = @('iflow2') }
            @{ Source = 'iflow3.sh';              Links = @('iflow3') }
            @{ Source = 'gsd-sync-clis.sh';       Links = @('gsd-sync-clis') }
            @{ Source = 'gsd-watch-start.sh';     Links = @('gsd-watch-start') }
            @{ Source = 'gsd-watch-stop.sh';      Links = @('gsd-watch-stop') }
            @{ Source = 'gsd-watch-status.sh';    Links = @('gsd-watch-status') }
            @{ Source = 'gsd-browser-headless.sh'; Links = @('gsd-browser') }
        )

        foreach ($script in $scripts) {
            $srcPath = Join-Path (Join-Path $RootDir 'scripts') $script.Source
            foreach ($linkName in $script.Links) {
                New-SafeLink -Src $srcPath -Dst (Join-Path $localBin $linkName)
                New-SafeLink -Src $srcPath -Dst (Join-Path $userBin $linkName)
            }
        }

        if ($OverrideBaseCmds) {
            New-SafeLink -Src (Join-Path (Join-Path $RootDir 'scripts') 'qoder-gsd.sh') -Dst (Join-Path $userBin 'qoder')
            New-SafeLink -Src (Join-Path (Join-Path $RootDir 'scripts') 'iflow1.sh') -Dst (Join-Path $userBin 'iflow')
            Write-Host '[ok] override automatico de qoder e iflow->iflow1 ativado via ~/bin' -ForegroundColor Green
        }

        Write-Host '[ok] links em ~/.local/bin e ~/bin criados/atualizados' -ForegroundColor Green
    }
}

if ($InstallHooks) {
    # Check if we're in a git repository
    try {
        $gitRoot = git -C $RootDir rev-parse --show-toplevel 2>$null
        if ($gitRoot) {
            $hooksDir = Join-Path $gitRoot '.git/hooks'

            foreach ($hookName in @('post-merge', 'post-checkout', 'post-rewrite')) {
                $hookFile = Join-Path $hooksDir $hookName
                Ensure-HookBlock -HookFile $hookFile
            }
            Write-Host "[ok] hooks git instalados em: $hooksDir" -ForegroundColor Green
        }
    }
    catch {
        Write-Host '[warn] diretorio nao esta em um repositorio git; hooks ignorados' -ForegroundColor Yellow
    }
}

if ($StartWatch) {
    $watchScript = Join-Path (Join-Path $RootDir 'scripts') 'gsd-watch-start.sh'
    if (Test-Path $watchScript) {
        Write-Host 'Iniciando watch mode...' -ForegroundColor Cyan
        bash $watchScript
    }
    else {
        Write-Warning "Watch script nao encontrado: $watchScript"
    }
}

Write-Host ''
Write-Host 'Concluido.' -ForegroundColor Green
Write-Host 'Uso transparente: qoder / iflow (iflow = iflow1).' -ForegroundColor Cyan
Write-Host 'Multiplas instancias: iflow1 / iflow2 / iflow3.' -ForegroundColor Cyan
Write-Host 'Compatibilidade: qoder-gsd / iflow-gsd.' -ForegroundColor Cyan
