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
8. **Testes & correção** ✅ — suíte GUT (unit + integration), gate `tools/run_tests.ps1`,
   simulador de balanceamento `tools/sim_runner.tscn` (win-rate fases 1–10: 100% com
   bot simples; esperado humano medio dentro de 60–80%+ ao subir a curva).
9. **Release prep** ✅ parcial — `export_presets.cfg` (Android), `icon.png`,
   `ASSETS_LICENSES.md`, `README.md`, `docs/QA_CHECKLIST.md`.
   **Pendente neste ambiente**: geração do APK (requer JDK + Android SDK instalados)
   e QA em device físico.

## Convenções do código
- GDScript tipado 100%, gdlint limpo (`.gdlintrc`).
- Composição: Health/Shooting/Moving/HitFlash reutilizados por gatos, inimigos e muro.
- Desacoplamento via EventBus; dados em `.tres` (zero números hardcoded fora de data/).
- Pooling de projéteis, inimigos, partículas e números de dano (PoolManager).

## Notas sobre assets
O pack pago “Merge Cats Defender” (craftpix) não está no disco: o jogo usa placeholders
procedurais CC0 gerados pelo pipeline. Para trocar, coloque frames em
`assets/art/raw/<personagem>/<anim>/` e rode `python tools/build_atlas.py`.
