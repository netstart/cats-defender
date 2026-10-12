# setup_emulator.ps1 — cria o AVD Redmi_Note_14_Pro_Plus_5G (idempotente).
# Códigos de saída != 0 em erro (seção 7).
param([switch]$LowEnd, [switch]$Wide69)
$ErrorActionPreference = "Stop"
$Sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "C:\android-sdk" }
$SdkMgr = Join-Path $Sdk "cmdline-tools\latest\bin\sdkmanager.bat"
$AvdMgr = Join-Path $Sdk "cmdline-tools\latest\bin\avdmanager.bat"

function Fail($m) { Write-Error $m; exit 1 }
if (-not (Test-Path $SdkMgr)) { Fail "sdkmanager ausente em $SdkMgr" }

# pacotes necessários (idempotente)
$yes = ("y`r`n" * 30)
[System.IO.File]::WriteAllText("$env:TEMP\sdk_yes.txt", $yes)
cmd /c "`"$SdkMgr`" --sdk_root=`"$Sdk`" platform-tools `"platforms;android-34`" `"build-tools;34.0.0`" emulator `"system-images;android-34;google_apis;x86_64`" < `"$env:TEMP\sdk_yes.txt`"" | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "sdkmanager falhou" }

$existing = & $AvdMgr list avd 2>&1 | Out-String
if ($existing -notmatch "Redmi_Note_14_Pro_Plus_5G") {
    cmd /c "`"$AvdMgr`" create avd -n Redmi_Note_14_Pro_Plus_5G -k `"system-images;android-34;google_apis;x86_64`" -d `"pixel_6_pro`" --force < `"$env:TEMP\sdk_yes.txt`"" | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail "avdmanager create falhou" }
    $ini = "$env:USERPROFILE\.android\avd\Redmi_Note_14_Pro_Plus_5G.avd\config.ini"
    if (Test-Path $ini) {
        $c = [IO.File]::ReadAllText($ini)
        $c = $c -replace 'hw\.lcd\.density=.*', 'hw.lcd.density=480' -replace 'hw\.lcd\.width=.*', 'hw.lcd.width=1220' -replace 'hw\.lcd\.height=.*', 'hw.lcd.height=2712'
        [IO.File]::WriteAllText($ini, $c)
    }
}
Write-Output "AVD Redmi_Note_14_Pro_Plus_5G pronto (1220x2712, 480dpi, API 34)."
