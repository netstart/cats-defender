# Plano: Merge Defense (Godot 4 + Android) usando 100% dos assets de C:\src\assets\craftpix-net

## 1. Resultado da verificação da pasta C:\src\assets\craftpix-net

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
- **Personagens/torres (merge):** `Characters\C1..C15\{Idle,Shoot}` (cadeia completa de merge: níveis 1–15 — decisão: máximo aproveitamento dos assets)
- **Unidades especiais melee:** `Cat Guardian` + `CatBoxing` (`Attack`/`Idle`) — slots na frente do caminho: alcance curto em área; Guardian com passiva de escudo na base (mecânica — seção 4)
- **Armas/tiros (3 arquétipos):** `Bullets\Artboard 1.png` (tiro reto), `Bullets\Artboard 1 copy.png` (tiro lento/slow), `Bullets\Artboard 1 copy 2.png` (granada balística explosiva) + `ShootFx\Fx2-animation_*.png` (tiro), `Explosion\ExplosionFx-*.png` (impacto)
- **Inimigos (8 arquétipos):** `Enemy Reg 1..8` — corredor rápido, tanque lento, cerco e suporte distribuídos nas 5 ondas (mistura por onda dá identidade a cada onda) + `Enemy Boss 1` como chefe final da fase
- **Moedas/economia:** `CoinIcon.png`, `GemsIcon.png`, `CoinBar.png`, `GemsBarBg.png`
- **Tela de compra (shop):** `ShopScreen.png`, `ShopBoxGreen/BlueShopBox/OrangeShopBox.png`, `ShopIcon1..7.png`, `BtnShopYellow/BtnShopDisable`, `OrangeLvl.png`
- **HUD de jogo:** `CoinBar/GemsBarBg` topo, `WaveBar.png`, `0Bar..5Bar.png` (vida), `BtnGreen*`, `AddOnSlotBtn.png`, `SettingBtn.png`, `BtnTab_*`
- **Upgrade/Addons:** `CatUpgradeScreen.png`, `AddonScreen.png`, `AddonIcon1..8.png`, `Up0..Up3.png`, `Uplogo1..15.png`
- **Áudio (exceção documentada — seção 12):** pack externo CC0 (ex.: Kenney) para SFX/música, pois o pack Craftpix não inclui áudio
- **Fonte (exceção documentada — seção 12):** `Font Link.txt` → **Passion One** (primária) + fonte built-in do Godot (fallback)

## 3. Arquitetura do jogo (Godot 4.x, GDScript, portrait 1080x2400, stretch=canvas_items mobile)

Cenário da fase: base defensiva na direita, caminho à esquerda; grade de slots à esquerda do caminho (ex. 4x3). Ondas de inimigos percorrem o caminho tentando alcançar a base; gatos atiram automaticamente.

### Ciclo do Merge Defense
1. Arrastar/dropar gato de nível N em slot livre (toque mobile; fantasma do gato no dedo + highlight do slot válido/inválido)
2. Comprar gato nível 1 com moedas (Shop)
3. Mesclar 2 gatos mesmo nível → nível N+1 (maior dano, sprite C{n+1}; glow de preview ao arrastar sobre par válido)
4. Comprar Addon em slot (`AddOnSlotBtn`) com moedas: buff de +dano/+alcance nos gatos (mecânica — seção 5)
5. **Pacing de ondas:** pausa de preparação entre ondas + banner Onda N (`WaveBar`) + botão iniciar agora com recompensa extra de Coins (gerenciar risco)
6. Inimigos avançam no caminho; os que alcançam a base entram em **cerco** — param ao lado e atacam (anim `Attack`, DPS de cerco) até serem derrubados; base sem HP → LosePopUp
7. Inimigos mortos deixam moedas (CoinIcon: cai com gravidade → 1 quique no chão → voa até o CoinBar)
8. Sobreviver a todas as ondas + chefe (barra de HP + **enrage a 50%**) → WinPopUp com estrelas 1–3 → recompensa de gems escalada pelas estrelas (`WinBonus`)

