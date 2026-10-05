# Cats Defender — Plano Premium Completo

## 1. Visão do Produto

Jogo mobile (Android, Godot 4.3+, renderer Mobile) de **Merge Defense** como modo principal: gatos atiradores posicionados em slots atrás de um muro defendem o território contra ondas de inimigos. O jogador compra gatos com moedas, faz **merge** (2 gatos iguais → gato de nível superior) e usa habilidades especiais. Modo bônus desbloqueável: **Tower Defense clássico** (caminho com waypoints, posicionamento livre em grid).

### Pilares de qualidade premium
- **Juiciness**: screenshake, hit-stop leve, flashes de impacto, partículas, squash & stretch
- **Transições**: fades/slides com Tween, loading screens com dicas
- **Luz**: glow 2D (WorldEnvironment + Light2D em flashes/SFX), vignette sutil
- **Áudio**: música dinâmica, SFX com variação de pitch, ducks de UI
- **Progressão**: 30+ fases merge + 10 fases TD bônus, curva de dificuldade calibrada, economia testada

## 2. Assets

### Existentes (craftpix-ne — pack "Merge Cats Defender")
- 15 gatos (C1–C15): Idle 20f + Shoot 10f
- Cat Guardian (boss): Idle 20f + Attack 25f
- CatBoxing: unidade corpo-a-corpo especial
- 8+ inimigos (Enemy Reg 1–8): Idle 20f, Walk 35f, Attack 25f, Dead 60f
- Cenário Area (beco com muro), Bullets (3), Explosion, ShootFx, UI completa
- Fontes alternativas: Spine (esquelético) e Json Atlas

### Assets externos gratuitos a baixar/integrar (CC0)
- **Kenney.nl (CC0)**: "game-icons", "UI Pack", "particles pack" — ícones extras, moedas, estrelas de rating
- **Freesound.org / Pixabay (CC0)**: SFX de tiro, explosão, merge, miados, cliques de UI; música de batalha/menu (Kevin MacLeod incompetech CC-BY como alternativa de qualidade)
- **Tipografia**: fonte cartoon estilo "Luckiest Guy" (assets/fonts)

Regra: tudo licenciado CC0/CC-BY, registrado em `ASSETS_LICENSES.md`.

## 3. Pipeline de Assets (etapa crítica)

Frames soltos (20–60 PNGs por animação) são inviáveis em memória/draw calls no mobile. Solução:
1. Script Python (`tools/build_atlas.py`): concatena frames em spritesheets por animação via Pillow, gera JSON de offsets
2. `SpriteFrames` no Godot alimentados por 1 atlas por personagem → 1 draw call por unidade
3. Import Godot: compressão ETC2/ASTC, pixel-art friendly
4. Copiar assets raw para `assets/art/` mantendo estrutura; atlas gerado para `assets/art/atlases/`

## 4. Arquitetura de Código (qualidade máxima)

```
project.godot (mobile renderer, autoloads, 1280x720 canvas_items/expand)
src/
  autoload/         EventBus, GameManager, SaveManager, AudioManager, TransitionManager, PoolManager
  core/
    events/         sinais tipados
    save/           SaveData (resource versionado, user://save.dat)
    input/          input adapter touch/mouse unificado
  game/
    cats/           cat_tower.gd + cat_data.gd (Resource)
    enemies/        enemy.gd + enemy_data.gd, states (walk/attack/die)
    components/     health.gd, hitbox.gd, hurtbox.gd, shooting.gd, mergeable.gd, moving.gd
    projectiles/    projectile.gd com pooling
    spawning/       wave_manager.gd, wave_data.gd (Resource)
    abilities/      spikes.gd, tnt.gd, boxer_call.gd
    merge/          merge_controller.gd (drag & drop + validação)
    tower_defense/  path_follow_enemy.gd, grid_placement.gd (modo bônus)
  ui/               hud.gd, menus, shop_panel, pause, game_over, win_screen, settings
scenes/  espelha src (1 cena por classe raiz)
data/    cats/*.tres, enemies/*.tres, waves/*.tres, upgrades/*.tres, economy/*.tres
tests/   GUT (unit + integration)
```

