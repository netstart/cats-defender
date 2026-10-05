# tools/run_tests.ps1 — gate de qualidade: GUT headless completo.
$ErrorActionPreference = 'Stop'
$godot = Join-Path $PSScriptRoot 'godot\Godot_v4.3-stable_win64_console.exe'
$proj  = Split-Path $PSScriptRoot

$out = Join-Path $env:TEMP 'cats_gut_out.txt'
$err = Join-Path $env:TEMP 'cats_gut_err.txt'
$p = Start-Process -FilePath $godot -ArgumentList @(
  '--headless','--path',$proj,'-s','addons/gut/gut_cmdln.gd',
  '-gdir=res://tests/unit,res://tests/integration','-gexit','-glog=1'
) -RedirectStandardOutput $out -RedirectStandardError $err -PassThru
if (-not $p.WaitForExit(600000)) { $p.Kill(); Write-Error 'GUT timeout' }

$txt = Get-Content $out -Raw
Write-Output $txt
if ($txt -match '(\d+)\s+Failing' -and [int]$Matches[1] -eq 0 -and $txt -match 'Passing\s+(\d+)' -and [int]$Matches[1] -gt 0) {
  Write-Output '== GATE OK: todos os testes passaram =='
  exit 0
}
Write-Error '== GATE FALHOU =='
