# Plano: Merge Defense (Godot 4 + Android) usando 100% dos assets de C:\src\assets\craftpix-ne

## 1. Resultado da verificação da pasta C:\src\assets\craftpix-ne

Pack Craftpix "Merge Defense – Cats vs... (zumbis)" (Ride the Wave / Merge Defense design original). 2.791 PNGs + outros formatos. Conteúdo:

| Pasta | Conteúdo |
|---|---|
| `Png\Ui` (~110 arquivos) | HUD completo: `LandingScreen.png` (splash/menu), `Logo.png`, `LevelMap.png` + `LevelMap_Bg_Screen.png`, `WinPopUp.png`/`LosePopUp.png`/`WinBonus.png`, `ShopScreen.png` + caixas (`ShopBoxGreen`, `BlueShopBox`, `OrangeShopBox`) + `ShopIcon1..7.png`, `CatUpgradeScreen.png`, `AddonScreen.png`, botões (verde/laranja/shop/tabs/música/som/vibra/ajuda/settings), barras (`0Bar..5Bar`, `CoinBar`, `GemsBarBg`, `WaveBar`, `ScrollBar*`), ícones (`CoinIcon`, `GemsIcon`, `Icon_house/Shop/Cat/Addon`, `Uplogo1..15`, `Up0..Up3`, `GreenLevel`, `OrangeLvl`, `Locked*`, `SelectedBorder`) |
| `Png\Characters\C1..C15` | 15 gatos-torres, cada um `Idle` (20 frames) + `Shoot` (10 frames) |
| `Png\Cat Guardian`, `Png\CatBoxing` | 2 personagens especiais com Attack/Idle (suporte ao merge design) |
| `Png\Enemies\Enemy Reg 1..8` | 8 inimigos regulares, cada um com Attack, Dead (60f), Idle (20f), Walk (35f) |
| `Png\Enemies\Enemy Boss 1..7` | 7 chefes com as 4 animações |
| `Png\Bullets` | 3 sprites de projétil (`Artboard 1*.png`) |
| `Png\Explosion` | 20 frames de explosão (`ExplosionFx-*`) |
| `Png\ShootFx` | 15 frames de efeito de tiro |
| `Png\Area\Area1..5.png` | 5 imagens de cenário/área (fundo da fase) |
| `Json Atlas` | 34 atlas (.png+.json) de todos os personagens (alternativa otimizada a frames soltos) |
| `Spine` | Esqueletos Spine (não usaremos — Godot 4 sem addon) |
| `Ai`/`Eps`/`Preview` | Fontes vetoriais e previews (não entram no build) |
| `license.txt` / `Font Link.txt` | Licença Craftpix; fonte sugerida **Passion One** (Google Fonts) |

**Conclusão:** o pack contém TUDO para um Merge Defense completo: splash, menu, mapa de níveis, vitória, derrota, loja, upgrade de gatos, moedas/gemas, torres (gatos), projéteis, inimigos, chefes, efeitos e fundo de fase.

## 2. Mapeamento de arquivos de asset por telas/mecânica (1 fase)

