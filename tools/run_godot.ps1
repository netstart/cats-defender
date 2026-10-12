# run_godot.ps1 — abre o jogo LOCALMENTE no Godot para teste manual.
# Uso: powershell -File tools\run_godot.ps1
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Godot = Join-Path $Root "godot-bin\Godot_v4.7.2-stable_win64.exe"
$Proj = Join-Path $Root "godot"
if (-not (Test-Path $Godot)) { Write-Error "Godot não encontrado em $Godot" }
Write-Output "Iniciando Merge Defense no Godot 4.7.2 (projeto: $Proj)"
& $Godot --path $Proj