### Princípios obrigatórios
- **Composição sobre herança**: componentes reutilizáveis (zero duplicação entre gato, inimigo, boss)
- **Desacoplamento via EventBus**: dados fluem via Resources tipados
- **Data-driven**: números em `.tres`, nunca hardcoded
- **Pooling obrigatório**: projéteis, partículas, números de dano
- **Tipagem estática GDScript** em 100% do código + gdlint
- Arquivos < 300 linhas; uma função, uma responsabilidade

## 5. Game Design

### Modo Merge Defense (principal)
- Grid 2×5 de slots atrás do muro; loja gera gato aleatório tier 1 por custo crescente
- Merge: mesma tier+tipo → tier+1 (máx. 3)
- DPS por tier: t1=1.0×, t2=2.2×, t3=5×
- Muro com HP; "Repair Wall"; game over se cair
- Habilidades: Espinhos (slow+dot), TNT (área), CatBoxing (melee temporário)
- Boss a cada 10 ondas: Cat Guardian

### Modo Tower Defense (bônus, desbloqueado após fase 5)
- Caminho splineado; placement em grid livre; reuso total de componentes
- 10 fases exclusivas

### Progressão e dificuldade (Modo Merge)
| Fases | Novidades | Curva |
|---|---|---|
| 1–3 | tutorial + Enemy Reg 1–2 | HP ×1.0–1.3, waves 3 |
| 4–6 | Enemy Reg 3–4, merge t2 obrigatório | ×1.5–2.0, waves 5 + Espinhos |
| 7–9 | Enemy Reg 5–6, TNT | ×2.2–3.0, waves 6 |
| 10 | Boss 1 (Cat Guardian) | ×3.5 |
| 11–15 | Enemy Reg 7–8, CatBoxing | ×3.8–6.0, waves 7 |
| 16–20 | waves mistas com timer | ×6.5–10 |
| 21–29 | elite variants (HP/speed mods) | ×11–20 |
| 30 | Boss final (Guardian buff) | ×25 |
| TD 1–10 | paralelo, sobe ×2 por fase | recompensa 2× moedas |

Economia: custo inicial 50, +15 por compra; kill drop = enemy_hp/10; reparo = 25% das moedas da wave. Valores em `data/economy/economy.tres` validados por simulação headless (win-rate alvo 60–80%).

## 6. Premium feel
- **TransitionManager**: fade + slide com Tween
- **Juice**: scale no merge, hit-stop 60ms no kill, shake no TNT, floating damage numbers
- **Luz**: glow modulado (additive), WorldEnvironment bloom leve (auto-desligável após benchmark)
- **Áudio**: pool de 16 players, pitch ±8%, buses Master/Music/SFX, volumes persistentes
- **Haptics**: vibração leve em kill/merge (Android Vibrate API)
- **Partículas**: GPU particles pré-alocadas

## 7. Testes, verificação e correção
- **GUT** (Godot Unit Test): unit + integration + regressão (red-green-refactor)
- **Headless**: `tools/run_tests.ps1` como gate antes de builds
- **Balance harness**: `tools/simulate.py` valida win-rate/tempo
- **QA no device**: APK debug, checklist (fps ≥50, sem leak de nós, notches, rotação, pausa em ligação)

## 8. Fases de Execução
1. **Fundação**: pipeline atlas, importar assets, sandbox (1 gato + 1 inimigo)
2. **Core loop**: health/hitbox/projectile/pooling + waves + moeda + HUD básico
3. **Merge**: slots, loja, drag&drop, tiers, reparo
4. **Habilidades & Boss**: espinhos, TNT, CatBoxing, Cat Guardian
5. **Progressão**: 30 fases .tres, save/load, estrelas, economia
6. **Modo TD bônus**: path + grid placement + 10 fases
7. **Polish premium**: transições, juice, luz, partículas, áudio, haptics, settings
8. **Testes & correção**: GUT completo, regressões, balance, build Android release
9. **Release prep**: ícone, keystore, export presets, ASSETS_LICENSES.md, README

## 9. Critérios de aceite
- Suíte GUT verde em headless; zero warnings gdlint; zero dead code
- 30 fases merge + 10 TD jogáveis ponta a ponta com save funcional
- Simulação: win-rate 60–80% com habilidade média
- FPS ≥ 50 com 30 inimigos ativos; sem alocação por frame no loop quente
- Licenças documentadas