### Estrutura de código (sem duplicação)
```
res://scenes/{splash, main_menu, level_select, shop_screen, upgrade_screen, game, win_popup, lose_popup}
res://scripts/core/{game_state.gd (state machine), event_bus.gd, save_system.gd (versionado), audio_manager.gd, scene_router.gd, settings.gd, localization.gd}
res://scripts/data/{cat_data.gd, enemy_data.gd, wave_data.gd, weapon_data.gd, addon_data.gd}  (Resources) + res://data/balance.csv
res://scripts/entities/{cat_tower.gd, enemy.gd, boss_enemy.gd, bullet.gd, coin.gd, base.gd, damage_number.gd}
res://scripts/systems/{merge_system.gd, economy.gd, wave_manager.gd, spawn_manager.gd, targeting.gd, addon_system.gd, object_pool.gd, status_effects.gd}
res://scripts/ui/{hud.gd, shop_ui.gd, popup_ui.gd, tutorial/*, buttons/*}
tests/gut/... (framework GUT) + scripts/validate_assets.gd + scripts/balance_sim.gd
tools/*.ps1 + .github/workflows/ci.yml
```
- **Dados em Resources** (`EnemyData`, `CatData`, `WaveData`, `AddonData`) — sem números mágicos; instâncias carregam frames via helper único `FrameLoader` (carrega diretório de PNGs → SpriteFrames, com **carregamento lazy por fase** para não estourar memória no Android)
- **Autoload** comuns: `GameState` (**state machine explícita**: MENU → LEVEL_SELECT → PLAYING → PAUSED → WIN/LOSE), `EventBus` (bus de sinais globais, evita acoplamento entre cenas), `SceneRouter`, `AudioManager`, `SaveSystem`, `Localization`
- **Save versionado**: campo `version` + função `migrate()` — nunca quebrar save em atualização
- Sinais via `EventBus`; zero `get_node()` solto; princípios SOLID/DRY; tipagem estática GDScript
- **Object pooling** (`object_pool.gd`) para `bullet`, `coin`, `damage_number`, `shoot_fx`, `explosion` — obrigatório para 60 FPS no Android
- **Input mobile**: `InputEventScreenTouch`/`ScreenDrag` com mouse-emulation OFF no Android; drag & drop com "fantasma" seguindo o dedo e highlight do slot (`SelectedBorder.png`)
- **Android UX:** back button pausa/sai com confirmação; pausa automática ao perder foco; HUD com safe-area anchors (notch/punch-hole do 1220x2712)
- **Determinismo:** ondas/dano em timestep fixo (fixed step) para testes reproduzíveis com seed
- **Performance:** `max_fps`/vsync estáveis; texturas ETC2/ASTC sem mipmaps, filtro configurado
- **Localização:** todos os textos via CSV do Godot (PT-BR + EN) desde o dia 1 (`localization.gd`)
- **Unidades melee (A4):** `cat_tower.gd` com `CatData.attack_mode` = `ranged` | `melee` — Guardian/Boxing atacam corpo a corpo na frente; passiva do Guardian: +escudo na base
- **Status `slow` (A3):** `status_effects.gd` — projétil lento reduz a velocidade do inimigo (fator + duração, empilhamento limitado), decai em fixed step
- **Autosave entre ondas (B3):** `SaveSystem` persiste onda atual, board, moedas e addons ao fim de cada onda → partida interrompida é retomável (save versionado)
- **Nota:** usar os PNGs soltos com `AnimatedSprite2D` (mais simples e compatível com GLES/Android do que processar Json Atlas; Atlas pode virar otimização futura — medir draw calls antes de migrar)

### Física e colisão

- **Tabela de Physics Layers:** `1=enemies`, `2=bullets`, `3=base (sensor)`, `4=slots` — masks: bullet→enemy, enemy→base; nenhum corpo físico fora dessa tabela
- **Detecção de dano:** `Area2D` em bullets e base; **desligar `monitoring` ao devolver ao pool** (evita hits fantasma em objetos reciclados)
- **Movimento dos inimigos é cinemático** (progresso manual/`PathFollow2D` no caminho) — **nenhum `RigidBody2D` no gameplay**, preserva o determinismo do `balance_sim`
- **Anti-overlap:** separação leve por posicionamento quando inimigos se sobrepõem (sem física)
- **Cerco à base (A1):** contato `enemy→base` coloca o inimigo em estado `SIEGE` (para ao lado da base e aplica DPS com a anim `Attack`); knockback o desgruda e retoma o avanço
- **Integração em fixed step:** balística (`v.y += g·dt`), knockback e queda de moedas rodam no timestep fixo; `_process` só interpola o visual — testes reproduzíveis por seed

