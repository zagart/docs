param([switch]$Daemon)
$NoDaemon = if (-not $Daemon) { "--no-daemon" } else { "" }

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$DocsSite = $PSScriptRoot

Write-Host "=== Generating API documentation ===" -ForegroundColor Cyan

function Run-Dokka([string]$ProjectName, [string]$ModuleTask, [string]$OutputRelPath, [string]$TargetSubDir) {
    $ProjectDir = Join-Path $WorkspaceRoot $ProjectName
    $SourceDir = Join-Path $ProjectDir $OutputRelPath
    $TargetDir = Join-Path $DocsSite $ProjectName
    if ($TargetSubDir) { $TargetDir = Join-Path $TargetDir $TargetSubDir }

    Write-Host "`n>>> $ProjectName ($ModuleTask)" -ForegroundColor Yellow
    Push-Location $ProjectDir
    try {
        $gradlew = Join-Path $ProjectDir "gradlew.bat"
        if (-not (Test-Path $gradlew)) {
            Write-Warning "gradlew.bat not found in $ProjectDir"
            return
        }

        & $gradlew $ModuleTask $NoDaemon 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "FAILED: $ProjectName $ModuleTask (exit code $LASTEXITCODE)"
            return
        }

        Write-Host "  Copying docs to $TargetDir" -ForegroundColor Gray
        if (Test-Path $TargetDir) { Remove-Item -LiteralPath $TargetDir -Recurse -Force }
        Copy-Item -LiteralPath $SourceDir -Destination $TargetDir -Recurse -Force
        Write-Host "  Done" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

Run-Dokka "navigation" ":core:dokkaGenerate"    "core/build/dokka/html" $null
Run-Dokka "keystone"   ":core:dokkaGenerate"    "core/build/dokka/html" $null

# Design has two library modules
Run-Dokka "design" ":ui:dokkaGenerate"      "ui/build/dokka/html"      "ui"
Run-Dokka "design" ":builder:dokkaGenerate" "builder/build/dokka/html" "builder"

Write-Host "`n=== Documentation assembled in docs-site/ ===" -ForegroundColor Cyan