- **Splash:** `Ui\LandingScreen.png`, `Ui\Logo.png`
- **Tela principal:** `LevelMap.png`, `LevelMap_Bg_Screen.png`, `GreenLevel.png` (nível 1 ativo), `LockedLevel.png`, `OrangeBTNAds`, `Icon_house/Shop/Cat/Addon.png`
- **Vitória/Derrota:** `WinPopUp.png`, `WinBonus.png`, `LosePopUp.png`, `BgPaused.png`
- **Mapa/fase:** `Png\Area\Area1.png` (fundo da fase 1)
- **Personagens/torres (merge):** `Characters\C1..C5\{Idle,Shoot}` (níveis 1–5 do merge para a fase 1)
- **Armas/tiros:** `Bullets\Artboard 1.png` (projétil base) + `ShootFx\Fx2-animation_*.png` (tiro), `Explosion\ExplosionFx-*.png` (impacto)
- **Inimigos:** `Enemy Reg 1..3` nas ondas + `Enemy Boss 1` como chefe final da fase
- **Moedas/economia:** `CoinIcon.png`, `GemsIcon.png`, `CoinBar.png`, `GemsBarBg.png`
- **Tela de compra (shop):** `ShopScreen.png`, `ShopBoxGreen/BlueShopBox/OrangeShopBox.png`, `ShopIcon1..7.png`, `BtnShopYellow/BtnShopDisable`, `OrangeLvl.png`
- **HUD de jogo:** `CoinBar/GemsBarBg` topo, `WaveBar.png`, `0Bar..5Bar.png` (vida), `BtnGreen*`, `AddOnSlotBtn.png`, `SettingBtn.png`, `BtnTab_*`
- **Upgrade/Addons:** `CatUpgradeScreen.png`, `AddonScreen.png`, `AddonIcon1..8.png`, `Up0..Up3.png`, `Uplogo1..15.png`

## 3. Arquitetura do jogo (Godot 4.x, GDScript, portrait 1080x2400, stretch=canvas_items mobile)

Cenário da fase: base defensiva na direita, caminho à esquerda; grade de slots à esquerda do caminho (ex. 4x3). Ondas de inimigos percorrem o caminho tentando alcançar a base; gatos atiram automaticamente.

### Ciclo do Merge Defense
1. Arrastar/dropar gato de nível N em slot livre (toque mobile)
2. Comprar gato nível 1 com moedas (Shop)
3. Mesclar 2 gatos mesmo nível → nível N+1 (maior dano, sprite C{n+1})
4. Inimigos mortos deixam moedas (CoinIcon + anim)
5. Sobreviver a todas as ondas + chefe → WinPopUp; base HP = 0 → LosePopUp

### Estrutura de código (sem duplicação)
```
res://scenes/{splash, main_menu, level_select, shop_screen, upgrade_screen, game, win_popup, lose_popup}
res://scripts/core/{game_state.gd, save_system.gd, audio_manager.gd, scene_router.gd, settings.gd}
res://scripts/data/{cat_data.gd, enemy_data.gd, wave_data.gd, weapon_data.gd}   (Resources)
res://scripts/entities/{cat_tower.gd, enemy.gd, boss_enemy.gd, bullet.gd, coin.gd, base.gd}
res://scripts/systems/{merge_system.gd, economy.gd, wave_manager.gd, spawn_manager.gd, targeting.gd}
res://scripts/ui/{hud.gd, shop_ui.gd, popup_ui.gd, buttons/*}
tests/gut/... (framework GUT)  + scripts/validate_assets.gd
tools/export_android.ps1, tools/run_emulator.ps1, tools/build_install_play.ps1
```
- **Dados em Resources** (`EnemyData`, `CatData`, `WaveData`) — sem números mágicos; instâncias carregam frames via helper único `FrameLoader` (carrega diretório de PNGs → SpriteFrames)
- **Autoload** comuns: `GameState`, `SceneRouter`, `AudioManager`, `SaveSystem`
- Sinais para comunicação; zero `get_node()` solto; princípios SOLID/DRY; tipagem estática GDScript
- **Nota:** usar os PNGs soltos com `AnimatedSprite2D` (mais simples e compatível com GLES/Android do que processar Json Atlas; Atlas pode virar otimização futura)

## 4. Qualidade, testes e verificação
- **Testes automatizados com GUT**: `merge_system` (merge válido/inválido/nível máximo), `economy` (compra, saldo, recompensa de kill), `wave_manager` (progressão, fim de fase), `targeting` (alcance, primeiro alvo), `damage/life`, `save_system` (round-trip)
- **Regressão visual**: testes de fumaça carregando cada cena e validando que todos os `SpriteFrames` têm frames > 0
- **`validate_assets.gd`**: script headless (`godot --headless -s`) que varre a lista de assets exigidos e falha com lista de faltantes
- Checagem estática: `godot --check-only` em CI local + smoke build