## 4. Game design premium (feel, UX e progressão)

- **Game feel (juice):** flash branco + knockback sutil no inimigo ao levar dano; números de dano flutuantes (`damage_number.gd`); screen shake leve apenas no impacto de boss; todos os popups entram com Tween/easing (nunca aparecer "seco"); haptics `Input.vibrate_handheld()` no merge e no dano da base, respeitando o toggle de vibração do HUD
- **Knockback formalizado:** impulso `kick_offset` na direção contrária ao avanço ao ser atingido; decai exponencialmente até 0 no fixed step; **clampado ao caminho** (nunca sai do spawn nem atravessa a base); boss com resistência (ex.: 0,2×) — força/decaimento no `balance.csv`
- **Queda de moedas com gravidade:** a moeda cai do inimigo, dá **1 quique no chão** e só então voa até o CoinBar
- **Partículas com gravidade:** brasas da explosão caem e a fumaça sobe (`gravity` nos `Particles2D`)
- **Projéteis balísticos (gravidade):** gatos de níveis altos (ex.: C10+) disparam granadas em arco (`gravity_scale` por arma no `WeaponData`) com **interceptação** do inimigo em movimento, dano em área + explosão no impacto; gatos comuns `gravity_scale=0` (tiro reto)
- **Tutorial guiado na fase 1:** seta/banner com `SelectedBorder.png` ("arraste aqui", "toque para comprar") — onboarding em 30 s
- **Preview de merge:** ao arrastar um gato sobre outro do mesmo nível, glow de confirmação + tooltip "dano atual → próximo"
- **Painel de info por long-press:** dano, alcance e DPS do gato selecionado
- **Pause menu completo:** continuar / reiniciar / sair (`BgPaused.png`), com toggles de som/música/vibração
- **Vitória com estrelas 1–3** (critério: HP restante + tempo) para rejugabilidade da fase única
- **Targeting configurável por `CatData`:** `first` / `last` / `strongest` / `closest` (estratégia, não só "primeiro alvo")
- **HP bars flutuantes (B1):** barra de vida sobre inimigos — sempre no boss, opcional nos normais; desenhada via `TextureProgressBar` + shader (pack não inclui sprite de barra de inimigo)
- **Feedback de dano na base (B2):** flash vermelho de borda da tela + haptic + segmentos `0Bar..5Bar` mapeados ao HP restante (6 estados: cheio → vazio)
- **Enrage do chefe (A7):** barra de HP do chefe visível + a 50% HP entra em enrage (velocidade/dano ↑) — multiplicadores no `balance.csv`
- **Loop estrelas → gems (B4):** no `WinBonus`, 1–3 estrelas convertem-se em gems (fechamento do loop de recompensa)
- **Velocidade 2× (C3):** botão de acelerar onda (reusa `BtnGreen*`) — ritmo mobile; pausável; testes continuam em fixed step
- **`OrangeBTNAds`:** asset mapeado no mapa de níveis, **sem comportamento definido** (sem SDK de anúncios no escopo — decidir em etapa futura)

## 5. Economia, balanceamento e Addons

- **Fontes e usos de moeda (sources/sinks):**
  - **Coins:** ganhos = kills + ondas + vitória; usos = comprar gato (Shop), upgrade permanente (`CatUpgradeScreen`), comprar Addons
  - **Gems:** ganhos = recompensa de vitória escalada por estrelas (`WinBonus`); usos = itens premium da loja (sem SDK de ads no escopo)
