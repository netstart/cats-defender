# Merge Defense — Release Checklist

## Build & Export
- [x] Godot 4.7.2 stable (win64)
- [x] Android Debug export com keystore `build/debug.keystore`
- [x] `-gpu host` no emulador (SwiftShader falha shader linking)
- [x] AVD `Redmi_Note_14_Pro_Plus_5G` (1220×2712, landscape sensor)
- [x] APK assinado com `apksigner.bat` (build-tools 34.0.0)

## Core Gameplay
- [x] Merge 2:1, tiers 1–15, `tier_cap` por fase (P1..P20)
- [x] Cat dmg/growth 1.35, siege max 30 dps
- [x] `SimWorld` pura (RefCounted, `SIM_DT=1/60`, xorshift32) desacoplada da render
- [x] 20 fases (P1..P20) com waves/bosses definidos em `data/enemies.json`

## Systems (Autoloads)
- [x] EventBus / GameState / SceneRouter / SaveSystem / GameSettings / Localization / AudioManager / FeatureFlags
- [x] Debug menu (`scripts/debug/debug_menu.gd`) + perf overlay (F2)
- [x] Tutorial overlay (buy + merge hint, dismiss on actions)
- [x] Save v2 + `.bak` + checksum; first-run "checksum inválido" é esperado

## Assets
- [x] Craftpix CC **proibido** — usado apenas Png subfolders licenciados
- [x] Audio CC0: Kenney (interface/impact/jingles/digital), DST Tower Defense Theme, Passion One OFL
- [x] `include_filter` / `exclude_filter` em `export_presets.cfg` para evitar leaks

## Data (JSON no APK)
- [x] `data/balance.json` — parâmetros de gameplay (key/value)
- [x] `data/enemies.json` — 15 inimigos (8 regulares + 7 chefes)
- [x] `data/localization.json` — PT-BR/EN (chave → {pt_BR, en})
- [x] `data/audio_manifest.json` / `data/credits_manifest.json`

## Balance Validation
- [x] `balance_sim.gd` roda 4 bots (optimal/medium/passive/idle) × 30 seeds
- [x] Gates CI: óptimo ≥ 85% vitória, passivo ≤ 15%, ordem preservada, tier ≤ tier_cap
- [x] Todas 20 fases (P1..P20) passam: óptimo 100%, passivo 0%, tier_max=7

## Android On-Device Tests
- [x] `adb install -r` + `monkey 5000` eventos → **sem crash do app**
- [x] Splash → Menu → LevelSelect → Gameplay navegação por toque funcional
- [x] Localização PT-BR aparece ("A noite caiu. Os gatos ficaram de guarda.", "Jogar", etc.)

## CI / Pipeline
- [x] `tests/run_tests.gd` → 202 testes OK, 0 falhas
- [x] `validate_assets.gd` → clean
- [x] GitHub Actions: build → export → test → upload artifacts

## Documentation
- [x] `README.md` com instruções de build/run/test
- [x] `docs/qa/requirements.csv` / `docs/qa/test-cases.csv`
- [x] `docs/CREDITS.md` com licenças de assets
- [x] `build_install_play.ps1` captura screenshots via `cmd /c "adb exec-out screencap -p > file"` (fixa PNG corrupto)

## Known Issues / Follow-ups
- [ ] `SaveSystem` warning "checksum inválido" no primeiro run (auto-heals) — documentar
- [ ] Perf overlay (F2) confirmar < 10ms frame no emulador `-gpu host`
- [ ] Verificar áudio em device físico (emulador sem som confiável)

---

**Status**: ✅ Pronto para release interno / QA
**Última atualização**: 2026-10-12