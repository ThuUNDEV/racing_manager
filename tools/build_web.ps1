# Export bản Web của game vào export/web/ và chép Horus SDK vào đó (Design/25 §7).
# Dùng: .\tools\build_web.ps1 [-Godot "C:\đường\dẫn\Godot_console.exe"]
# Cần export template Web của đúng phiên bản Godot (Editor > Manage Export Templates).
param([string]$Godot = "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe")
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
New-Item -ItemType Directory -Force export\web | Out-Null
& $Godot --headless --path . --import *> $null
$out = & $Godot --headless --path . --export-release "Web" export/web/index.html 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $out -match "ERROR:") { Write-Host $out; throw "Export Web lỗi" }
if (-not (Test-Path export\web\index.html)) { throw "Không thấy export/web/index.html" }
Copy-Item horus-sdk\horus-sdk.js export\web\horus-sdk.js -Force
Write-Host "Xong: export/web ($((Get-ChildItem export\web -Recurse | Measure-Object Length -Sum).Sum / 1MB -as [int]) MB)"