- **Addons (mecânica definida):** slots de addon (`AddOnSlotBtn`, `AddonScreen`) com 8 ícones (`AddonIcon1..8`); cada addon comprável com Coins aplica buff (ex.: +dano, +alcance, +cadência de tiro) aos gatos, limitado pelos slots disponíveis — profundidade estratégica extra
- **Balanceamento data-driven:** `res://data/balance.csv` (HP base, DPS dos gatos 1–15, recompensa por inimigo, custos de compra/upgrade/addon, curva das 5 ondas + chefe, **física: força/decaimento do knockback, resistência do boss, gravidade `g`/`gravity_scale` dos projéteis, quique de moedas**) — nenhum número hardcoded no código
- **Teste automático de balanceamento:** `balance_sim.gd` roda a fase headless N vezes com seeds fixas e asserta: (a) estratégia otimista (compra+merge+addons) **vence**; (b) estratégia rastrosa (sem merge) **perde** — detecta regressões de balanceamento no CI
- **Venda/devolução de gato (A5):** long-press no gato → botão vender (ou arrastar para fora do board) devolve `sell_refund`% das Coins — board de 12 slots nunca prende o jogador (UI: caixa `ShopBoxGreen`)
- **Upgrade de gatos explícito (A8):** `CatUpgradeScreen` → +dano% global por nível, custo escalando geometricamente — curva e efeitos no `balance.csv` (sink principal de Coins no late game)
- **Novos parâmetros no `balance.csv`:** arquétipos (`Reg 1..8`: HP, velocidade, papel), DPS de cerco, slow (fator/duração/stack), enrage (multiplicadores), `sell_refund`, recompensa por estrela → gems, bônus de "iniciar agora", pausa entre ondas

## 6. Qualidade, testes e verificação

- **Testes automatizados com GUT**: `merge_system` (merge válido/inválido/nível máximo + testes de propriedade: conservação de unidades 2× nível N ≡ 1× nível N+1), `economy` (compra, saldo, recompensa de kill), `wave_manager` (progressão, fim de fase), `targeting` (alcance + as 4 estratégias), `damage/life`, `addon_system` (compra, aplicação de buff), `save_system` (round-trip + migração de versão)
- **Regressão visual**: testes de fumaça carregando cada cena e validando que todos os `SpriteFrames` têm frames > 0
- **`validate_assets.gd`**: script headless (`godot --headless -s`) que varre a lista de assets exigidos e falha com lista de faltantes
- **Teste de integração auto-play**: simulação headless da fase 1 inteira com seed fixa → asserts de vitória com estratégia válida e derrota sem merge (via `balance_sim.gd` — seção 5)
- Checagem estática: `godot --check-only` + **gdlint/gdformat (gdtoolkit)** no CI local + smoke build
- **CI dupla:** local (`run_checks.ps1`) + **GitHub Actions** (`.github/workflows/ci.yml`) rodando check + lint + tests + validate em push/PR
- **Testes de física:** trajetória balística fecha (dado `g`, `v0` → alcance esperado); knockback decai a 0 e nunca ultrapassa os limites do caminho; bullet reciclado do pool não gera hit fantasma (`monitoring` desligado); inimigo nunca ultrapassa progress 1.0 (não atravessa a base)
- **Teste de input simulado (C2):** driver headless de `InputEventScreenTouch`/`ScreenDrag` — drag & drop de gato em slot válido/inválido, merge por soltar sobre par, long-press abre info; gesto crítico coberto sem toque real
- **Testes das mecânicas novas:** cerco (inimigo em SIEGE causa DPS e knockback o desgruda), slow (velocidade cai e decai), venda de gato (refund íntegro de unidade), enrage (50% → multiplicadores), autosave/restore (round-trip no meio das ondas), wave banner + "iniciar agora" (bônus pago ao antecipar)

## 7. Android + Emulador "Redmi Note 14 Pro + 5G"

- Configurar **Godot 4.x + export templates + Android SDK/JDK**
- Export `export_presets.cfg` → `build/merge-defense.apk` (com keystore debug gerada automaticamente)
- **AVD** `Redmi_Note_14_Pro_Plus_5G`: 6.67", **1220x2712**, density 480dpi, Android 14 (API 34), 8GB RAM — criado via `avdmanager` (nome aproximado; hardware profile XML customizado em `devices.xml`)
- **Otimização para ETC2/ASTC**: texturas comprimidas suportadas pelas configurações de qualidade do Android
- **Scripts PowerShell em `tools/`**:
  - `setup_emulator.ps1` — cria o AVD se não existir
  - `build_install_play.ps1` → fluxo completo: valida assets → roda testes GUT → compila APK (`godot --headless --export-release`) → inicia emulador → `adb wait-for-device` → `adb install -r` → `adb shell monkey -p com.studio.mergedefense` → janela pronta para jogo manual
