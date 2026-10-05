# Cats Defender — Relatório de Execução (Plano 01)

## Executado

1. **Fundação** ✅ — `tools/build_atlas.py` (spritesheets + índice JSON + placeholders
   procedurais para gatos/inimigos/boss/boxer), `tools/build_fx.py` (balas/explosão/ícones),
   `tools/build_audio.py` (SFX + música WAV procedurais), Godot 4.3 em `tools/godot/`.
2. **Core loop** ✅ — Health/Shooting/Moving/HitFlash (composição), Projectile com pool,
   WaveManager + WaveData/LevelData (.tres), economia (EconomyData), HUD.
3. **Merge** ✅ — SlotGrid 2×5, MergeController (drag&drop touch/mouse), tiers 1–3
   (1.0×/2.2×/5×), loja com custo crescente, reparo do muro (25% das moedas da onda).
4. **Habilidades & Boss** ✅ — Espinhos (slow+DoT), TNT (área + shake), CatBoxing
   (melee temporário), Cat Guardian nas fases 10/30.
5. **Progressão** ✅ — 30 fases merge + 10 TD geradas (`tools/gen_data.gd`),
   curva de HP ×1.0→×25, save/load versionado (SaveManager), estrelas por fase,
   TD desbloqueado após fase 5.
6. **Modo TD bônus** ✅ — caminho splineado (Path2D), placement livre em grid 96px,
   reusa CatTower/Enemy/WaveManager, recompensa 2×, vidas da base.
7. **Polish premium** ✅ — TransitionManager (fade + dicas), hit-stop 60ms no kill,
   screenshake por trauma, flash de impacto, números de dano pooled, partículas GPU
   pooled, bloom leve (WorldEnvironment), 16 players de áudio com pitch ±8%,
   buses Master/Music/SFX com volume persistente, haptics Android, fonte Luckiest Guy.
8. **Testes & correção** ✅ — suíte GUT: **31/31 testes passando** (headless),
   gate `tools/run_tests.ps1`, simulador `tools/sim_runner.tscn`, gdlint limpo.
9. **Release prep** ✅ — `export_presets.cfg` (Android), `icon.png`,
   `ASSETS_LICENSES.md`, `README.md`, `docs/QA_CHECKLIST.md`, keystore em
   `platform/release.keystore`, e **APK release gerado em `build/cats_defender.apk`**.

## Resultados de balanceamento (simulação headless, bot de habilidade média)
- Fases 1–27: **100% de vitória** (3★ na maioria).
- Fases 28–30 (elite/boss final): batalhas de atrito além do limite da simulação;
  reproduzívelmente alcança waves tardias — calibragem fina prevista para QA em device.
- Correções de design durante a execução: recompensa de kill escala com HP efetivo
  (plano: hp/10), pool de gatos por fase (merge viável), fila de 2 atacantes por
  pista na parede (evita melt instantâneo), bônus de fim de onda.

## Pendências (ambiente/QA físico)
- QA em device real (checklist em `docs/QA_CHECKLIST.md`).
- Julgamento final de dificuldade das fases 28–30 com jogadores.
- Substituir placeholders pelos assets craftpix quando licenciados (pipeline pronto).

## Convenções do código
- GDScript tipado 100%, gdlint limpo (`.gdlintrc`).
- Composição: Health/Shooting/Moving/HitFlash reutilizados por gatos, inimigos e muro.
- Desacoplamento via EventBus; dados em `.tres` (zero números hardcoded fora de data/).
- Pooling de projéteis, inimigos, partículas e números de dano (PoolManager).

## Notas sobre assets
O pack pago “Merge Cats Defender” (craftpix) não está no disco: o jogo usa placeholders
procedurais CC0 gerados pelo pipeline. Para trocar, coloque frames em
`assets/art/raw/<personagem>/<anim>/` e rode `python tools/build_atlas.py`.
