# copy_assets.ps1 — copia seletiva Craftpix (2.1) e gera assets_manifest.json
# com sha256 por arquivo (M02/M25). Registrado como candidato aprovado em 2.3.
param(
    [string]$AssetsRoot = "C:\src\assets\craftpix-net",
    [string]$ProjectRoot = "C:\src\2\cats-defender\godot"
)
$ErrorActionPreference = "Stop"
$dest = Join-Path $ProjectRoot "assets\art"
New-Item -ItemType Directory -Force $dest | Out-Null

$copyJobs = @()
# UI completa
$copyJobs += @{ From = "Png\Ui"; To = "Ui" }
# Gatos C1..C15
$copyJobs += @{ From = "Png\Characters"; To = "Characters" }
# Melee
$copyJobs += @{ From = "Png\Cat Guardian"; To = "CatGuardian" }
$copyJobs += @{ From = "Png\CatBoxing"; To = "CatBoxing" }
# Inimigos Reg 1..8 e Boss 1..7
$copyJobs += @{ From = "Png\Enemies"; To = "Enemies" }
# Efeitos / projéteis / áreas
$copyJobs += @{ From = "Png\Bullets"; To = "Bullets" }
$copyJobs += @{ From = "Png\Explosion"; To = "Explosion" }
$copyJobs += @{ From = "Png\ShootFx"; To = "ShootFx" }
$copyJobs += @{ From = "Png\Area"; To = "Area" }

$copied = 0
foreach ($job in $copyJobs) {
    $src = Join-Path $AssetsRoot $job.From
    if (-not (Test-Path $src)) { Write-Error "Fonte ausente: $src"; continue }
    Copy-Item $src (Join-Path $dest $job.To) -Recurse -Force
    $copied += (Get-ChildItem (Join-Path $dest $job.To) -Recurse -File).Count
}

# Manifesto com hash de todos os arquivos copiados
$entries = @()
Get-ChildItem $dest -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring((Join-Path $ProjectRoot "assets").Length + 1).Replace("\", "/")
    $entries += [pscustomobject]@{
        file = "res://assets/$rel"
        source_package = "craftpix-cat-defense-free"
        license = "Craftpix Freebie (uso comercial permitido; ver docs/licenses/craftpix/)"
        sha256 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
        bytes = $_.Length
    }
}
$manifest = [pscustomobject]@{
    generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    generator = "tools/copy_assets.ps1"
    items = $entries
}
$manifest | ConvertTo-Json -Depth 5 | Out-File (Join-Path $ProjectRoot "assets_manifest.json") -Encoding UTF8
Write-Output "Copiados $copied arquivos; manifesto com $($entries.Count) itens."