- Parâmetros: `-SkipTests`, `-BuildOnly`, `-Fresh`
- `version_code`/`version_name` no `export_presets.cfg` desde a primeira build
- **Log de debug:** escrever em `user://logs` para diagnóstico no emulador
- Orçamento de performance: **60 FPS** no emulador com ondas ativas; **APK ≤ 200 MB** (critérios — seção 10)

## 8. Entregáveis desta execução (após aprovação)

1. **`.ai\plan\01-merge-defense-game-plan.md`** — este plano completo gravado em arquivo (passo 1)
2. Projeto Godot 4.x em `C:\src\cats-defender\godot/` (raiz do projeto) com todas as cenas e sistemas acima, assets de imagem copiados de `C:\src\assets\craftpix-net` para `res://assets/` (áudio/fonte: exceções da seção 12)
3. `assets_manifest.json` gerado + validador
4. Suíte GUT (unit + propriedade + auto-play) + `validate_assets.gd` + lint (gdlint/gdformat) + CI local (`run_checks.ps1` = check + lint + tests + validate + build)
5. `tools/*.ps1` (setup, build, emulator, build+install+play)
6. APK debug + instruções `README.md` para o fluxo Redmi Note 14 Pro + 5G
7. `.github/workflows/ci.yml` (GitHub Actions — check + lint + tests + validate em push/PR)
8. `data/balance.csv` + `balance_sim.gd`; localização PT-BR/EN (CSV); áudio CC0 + fonte Passion One (exceções da seção 12)

## 9. Etapas de implementação (ordem)

**Abordagem: vertical slice primeiro** (valida touch/drag no emulador cedo), depois a largura completa:

**Definition of Done (DoD) por etapa (C1):** etapa só avança quando (a) código implementado e `--check-only` limpo, (b) testes GUT novos correspondentes verdes, (c) `validate_assets` sem faltantes, (d) smoke manual no emulador quando afetar UI/gameplay.
1. Gravar `.ai\plan\01-merge-defense-game-plan.md`
2. Criar projeto Godot (versão estável 4.x fixada em `project.godot`) + copiar seletivamente os assets da seção 2 (com .import, compressão ETC2/ASTC) + exceções da seção 12 (áudio CC0, fonte Passion One)
3. **Vertical slice jogável:** board mínimo com 2 slots, 1 gato, 1 inimigo, merge manual, dano/moeda — validar drag & drop por toque no emulador
4. Core: autoloads (GameState state machine, EventBus), SceneRouter, SaveSystem versionado, Localization, dados (Resources), FrameLoader, object pool
5. Cenas: Splash → Menu → LevelSelect(1 nível) → Game (board, puxar/mesclar, ondas, base) → Win/Lose popups; pause menu; tutorial guiado; Shop, Upgrade e Addon screens
6. Sistemas: merge (C1..C15), economia (sources/sinks, venda de gato, upgrade), addons, waves (pacing/banner/iniciar agora), targeting (4 estratégias), cerco (SIEGE), slow, enrage, melee (Guardian/Boxing), bullets 3 arquétipos (pool), juice, estrelas→gems, velocidade 2×, autosave
7. Balanceamento data-driven: `balance.csv` + `balance_sim.gd`
8. Suíte GUT + propriedade + input simulado + mecânicas novas + auto-play headless + validate_assets + gdlint/gdformat
9. Export Android, AVD, scripts, APK + validação manual no emulador
10. CI: `run_checks.ps1` local + workflow GitHub Actions
11. `run_checks.ps1` final: check → lint → tests → validate → build → install → launch

## 10. Critérios de aceitação

