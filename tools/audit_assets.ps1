# audit_assets.ps1 - Etapa 0 [M06][M07]
# Gera godot/docs/assets_audit.md com dimensões, memória estimada e inventário do pack Craftpix.
param(
    [string]$AssetsRoot = "C:\src\assets\craftpix-net",
    [string]$OutFile = "C:\src\2\cats-defender\godot\docs\assets_audit.md"
)
Add-Type -AssemblyName System.Drawing
$rows = New-Object System.Collections.Generic.List[object]

function Get-PngInfo([System.IO.FileInfo]$f) {
    try {
        $img = [System.Drawing.Image]::FromFile($f.FullName)
        $w = $img.Width; $h = $img.Height; $img.Dispose()
        return @{ W = $w; H = $h }
    } catch { return @{ W = 0; H = 0 } }
}

# Inventário por grupo
$groups = @(
    @{ Name = "Ui"; Path = "Png\Ui" },
    @{ Name = "Characters C1..C15"; Path = "Png\Characters" },
    @{ Name = "CatGuardian"; Path = "Png\Cat Guardian" },
    @{ Name = "CatBoxing"; Path = "Png\CatBoxing" },
    @{ Name = "Enemies Reg"; Path = "Png\Enemies" },
    @{ Name = "Bullets"; Path = "Png\Bullets" },
    @{ Name = "Explosion"; Path = "Png\Explosion" },
    @{ Name = "ShootFx"; Path = "Png\ShootFx" },
    @{ Name = "Area"; Path = "Png\Area" }
)

$pngTotal = 0; $diskTotal = 0.0; $gpuTotal = 0.0
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Auditoria de Assets - pack Craftpix Free Cartoon Cat Defense Game Asset Kit")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Gerado por tools/audit_assets.ps1 em $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Resumo por grupo")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Grupo | Arquivos PNG | Disco (MB) | GPU est. RGBA8 (MB) | Dimensões observadas |")
[void]$sb.AppendLine("|---|---|---|---|---|")

foreach ($g in $groups) {
    $dir = Join-Path $AssetsRoot $g.Path
    if (-not (Test-Path $dir)) { [void]$sb.AppendLine("| $($g.Name) | 0 | - | - | pasta ausente |"); continue }
    $files = Get-ChildItem $dir -Recurse -Filter *.png -File
    $disk = 0.0; $gpu = 0.0; $dims = @{}
    foreach ($f in $files) {
        $disk += $f.Length / 1MB
        $info = Get-PngInfo $f
        $gpu += ($info.W * $info.H * 4) / 1MB
        $key = "$($info.W)x$($info.H)"
        $dims[$key] = ($dims[$key] + 1)
    }
    $pngTotal += $files.Count; $diskTotal += $disk; $gpuTotal += $gpu
    $dimStr = ($dims.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object { "$($_.Key) ($($_.Value))" }) -join ", "
    [void]$sb.AppendLine("| $($g.Name) | $($files.Count) | $([math]::Round($disk,1)) | $([math]::Round($gpu,1)) | $dimStr |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Total PNG (Png\\):** $pngTotal arquivos · $([math]::Round($diskTotal,1)) MB em disco · $([math]::Round($gpuTotal,1)) MB estimados em GPU (RGBA8; ASTC ~1 byte/px reduziria ~4x)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Detalhe: personagens (frames por animação)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Entidade | Animações | Frames (total) | Dimensões |")
[void]$sb.AppendLine("|---|---|---|---|")

$chars = Get-ChildItem (Join-Path $AssetsRoot "Png\Characters") -Directory
$mains = @((Join-Path $AssetsRoot "Png\Cat Guardian"), (Join-Path $AssetsRoot "Png\CatBoxing")) | Where-Object { Test-Path $_ }
foreach ($c in $chars) { $mains += $c.FullName }
$enemies = Get-ChildItem (Join-Path $AssetsRoot "Png\Enemies") -Directory
foreach ($base in $mains) {
    $anims = Get-ChildItem $base -Directory
    foreach ($a in $anims) {
        $frames = Get-ChildItem $a.FullName -Filter *.png -File
        if ($frames.Count -eq 0) { continue }
        $info = Get-PngInfo ($frames | Sort-Object Length -Descending | Select-Object -First 1)
        $rel = ($base -replace [regex]::Escape($AssetsRoot), "").TrimStart('\')
        [void]$sb.AppendLine("| $rel / $($a.Name) | $($a.Name) | $($frames.Count) | $($info.W)x$($info.H) |")
    }
}
foreach ($e in $enemies) {
    $anims = Get-ChildItem $e.FullName -Directory
    foreach ($a in $anims) {
        $frames = Get-ChildItem $a.FullName -Filter *.png -File
        if ($frames.Count -eq 0) { continue }
        $info = Get-PngInfo ($frames | Sort-Object Length -Descending | Select-Object -First 1)
        $rel = ($e.FullName -replace [regex]::Escape($AssetsRoot), "").TrimStart('\')
        [void]$sb.AppendLine("| $rel / $($a.Name) | $($a.Name) | $($frames.Count) | $($info.W)x$($info.H) |")
    }
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("## UI: dimensões-chave e texto embutido")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Arquivo | Dimensões | Obs. auditoria |")
[void]$sb.AppendLine("|---|---|---|")
$ui = Get-ChildItem (Join-Path $AssetsRoot "Png\Ui") -Filter *.png -File | Sort-Object Name
foreach ($f in $ui) {
    $info = Get-PngInfo $f
    [void]$sb.AppendLine("| $($f.Name) | $($info.W)x$($info.H) |  |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Áreas (fundos de fase)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Arquivo | Dimensões |")
[void]$sb.AppendLine("|---|---|")
foreach ($f in (Get-ChildItem (Join-Path $AssetsRoot "Png\Area") -Filter *.png)) {
    $info = Get-PngInfo $f
    [void]$sb.AppendLine("| $($f.Name) | $($info.W)x$($info.H) |")
}
$canvasW = 1200; $canvasH = 540
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Canvas de referência: ${canvasW}x${canvasH} (landscape). Áreas de ~2:1 exigem crop vertical ou letterbox controlado.")

[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Contagem de outros formatos (fora do build)")
[void]$sb.AppendLine("")
foreach ($ext in @("spine", "json", "ai", "eps", "ttf", "otf")) {
    $files = Get-ChildItem $AssetsRoot -Recurse -Filter "*.$ext" -File -ErrorAction SilentlyContinue
    [void]$sb.AppendLine("- .$ext : $($files.Count) arquivos")
}

New-Item -ItemType Directory -Force (Split-Path $OutFile) | Out-Null
$sb.ToString() | Out-File $OutFile -Encoding UTF8
Write-Output "Gerado: $OutFile ($pngTotal PNGs, $([math]::Round($diskTotal,1)) MB)"

