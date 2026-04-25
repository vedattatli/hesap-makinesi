param(
    [string]$FlutterPath = 'C:\src\flutter\bin\flutter.bat'
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$stagingRoot = 'C:\codex_projects\hesap_makinesi_windows_build'
$outputRoot = Join-Path $projectRoot 'artifacts\windows'

if (Test-Path $stagingRoot) {
    Remove-Item $stagingRoot -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $stagingRoot | Out-Null
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$null = robocopy $projectRoot $stagingRoot /E /XD .git .dart_tool build .idea artifacts
if ($LASTEXITCODE -gt 7) {
    throw "Robocopy failed with exit code $LASTEXITCODE."
}

Push-Location $stagingRoot
try {
    & $FlutterPath pub get
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter pub get failed.'
    }

    & $FlutterPath build windows
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter build windows failed.'
    }

    $builtExe = Join-Path $stagingRoot 'build\windows\x64\runner\Release\hesap_makinesi.exe'
    if (-not (Test-Path $builtExe)) {
        throw 'Windows executable was not produced.'
    }

    Copy-Item (Join-Path $stagingRoot 'build\windows\x64\runner\Release\*') $outputRoot -Recurse -Force
}
finally {
    Pop-Location
}

Write-Host "Windows build copied to: $outputRoot"
