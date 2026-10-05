# Cats Defender

Jogo mobile (Android, Godot 4.3+, renderer Mobile) de **Merge Defense**: gatos
atiradores atrás de um muro defendem o território contra ondas de inimigos.
Compre gatos, faça merge (2 iguais → nível superior) e use habilidades.
Modo bônus desbloqueável: **Tower Defense** clássico (caminho + grid livre).

## Estrutura

```
project.godot            Godot 4.3, renderer Mobile, 1280x720 expand
src/
  autoload/              EventBus, GameManager, SaveManager, AudioManager,
                         PoolManager, ScreenShake, TransitionManager
  core/atlas/            AtlasLoader (SpriteFrames a partir de atlases)
  game/
    cats/                cat_tower.gd, cat_data.gd, cat_boxer.gd
    enemies/             enemy.gd, enemy_data.gd, enemy_registry.gd
    components/          health, shooting, moving, hit_flash (composição)
    projectiles/        projectile.gd (pooled)
    spawning/            wave_manager.gd, wave_data.gd, level_data.gd
    merge/               slot_grid.gd, merge_controller.gd (drag&drop)
    abilities/           ability, spikes, tnt, boxer_call
    tower_defense/       path_follow_enemy, grid_placement, td_game
    fx/                  damage_numbers (pooled)
  ui/                    hud, menus, dialogs (pausa, game over)
data/                    *.tres gerados por tools/gen_data.gd
assets/art/atlases/      spritesheets gerados por tools/build_atlas.py
tests/                   suíte GUT (unit + integration)
tools/                   pipeline (build_atlas, build_fx, build_audio,
                         gen_data, sim_runner, run_tests)
```

## Pipeline de assets

```
python tools/build_atlas.py   # frames (ou placeholders) -> spritesheets
python tools/build_fx.py      # fx/balas/ícones procedurais
python tools/build_audio.py   # SFX/música procedurais (WAV)
godot --headless --path . --script tools/gen_data.gd   # gera data/*.tres
```

Se o pack pago “Merge Cats Defender” (craftpix) estiver em
`assets/art/raw/<personagem>/<anim>/`, ele é usado no lugar dos placeholders.

## Testes e balanceamento (gate antes de builds)

```
pwsh tools/run_tests.ps1                       # suíte GUT completa (headless)
godot --headless --path . res://tools/sim_runner.tscn -- --from 1 --to 10
```

Critério de balanceamento: win-rate do bot simples em 60–100% nas fases 1–10.

## Build Android

1. Instalar export templates do Godot 4.3 (Editor > Manage Export Templates).
2. `godot --headless --path . --export-release "Android" build/cats_defender.apk`
   (preset em `export_presets.cfg`; assinar com keystore própria — ver §9 do plano).

## Licenças

Ver `ASSETS_LICENSES.md`.
