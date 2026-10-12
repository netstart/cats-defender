# build_install_play.ps1 — fluxo completo (seção 7):
# valida assets -> testes -> compila APK -> inicia emulador -> instala -> abre.
# Parâmetros: -SkipTests, -BuildOnly, -Fresh, -Verify
param(
    [switch]$SkipTests,
    [switch]$BuildOnly,
    [switch]$Fresh,
    [switch]$Verify,
    [int]$VerifySeconds = 25
)
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Proj = Join-Path $Root "godot"
$Godot = Join-Path $Root "godot-bin\Godot_v4.7.2-stable_win64.exe"
$Build = Join-Path $Root "build"
$Apk = Join-Path $Build "merge-defense-debug.apk"
$Sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "C:\android-sdk" }
$Adb = Join-Path $Sdk "platform-tools\adb.exe"
$Emu = Join-Path $Sdk "emulator\emulator.exe"
New-Item -ItemType Directory -Force $Build, "$Root\reports" | Out-Null

function Fail($msg) { Write-Error $msg; exit 1 }

# 1. validate assets
& $Godot --headless --path $Proj -s res://scripts/validate_assets.gd | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "validate_assets falhou" }
Write-Output "[1/6] assets OK"

# 2. testes
if (-not $SkipTests) {
    & $Godot --headless --path $Proj -s res://tests/run_tests.gd | Select-String 'Testes:' | ForEach-Object { $_.Line }
    if ($LASTEXITCODE -ne 0) { Fail "testes falharam" }
    Write-Output "[2/6] testes OK"
} else { Write-Output "[2/6] testes pulados" }

# 3. keystore + export
$ks = Join-Path $Build "debug.keystore"
if (-not (Test-Path $ks)) {
    & keytool -genkeypair -v -keystore $ks -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -storepass android -keypass android -dname "CN=Android Debug,O=Android,C=US" | Out-Null
}
$env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH = $ks
$env:GODOT_ANDROID_KEYSTORE_DEBUG_USER = "androiddebugkey"
$env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD = "android"
if ($Fresh) { Remove-Item $Apk -ErrorAction SilentlyContinue }
& $Godot --headless --path $Proj --export-debug "Android Debug" $Apk | Out-Null
if (-not (Test-Path $Apk)) { Fail "export falhou (APK não criado)" }
$mb = [math]::Round((Get-Item $Apk).Length / 1MB, 1)
Write-Output "[3/6] APK exportado: $mb MB (teto 200 MB)"
if ($mb -gt 200) { Fail "APK acima do teto de 200 MB" }
if ($BuildOnly) { Write-Output "BuildOnly: fim."; return }

# 4/5. emulador + instalação
$devices = & $Adb devices | Select-String "device$"
if (-not $devices) {
    Write-Output "[4/6] iniciando emulador..."
    Start-Process $Emu -ArgumentList '-avd','Redmi_Note_14_Pro_Plus_5G','-gpu','swiftshader_indirect'
}
& $Adb wait-for-device | Out-Null
& $Adb shell "while [ -z `$(getprop sys.boot_completed) ]; do sleep 2; done" 2>$null
Write-Output "[4/6] emulador online; instalando..."
& $Adb install -r $Apk | Select-Object -Last 1 | ForEach-Object { if ($_ -match 'Failure') { Fail "adb install falhou: $_" } }

# 6. abrir
& $Adb shell monkey -p com.studio.mergedefense -c android.intent.category.LAUNCHER 1 | Out-Null
Write-Output "[6/6] jogo aberto no emulador"

if ($Verify) {
    Start-Sleep -Seconds $VerifySeconds
    $log = & $Adb logcat -d -s godot 2>&1 | Out-String
    $log | Out-File "$Root\reports\logcat_verify.txt" -Encoding UTF8
    $bad = $log -split "`n" | Where-Object { $_ -match 'ERROR|missing' }
    $shot = "$Root\reports\screenshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
    & $Adb exec-out screencap -p | Set-Content -Path $shot -Encoding Byte
    Write-Output "screenshot: $shot"
    if ($bad.Count -gt 0) { Fail "logcat contém ERROR/missing: $($bad.Count) linhas" }
    Write-Output "Verify OK: logcat limpo"
}
