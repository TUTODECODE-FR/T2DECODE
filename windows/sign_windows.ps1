# sign_windows.ps1
# Script de signature du binaire Windows TutoDeCode
# Usage : .\sign_windows.ps1

param(
    [string]$Configuration = "Release",
    [string]$PfxPath = "$PSScriptRoot\tutodecode-codesign.pfx",
    [string]$PfxPassword = ""
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  TutoDeCode — Signature Windows" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# 1. Trouver signtool.exe (Windows SDK)
$signtoolPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe"
)
$signtool = $signtoolPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $signtool) {
    $signtool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" `
        -Recurse -Filter "signtool.exe" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*x64*" } |
    Select-Object -First 1 -ExpandProperty FullName
}

if (-not $signtool) {
    Write-Error "signtool.exe introuvable. Installez le Windows SDK."
}

Write-Host "signtool : $signtool" -ForegroundColor Green

# 2. Chemin du binaire Flutter Windows
$exePath = "$PSScriptRoot\..\build\windows\x64\runner\$Configuration\tutodecode_flutter.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "Build introuvable. Compilation en cours..." -ForegroundColor Yellow
    Set-Location "$PSScriptRoot\.."
    flutter build windows --release
    Set-Location $PSScriptRoot
}

if (-not (Test-Path $exePath)) {
    Write-Error "Binaire introuvable après build : $exePath"
}

Write-Host "Binaire : $exePath" -ForegroundColor Green

# 3. Signer le fichier
Write-Host "Signature en cours..." -ForegroundColor Yellow

& $signtool sign `
    /f $PfxPath `
    /p $PfxPassword `
    /fd SHA256 `
    /tr "http://timestamp.digicert.com" `
    /td SHA256 `
    /v `
    $exePath

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCES : Binaire signe avec succes !" -ForegroundColor Green
}
else {
    # Retry sans timestamp (en cas de timeout réseau)
    Write-Host "Retry sans timestamp..." -ForegroundColor Yellow
    & $signtool sign `
        /f $PfxPath `
        /p $PfxPassword `
        /fd SHA256 `
        /v `
        $exePath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCES : Signe (sans timestamp)" -ForegroundColor Yellow
    }
    else {
        Write-Error "ECHEC de la signature (code $LASTEXITCODE)"
    }
}

# 4. Vérifier la signature
Write-Host ""
Write-Host "Verification de la signature :" -ForegroundColor Cyan
& $signtool verify /pa /v $exePath
