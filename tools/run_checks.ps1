# run_checks.ps1 — CI local (M20): check + validate + tests + balance + build.
# Mesmo script usado pelo GitHub Actions (com -CI os assets grandes podem faltar;
# validate roda em modo --manifest-only nesse caso).
param([switch]$CI, [switch]$SkipBuild)
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Proj = Join-Path $Root "godot"
$Godot = Join-Path $Root "godot-bin\Godot_v4.7.2-stable_win64.exe"
if (-not (Test-Path $Godot)) {
    $g = Get-Command godot -ErrorAction SilentlyContinue
    if ($g) { $Godot = $g.Source } else { Write-Error "Godot não encontrado"; exit 1 }
}
$fail = $false

Write-Output "== 1. validate_assets =="
& $Godot --headless --path $Proj -s res://scripts/validate_assets.gd | Select-Object -Last 2
if ($LASTEXITCODE -ne 0) { $fail = $true }

Write-Output "== 2. testes =="
& $Godot --headless --path $Proj -s res://tests/run_tests.gd | Select-String 'Testes:|FAIL' | ForEach-Object { $_.Line }
if ($LASTEXITCODE -ne 0) { $fail = $true }

Write-Output "== 3. balance_sim (amostra) =="
& $Godot --headless --path $Proj -s res://scripts/balance_sim.gd -- --stage P1 --seeds 10 | Select-String 'win=' | ForEach-Object { $_.Line }
if ($LASTEXITCODE -ne 0) { $fail = $true }

if (-not $CI -and -not $SkipBuild) {
    Write-Output "== 4. build APK debug =="
    & (Join-Path $PSScriptRoot "build_install_play.ps1") -SkipTests -BuildOnly
}

if ($fail) { Write-Error "run_checks FALHOU"; exit 1 }
Write-Output "run_checks OK"
