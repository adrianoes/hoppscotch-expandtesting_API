<#
.SYNOPSIS
    Scripts ultra-simplificados para execução rápida de testes

.DESCRIPTION
    Comandos de uma linha para cenários comuns
#>

param(
    [Parameter(Position=0)]
    [string]$TestCode
)

# Configuração
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$env = Join-Path $scriptPath "expandtesting_env.json"
$collection = Join-Path $scriptPath "expandtesting.json"
$delay = 1000
$report = Join-Path $scriptPath "reports\report.xml"

function Show-Help {
    Write-Host @"

=== QUICK TEST - Quick Commands ===

USAGE:
  .\quick-test.ps1 <code>         Run specific test case
  .\quick-test.ps1 all            Run all tests
  .\quick-test.ps1 neg            Run negative tests
  .\quick-test.ps1 pos            Run positive tests
  .\quick-test.ps1 help           Show this help

EXAMPLES:
  .\quick-test.ps1 TC001          Run only TC001
  .\quick-test.ps1 TC090          Run only TC090
  .\quick-test.ps1 neg            Run bad request + unauthorized
  .\quick-test.ps1 pos            Run only happy path

"@ -ForegroundColor Cyan
}

# Processa comando
switch ($TestCode.ToLower()) {
    "all" {
        Write-Host "Running ALL tests..." -ForegroundColor Cyan
        hopp test -e $env -d $delay $collection --reporter-junit $report
    }
    "neg" {
        Write-Host "Running NEGATIVE tests..." -ForegroundColor Cyan
        & (Join-Path $scriptPath "run-tests.ps1") -Negative
    }
    "pos" {
        Write-Host "Running POSITIVE tests..." -ForegroundColor Cyan
        & (Join-Path $scriptPath "run-tests.ps1") -Positive
    }
    "help" {
        Show-Help
    }
    "" {
        Show-Help
    }
    default {
        # Assume it is a test case code
        Write-Host "Running $TestCode..." -ForegroundColor Cyan
        & (Join-Path $scriptPath "run-tests.ps1") -TestCase $TestCode
    }
}
