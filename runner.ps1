<#
.SYNOPSIS
    Runner unico para execucao de testes Hoppscotch
#>

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptPath "expandtesting_env.json"
$reportFile = Join-Path $scriptPath "reports\report.xml"
$tempDir = Join-Path $scriptPath "temp_tests"
$collectionFile = Join-Path $scriptPath "expandtesting.json"
$filterPy = Join-Path $scriptPath "filter_collection.py"
$delay = 1000

if (-not (Test-Path $collectionFile)) {
    Write-Host "Error: $collectionFile not found." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

function Normalize-TestCode {
    param([string]$value)

    if (-not $value) {
        return $null
    }

    if ($value -match '^TC\d+$') {
        return $value
    }

    if ($value -match '^\d+$') {
        $num = [int]$value
        $padded = $num.ToString('000')
        return "TC$padded"
    }

    return $null
}

function Create-FilteredCollection {
    param(
        [string]$FilterType,
        [string]$FilterValue,
        [string]$Description
    )

    Write-Host "`n=== $Description ===" -ForegroundColor Cyan

    $tempFile = Join-Path $tempDir "filtered_$(Get-Random).json"

    python $filterPy $collectionFile $tempFile $FilterType $FilterValue

    if ($LASTEXITCODE -ne 0) {
        Write-Host "No tests found." -ForegroundColor Yellow
        return $null
    }

    $filtered = Get-Content $tempFile | ConvertFrom-Json
    Write-Host "Tests found: $($filtered.requests.Count)" -ForegroundColor Green
    $filtered.requests | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor Gray }

    return $tempFile
}

$executionMode = $null
$singleCase = $null
$multipleCases = @()
$category = $null
$enableJira = $false
$convertReport = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]

    switch -Regex ($arg) {
        '^-all$' {
            if ($executionMode) { Write-Host "Error: execution options are exclusive." -ForegroundColor Red; exit 1 }
            $executionMode = 'all'
        }
        '^-i$' {
            if ($executionMode) { Write-Host "Error: execution options are exclusive." -ForegroundColor Red; exit 1 }
            if ($i + 1 -ge $args.Count) { Write-Host "Error: -i requires a test number." -ForegroundColor Red; exit 1 }
            $singleCase = Normalize-TestCode $args[$i + 1]
            if (-not $singleCase) { Write-Host "Error: invalid test number for -i." -ForegroundColor Red; exit 1 }
            $executionMode = 'single'
            $i++
        }
        '^-m-' {
            if ($executionMode) { Write-Host "Error: execution options are exclusive." -ForegroundColor Red; exit 1 }
            $raw = $arg.Substring(3)
            $parts = $raw.Split('-', [System.StringSplitOptions]::RemoveEmptyEntries)
            if ($parts.Count -eq 0) { Write-Host "Error: -m must include test numbers." -ForegroundColor Red; exit 1 }
            foreach ($part in $parts) {
                $code = Normalize-TestCode $part
                if (-not $code) { Write-Host "Error: invalid test number in -m." -ForegroundColor Red; exit 1 }
                $multipleCases += $code
            }
            $executionMode = 'multiple'
        }
        '^-c-(pos|neg|full)$' {
            if ($executionMode) { Write-Host "Error: execution options are exclusive." -ForegroundColor Red; exit 1 }
            $category = $Matches[1]
            $executionMode = 'category'
        }
        '^-bt$' {
            $enableJira = $true
        }
        '^-cr$' {
            $convertReport = $true
        }
        default {
            Write-Host "Error: unknown option '$arg'." -ForegroundColor Red
            exit 1
        }
    }
}

if (-not $executionMode) {
    if ($convertReport -and -not $enableJira) {
        Write-Host "Converting report only..." -ForegroundColor Cyan
        if (-not (Test-Path $reportFile)) {
            Write-Host "Error: report.xml not found. Run tests first." -ForegroundColor Red
            exit 1
        }
        node (Join-Path $scriptPath "convert-report.js")
        exit $LASTEXITCODE
    }

    $executionMode = 'all'
}

$collectionToRun = $null

switch ($executionMode) {
    'all' {
        $collectionToRun = $collectionFile
    }
    'single' {
        $collectionToRun = Create-FilteredCollection -FilterType "test_case" -FilterValue $singleCase -Description "Running: $singleCase"
    }
    'multiple' {
        $list = $multipleCases -join ','
        $collectionToRun = Create-FilteredCollection -FilterType "multiple" -FilterValue $list -Description "Running: $($multipleCases -join ', ')"
    }
    'category' {
        if ($category -eq 'full') {
            $collectionToRun = $collectionFile
        } elseif ($category -eq 'neg') {
            $collectionToRun = Create-FilteredCollection -FilterType "negative" -FilterValue "" -Description "Running NEGATIVE tests"
        } elseif ($category -eq 'pos') {
            $collectionToRun = Create-FilteredCollection -FilterType "positive" -FilterValue "" -Description "Running POSITIVE tests"
        }
    }
}

if (-not $collectionToRun) {
    exit 1
}

try {
    hopp test -e $envFile -d $delay $collectionToRun --reporter-junit $reportFile
} finally {
    if ($collectionToRun -ne $collectionFile) {
        Remove-Item $collectionToRun -ErrorAction SilentlyContinue
    }
}

if ($convertReport) {
    node (Join-Path $scriptPath "convert-report.js")
}

if ($enableJira) {
    node (Join-Path $scriptPath "jira-reporter.js")
}

Write-Host "`nCompleted!" -ForegroundColor Green
