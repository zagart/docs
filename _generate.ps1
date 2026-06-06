param([switch]$Daemon)
$NoDaemon = if (-not $Daemon) { "--no-daemon" } else { "" }

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DocsSite = Join-Path $RepoRoot "docs-site"

$Projects = @(
    @{ Dir = "design";   Tasks = @(":ui:dokkaGenerate", ":builder:dokkaGenerate") }
    @{ Dir = "keystone"; Tasks = @(":core:dokkaGenerate") }
    @{ Dir = "navigation"; Tasks = @(":core:dokkaGenerate") }
)

Write-Host "=== Generating API documentation ===" -ForegroundColor Cyan

foreach ($Project in $Projects) {
    $ProjectDir = Join-Path $RepoRoot $Project.Dir

    Write-Host "`n>>> $($Project.Dir)" -ForegroundColor Yellow
    Push-Location $ProjectDir
    try {
        foreach ($Task in $Project.Tasks) {
            Write-Host "  Running $Task..." -ForegroundColor Gray
            $gradlew = Join-Path $ProjectDir "gradlew.bat"
            & $gradlew $Task $NoDaemon 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "FAILED: $Task (exit code $LASTEXITCODE)"
                continue
            }

            # Determine source and target paths
            $module = $Task.Split(':')[1]  # e.g., "ui", "core"
            $Source = Join-Path $ProjectDir "$module/build/dokka/html"

            if ($Project.Dir -eq "design") {
                $Target = Join-Path $DocsSite "design/$module"
            } else {
                $Target = Join-Path $DocsSite $Project.Dir
            }

            if (Test-Path $Target) { Remove-Item -LiteralPath $Target -Recurse -Force }
            Copy-Item -LiteralPath $Source -Destination $Target -Recurse -Force
            Write-Host "  Copied to $Target" -ForegroundColor Gray
        }
    } finally {
        Pop-Location
    }
}

# Fix ERROR CLASS references from unresolved cross-module types
Write-Host "`nFixing unresolved symbol references..." -ForegroundColor Cyan
Get-ChildItem -LiteralPath $DocsSite -Recurse -Filter "*.html" | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName)
    if ($content -match 'ERROR CLASS: Symbol not found for') {
        $content = $content -replace 'ERROR CLASS: Symbol not found for (\w+)', '$1'
        [System.IO.File]::WriteAllText($_.FullName, $content)
    }
}

# Copy landing pages and guides
$Assets = Join-Path $PSScriptRoot "docs-site-assets"
if (Test-Path $Assets) {
    Copy-Item -LiteralPath "$Assets/index.html" -Destination (Join-Path $DocsSite "") -Force
    Copy-Item -LiteralPath "$Assets/design" -Destination (Join-Path $DocsSite "design") -Recurse -Force
    Copy-Item -LiteralPath "$Assets/guides" -Destination (Join-Path $DocsSite "guides") -Recurse -Force
    Write-Host "  Landing pages and guides copied" -ForegroundColor Gray
}

Write-Host "`n=== Documentation assembled in docs-site/ ===" -ForegroundColor Cyan