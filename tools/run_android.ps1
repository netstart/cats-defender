# run_android.ps1 — inicia o emulador e instala/abre o jogo (APK debug).
# Uso: powershell -File tools\run_android.ps1 [-Build]
param([switch]$Build)
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "C:\android-sdk" }
$Adb = Join-Path $Sdk "platform-tools\adb.exe"
$Emu = Join-Path $Sdk "emulator\emulator.exe"
$Apk = Join-Path $Root "build\merge-defense-debug.apk"

if ($Build -or -not (Test-Path $Apk)) {
    & (Join-Path $PSScriptRoot "build_install_play.ps1") -BuildOnly
    return
}

# inicia o emulador se nenhum dispositivo conectado
$devices = & $Adb devices | Select-String "device$"
if (-not $devices) {
    Write-Output "Iniciando emulador Redmi_Note_14_Pro_Plus_5G ..."
    Start-Process $Emu -ArgumentList '-avd','Redmi_Note_14_Pro_Plus_5G','-gpu','swiftshader_indirect'
}
Write-Output "Aguardando boot..."
& $Adb wait-for-device | Out-Null
& $Adb shell "while [ -z `$(getprop sys.boot_completed) ]; do sleep 2; done" 2>$null
Write-Output "Instalando APK..."
& $Adb install -r $Apk | Select-Object -Last 1
Write-Output "Abrindo o jogo..."
& $Adb shell monkey -p com.studio.mergedefense -c android.intent.category.LAUNCHER 1
Write-Output "Pronto. Janela do emulador aberta para jogo manual."
