# curate_audio.ps1 — seleção de áudio CC0 (12.1) + audio_manifest.json com sha256
$ErrorActionPreference = "Stop"
$Src = "C:\src\2\cats-defender\_audio_src"
$Proj = "C:\src\2\cats-defender\godot"
$DirSfx = "$Proj\assets\audio\sfx"
$DirMusic = "$Proj\assets\audio\music"
New-Item -ItemType Directory -Force $DirSfx, $DirMusic | Out-Null

$eventMap = @(
    @{ ev = "click";          pack = "interface"; src = "click_001.ogg";             out = "click" },
    @{ ev = "buy";            pack = "interface"; src = "confirmation_001.ogg";      out = "buy" },
    @{ ev = "error";          pack = "interface"; src = "error_001.ogg";             out = "error" },
    @{ ev = "toggle";         pack = "interface"; src = "switch_001.ogg";            out = "toggle" },
    @{ ev = "coin";           pack = "interface"; src = "pluck_001.ogg";             out = "coin" },
    @{ ev = "sell";           pack = "interface"; src = "minimize_001.ogg";          out = "sell" },
    @{ ev = "merge";          pack = "impact";    src = "impactMetal_light_000.ogg"; out = "merge" },
    @{ ev = "hit";            pack = "impact";    src = "impactGeneric_light_000.ogg"; out = "hit" },
    @{ ev = "enemy_die";      pack = "impact";    src = "impactPlank_medium_000.ogg"; out = "enemy_die" },
    @{ ev = "siege_hit";      pack = "impact";    src = "impactMining_000.ogg";      out = "siege_hit" },
    @{ ev = "base_damage";    pack = "impact";    src = "impactPlate_heavy_000.ogg"; out = "base_damage" },
    @{ ev = "explosion";      pack = "impact";    src = "impactGlass_heavy_000.ogg"; out = "explosion" },
    @{ ev = "shoot_straight"; pack = "digital";   src = "laser1.ogg";                out = "shoot_straight" },
    @{ ev = "shoot_slow";     pack = "digital";   src = "laser2.ogg";                out = "shoot_slow" },
    @{ ev = "shoot_grenade";  pack = "digital";   src = "laser4.ogg";                out = "shoot_grenade" },
    @{ ev = "wave_start";     pack = "jingles";   src = "jingles_HIT00.ogg";         out = "wave_start" },
    @{ ev = "boss_alert";     pack = "jingles";   src = "jingles_HIT05.ogg";         out = "boss_alert" },
    @{ ev = "star";           pack = "jingles";   src = "jingles_NES01.ogg";         out = "star" },
    @{ ev = "win";            pack = "jingles";   src = "jingles_NES10.ogg";         out = "win" },
    @{ ev = "lose";           pack = "jingles";   src = "jingles_NES02.ogg";         out = "lose" },
    @{ ev = "merge_high";     pack = "jingles";   src = "jingles_NES03.ogg";         out = "merge_high" }
)
$musicMap = @(
    @{ ev = "phase_theme"; src = "$Src\dst_td_theme.mp3"; out = "phase_theme"; pack = "opengameart-dst" },
    @{ ev = "menu_theme";  src = "$Src\jingles\Audio\8-Bit jingles\jingles_NES13.ogg"; out = "menu_theme"; pack = "jingles" }
)

$packUrls = @{
    "interface" = "https://kenney.nl/assets/interface-sounds"
    "impact"    = "https://kenney.nl/assets/impact-sounds"
    "jingles"   = "https://kenney.nl/assets/music-jingles"
    "digital"   = "https://kenney.nl/assets/digital-audio"
    "opengameart-dst" = "https://opengameart.org/content/tower-defense-theme"
}
$packAuthors = @{
    "interface" = "Kenney Vleugels"; "impact" = "Kenney Vleugels"
    "jingles" = "Kenney Vleugels"; "digital" = "Kenney Vleugels"
    "opengameart-dst" = "DST"
}

$entries = @()
foreach ($m in $eventMap) {
    $found = Get-ChildItem (Join-Path $Src $m.pack) -Recurse -File | Where-Object { $_.Name -eq $m.src } | Select-Object -First 1
    if (-not $found) { Write-Error "Faltando: $($m.src)"; continue }
    $ext = [IO.Path]::GetExtension($found.Name)
    $outFile = $m.out + $ext
    $dstFile = Join-Path $DirSfx $outFile
    Copy-Item $found.FullName $dstFile -Force
    $hash = (Get-FileHash $dstFile -Algorithm SHA256).Hash.ToLower()
    $entries += [pscustomobject]@{
        file = "res://assets/audio/sfx/$outFile"
        event = $m.ev; pack = $m.pack; original_file = $m.src
        author = $packAuthors[$m.pack]; source_url = $packUrls[$m.pack]
        license = "CC0 1.0"; license_url = "https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt"
        sha256 = $hash; bytes = (Get-Item $dstFile).Length
    }
}
foreach ($m in $musicMap) {
    $ext = [IO.Path]::GetExtension($m.src)
    $outFile = $m.out + $ext
    $dstFile = Join-Path $DirMusic $outFile
    Copy-Item $m.src $dstFile -Force
    $hash = (Get-FileHash $dstFile -Algorithm SHA256).Hash.ToLower()
    $entries += [pscustomobject]@{
        file = "res://assets/audio/music/$outFile"
        event = $m.ev; pack = $m.pack
        original_file = ($m.src -replace [regex]::Escape($Src + '\'), '')
        author = $packAuthors[$m.pack]; source_url = $packUrls[$m.pack]
        license = "CC0 1.0"; license_url = "https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt"
        sha256 = $hash; bytes = (Get-Item $dstFile).Length
    }
}

$manifest = [pscustomobject]@{
    generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    rule = "Somente CC0; provas em docs/licenses/audio/"
    items = $entries
}
$manifest | ConvertTo-Json -Depth 4 | Out-File "$Proj\data\audio_manifest.json" -Encoding UTF8
$totalMB = [math]::Round(($entries | Measure-Object bytes -Sum).Sum / 1MB, 1)
Write-Output "Áudio curado: $($entries.Count) arquivos, $totalMB MB (orcamento <= 25 MB)"