- `run_checks.ps1` passa de ponta a ponta (0 falhas, 0 warnings nos testes) e o workflow GitHub Actions verde
- Assets de imagem exclusivamente de `C:\src\assets\craftpix-net`, ressalvadas as exceções documentadas na seção 12 (áudio CC0, fonte Passion One)
- Fase 1 completa: 5 ondas regulares + escala de dificuldade + chefe; vitória (com estrelas 1–3) e derrota funcionais
- Merge C1..C15, compra (com moedas), loja, addons, popups, pause/settings, tutorial funcionando
- **Sons de áudio CC0 funcionando no jogo** (exceção aprovada — seção 12)
- **Texturas comprimidas ETC2/ASTC funcionando corretamente no emulador Android**
- **Métricas:** 60 FPS estáveis no emulador durante ondas com pool ativo; APK ≤ 200 MB; troca de tela < 1 s; 0 "missing asset"/erro no log do Godot
- **Mecânicas novas funcionando:** cerco, venda de gato, banner de onda + iniciar agora, slow, melee (Guardian/Boxing), enrage, HP bars, 0Bar..5Bar, estrelas→gems, velocidade 2×, autosave/restore no meio da onda
- APK instala e abre no emulador "Redmi Note 14 Pro + 5G" via `build_install_play.ps1`

## 11. Riscos e mitigações
| Risco | Mitigação |
|---|---|
| Godot 'última estável 4.x' pode ter breaking changes nas APIs Android | Fixar versão exata em `project.godot` + export templates; validar export já na etapa 9 |
| Cadeia de merge C1..C15 exige mais balanceamento | `balance.csv` data-driven + `balance_sim.gd` automatizado (seção 5) |
| AVD de perfil custom 'Redmi Note 14 Pro + 5G' pode falhar no setup | `setup_emulator.ps1` idempotente; fallback para AVD genérico 1080x2400 |
| PNGs soltos podem gerar muitos draw calls no Android | Medir no emulador; Json Atlas do pack (34 atlas) como plano B |
| Exceções de assets externos (áudio/fonte) | Exceções documentadas na seção 12; fallback built-in do Godot sempre disponível |
| Escopo de mecânicas cresceu (16 novas) — risco de prazo | Priorização: vertic slice → grupo 🔴 → 🟠 → 🟡; DoD por etapa corta atraso cedo |

## 12. Premissas/explicitações (inclui decisões registradas)

- Godot **última versão estável 4.x** (decisão registrada — substitui o anterior 4.2.x LTS; mitigação na seção 11); versão exata fixada ao criar `project.godot`
- Keystore **debug** gerada automaticamente; release requer keystore do usuário (fora de escopo)
- **Áudio — exceção aprovada:** pack de áudio externo CC0 (ex.: Kenney) para SFX/música, pois o pack Craftpix não inclui sons; toggles de som/música permanecem funcionais
- **Fonte — exceção aprovada:** Passion One (indicada pelo próprio pack via `Font Link.txt`) como primária + fonte built-in do Godot como fallback
- **Addons:** mecânica definida na seção 5 (buffs compráveis em slots) — em escopo
- **HP bars flutuantes (B1):** barra de vida sobre inimigos — sempre no boss, opcional nos normais; desenhada via `TextureProgressBar` + shader (pack não inclui sprite de barra de inimigo)
- **Feedback de dano na base (B2):** flash vermelho de borda da tela + haptic + segmentos `0Bar..5Bar` mapeados ao HP restante (6 estados: cheio → vazio)
- **Enrage do chefe (A7):** barra de HP do chefe visível + a 50% HP entra em enrage (velocidade/dano ↑) — multiplicadores no `balance.csv`
- **Loop estrelas → gems (B4):** no `WinBonus`, 1–3 estrelas convertem-se em gems (fechamento do loop de recompensa)
- **Velocidade 2× (C3):** botão de acelerar onda (reusa `BtnGreen*`) — ritmo mobile; pausável; testes continuam em fixed step
- **`OrangeBTNAds`:** asset mapeado no mapa de níveis, **sem comportamento definido** — decisão adiada, fora do escopo desta execução
- **CI:** GitHub Actions (`.github/workflows/ci.yml`) além do CI local `run_checks.ps1`
- Uma única fase jogável, mas arquitetura já preparada para múltiplas (LevelSelect com `LockedLevel.png`)
- "Armas" do pedido = projéteis dos gatos (o pack não tem ítens de arma separados; `Uplogo*` representam upgrades)