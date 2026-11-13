# Chạy toàn bộ test headless trên Windows.
# Dùng: .\tools\run_tests.ps1 [-Godot "C:\đường\dẫn\Godot_console.exe"]
param([string]$Godot = "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe")
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
Write-Host "== Import project =="
& $Godot --headless --path . --import *> $null
$fail = $false
foreach ($t in "big_number_test", "economy_test", "data_test", "golden_test", "sim_test", "traffic_test", "state_test", "class_test", "facility_test", "class_ui_test", "upgrade_test", "boot_test", "power_banner_test", "trophy_test", "trophy_ui_test", "tutorial_test", "tutorial_unlock_test", "tutorial_tips_test", "ads_test", "ads_v1_test", "ads_ui_test", "ads_shop_test", "horus_test", "iap_test") {
    Write-Host ""; Write-Host "##### $t #####"
    $out = & $Godot --headless --path . -s "res://tests/$t.gd" 2>&1 | Out-String
    $code = $LASTEXITCODE
    Write-Host $out
    if ($code -ne 0 -or $out -match "SCRIPT ERROR|Parse Error|  FAIL ") {
        Write-Host ">>> ${t}: THAT BAI (exit $code)"; $fail = $true
    } else { Write-Host ">>> ${t}: dat" }
}
if ($fail) { Write-Host "CO TEST THAT BAI"; exit 1 }
Write-Host "TAT CA TEST DAT"