## 5. Android + Emulador "Redmi Note 14 Pro + 5G"
- Configurar **Godot 4.x + export templates + Android SDK/JDK**
- Export `export_presets.cfg` → `build/merge-defense.apk` (com keystore debug gerada automaticamente)
- **AVD** `Redmi_Note_14_Pro_Plus_5G`: 6.67", **1220x2712**, density 480dpi, Android 14 (API 34), 8GB RAM — criado via `avdmanager` (nome aproximado; hardware profile XML customizado em `devices.xml`)
- **Scripts PowerShell em `tools/`**:
  - `setup_emulator.ps1` — cria o AVD se não existir
  - `build_install_play.ps1` → fluxo completo: valida assets → roda testes GUT → compila APK (`godot --headless --export-release`) → inicia emulador → `adb wait-for-device` → `adb install -r` → `adb shell monkey -p com.studio.mergedefense` → janela pronta para jogo manual
- Parâmetros: `-SkipTests`, `-BuildOnly`, `-Fresh`

## 6. Entregáveis desta execução (após aprovação)
1. **`.ai\plan\01-merge-defense-game-plan.md`** — este plano completo gravado em arquivo (passo 1)
2. Projeto Godot 4.x em `C:\src\cats-defender\godot/` (raiz do projeto) com todas as cenas e sistemas acima, apenas assets copiados de `C:\src\assets\craftpix-ne` para `res://assets/`
3. `assets_manifest.json` gerado + validador
4. Suíte GUT + CI local (`run_checks.ps1` = check + tests + validate + build)
5. `tools/*.ps1` (setup, build, emulator, build+install+play)
6. APK debug + instruções `README.md` para o fluxo Redmi Note 14 Pro + 5G

## 7. Etapas de implementação (ordem)
1. Gravar `.ai\plan\01-merge-defense-game-plan.md`
2. Criar projeto Godot + copiar seletivamente os assets listados na seção 2 (com .import, compressão ETC2/ASTC)
3. Core: autoloads, SceneRouter, SaveSystem, dados (Resources), FrameLoader
4. Cenas: Splash → Menu → LevelSelect(1 nível) → Game (board, puxar/mesclar, ondas, base) → Win/Lose popups; Shop e Upgrade screens
5. Sistemas: merge, economia, waves, targeting, bullets/FX (ShootFx, Explosion), coins
6. Cena de teste headless + suíte GUT + validate_assets
7. Export Android, AVD, scripts, APK + validação manual no emulador
8. `run_checks.ps1` final: check → tests → build → install → launch

## 8. Critérios de aceitação
- `run_checks.ps1` passa de ponta a ponta (0 falhas, 0 warnings nos testes)
- Todos os assets usados vêm exclusivamente de `C:\src\assets\craftpix-ne`
- Fase 1 completa: 5 ondas regulares + escala de dificuldade + chefe; vitória e derrota funcionais
- Merge, compra (com moedas), loja, popups, pause/settings funcionando
- APK instala e abre no emulador "Redmi Note 14 Pro + 5G" via `build_install_play.ps1`

## 9. Premissas/explicitações
- Godot **4.2.x** (LTS) com export presets oficiais; versão exata será a definida ao criar `project.godot`
- Keystore **debug** gerada automaticamente; release requer keystore do usuário (fora de escopo)
- Áudio: o pack não inclui sons → uso de `AudioStreamPlayer` com efeitos gerados ou silêncio por padrão (documentado; NÃO criar som de outra origem, manter toggle de som/música funcional mas mutável). Caso o usuário queira, apontar fonte de áudio posteriormente.
- Uma única fase jogável, mas arquitetura já preparada para múltiplas (LevelSelect com `LockedLevel.png`)
- "Armas" do pedido = projéteis dos gatos (o pack não tem ítens de arma separados; `Uplogo*` representam upgrades)