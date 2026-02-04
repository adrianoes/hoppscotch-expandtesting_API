<#
.SYNOPSIS
    Script para executar testes Hoppscotch com filtros

.PARAMETER TestCase
    Código do test case (ex: TC090)

.PARAMETER Multiple
    Array de test cases (ex: TC001,TC090)

.PARAMETER Negative
    Executa apenas testes negativos

.PARAMETER Positive
    Executa apenas testes positivos
#>

param(
    [string]$TestCase,
    [string[]]$Multiple,
    [switch]$Negative,
    [switch]$Positive,
    [string]$Collection = 'independent',
    [int]$Delay = 1000
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptPath "expandtesting_env.json"
$reportFile = Join-Path $scriptPath "reports\report.xml"
$tempDir = Join-Path $scriptPath "temp_tests"

$collectionFile = Join-Path $scriptPath "expandtesting.json"

if (-not (Test-Path $collectionFile)) {
    Write-Host "Error: $collectionFile not found!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

function Create-FilteredCollection {
    param(
        [string]$FilterType,
        [string]$FilterValue,
        [string]$Description
    )
    
    Write-Host "`n=== $Description ===" -ForegroundColor Cyan
    
    $tempFile = Join-Path $tempDir "filtered_$(Get-Random).json"
    $filterPy = Join-Path $scriptPath "filter_collection.py"
    
    # Usa Python para filtrar
    python $filterPy $collectionFile $tempFile $FilterType $FilterValue
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "No tests found." -ForegroundColor Yellow
        return $null
    }
    
    # Show found tests
    $filtered = Get-Content $tempFile | ConvertFrom-Json
    Write-Host "Tests found: $($filtered.requests.Count)" -ForegroundColor Green
    $filtered.requests | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor Gray }
    
    return $tempFile
}

if ($TestCase) {
    $tempFile = Create-FilteredCollection -FilterType "test_case" -FilterValue $TestCase -Description "Running: $TestCase"
    if ($tempFile) {
        try {
            hopp test -e $envFile -d $Delay $tempFile --reporter-junit $reportFile
        } finally {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }
} elseif ($Multiple) {
    $tempFile = Create-FilteredCollection -FilterType "multiple" -FilterValue ($Multiple -join ',') -Description "Running: $($Multiple -join ', ')"
    if ($tempFile) {
        try {
            hopp test -e $envFile -d $Delay $tempFile --reporter-junit $reportFile
        } finally {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }
} elseif ($Negative) {
    $tempFile = Create-FilteredCollection -FilterType "negative" -FilterValue "" -Description "Running NEGATIVE tests"
    if ($tempFile) {
        try {
            hopp test -e $envFile -d $Delay $tempFile --reporter-junit $reportFile
        } finally {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }
} elseif ($Positive) {
    $tempFile = Create-FilteredCollection -FilterType "positive" -FilterValue "" -Description "Running POSITIVE tests"
    if ($tempFile) {
        try {
            hopp test -e $envFile -d $Delay $tempFile --reporter-junit $reportFile
        } finally {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }
} else {
    hopp test -e $envFile -d $Delay $collectionFile --reporter-junit $reportFile
}

Write-Host "`nCompleted!" -ForegroundColor Green
