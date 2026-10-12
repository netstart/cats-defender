# Plano: Merge Defense (Godot 4, Android) com Craftpix e assets visuais CC0 (cobertura rastreada)

você vai criar um jogo que eu possa testar localmente utilizando apenas o Godot, quero que na pasta do projeto tenha um diretório com o Godot disponível para execução, carregamento do jogo pra eu poder testar o jogo manualmente no Godot. Também quero que seja possível testar em um emulador do Android. Para os dois casos você deve disponibilizar um script que me permita iniciar o jogo individualmente em cada um.

Antes de começar, analise a pasta do Craftpix disponível em C:\src\assets\craftpix-net
* analise
* identifique personagens, terrenos, água, vegetação, clima, construções, e props disponíveis
* entenda o tamanhos, spritesheets e animações existentes;
* NÃO GERE ARTE NOVA
* Não substitua assets por formas próprias se já existir algo adequado
* 

Deve entregar o melhor jogo completo, funcional, bonito, polido divertido

Você deve atuar simultaneamente como:
* Desenvolvedor sênior de jogos
* Especialista em Game Designer;
* Especialista em Level Designer;
* especialista em UI/UX Designer;
* Tecnical Art;
* Integrador de Pixel Art;
* Programador de Gameplay
* Roteirista / Escritor de Narrativa, Narrative Designer
* Comcept artist
* Modelador e animador 2D e 3D
* Designer de Som / Compositor
* Game Tester

Você deve fazer pesquisas na internet e encontrar referências dos jogos, estudar e compreender como funciona o jogo Plants versus Zombies que é a referência para este jogo, deve criar um clone do mesmo mas utilizando a temática dos gatos. Na suas pesquisas analise imagens, game play, vídeos, e descrições, capturando jogabilidade, design, sons, efeitos, mecânicas do jogo, economia, avanço entre frases, atualizações para ficar mais forte, não se limite a estes itens, analise tudo que faz parte do jogo Plants versus Zombies para criar o melhor clone, divertido e jogável, sem copiar conteúdo do Plants versus Zombies.





> **Versão 8 — eficiência e orçamento de recursos.** O jogo deve ser construído com práticas de arquitetura, conteúdo e profiling que mantenham baixo uso de CPU, RAM, GPU e armazenamento, com limites mensuráveis verificados durante todo o desenvolvimento (`[M38]`, seções 3.8, 6.1, 7 e 10).

## 0. Revisão especialista — resumo dos achados

**Legenda de prioridade** (também define os grupos 🔴🟠🟡 usados na seção 9.2 e 11, que antes não tinham legenda):
- 🔴 **Crítico** — compromete viabilidade, legalidade ou o build; resolver antes de implementar
- 🟠 **Importante** — gera retrabalho ou bug provável se ignorado
- 🟡 **Desejável** — qualidade e polimento

| ID | Prio | Achado | Ação | Seção |
|---|---|---|---|---|
| M01 | 🔴 | **Cadeia C1..C15 é matematicamente inalcançável com 12 slots e merge 2:1.** Nível máximo = nº de slots (12); C13–C15 nunca existem, e C12 já exige 2.048 compras de nível 1 (C15 = 16.384). | Gating de tiers por fase + "nível de compra" como upgrade + slots extras; `balance_sim` reporta tier máximo alcançável; C13–C15 testados via debug menu | 3, 5, 10 |
| M02 | 🔴 | **Licença CraftPix e distribuição dos arquivos-fonte.** O pack usado é o freebie oficial Free Cartoon Cat Defense Game Asset Kit; a licença de arquivos permite uso comercial e distribuição do jogo, mas proíbe redistribuir/expor arte-fonte para extração. | Arquivar a [página exata do produto](https://craftpix.net/freebies/free-cartoon-cat-defense-game-asset-kit/) e a [licença oficial](https://craftpix.net/file-licenses/), registrar assets/hash/manifests e inspecionar o APK para garantir que só sejam recursos integrados ao jogo | 2, 7, 8, 11 |
| M03 | 🔴 | **Export inconsistente:** `--export-release` exige keystore *release*; o plano usa keystore debug e entrega "APK debug". Godot não gera keystore debug em modo headless. | Usar `--export-debug`; `setup` gera a keystore com `keytool` e exporta as variáveis de ambiente | 7 |
| M04 | 🔴 | **Contradição de autosave:** B3 salva "ao fim de cada onda", mas a aceitação/testes exigem restore "no meio da onda". | Checkpoint no fim de onda **e** em `FOCUS_OUT`/pausa, incluindo estado do RNG | 3, 6, 10 |
| M05 | 🔴 | **O alvo de orientação é landscape (celular deitado)**; todas as telas e a rota/grade precisam caber sem corte em diferentes aspect ratios e safe areas. | Wireframe landscape 1200×540, orientação horizontal, adaptação de HUD/grade/controles e QA em 16:9 e 20:9 | 3, 6, 7 |
| M06 | 🔴 | **Falta auditoria de assets** (dimensões, orientação, texto embutido nos PNGs de UI, pivôs, tamanho total). Texto "baked" em inglês quebra a localização PT-BR/EN. | Etapa 0: `assets_audit.md` gerado por script | 2, 9 |
| M07 | 🔴 | **Orçamento de memória/APK não estimado.** Frames soltos (Dead 60f × 15 inimigos, Idle 20f × 15 gatos…) podem estourar RAM e APK; Godot exporta tudo por padrão (inclusive Spine/Ai/Eps). | Estimativa na Etapa 0, `exclude_filter`, subamostragem de frames, *gate* de decisão Atlas no vertical slice | 3, 7 |
| M08 | 🔴 | **Simulação acoplada a nós** torna `balance_sim` lento e o determinismo frágil; `Area2D` a 60 Hz com projéteis rápidos pode "atravessar" alvos. | Núcleo de simulação puro (sem `Node`), RNG injetado, caminho 1D, hit-test analítico; a view só renderiza | 3, 6 |
| M09 | 🟠 | **Renderer não especificado** e `Particles2D` não existe no Godot 4. | Fixar renderer **Compatibility**; usar `CPUParticles2D` | 3, 7 |
| M10 | 🟠 | **Economia ambígua:** "Coins" servem tanto in-run (comprar gato) quanto permanente (upgrade); custo de compra não cresce; gems sem usos concretos; `ShopIcon1..7`/caixas sem mapeamento; `Uplogo1..15` sugerem upgrade **por gato**, mas A8 define upgrade global. | Duas contas (run/bank), curva de custo, tabela de itens da loja, upgrade por gato | 5 |
| M11 | 🟠 | **Balanceamento com só 2 bots** (vence/perde) não detecta curva ruim. | 4 bots + faixas-alvo + teste de sensibilidade ±10% | 5, 6 |
| M12 | 🟠 | **Inimigos sub-especificados:** papel "suporte" sem mecânica; cerco sem limite de atacantes; interação slow × enrage × boss indefinida. | Tabela de arquétipos, `siege_slots`, regras de CC | 3 |
| M13 | 🟠 | **Sincronia animação ↔ gameplay** não definida (frame de disparo, frame de golpe, *foot-sliding*, Dead de 60 frames). | `fire_frame`, `hit_frame`, `speed_scale` por velocidade, Dead acelerado | 3 |
| M14 | 🟠 | **Casos de borda do board** não listados (board cheio, soltar fora, venda acidental, multi-touch, cascata de merge). | Lista de comportamentos + testes | 3, 6 |
| M15 | 🟠 | **Ciclo de vida Android incompleto** (permissão VIBRATE, `quit_on_go_back`, keep-screen-on, alvos de toque, offset do fantasma, aspect ratios, save atômico). | Checklist Android | 3, 7 |
| M16 | 🟠 | **Metas de performance imprecisas** ("60 FPS estáveis" não é mensurável) e emulador não representa dispositivo real. | p95/p99 de frame time, perfil low-end, pre-warm de pools, limite de ticks/frame, verificação de logcat | 7, 10 |
| M17 | 🟠 | **State machine e cenas incompletas:** faltam sub-estados da fase (PREP/WAVE/BOSS) e cenas de pause, settings, addon e credits. | Estados e cenas adicionados | 3 |
| M18 | 🟠 | **Priorização citada mas indefinida** (grupos 🔴🟠🟡, IDs A*/B*/C*). | Tabela de priorização das mecânicas | 9.2 |
| M19 | 🟠 | **Ordem das etapas gera retrabalho:** slice (etapa 3) antes do core (etapa 4); testes só na etapa 8 apesar do DoD exigir testes por etapa; export só na etapa 9. | Core mínimo antes do slice, testes por etapa, export smoke no slice | 9 |
| M20 | 🟠 | **CI e local divergem** e versões não fixadas (Godot, GUT, gdtoolkit). | Mesmo script (`-CI`), versões e checksums fixados, `.gitignore`/`.gitattributes` | 7, 8 |
| M21 | 🟡 | **Acessibilidade/conforto:** flash vermelho, screen shake e flash branco sem opção de redução. | Toggles "reduzir efeitos", contraste, escala de texto | 4 |
| M22 | 🟡 | **Áudio sem arquitetura:** buses, limite de vozes, variação de pitch; licenças (OFL da Passion One, CC0) sem tela de créditos. | Buses + pool de SFX + `credits` | 4, 12 |
| M23 | 🟡 | **Critério de estrelas depende de tempo**, que conflita com 2× e "iniciar agora". | Estrelas por HP restante + eficiência medida em tempo de simulação | 4 |
| M24 | 🟡 | **`OrangeBTNAds` sem comportamento** (botão morto na tela é pior que ausente). | Feature flag `ads_enabled=false`, botão oculto | 12 |
| M25 | 🟡 | **"100% dos assets" é falso na prática** (Spine, Ai/Eps, Boss 2..7, Area2..5 não entram). | Matriz de cobertura + roadmap pós-MVP + `assets_coverage` gerado | 2, 13 |
| M26 | 🟡 | **Sem ferramentas de depuração** para testar C13–C15, chefes e ondas. | Debug menu (apenas build debug) + overlay de performance | 7 |
| M27 | 🟡 | **Preparação para release** não registrada (AAB, target API, package id definitivo). | Nota fora de escopo | 12 |
| M28 | 🟡 | **Erros editoriais:** título "100%", nome do pack truncado, "rastrosa", "vertic slice", referência "seção 4" para melee (é a seção 3), itens duplicados nas seções 4 e 12, IDs A2/A6 ausentes do arquivo. | Corrigidos | todas |
| M29 | 🟠 | **Áudio sem fontes concretas nem rastreio de licença.** O plano dizia só "pack CC0 (ex.: Kenney)"; faltavam packs escolhidos, mapeamento evento → som, lista do que **não** usar para um jogo vendido e prova de licença por arquivo. | Catálogo CC0 pesquisado + mapeamento + `audio_manifest.json` + teste de conformidade | 2, 6, 8, 9, 10, 11, 12.1, 14 |
| M30 | 🟠 | **Efeitos visuais previstos, mas sem cobertura por evento nem limites de acessibilidade/performance.** | Linguagem visual por evento, modo reduzir efeitos, orçamento de partículas/pools e QA visual | 4.1, 6, 10 |
| M31 | 🟠 | **A tela `credits` era citada, mas sem conteúdo definido para licenças, grupos de assets e links para encontrá-los.** | Tela rolável offline, gerada de manifesto, com autores, pacotes, licenças e links de origem | 8, 9, 10, 12.2 |
| M32 | 🟠 | **O jogo tinha tema visual, mas nenhuma história conectando gatos, merges, ondas, refúgio e chefe.** | Premissa curta, tom, sequência narrativa da fase 1, apresentação sem interromper gameplay e strings localizadas | 4.2, 8, 9, 10 |
| M33 | 🟠 | **O plano não define um conjunto amplo de fases bônus nem garante que todas permaneçam tower defense.** | Roadmap com 15 fases bônus (3 por área), desafios data-driven e critérios de desbloqueio/conclusão | 3, 8, 9, 10, 13 |
| M34 | 🟠 | **O plano restringia imagens ao pack Craftpix e não rastreava fontes gratuitas CC0 adicionais.** | Acrescentar candidatos CC0 de VFX, cenário e inimigos, condicionados à auditoria de estilo/licença e registrados no manifesto/créditos | 2, 6, 8, 9, 10, 12.2 |
| M35 | 🟠 | **As fontes externas estavam apenas como candidatos; fases não tinham uso concreto e a distinção entre CC0 e freebies comerciais era insuficiente.** | Pesquisa de pacotes adicionais gratuitos, papéis aprovados/restritos e matriz de uso cobrindo campanha e cada bônus sem abandonar tower defense | 2.3, 8, 12.2, 13 |
| M36 | 🔴 | **Critérios de aceite existiam, mas faltava um gate rastreável que impedisse declarar o jogo concluído com fases, fluxos ou plataformas ainda não testados.** | Matriz requisito→caso→resultado→evidência, testes automatizados e manuais por fase, validação do candidato Android release e regra de bloqueio sem exceções | 6, 9, 10 |
| M37 | 🟠 | **Implementação sequencial limita o paralelismo; agentes compartilhando arquivos podem sobrescrever código, divergir contratos ou validar versões diferentes.** | Frentes independentes em worktrees, contratos congelados, agente integrador, QA em paralelo e reteste obrigatório após integração no mesmo commit | 6, 9.1 |
| M38 | 🔴 | **O plano tinha otimizações pontuais, mas não definia práticas gerais nem limites claros para manter baixo consumo de CPU, RAM e GPU.** | Projeto orientado a orçamento de recursos desde o protótipo, carregamento por demanda, arquitetura de sim/view, limites de memória/frame e profiling/regressão em dispositivos low-end | 3.8, 6.1, 7, 10 |

---

## 1. Resultado da verificação da pasta C:\src\assets\craftpix-net

Pack CraftPix **Free Cartoon Cat Defense Game Asset Kit** (gatos contra zumbis), correspondente à [página oficial do produto](https://craftpix.net/freebies/free-cartoon-cat-defense-game-asset-kit/) e à [licença oficial](https://craftpix.net/file-licenses/). O produto é listado como Free Download e a licença Freebie autoriza uso comercial e distribuição de jogos; não se redistribuem os arquivos-fonte separadamente. Evidências arquivadas em `godot/docs/licenses/craftpix/`. O pacote local contém 2.791 PNGs + outros formatos. Conteúdo:

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
- **Tela principal:** `LevelMap.png`, `LevelMap_Bg_Screen.png`, `GreenLevel.png` (nível 1 ativo), `LockedLevel.png`, `OrangeBTNAds` (🆕 [M24] oculto por feature flag — seção 12), `Icon_house/Shop/Cat/Addon.png`
- **Vitória/Derrota:** `WinPopUp.png`, `WinBonus.png`, `LosePopUp.png`, `BgPaused.png`
- **Mapa/fase:** `Png\Area\Area1.png` (fundo da fase 1)
- **Personagens/torres (merge):** `Characters\C1..C15\{Idle,Shoot}` (cadeia completa implementada: níveis 1–15 — decisão: máximo aproveitamento dos assets). 🆕 **[M01]** Implementar ≠ alcançar em jogo: o alcance de cada tier é regulado por gating (seção 5.1).
- **Unidades especiais melee:** `Cat Guardian` + `CatBoxing` (`Attack`/`Idle`) — slots na frente do caminho: alcance curto em área; Guardian com passiva de escudo na base (mecânica — seção 3). 🆕 **[M12]** Aquisição definida: 2 slots melee fixos, destravados via upgrade (seção 5.4).
- **Armas/tiros (3 arquétipos):** `Bullets\Artboard 1.png` (tiro reto), `Bullets\Artboard 1 copy.png` (tiro lento/slow), `Bullets\Artboard 1 copy 2.png` (granada balística explosiva) + `ShootFx\Fx2-animation_*.png` (tiro), `Explosion\ExplosionFx-*.png` (impacto)
- **Inimigos (8 arquétipos):** `Enemy Reg 1..8` — papéis na tabela da seção 3 (🆕 [M12]), distribuídos nas 5 ondas (mistura por onda dá identidade a cada onda) + `Enemy Boss 1` como chefe final da fase
- **Moedas/economia:** `CoinIcon.png`, `GemsIcon.png`, `CoinBar.png`, `GemsBarBg.png`
- **Tela de compra (shop):** `ShopScreen.png`, `ShopBoxGreen/BlueShopBox/OrangeShopBox.png`, `ShopIcon1..7.png`, `BtnShopYellow/BtnShopDisable`, `OrangeLvl.png` (mapeamento item ↔ ícone na seção 5.3)
- **HUD de jogo:** `CoinBar/GemsBarBg` topo, `WaveBar.png`, `0Bar..5Bar.png` (vida), `BtnGreen*`, `AddOnSlotBtn.png`, `SettingBtn.png`, `BtnTab_*`
- **Upgrade/Addons:** `CatUpgradeScreen.png`, `AddonScreen.png`, `AddonIcon1..8.png`, `Up0..Up3.png`, `Uplogo1..15.png`
- **Áudio (exceção documentada — seção 12):** packs externos CC0 (Kenney, Juhani Junkala, DST, kmontesdev) para SFX/música, pois o pack Craftpix não inclui áudio — 🆕 [M29] catálogo, links e mapeamento evento → som na seção 12.1
- **Fonte (exceção documentada — seção 12):** `Font Link.txt` → **Passion One** (primária) + fonte built-in do Godot (fallback)

### 2.1 🆕 Matriz de cobertura dos assets [M25]

O título original prometia "100% dos assets", o que não é verdade nem desejável (Spine, vetoriais e previews não entram). A meta passa a ser **cobertura rastreada**: cada arquivo do pack recebe um status em `assets_manifest.json`.

| Grupo | Status no MVP | Observação |
|---|---|---|
| `Ui` (HUD, popups, loja, barras, ícones) | Usado | Exceto itens marcados "texto embutido" na auditoria (2.2) |
| `Characters\C1..C15` | Usado (implementado) | Alcance em jogo regulado por gating (5.1) |
| `Cat Guardian`, `CatBoxing` | Usado | Slots melee |
| `Enemy Reg 1..8`, `Enemy Boss 1` | Usado | |
| `Enemy Boss 2..7` | Adiado (pós-MVP) | Seção 13 |
| `Bullets`, `Explosion`, `ShootFx` | Usado | |
| `Area1` | Usado | |
| `Area2..5` | Adiado (pós-MVP) | Seção 13 |
| `Json Atlas` | Plano B (performance) | Decisão no *gate* do vertical slice |
| `Spine`, `Ai`, `Eps`, `Preview` | Excluído do build | Documentado, fora do repo/export |

| Assets visuais externos CC0 | Candidatos pós-auditoria | Kenney Particle Pack / Background Elements; zumbi OpenGameArt apenas se combinar com os sprites existentes (2.3) |

`validate_assets.gd` passa a imprimir o **relatório de cobertura** (usado / adiado / excluído / faltante) e falha apenas em faltantes de itens "usados".

### 2.2 🆕 Auditoria de assets — Etapa 0 [M06][M07]

Antes de copiar qualquer coisa para o projeto, `tools/audit_assets.ps1` (ou `.gd`) gera `docs/assets_audit.md` com, por arquivo/pasta:

- **Dimensões** (px) e proporção; resolução nativa do pack vs. canvas de referência 1200x540 em landscape (risco de upscale borrado ou de assets enormes)
- **Composição e proporção** de `Area1..5.png` (informam o enquadramento/crop, mas não definem orientação; seção 3, `[M05]`)
- **Texto embutido** nos PNGs de UI (ex.: palavras no `WinPopUp`, `LosePopUp`, botões, `Logo`). Texto baked em inglês **não é localizável**: classificar cada um como *sem texto* / *texto aceitável (logo)* / *texto baked → sobrepor com Label ou ocultar*
- **Pivô/canvas** dos frames de personagens (consistência do ponto dos pés; define `offset` no `FrameLoader`)
- **Tamanho em disco** e **memória estimada em GPU** (`largura × altura × bytes/pixel`; ASTC/ETC2 ≈ 1 byte/pixel; RGBA8 = 4 bytes/pixel) por fase, para validar o orçamento de memória e o APK ≤ 200 MB
- **Inspeção visual** de `Reg 1..8`, `Boss 1`, `C1..C15`, `Guardian/Boxing`, `Bullets`, `ShopIcon1..7`, `Up0..Up3`, `Uplogo1..15`, `AddonIcon1..8` para fechar as atribuições de papel/função (3 e 5)

Saída esperada: lista de decisões que alimentam o `balance.csv`, o `CatData`/`EnemyData` e o layout.

### 2.3 🆕 Assets visuais gratuitos adicionais [M34][M35]

Pesquisa atualizada em 08/10/2026. **“Gratuito” não significa sempre CC0:** Kenney e OpenGameArt abaixo usam CC0 conforme suas páginas; CraftPix marca os freebies como royalty-free e permite projetos comerciais ilimitados e venda/distribuição do jogo, sem crédito obrigatório. Para este jogo, o produto confirmado é [Free Cartoon Cat Defense Game Asset Kit](https://craftpix.net/freebies/free-cartoon-cat-defense-game-asset-kit/) e a licença é [https://craftpix.net/file-licenses/](https://craftpix.net/file-licenses/). Os termos proíbem revender/redistribuir os arquivos-fonte ou expor os assets para extração. Cópias das páginas e hashes estão em `godot/docs/licenses/craftpix/`; cadastrar apenas itens usados nos manifestos.

| Pacote | Licença verificada na página | Uso planejado no jogo | Decisão |
|---|---|---|---|
| [Kenney — Particle Pack](https://kenney.nl/assets/particle-pack) | CC0; 80 arquivos 2D VFX | Impacto, tiros, merge, fumaça, moedas e efeitos de chefe; usar atlas/pool com orçamento de 4.1 | Integrar em campanha e bônus após otimização |
| [Kenney — Background Elements](https://kenney.nl/assets/background-elements) | CC0; 110 arquivos 2D | Props pequenos, silhuetas/parallax e decoração de rotas; recolorir/atenuar quando necessário | Integrar somente itens aprovados na prancha de estilo |
| [OpenGameArt — The Zombie: Free Sprites](https://opengameart.org/content/the-zombie-free-sprites) | CC0 indicado na página; 2 zumbis e até 4 estados de animação | Dois arquétipos de reforço para B3 de áreas 2 e 3; opção de silhueta/variante secundária | Pós-MVP, condicionado à compatibilidade visual e escala |
| [CraftPix — Free Plague Town Vector Tileset](https://craftpix.net/freebies/free-plague-town-2d-platformer-vector-tileset/) | Freebie CraftPix; uso comercial ilimitado conforme [licença](https://craftpix.net/file-licenses/) | Fundo/props de cidade em quarentena: placas, casas, cercas, túmulos e poças; nunca importar física/plataformas | Integrar como decoração em Área 2/3 e bônus associados |
| [CraftPix — Free Horizontal 2D Game Backgrounds](https://craftpix.net/freebies/free-horizontal-2d-game-backgrounds/) | Freebie CraftPix; uso comercial ilimitado conforme [licença](https://craftpix.net/file-licenses/) | Camadas de horizonte/parallax nas cinco áreas quando paleta e enquadramento coincidirem | Integrar seletivamente; não substituir o caminho nem reduzir contraste de gameplay |
| [CraftPix — 2D Game Zombie Character Free Sprite Pack 1](https://craftpix.net/freebies/2d-game-zombie-character-free-sprite-pack-1/) | Freebie CraftPix; 3 personagens, 138 PNGs de animação, royalty-free comercial | Novas variantes animadas de inimigos em campanha e desafios de horda | Integrar após conferir pivôs, tamanhos e licença do ZIP |
| [CraftPix — Free Forbidden Graveyard Tileset](https://craftpix.net/freebies/free-forbidden-graveyard-2d-platformer-tileset/) | Freebie listado no catálogo CraftPix; confirmar página/licença ao baixar | Túmulos, cercas e decoração de necrópole para Área 3 e bônus de cerco/horda | Integrar como cenário/props, não como plataformas |
| [CraftPix — Free Market Cartoon 2D Game Tileset](https://craftpix.net/freebies/free-market-cartoon-2d-game-tileset/) | Freebie CraftPix; uso comercial ilimitado conforme [licença](https://craftpix.net/file-licenses/) | Barracas, poço, lanternas, caixas e cercas para missão de evacuação/mercado na Área 2 | Integrar em uma variação bônus; manter caminho TD legível |

**Direção de arte:** CraftPix continua como fonte de personagens, interface e identidade visual. Os pacotes gratuitos do mesmo fornecedor têm prioridade por coerência de vetor/cartoon; Kenney entra como partículas/props e OpenGameArt como variante secundária, depois de prancha comparativa de contorno, saturação, proporção, perspectiva e tamanho em tela. O tileset de mercado tem tema de fantasia/medieval: limitar a uma missão bônus estilizada como feira de sobreviventes, sem usá-lo como cenário dominante da campanha. Se um pacote falhar na prancha, registrá-lo como rejeitado e removê-lo da matriz de uso/manifesta/build — não afirmar que está integrado. Não usar [Kenney Tower Defense (Top-Down)](https://kenney.nl/assets/tower-defense-top-down) porque sua perspectiva não corresponde ao gameplay lateral.

**Etapa de integração/licença:** CraftPix Freebie não é CC0; sua licença permite uso comercial e venda do jogo, mas proíbe redistribuição dos arquivos-fonte ou permitir sua extração pelo usuário. Credits ainda listam fontes e URLs como cortesia/documentação. Guardar prova da licença, registrar URL/autor/licença/hash/arquivos usados/IDs de fase em `assets_manifest.json` e `credits_manifest.json`, e manter arquivos de origem fora de exportações acessíveis. Medir dimensões, memória, atlas e custo de draw calls na auditoria 2.2.


## 3. Arquitetura do jogo (Godot 4.x, GDScript, landscape 1200x540, stretch=canvas_items mobile)

Em landscape: board/grade 4×3 no painel esquerdo; rota no painel direito, com base na extremidade direita. Ondas percorrem a rota até a base; gatos atiram automaticamente.

### 3.0 Layout landscape para celular deitado [M05]

O alvo é **landscape** em um canvas de referência 1200×540. A rota fica no painel direito e corre da esquerda para a base à direita; a grade 4×3 fica no painel esquerdo; HUD e pausa ocupam a faixa superior e compra/venda/alvo/onda ficam em uma faixa de ação inferior. Nenhum controle essencial pode ficar sob recortes ou gestos de borda. A orientação aceita landscape nos dois lados (rotação 180°) e não oferece modo portrait.

```text
┌──────────────────────────────────────────────────────────────┐
│ HUD: fase · moedas · gems · ondas · pausa                    │
├──────────────────────────────┬───────────────────────────────┤
│ BOARD 4×3                    │ ROTA: spawn → inimigos → BASE │
│ [slot][slot][slot][slot]     │ HP da base · área · combate   │
│ [slot][slot][slot][slot]     │                               │
│ [slot][slot][slot][slot]     │                               │
├──────────────────────────────┴───────────────────────────────┤
│ comprar · vender · alvo · addon · velocidade · iniciar onda  │
└──────────────────────────────────────────────────────────────┘
```

O fundo é enquadrado/cortado com preservação da legibilidade da rota; ele nunca determina a orientação do jogo. Registrar o wireframe, margens seguras, tamanhos de toque e ajustes por proporção em `godot/docs/layout.md` antes da revisão manual.

**Aceite do layout landscape:** (1) o aparelho permanece horizontal, aceitando giro para os dois lados; (2) menu, mapa, partida, tutorial, pausa, oficina, settings, créditos e resultados não cortam texto/controles em 16:9 e 20:9; (3) a área segura respeita recortes e gestos de borda; (4) alvos primários de toque têm ao menos 48 dp; (5) os 12 slots, rota, HP da base e botões de compra/início continuam visíveis e operáveis simultaneamente; (6) capturas de todas as 20 fases e dos fluxos UX são revisadas em AVD e aparelho físico.

### 3.1 Ciclo do Merge Defense
1. Arrastar/dropar gato de nível N em slot livre (toque mobile; fantasma do gato no dedo + highlight do slot válido/inválido)
2. Comprar gato nível 1 com moedas (Shop) — 🆕 [M10] custo crescente por compra na partida (seção 5.2)
3. Mesclar 2 gatos mesmo nível → nível N+1 (maior dano, sprite C{n+1}; glow de preview ao arrastar sobre par válido)
4. Comprar Addon em slot (`AddOnSlotBtn`) com moedas: buff de +dano/+alcance nos gatos (mecânica — seção 5)
5. **Pacing de ondas:** pausa de preparação entre ondas + banner Onda N (`WaveBar`) + botão iniciar agora com recompensa extra de Coins (gerenciar risco)
6. Inimigos avançam no caminho; os que alcançam a base entram em **cerco** — param ao lado e atacam (anim `Attack`, DPS de cerco) até serem derrubados; base sem HP → LosePopUp
7. Inimigos mortos deixam moedas (CoinIcon: cai com gravidade → 1 quique no chão → voa até o CoinBar)
8. Sobreviver a todas as ondas + chefe (barra de HP + **enrage a 50%**) → WinPopUp com estrelas 1–3 → recompensa de gems escalada pelas estrelas (`WinBonus`)

### 3.2 🆕 Casos de borda do board [M14]

| Situação | Comportamento definido |
|---|---|
| Comprar com board cheio | Botão desabilitado + feedback (balanço + som); nenhuma moeda debitada |
| Soltar gato em slot ocupado de **nível diferente** | Troca de posição (swap) |
| Soltar gato em slot ocupado de **mesmo nível** | Merge |
| Soltar gato no nível máximo sobre outro igual | Inválido (highlight vermelho), gato volta ao slot de origem |
| Soltar **fora** do board | Gato volta ao slot de origem (**não vende**) |
| Venda | Somente por long-press → botão vender, ou arrastar até uma **zona "Vender"** explícita; **desfazer por 3 s** (evita venda acidental — substitui "arrastar para fora do board" do A5) |
| Merge em cascata | Entrada de novos drags enfileirada durante a animação (≤ 300 ms) |
| Merge com projéteis em voo | Projéteis guardam *snapshot* de dano/efeito e seguem independentes do gato de origem |
| Drag interrompido (ligação, perda de foco, segundo dedo) | Cancela e devolve o gato ao slot de origem |
| Multi-touch | Só o primeiro ponteiro controla o drag; demais ignorados |
| Toque duplo rápido em Comprar | *Debounce* (≥ 150 ms) |
| Pausa | Board não pode ser manipulado; o estado do drag é descartado |
| Save durante drag | Persiste o estado **pré-drag** |

### 3.3 Estrutura de código (sem duplicação)
```
res://scenes/{splash, main_menu, level_select, shop_screen, upgrade_screen, addon_screen, settings, credits, game, pause_popup, win_popup, lose_popup}
res://scripts/core/{game_state.gd (state machine), event_bus.gd, save_system.gd (versionado), audio_manager.gd, scene_router.gd, settings.gd, localization.gd, feature_flags.gd}
res://scripts/sim/{sim_world.gd, sim_rng.gd, sim_path.gd, sim_events.gd}   # 🆕 [M08] núcleo puro (RefCounted), sem Node
res://scripts/data/{cat_data.gd, enemy_data.gd, wave_data.gd, weapon_data.gd, addon_data.gd}  (Resources) + res://data/balance.csv
res://scripts/entities/{cat_tower.gd, enemy.gd, boss_enemy.gd, bullet.gd, coin.gd, base.gd, damage_number.gd}   # views que espelham o estado da sim
res://scripts/systems/{merge_system.gd, economy.gd, wave_manager.gd, spawn_manager.gd, targeting.gd, addon_system.gd, object_pool.gd, status_effects.gd}
res://scripts/ui/{hud.gd, shop_ui.gd, popup_ui.gd, tutorial/*, buttons/*}
res://scripts/debug/{debug_menu.gd, perf_overlay.gd}   # 🆕 [M26] excluídos do export release
tests/gut/... (framework GUT) + scripts/validate_assets.gd + scripts/balance_sim.gd
tools/*.ps1 + .github/workflows/ci.yml
```
- **Dados em Resources** (`EnemyData`, `CatData`, `WaveData`, `AddonData`) — sem números mágicos; instâncias carregam frames via helper único `FrameLoader` (carrega diretório de PNGs → SpriteFrames, com **carregamento lazy por fase** para não estourar memória no Android). 🆕 [M07] Pré-carregar em thread (`ResourceLoader.load_threaded_request`) durante Splash/LevelSelect para cumprir "troca de tela < 1 s"; *pre-warm* dos pools no carregamento da fase.
- **Autoload** comuns: `GameState` (**state machine explícita**), `EventBus` (bus de sinais globais, evita acoplamento entre cenas), `SceneRouter`, `AudioManager`, `SaveSystem`, `Localization`, `FeatureFlags`
- 🆕 **[M17] State machine em dois níveis:**
  - Nível aplicação: `SPLASH → MENU → LEVEL_SELECT → (SHOP | UPGRADE | ADDON | SETTINGS | CREDITS) → LOADING → PLAYING → PAUSED → WIN/LOSE`
  - Sub-estados de `PLAYING`: `PREP` (pausa entre ondas, board livre) → `WAVE_ACTIVE` → `WAVE_CLEAR` → … → `BOSS` → `VICTORY`/`DEFEAT`. Transições inválidas lançam erro em debug e são cobertas por teste.
- **Save versionado**: campo `version` + função `migrate()` — nunca quebrar save em atualização. 🆕 [M15] **Escrita atômica**: gravar `save.tmp` → renomear; manter `save.bak`; checksum no cabeçalho; se o principal estiver corrompido, cair para `.bak`.
- Sinais via `EventBus`; zero `get_node()` solto; princípios SOLID/DRY; tipagem estática GDScript
- **Object pooling** (`object_pool.gd`) para `bullet`, `coin`, `damage_number`, `shoot_fx`, `explosion` — obrigatório para 60 FPS no Android. 🆕 Tamanhos de pool no `balance.csv`; falha alta (log) se um pool precisar crescer além do previsto; projéteis usam `Sprite2D`, não `AnimatedSprite2D`.
- **Input mobile**: `InputEventScreenTouch`/`ScreenDrag` com mouse-emulation OFF no Android; drag & drop com "fantasma" seguindo o dedo e highlight do slot (`SelectedBorder.png`). 🆕 [M15] Fantasma **deslocado ~1 slot acima do dedo** (o dedo não cobre o gato); limiar de drag ≥ 12 px; long-press = 500 ms; alvos de toque ≥ 48 dp (≈ 126 px a 480 dpi); em desktop, *emulate touch from mouse* ligado só para testes.
- **Android UX:** back button pausa/sai com confirmação; pausa automática ao perder foco; HUD com safe-area anchors (notch/punch-hole do 1220x2712). 🆕 [M15] ver checklist Android na seção 7.1.
- **Determinismo:** ondas/dano em timestep fixo (fixed step) para testes reproduzíveis com seed. 🆕 [M08] Ver 3.4.
- **Performance:** `max_fps`/vsync estáveis; texturas ETC2/ASTC sem mipmaps, filtro configurado
- **Localização:** todos os textos via CSV do Godot (PT-BR + EN) desde o dia 1 (`localization.gd`). 🆕 [M06] Textos baked nos PNGs de UI tratados conforme a auditoria (2.2); botões com largura flexível (PT costuma ser ~20% mais longo que EN).
- **Unidades melee (A4):** `cat_tower.gd` com `CatData.attack_mode` = `ranged` | `melee` — Guardian/Boxing atacam corpo a corpo na frente; passiva do Guardian: +escudo na base
- **Status `slow` (A3):** `status_effects.gd` — projétil lento reduz a velocidade do inimigo (fator + duração, empilhamento limitado), decai em fixed step
- **Autosave (B3, 🆕 corrigido [M04]):** `SaveSystem` persiste onda atual, board, moedas, addons **e estado do RNG** (a) ao fim de cada onda e (b) como **checkpoint em `FOCUS_OUT`/pausa/`WM_GO_BACK_REQUEST`** → partida interrompida é retomável, inclusive no meio da onda (save versionado). No restore no meio da onda, os inimigos em campo são restaurados a partir do snapshot da sim.
- **Nota:** usar os PNGs soltos com `AnimatedSprite2D` (mais simples e compatível com GLES/Android do que processar Json Atlas; Atlas pode virar otimização futura — medir draw calls antes de migrar). 🆕 [M07] **Gate de decisão no vertical slice (etapa 4):** com 1 fase carregada e ~20 inimigos na tela, medir draw calls, memória e *frame time* no AVD; se estourar o orçamento, migrar para os Json Atlas (34 atlas já prontos, loader lê o `.json` e cria `AtlasTexture`) e/ou subamostrar frames (ex.: `Dead` 60f → 30f, `Walk` 35f → 18f).
- 🆕 **[M09] Renderer:** fixar **Compatibility** (OpenGL) em `project.godot` — projeto 100% 2D, maior compatibilidade com dispositivos e com o emulador; avaliar Mobile (Vulkan) apenas se a medição justificar. Partículas: **`CPUParticles2D`** (o antigo `Particles2D` não existe no Godot 4; `GPUParticles2D` tem suporte irregular em Compatibility/emulador).

### 3.4 🆕 Núcleo de simulação puro + view [M08]

- A lógica de jogo (movimento ao longo do caminho, alcance, dano, cerco, status, ondas, economia, merge) vive em `scripts/sim/*` como **`RefCounted` sem `Node`**, avançando em **tick fixo** `SIM_DT = 1/60`. Os nós (`cat_tower`, `enemy`, …) apenas **espelham** o estado e tocam animação/efeitos.
- **Caminho 1D:** inimigos têm `progress ∈ [0,1]` no caminho. `first`/`last`/`strongest`/`closest` viram ordenações simples sobre listas; alcance = comparação de distância; nada de consultas espaciais caras.
- **Hit-test analítico** (distância/raio, com *swept test* para projéteis rápidos) **em vez de `Area2D`**: sem *tunneling*, sem hits fantasma de objetos reciclados e roda sem árvore de cenas. A tabela de physics layers abaixo permanece como fallback caso `Area2D` seja usado para algum detector visual.
- **RNG injetado** (`SimRng`, seed + estado serializável); proibido `randf()`/`randi()` globais dentro de `sim/`.
- **Velocidade 2× (C3):** executar **2 ticks por frame** (não usar `Engine.time_scale`, que distorce áudio/Tweens); limite `max_ticks_per_frame = 4` para evitar espiral de morte quando o frame atrasa.
- **`balance_sim.gd`** instancia apenas a `SimWorld` (sem cenas): milhares de partidas por minuto no CI, com bots (seção 5.5).

### 3.5 🆕 Inimigos: arquétipos, cerco e controle [M12]

Atribuição `Reg N → papel` é provisória e fecha após a inspeção visual da Etapa 0 (2.2).

| Arquétipos | Papel | Parâmetros-chave | Observação |
|---|---|---|---|
| Reg 1–2 | Corredor rápido | HP baixo, velocidade alta | Pune defesa lenta; ótimo alvo para `first` |
| Reg 3–4 | Tanque lento | HP alto, velocidade baixa, resistência parcial a slow | Pune DPS baixo |
| Reg 5–6 | Cerco | DPS de cerco alto, HP médio | Pressiona a base se passar |
| Reg 7–8 | Suporte | **Mecânica a definir (proposta):** aura de +X% de velocidade a aliados em raio R, ou cura em pulso a cada T s | Alvo prioritário (`strongest`/`closest`); sem mecânica definida o papel "suporte" não existe |
| Boss 1 | Chefe final | HP muito alto, resist. knockback 0,2×, resist. slow 0,5×, enrage a 50% | Barra de HP sempre visível |

**Regras do cerco:**
- Máximo de `siege_slots` atacantes simultâneos na base (seed: 3); os demais **aguardam em fila** atrás (sem sobreposição visual nem DPS ilimitado)
- DPS total de cerco com teto (`siege_dps_cap`) para evitar derrota instantânea por acúmulo
- Knockback desgruda o inimigo do cerco e libera o slot; ele retoma o avanço

**Regras de controle (CC):**
- Velocidade final = `base × enrage_mult × slow_factor`, com piso `min_speed_factor` (seed: 0,3)
- Slow: empilhamento limitado (`slow_max_stacks`), duração renovada (não somada); chefe com `slow_resist`
- Enrage não remove slow; o slow é aplicado após o multiplicador de enrage
- Tudo no `balance.csv`

### 3.6 🆕 Sincronia de animação ↔ gameplay [M13]

- `CatData.fire_frame`: frame da animação `Shoot` (10f) em que o projétil nasce (definido na auditoria visual). Cadência mais rápida que a animação → `speed_scale` da animação; mais lenta → volta ao `Idle`.
- `EnemyData.hit_frame`: frame do `Attack` em que o dano é aplicado (DPS de cerco aplicado em pulsos nesse frame).
- **`Walk` (35f):** `speed_scale = velocidade_atual / stride_speed` do arquétipo, evitando *foot-sliding* (inclui slow/enrage).
- **`Dead` (60f):** o inimigo sai imediatamente do *targeting*, do cerco e do cálculo de colisão no **frame 0** da morte; a moeda nasce nesse instante; reproduzir a ~2× (ou cortar após N frames) para não deixar corpos poluindo a tela.
- FPS de cada animação definido em `CatData`/`EnemyData` (seed: 24–30 fps), nunca hardcoded no `FrameLoader`.
- Ordenação de desenho: `y_sort`/`z_index` por faixa (inimigos > fx de chão; fantasma do drag sempre por cima).

### 3.7 Física e colisão

- **Tabela de Physics Layers:** `1=enemies`, `2=bullets`, `3=base (sensor)`, `4=slots` — masks: bullet→enemy, enemy→base; nenhum corpo físico fora dessa tabela. 🆕 [M08] Layers valem apenas para os nós de *view* que usarem `Area2D`; a lógica de dano usa o hit-test analítico da sim (3.4).
- **Detecção de dano:** hit-test no núcleo de sim; se houver `Area2D` na view, **desligar `monitoring` ao devolver ao pool** (evita hits fantasma em objetos reciclados)
- **Movimento dos inimigos é cinemático** (progresso manual/`PathFollow2D` no caminho) — **nenhum `RigidBody2D` no gameplay**, preserva o determinismo do `balance_sim`
- **Anti-overlap:** separação leve por posicionamento quando inimigos se sobrepõem (sem física)
- **Cerco à base (A1):** contato `enemy→base` coloca o inimigo em estado `SIEGE` (para ao lado da base e aplica DPS com a anim `Attack`); knockback o desgruda e retoma o avanço (limites em 3.5)
- **Integração em fixed step:** balística (`v.y += g·dt`), knockback e queda de moedas rodam no timestep fixo; `_process` só interpola o visual — testes reproduzíveis por seed

### 3.8 🆕 Boas práticas de performance e orçamento de recursos [M38]

Performance e consumo reduzido são requisitos de arquitetura desde o protótipo, não uma etapa de otimização no fim. A meta é executar suavemente no perfil Android low-end definido na seção 7 sem carregar dados de áreas inativas nem fazer trabalho contínuo quando o jogo está ocioso.

**Orçamento inicial obrigatório para o perfil low-end (3 GB RAM), medido em release sob pico de onda/chefe:**

| Recurso | Meta de aceite |
|---|---|
| Processo do jogo (PSS) | pico ≤ 256 MiB |
| Texturas residentes da fase ativa (estimativa/import do Godot) | ≤ 128 MiB |
| CPU no thread principal (script + simulação + física) | p95 ≤ 8 ms/frame |
| Frame completo | p95 ≤ 16,7 ms; p99 ≤ 25 ms; nenhum travamento > 100 ms fora de carregamento |
| APK | meta ≤ 150 MB; teto absoluto de aceite ≤ 200 MB |
| Pools | capacidades máximas fixas por tipo, calculadas no slice; não crescer sem limite em runtime |

Esses valores são limites de projeto e devem ser validados no slice contra medições reais da build/export/device. Se uma meta não for atingida, reduzir custo de conteúdo/código ou otimizar a representação e repetir a medição; não aumentar silenciosamente o orçamento. Registrar baseline, cenário, perfil, ferramenta, valores e decisão em `docs/performance/baseline.md`. Memória de GPU deve ser estimada separadamente da PSS sempre que a ferramenta/dispositivo permitir; a estimativa de textura ativa e a PSS não podem ser somadas como se fossem a mesma métrica.

**Práticas mandatórias:**

- **Separar simulação e apresentação:** gameplay determinístico em `SimWorld` pura com tick fixo; nós Godot renderizam/recebem input e não decidem regras. Não executar simulação inteira em cada `_process`; limitar ticks por frame e interpolar visualmente.
- **Processar somente o necessário:** desativar `_process`/`_physics_process`, animações, timers e sinais de nós fora de uso/fora da tela quando seguro; centralizar atualizações repetitivas em sistemas e evitar um nó/Timer por projétil ou inimigo sem necessidade.
- **Evitar alocações no hot path:** não criar/free nós, arrays, dicionários, strings ou recursos repetidamente por frame/tiro; reutilizar pools e buffers, limitar sinais/conexões temporárias, cachear referências e evitar buscas `get_node()` em loops de combate. Pool tem teto e telemetria; overflow deve degradar/recusar efeito cosmético com log controlado, nunca alocar indefinidamente.
- **Carregar sob demanda:** carregar somente a fase atual e dados necessários; descarregar texturas/recursos de área ao sair; pré-carregar em thread apenas telas/fases próximas, monitorando pressão de memória. Não manter todos os frames e cinco áreas residentes. Usar import settings por tipo: compressão apropriada para sprites, lossless para UI delicada, mipmaps desligados em arte 2D e excluir arquivos-fonte, previews e formatos não usados do export.
- **Conteúdo visual/audio eficiente:** reduzir/subamostrar frames quando a auditoria de qualidade aprovar; usar atlas apenas quando o profiler demonstrar benefício; evitar resolução maior que a exibida, transparência excessiva, efeitos de tela cheia, partículas persistentes, excesso de camadas parallax e áudio simultâneo fora dos limites.
- **Medir antes de otimizar:** usar Godot Profiler/Monitors, `perf.csv`, Android Profiler/ADB e build release; comparar CPU, GPU/frame time, PSS, texturas, draw calls, nós, pools e tamanho de export no cenário de pico. Não adotar otimização que prejudique legibilidade/manutenção sem evidência de ganho.
- **Preservar estabilidade:** execução prolongada e troca/reentrada em fases não podem acumular nós, recursos, conexões ou memória; alvos reciclados são desativados, recursos de fase liberados e o frame-time permanece no orçamento após várias partidas.

Toda nova funcionalidade, fase, VFX, asset ou agente de IA precisa declarar impacto esperado nos budgets. O DoD da etapa exige perfil/benchmark quando a mudança afeta runtime, rendering, áudio, memória ou build. A seção 6.1 valida os limites no candidato final; o limite mais estrito entre esta seção e a matriz de dispositivos é o aplicável.

## 4. Game design premium (feel, UX e progressão)

### 4.1 🆕 Linguagem de efeitos visuais

O plano já prevê flashes localizados, knockback, números de dano, moedas com quique, partículas, shake em impacto de chefe e popups animados. Esta seção fecha a cobertura por evento. Os efeitos devem ser breves, legíveis em celular e informar uma ação; evitar partículas persistentes e flashes de tela cheia. Implementar como cenas reutilizáveis com pools, usando `CPUParticles2D` quando necessário e configuração central `VfxConfig`.

| Evento | Efeito visual proposto | Limite/feedback |
|---|---|---|
| Arrastar gato | Fantasma translúcido no dedo, sombra curta, slot válido com contorno/halo; slot inválido com ícone e cor | Um fantasma por toque; sem shake |
| Merge válido | Pulso de escala nos gatos, anel de energia no slot, partículas ascendentes e brilho breve no gato resultante | 250–400 ms; resultado sempre visível imediatamente |
| Merge inválido/board cheio | Retorno elástico curto e realce do motivo (cheio/níveis diferentes) | Sem flash de tela; respeita reduzir efeitos |
| Disparo e impacto | Trilha curta do projétil; flash localizado e número de dano opcional; explosão em área com anel de alcance | Efeitos em pool; não ocultar inimigos ou HUD |
| Inimigo atingido/morre | Flash localizado, knockback, animação de morte e moedas com brilho breve | Sem empilhar números de dano; sai do targeting no frame 0 (3.6) |
| Inimigo em cerco/base recebe dano | Pulso curto no segmento de HP, borda vermelha suave e vibração opcional | Sem tremor contínuo; intensidade limitada |
| Chefe/enrage | Entrada com poeira/impacto, barra de HP animada; mudança de cor e ícone/texto no enrage | Não depender só da cor; shake apenas em eventos fortes |
| Onda/chefe começa | Banner com contagem breve; fundo levemente escurecido durante a entrada | Não bloquear interação > 600 ms nem pausar simulação implicitamente |
| Vitória/derrota/recompensa | Popup com easing, confete leve na vitória e moedas/gems voando ao contador | Confete desligável; recompensa independe da animação |
| Menu/transição | Fade entre cenas e feedback de foco/pressionado nos botões | 120–220 ms; modo reduzido mantém transição simples |

- **Acessibilidade:** “Reduzir efeitos” desliga shake e partículas decorativas, substitui flashes por contorno/pulso suave e mantém indicadores de estado. Evitar flashes de tela inteira e alternância rápida de alto contraste.
- **Orçamento inicial:** pool por efeito; máximo de 40 partículas vivas e 12 efeitos simultâneos, duração de combate até 1,2 s (morte usa duração de animação). Ajustar no vertical slice com medições.
- **QA visual:** capturar screenshots/vídeo de merge, impacto, cerco, entrada de chefe e vitória em landscape (16:9 e 20:9); conferir legibilidade, safe area, AVD low-end e opção “Reduzir efeitos”.

### 4.2 🆕 História e clima do jogo

**Premissa narrativa proposta — “O Último Refúgio”:** uma névoa estranha tomou a cidade e transformou seus moradores em zumbis. Um pequeno grupo de gatos protege o último refúgio, construído ao redor de um farol que mantém a névoa afastada. Os gatos descobriram que, quando dois iguais se unem, sua energia de ronronar desperta uma forma mais poderosa. A cada onda, a horda chega mais perto; ao fim da quinta onda, o Chefe dos Infectados tenta apagar o farol. O jogador organiza e combina os gatos para manter o refúgio aceso até o amanhecer.

**Tom:** aventura leve com suspense cartunesco, humor afetuoso e perigo sem violência gráfica. A história deve combinar com a arte de gatos e zumbis do pack. Não explicar toda a origem da névoa na fase 1: deixar uma pergunta para as fases futuras.

**Como a narrativa aparece no jogo (sem interromper partidas):**

| Momento | Conteúdo narrativo |
|---|---|
| Splash/menu | Logo e frase curta: “A noite caiu. Os gatos ficaram de guarda.” |
| Abertura da fase 1 | Painel ilustrado de 2–3 quadros, dispensável após a primeira leitura: a névoa chega, os gatos se reúnem, o farol acende. |
| Tutorial | Guia apresenta o refúgio e ensina a comprar/mesclar gatos em balões de uma frase; usar Cat Guardian como guia somente se a auditoria visual confirmar que funciona como personagem amigável. |
| Entre ondas | Banner e mensagens ocasionais de uma linha com aumento de tensão; nunca pausar ou cobrir o board. |
| Chefe | Anúncio do Chefe dos Infectados com nome/título localizável e aviso de ameaça; história não depende de texto para compreender o combate. |
| Vitória | Amanhecer, farol ainda aceso e gatos comemorando; gancho breve revela que a névoa continua além da cidade. |
| Derrota | Farol se apaga e os gatos recuam para dentro do refúgio; mensagem encorajadora para tentar novamente, sem apagar o progresso permanente. |

- **Escopo narrativo do MVP:** premissa, abertura curta, tutorial contextual, identificação do chefe e finais de vitória/derrota. Sem dublagem, cutscenes longas ou árvores de diálogo.
- **Narrativa extensível:** áreas 2–5 podem revelar a origem da névoa e apresentar novos chefes; não escrever fatos irreversíveis sobre essas áreas até o respectivo conteúdo entrar em produção.
- **Conteúdo/localização:** guardar falas, nomes, títulos e textos de história em `data/localization.csv` (PT-BR e EN), com chaves estáveis e limite de caracteres para caber nos painéis landscape. Revisar tom e comprimento nas duas línguas.
- **Acessibilidade e ritmo:** introdução pode ser pulada; mensagens de onda não exigem leitura para jogar; nenhum texto narrativo contém informação mecânica exclusiva — regras também aparecem em ícones/HUD/tutorial.
- **Entregável:** `docs/narrative.md` com premissa, tom, personagens confirmados, sequência de beats, texto final PT-BR/EN e perguntas reservadas para fases futuras.

- **Game feel (juice):** flash branco + knockback sutil no inimigo ao levar dano; números de dano flutuantes (`damage_number.gd`); screen shake leve apenas no impacto de boss; todos os popups entram com Tween/easing (nunca aparecer "seco"); haptics `Input.vibrate_handheld()` no merge e no dano da base, respeitando o toggle de vibração do HUD
- **Knockback formalizado:** impulso `kick_offset` na direção contrária ao avanço ao ser atingido; decai exponencialmente até 0 no fixed step; **clampado ao caminho** (nunca sai do spawn nem atravessa a base); boss com resistência (ex.: 0,2×) — força/decaimento no `balance.csv`
- **Queda de moedas com gravidade:** a moeda cai do inimigo, dá **1 quique no chão** e só então voa até o CoinBar
- **Partículas com gravidade:** brasas da explosão caem e a fumaça sobe (`gravity` nos `CPUParticles2D`)
- **Projéteis balísticos (gravidade):** gatos de níveis altos (ex.: C10+) disparam granadas em arco (`gravity_scale` por arma no `WeaponData`) com **interceptação** do inimigo em movimento, dano em área + explosão no impacto; gatos comuns `gravity_scale=0` (tiro reto). 🆕 [M01] Como C10+ só é alcançável com gating/progressão (5.1), as granadas também podem ser atribuídas a um tier mais baixo (ex.: C6+) se o balanceamento mostrar que o arquétipo ficaria invisível na fase 1 — parâmetro no `balance.csv`.
- **Tutorial guiado na fase 1:** seta/banner com `SelectedBorder.png` ("arraste aqui", "toque para comprar") — onboarding em 30 s
- **Preview de merge:** ao arrastar um gato sobre outro do mesmo nível, glow de confirmação + tooltip "dano atual → próximo"
- **Painel de info por long-press:** dano, alcance e DPS do gato selecionado
- **Pause menu completo:** continuar / reiniciar / sair (`BgPaused.png`), com toggles de som/música/vibração
- **Vitória com estrelas 1–3** para rejugabilidade da fase única. 🆕 **[M23]** Critério independente de velocidade e de tempo real: **estrelas = f(HP da base restante, eficiência)**, onde eficiência = vazamentos (inimigos que chegaram ao cerco) e uso de "iniciar agora"; qualquer tempo é medido em **tempo de simulação**, nunca em tempo de relógio — 2× e pausa não alteram o resultado. Limiares no `balance.csv`.
- **Targeting configurável por `CatData`:** `first` / `last` / `strongest` / `closest` (estratégia, não só "primeiro alvo")
- **HP bars flutuantes (B1):** barra de vida sobre inimigos — sempre no boss, opcional nos normais; desenhada via `TextureProgressBar` + shader (pack não inclui sprite de barra de inimigo)
- **Feedback de dano na base (B2):** flash vermelho de borda da tela + haptic + segmentos `0Bar..5Bar` mapeados ao HP restante (6 estados: cheio → vazio)
- **Enrage do chefe (A7):** barra de HP do chefe visível + a 50% HP entra em enrage (velocidade/dano ↑) — multiplicadores no `balance.csv`
- **Loop estrelas → gems (B4):** no `WinBonus`, 1–3 estrelas convertem-se em gems (fechamento do loop de recompensa)
- **Velocidade 2× (C3):** botão de acelerar onda (reusa `BtnGreen*`) — ritmo mobile; pausável; implementação via 2 ticks/frame (3.4); testes continuam em fixed step
- **`OrangeBTNAds`:** ver seção 12 (decisão registrada — feature flag desligada)
- 🆕 **[M21] Acessibilidade e conforto:**
  - Settings: **"Reduzir efeitos"** (desliga screen shake, flash branco e reduz o flash vermelho de borda para um pulso suave) — evita desconforto/fotossensibilidade
  - Escala de texto (100%/115%/130%) nos textos gerados por `Label`; contraste mínimo 4,5:1 em textos sobre os painéis
  - Informação nunca só por cor: estados inválido/válido do drag também com ícone/forma; barras de vida com contorno
  - Respeitar toggles de som, música e vibração em 100% dos pontos
- 🆕 **[M22] Áudio (arquitetura):** buses `Master → Music / SFX / UI`; **limite de vozes simultâneas** por SFX (ex.: máx. 4 tiros ao mesmo tempo) com variação aleatória de pitch (±5%) para evitar "metralhadora de samples idênticos"; *ducking* leve da música em popups de vitória/derrota; SFX curtos em WAV, música em OGG com loop; áudio pausa com o jogo e retoma no foco. 🆕 [M29] Fontes, licenças e mapeamento evento → som na seção 12.1; loudness normalizado entre packs.

## 5. Economia, balanceamento e Addons

### 5.1 🆕 Progressão da cadeia de merge e gating de tiers [M01]

**Problema (matemático):** com merge 2:1, criar o nível L exige `2^(L-1)` compras de nível 1 e `L` slots ocupados no pior momento do encadeamento. Com **12 slots, o nível máximo possível é 12**; **C13, C14 e C15 não podem existir**, e C12 exigiria 2.048 compras. Mesmo C8 exige 128 compras em uma fase de 5 ondas. Sem tratamento, 3–7 dos 15 gatos nunca apareceriam em jogo, contrariando o objetivo de "máximo aproveitamento".

**Decisão proposta** (a aprovar — seção 14):
1. **Cadeia C1..C15 implementada e testada integralmente** (inclusive via debug menu, `[M26]`).
2. **Alcance por fase regulado por `tier_cap` no `balance.csv`** (seed: fase 1 → C1..C8; o restante destravado por progressão).
3. **"Nível de compra" como upgrade permanente** (`CatUpgradeScreen`/Shop com gems): comprar gato direto em C2, C3… reduz o custo em compras do tier alto (ex.: nível de compra 3 → C8 = 32 compras).
4. **Slots extras como item de progressão** (gems; ex.: 12 → 14 → 16) — cada slot extra eleva em 1 o teto matemático.
5. **Custo crescente por compra na partida** (5.2) para que 100+ compras sejam inviáveis na fase 1.
6. `balance_sim` **mede e reporta o tier máximo alcançado** por estratégia; o CI falha se o bot ótimo não atingir o `tier_alvo` ou se alcançar tier acima do `tier_cap`.

### 5.2 Fontes e usos de moeda (sources/sinks)

🆕 **[M10] Duas contas separadas** (a ambiguidade original: "Coins" eram usadas tanto para comprar gato na partida quanto para upgrade permanente):

| Conta | Onde aparece | Fontes | Usos |
|---|---|---|---|
| **Moedas da partida** (`run_coins`) | `CoinBar` no HUD de jogo; **zeram** a cada partida | kills, ondas, bônus de "iniciar agora", venda de gato | comprar gato (Shop in-run), comprar Addon em slot |
| **Moedas do cofre** (`bank_coins`) | `CoinBar` nas telas de menu | pagamento ao fim da partida: vitória (`win_payout`) e derrota (`lose_payout_ratio` do valor, ex. 30%) | upgrades permanentes (`CatUpgradeScreen`), destravar addons e slots melee |
| **Gems** | `GemsBarBg` (HUD e menus) | recompensa de vitória escalada por estrelas (`WinBonus`) | itens da loja premium (5.3) |

- **Custo crescente de compra:** `buy_cost(n) = round(base_cost × growth^n)`, com `n` = compras na partida atual (seed: `growth` 1,06–1,12). Reinicia a cada partida.
- **Sem arbitragem (propriedade testada):** `sell_refund`% (< 100) é calculado sobre o **valor pago acumulado** do gato; nenhum ciclo comprar → mesclar → vender pode gerar saldo líquido positivo.
- **Addons — duas camadas coerentes com o ciclo original:** (a) `AddonScreen` (menu): destrava tipos de addon e quantidade de slots com `bank_coins`; (b) in-run: comprar o addon destravado no `AddOnSlotBtn` com `run_coins`, aplicando o buff aos gatos. Limitado pelos slots disponíveis — profundidade estratégica extra.

### 5.3 🆕 Loja premium: mapeamento de itens e ícones [M10]

O plano original mapeia 3 caixas (`ShopBoxGreen`, `BlueShopBox`, `OrangeShopBox`) e 7 ícones sem dizer o que cada um vende. Proposta (confirmar após a inspeção visual dos `ShopIcon1..7`):

| Caixa | Categoria | Itens (7 `ShopIcon`) | Moeda |
|---|---|---|---|
| `ShopBoxGreen` | Moedas | pacotes de `bank_coins` (2 ícones) | Gems |
| `BlueShopBox` | Progressão | +1 nível de compra; +2 slots no board; slot melee extra (3 ícones) | Gems |
| `OrangeShopBox` | Especiais | boost de moedas na próxima partida; addon temporário (2 ícones) | Gems |

Sem SDK de ads no escopo; **nenhuma compra com dinheiro real** nesta execução.

### 5.4 Upgrade de gatos e Addons

- **Addons (mecânica definida):** slots de addon (`AddOnSlotBtn`, `AddonScreen`) com 8 ícones (`AddonIcon1..8`); cada addon aplica buff (ex.: +dano, +alcance, +cadência de tiro) aos gatos — conforme 5.2.
- **Upgrade de gatos explícito (A8) — 🆕 revisado [M10]:** os assets trazem `Uplogo1..15` (um por gato) e `Up0..Up3` (4 níveis visuais), o que sugere **upgrade por gato** (15 trilhas × 4 níveis), não só "+dano% global". Proposta: `CatUpgradeScreen` mostra a trilha de cada gato (`Uplogo{n}` + `Up0..Up3`), custo em `bank_coins` escalando geometricamente; **gatos acima do `tier_cap` ficam bloqueados** (ícone `Locked*`) até serem alcançáveis. Curva e efeitos no `balance.csv` (sink principal de Coins no late game). Alternativa se a auditoria mostrar outro uso para `Uplogo*`: manter o upgrade global original.
- **Implementação em `godot/`:** a Oficina persiste 15 trilhas por tier, cada uma com quatro níveis comprados com moedas bancadas; cada nível acrescenta 5% de dano às torres daquele tier. Os oito add-ons custam 150 moedas bancadas para desbloquear e 20 moedas de partida para equipar: Sobrecarga (+30% dano), Mira Longa (+30% alcance), Tiro Rápido (+30% cadência), Gélido (reduz velocidade do inimigo em 35% por 1,5 s), Projétil Veloz (+35% velocidade de projétil), Recompensa (+2 moedas por abate), Recuperação (reembolso de venda sobe de 50% para 75%) e Guardião (reduz dano de cerco à base em 15%, limitado a 45%). Cada torre aceita dois efeitos, inclusive cópias do mesmo tipo; efeitos e projéteis em trânsito são serializados, efeitos de torre combinam no merge e saves antigos de Sobrecarga migram para a lista de espaços. A interface PT-BR/EN permite desbloquear cada add-on na oficina e equipá-lo pelo seletor de partida. Revisão visual dos ícones e calibração de balanceamento permanecem abertas.
- **Melee:** `Cat Guardian`/`CatBoxing` ocupam 2 slots fixos na frente do caminho, destravados por upgrade (`bank_coins`). Em `godot/`, o desbloqueio persistente custa 400 moedas bancadas; cada unidade custa 30 moedas de partida, ataca automaticamente em curto alcance e pode ser vendida. Guardian reduz o dano de cerco em 15% enquanto estiver implantado.

### 5.5 Balanceamento data-driven

- `res://data/balance.csv` (HP base, DPS dos gatos 1–15, recompensa por inimigo, custos de compra/upgrade/addon, curva das 5 ondas + chefe, **física: força/decaimento do knockback, resistência do boss, gravidade `g`/`gravity_scale` dos projéteis, quique de moedas**) — nenhum número hardcoded no código
- **Novos parâmetros no `balance.csv`:** arquétipos (`Reg 1..8`: HP, velocidade, papel), DPS de cerco, `siege_slots`, `siege_dps_cap`, slow (fator/duração/stack/`min_speed_factor`), enrage (multiplicadores), `sell_refund`, `growth` de compra, `tier_cap`, recompensa por estrela → gems, `win_payout`/`lose_payout_ratio`, bônus de "iniciar agora", pausa entre ondas, tamanhos de pool, `fire_frame`/`hit_frame`/fps por entidade
- **🆕 Teste automático de balanceamento [M11]:** `balance_sim.gd` roda a fase com a `SimWorld` (sem cenas), N partidas por estratégia com seeds fixas. **Quatro bots** com faixas-alvo (valores-semente a calibrar):

| Bot | Comportamento | Resultado esperado (N=100 seeds) |
|---|---|---|
| **Ótimo** | compra + merge + addons + upgrades, targeting adequado | vence ≥ 90%; ≥ 2 estrelas em ≥ 60% |
| **Médio** | compra + merge; sem addons nem upgrades; no benchmark implementado, mescla no máximo uma vez a cada duas ondas concluídas | vence 50–80% |
| **Passivo** | compra e posiciona, nunca mescla | vence ≤ 10% |
| **Ocioso** | não faz nada | perde até a onda 2 em 100% |

  O tutorial A1 é amostrado separadamente para confirmar que o benchmark não altera sua função de onboarding. A1_B2, com 8 slots, 77 moedas e inimigos com HP em 235%, é o desafio de balanceamento para separar a eficiência dos bots. Além disso: (a) **teste de sensibilidade** — variar custos/HP/dano ±10% não pode inverter a ordem Ótimo > Médio > Passivo nem levar o Ótimo abaixo de 70%; (b) **teto de tier** respeitado (5.1); (c) relatório `reports/balance_report.json` com tier máximo, ouro gasto por categoria e onda em que cada bot morre — detecta regressões de balanceamento no CI. A suíte completa é obrigatória no gate local, não um passo opcional.
- **Venda/devolução de gato (A5):** long-press no gato → botão vender (ou arrastar até a **zona "Vender"** — 🆕 [M14], não mais "fora do board") devolve `sell_refund`% das Coins — board de 12 slots nunca prende o jogador (UI: caixa `ShopBoxGreen`); desfazer por 3 s

## 6. Qualidade, testes e verificação

- **Testes automatizados com GUT**: `merge_system` (merge válido/inválido/nível máximo + testes de propriedade: conservação de unidades 2× nível N ≡ 1× nível N+1), `economy` (compra, saldo, recompensa de kill), `wave_manager` (progressão, fim de fase), `targeting` (alcance + as 4 estratégias), `damage/life`, `addon_system` (compra, aplicação de buff), `save_system` (round-trip + migração de versão)
- **Regressão visual**: testes de fumaça carregando cada cena e validando que todos os `SpriteFrames` têm frames > 0
- **`validate_assets.gd`**: script headless (`godot --headless -s`) que varre a lista de assets exigidos e falha com lista de faltantes. 🆕 [M25] Também emite o relatório de cobertura (2.1) e, com `--manifest-only`, valida hashes contra `assets_manifest.json` quando os assets não estão presentes (CI — `[M02]`).
- **Teste de integração auto-play**: simulação headless da fase 1 inteira com seed fixa → asserts de vitória com estratégia válida e derrota sem merge (via `balance_sim.gd` — seção 5.5)
- Checagem estática: `godot --check-only` + **gdlint/gdformat (gdtoolkit)** no CI local + smoke build
- **CI dupla:** local (`run_checks.ps1`) + **GitHub Actions** (`.github/workflows/ci.yml`) rodando check + lint + tests + validate em push/PR — 🆕 [M20] ambos chamam **o mesmo script** (`run_checks.ps1 -CI`), com versões fixadas
- **Testes de física:** trajetória balística fecha (dado `g`, `v0` → alcance esperado); knockback decai a 0 e nunca ultrapassa os limites do caminho; bullet reciclado do pool não gera hit fantasma (estado `active=false`/`monitoring` desligado); inimigo nunca ultrapassa progress 1.0 (não atravessa a base); 🆕 [M08] projétil rápido não "atravessa" alvo fino (*swept test*)
- **Teste de input simulado (C2):** driver headless de `InputEventScreenTouch`/`ScreenDrag` — drag & drop de gato em slot válido/inválido, merge por soltar sobre par, long-press abre info; gesto crítico coberto sem toque real
- **QA de VFX [M30]:** smoke visual para merge válido/inválido, impacto, dano na base, chefe e recompensa; testar “Reduzir efeitos”, confirmar ausência de flashes de tela inteira e validar limites de partículas e pools de 4.1.
- **Testes das mecânicas novas:** cerco (inimigo em SIEGE causa DPS e knockback o desgruda), slow (velocidade cai e decai), venda de gato (refund íntegro de unidade), enrage (50% → multiplicadores), autosave/restore (round-trip no meio das ondas), wave banner + "iniciar agora" (bônus pago ao antecipar)
- 🆕 **Testes adicionais da revisão:**
  - **[M08] Determinismo:** mesma seed → mesmo *hash* do estado final da `SimWorld`; sem uso de RNG global em `sim/` (teste estático por busca)
  - **[M01] Progressão:** tier máximo alcançado ≤ `tier_cap`; matemática do merge (`2^(L-1)` compras; teto = nº de slots) coberta por teste de propriedade
  - **[M10] Economia:** sem arbitragem comprar→mesclar→vender; `run_coins` zeram a cada partida; `bank_coins` pagos corretamente em vitória e derrota
  - **[M12] Cerco/CC:** nunca mais que `siege_slots` atacantes; DPS ≤ teto; velocidade ≥ `min_speed_factor`
  - **[M14] Board:** todos os casos da tabela 3.2 (cheio, swap, fora do board, cascata, multi-touch, cancelamento)
  - **[M15] Save atômico:** `.tmp` parcial é ignorado; corrupção do principal restaura `.bak`; checkpoint em `FOCUS_OUT` restaura RNG e inimigos
  - **[M17] State machine:** transições inválidas rejeitadas
  - **Localização:** todas as chaves existem em PT-BR e EN; nenhum texto hardcoded em cenas
  - **[M16] Vazamento:** contagem de nós/recursos após 3 partidas seguidas estável; pools não crescem
  - **[M23] Estrelas:** resultado idêntico com 1× e 2×
  - **[M29] Áudio/licenças:** todo arquivo em `res://assets/audio` consta em `audio_manifest.json`; licença ∈ lista permitida (CC0 ou royalty-free comercial sem atribuição); sem arquivos órfãos nem entradas sem arquivo; hash confere; orçamento de áudio respeitado
  - **[M31] Créditos:** cada asset empacotado aparece no manifesto/catálogo; créditos obrigatórios têm texto integral; links de origem válidos; tela carrega offline e possui chaves PT-BR/EN
- **[M34] Arte externa:** cada imagem fora de Craftpix consta em `assets_manifest.json` e `credits_manifest.json`, com licença CC0 verificada, autor/URL/hash e decisão visual aprovada; rejeitados/ausentes não entram no build

### 6.1 🆕 Gate de validação integral e encerramento [M36]

**Regra de encerramento:** “desenvolvimento concluído” significa que o escopo final aprovado, incluindo as 5 fases principais e as 15 bônus, passou por todos os gates desta seção no mesmo candidato de release. MVP, vertical slice e entregas intermediárias são marcos de desenvolvimento, nunca evidência de conclusão do jogo. Requisito sem teste executado, resultado sem evidência ou teste bloqueado conta como **não aprovado**. Não se fecha a entrega nem se declara concluída enquanto houver falha, regressão, licença pendente, fase não testada ou item de aceite em aberto.

**Rastreabilidade obrigatória:** criar `docs/qa/requirements.csv` (IDs de requisito e aceite → IDs de casos), `docs/qa/test-cases.csv`, `docs/qa/test-runs/<build_id>/` e `docs/qa/release-checklist.md`. Cada execução guarda: ID do caso, requisito, versão/commit e hash do build, ambiente/dispositivo, passos ou seed, resultado esperado e observado, PASS/FAIL/BLOCKED, log/captura/vídeo quando aplicável, data e executor. A matriz não pode ter requisito sem caso, caso sem requisito, nem resultado sem evidência; a automação publica relatório de cobertura por requisito. Resultado de execução anterior não substitui execução no candidato final.

**Níveis de validação requeridos:**

1. **Unitário e propriedade:** todos os sistemas e casos de borda da seção 6; determinismo e seeds; economia sem arbitragem; merge, RNG, save/migração, ondas, chefe, targeting, colisão/hit-test, pool, input, localização e configurações. Resultado: suíte GUT + lint/check sem falhas.
2. **Integração e conteúdo:** smoke-load de todas as cenas/dados; iniciar, pausar, retomar, vencer e perder; salvar/restaurar; loja e recompensas; desbloqueios e replay; auditar IDs, assets referenciados e manifestos. Executar autoplay/simulação em **cada uma das 20 fases**, com seeds registradas e estratégias/bots definidos em 5.5; testar o caminho de vitória e cenários de derrota/limites relevantes.
3. **Jogo manual por fase:** completar uma sessão de cada uma das 20 fases no build de QA, conferindo caminho e torre-gato, leitura visual, ondas, chefe, modificadores, recursos, vitória/derrota, desbloqueio/recompensa e retorno ao mapa. Testar explicitamente as 15 bônus para confirmar que continuam tower defense. Guardar checklist e evidência por `stage_id`; não inferir a validação de uma fase a partir de outra.
4. **Compatibilidade, UX e acessibilidade:** Android em AVD principal, AVD low-end e landscape 16:9/20:9 com safe areas; instalar/atualizar e jogar no dispositivo físico Android de referência antes do aceite final. Validar rotação horizontal normal/invertida, touch/drag/multitouch, lifecycle/interrupção, PT-BR/EN e acentos, áudio/toggles, VFX e “Reduzir efeitos”, tela de créditos offline, desempenho, memória, bateria/estabilidade em sessão longa e logs. Repetir testes relevantes em cada resolução/perfil suportado.
5. **Desempenho/eficiência [M38]:** em build release e dispositivo/perfil low-end, medir PSS, textura residente, CPU do thread principal p95, frame time p95/p99, pools, draw calls e travamentos na onda mais carregada e numa sessão prolongada; cumprir todos os limites da seção 3.8 e guardar perfis/logs. Testar ida/volta por todas as áreas e três partidas seguidas para detectar retenção/crescimento de recursos.
6. **Assets e compliance:** executar `validate_assets`, auditoria de cobertura e hashes; verificar que todo asset efetivamente empacotado consta nos manifestos e créditos, tem licença/prova arquivada e uso previsto aprovado; conferir links e textos de atribuição; validar export para garantir que arquivos-fonte vedados não possam ser extraídos. Nenhum asset pendente ou “candidato” entra no release.
7. **Candidato final/release:** rodar `run_checks.ps1`/CI do zero no commit de release (check, lint, toda a suíte, simulação/balanceamento, manifestos, build e smoke); gerar export Android **release assinado**, instalar como instalação limpa e sobre uma versão anterior, abrir, jogar o fluxo principal e verificar logs; validar integridade/tamanho e arquivar hash, configuração e relatório. APK debug sozinho não aprova encerramento.

Suítes independentes podem ser distribuídas em paralelo em runners/worktrees, desde que todas usem o **mesmo commit imutável**, ambiente/versionamento fixados e seeds reproduzíveis; reunir os resultados em um único relatório completo. Sharding não pode omitir suites/casos nem converter timeout/ausência de resultado em sucesso. A validação manual e o smoke de integração continuam obrigatórios no candidato integrado.

**Falha, intermitência ou mudança:** qualquer FAIL/BLOCKED, crash, asset ausente, log `ERROR`, licença sem comprovação ou evidência faltante abre defeito rastreado e bloqueia o gate. Corrigir, executar novamente o caso afetado e a regressão relacionada; depois repetir a suíte completa e os checks de release no novo commit/build. Teste flaky não é aprovado pela média: reproduzir e estabilizar ou corrigir antes de fechar. Após qualquer mudança de código, conteúdo, assets, dados, licença, configuração de export ou dependências, invalidar as evidências que ela possa afetar e executar novamente os casos pertinentes; na mudança do candidato/commit, repetir todos os gates finais.

**Saída assinada do gate:** `docs/qa/final-validation-report.md` lista escopo e build/hash validados, contagem PASS/FAIL/BLOCKED, cobertura de requisitos/fases/plataformas, links das evidências, métricas, defeitos encerrados e aprovação de cada responsável. Aprovação final exige 100% dos requisitos do escopo com PASS e evidência, 20/20 fases testadas, 0 FAIL/BLOCKED/itens críticos abertos, CI verde e release candidate validado. Se um dispositivo físico ainda não estiver disponível, a entrega permanece “em validação”, não “concluída”.

## 7. Android + Emulador "Redmi Note 14 Pro + 5G"

- Configurar **Godot 4.x + export templates + Android SDK/JDK** — 🆕 [M20] versões **fixadas** (Godot, templates, GUT, gdtoolkit; JDK e build-tools conforme a documentação da versão do Godot escolhida) com checksums registrados em `docs/toolchain.md`
- Export `export_presets.cfg` → `build/merge-defense.apk`. 🆕 **[M03]** O build debug usa **`godot --headless --export-debug`** (`--export-release` exige keystore *release*, fora de escopo). A keystore **debug** é criada por `tools/setup_*.ps1` via `keytool` e informada ao Godot por variáveis de ambiente (`GODOT_ANDROID_KEYSTORE_DEBUG_PATH/USER/PASSWORD`) ou `export_presets.cfg` — o Godot não a gera sozinho em modo headless.
- **AVD** `Redmi_Note_14_Pro_Plus_5G`: 6.67", **1220x2712**, density 480dpi, Android 14 (API 34), 8GB RAM — criado via `avdmanager` (nome aproximado; hardware profile XML customizado em `devices.xml`)
- 🆕 **[M16] Matriz de dispositivos de teste:** (1) AVD Redmi (alto), (2) AVD **low-end** (≈ 3 GB RAM, 720x1600) para checar memória/GPU, (3) AVD ou configuração em **16:9** para validar aspect ratio/safe area, (4) **dispositivo físico** assim que disponível — o emulador não representa a GPU real; medições de performance valem como tendência.
- **Otimização para ETC2/ASTC**: texturas comprimidas suportadas pelas configurações de qualidade do Android. 🆕 [M07] Habilitar `rendering/textures/vram_compression/import_etc2_astc`; por classe de asset: sprites animados → VRAM Compressed; **UI com gradientes/bordas finas → Lossless** (compressão ASTC/ETC2 gera artefatos visíveis em gradientes); mipmaps desligados; verificar a qualidade visual no emulador antes de congelar.
- 🆕 **[M07] Exportação enxuta:** `exclude_filter` no preset para `Spine`, `Ai`, `Eps`, `Preview`, `Json Atlas` (se não adotado) e `debug/*`; manifesto lista o que entra. Meta de APK mais agressiva que o teto: **≤ 150 MB** (teto de aceitação continua 200 MB).
- **Scripts PowerShell em `tools/`**:
  - `setup_emulator.ps1` — cria o AVD se não existir (idempotente, códigos de saída ≠ 0 em erro)
  - `build_install_play.ps1` → fluxo completo: valida assets → roda testes GUT → compila APK (`godot --headless --export-debug`) → inicia emulador → `adb wait-for-device` → `adb install -r` → `adb shell monkey -p com.studio.mergedefense` → janela pronta para jogo manual
- Parâmetros: `-SkipTests`, `-BuildOnly`, `-Fresh`, 🆕 `-Verify` (após abrir o app, coleta `adb logcat -s godot` por N segundos, **falha se houver linhas `ERROR`/`missing`**, e salva screenshot via `adb exec-out screencap -p` em `reports/`)
- `version_code`/`version_name` no `export_presets.cfg` desde a primeira build
- **Log de debug:** habilitar `debug/file_logging/enable_file_logging` e escrever em `user://logs` para diagnóstico no emulador; `perf.csv` (frame time, memória, nós, draw calls, 1 linha/s) apenas em debug
- Orçamento de performance [M16][M38]: build release no perfil low-end mantém PSS ≤ 256 MiB e texturas residentes da fase ≤ 128 MiB; CPU principal p95 ≤ 8 ms/frame; frame completo p95 ≤ 16,7 ms e p99 ≤ 25 ms no pico da onda (nenhum frame > 100 ms fora de carregamento); APK ≤ 200 MB (meta ≤ 150 MB). Medir no cenário de estresse e registrar dados em `docs/performance/` conforme seções 3.8 e 6.1.
- 🆕 **[M26] Debug menu (somente build debug, removido do release):** dar moedas/gems, spawnar gato de nível N (valida C13–C15 e o balanceamento visual), pular onda, matar chefe, ligar 2× e overlay de performance (FPS, frame time, draw calls, memória, nº de entidades).

### 7.1 🆕 Checklist de ciclo de vida e plataforma Android [M15]

- `application/config/quit_on_go_back=false`; tratar `NOTIFICATION_WM_GO_BACK_REQUEST` (pausa/confirmar saída)
- `NOTIFICATION_APPLICATION_FOCUS_OUT`/`PAUSED` → pausar a sim + checkpoint (`[M04]`); no retorno, **não** retomar automaticamente: mostrar o pause menu
- **Permissão `VIBRATE`** marcada no preset de export (sem ela `Input.vibrate_handheld()` não faz nada)
- `DisplayServer.screen_set_keep_on(true)` durante a partida; orientação **landscape** (normal e invertida), portrait desativado
- Safe area: `DisplayServer.get_display_safe_area()` e cutout aplicados ao layout; stretch `canvas_items` com aspect `keep`; teste automatizado cobre insets simulados. Validar em aparelhos 16:9 e 20:9, incluindo notch e cutouts.
- Compatibilidade com *gesture navigation* (gestos de borda não podem disparar drags — margem lateral de 24 dp no board)
- Interrupções (ligação, notificação, trocar de app) cobertas pelo cancelamento de drag (3.2)

## 8. Entregáveis desta execução (após aprovação)

1. **`.ai\plan\01-merge-defense-game-plan.md`** — este plano completo gravado em arquivo (passo 1)
2. Projeto Godot 4.x em `C:\src\cats-defender\godot/` (raiz do projeto) com todas as cenas e sistemas acima; assets principais de `C:\src\assets\craftpix-net` e apenas assets visuais CC0 selecionados na seção 2.3 em `res://assets/` (áudio/fonte: seção 12)
3. `assets_manifest.json` gerado + validador + 🆕 `docs/assets_audit.md` e relatório de cobertura [M06][M25]
4. Suíte GUT (unit + propriedade + auto-play) + `validate_assets.gd` + lint (gdlint/gdformat) + CI local (`run_checks.ps1` = check + lint + tests + validate + build)
5. `tools/*.ps1` (setup, build, emulator, build+install+play)
6. APK debug + instruções `README.md` para o fluxo Redmi Note 14 Pro + 5G
7. `.github/workflows/ci.yml` (GitHub Actions — check + lint + tests + validate em push/PR; mesmo `run_checks.ps1 -CI` — `[M20]`)
8. `data/balance.csv` + `balance_sim.gd` (+ `reports/balance.md`); localização PT-BR/EN (CSV); áudio CC0 + fonte Passion One (exceções da seção 12); 🆕 [M29] `audio_manifest.json` + cópias das páginas de licença em `docs/licenses/audio/`
9. 🆕 `.gitignore` (`.godot/`, `build/`, `reports/`, keystores) e `.gitattributes` (Git LFS para PNG/OGG/WAV) [M02][M20]
10. 🆕 `docs/{licenses.md, layout.md, toolchain.md, narrative.md}`, tela `credits`, `CREDITS.md` e `credits_manifest.json` com autores, pacotes, licenças, assets por grupo e links de origem [M02][M22][M31][M32]
11. 🆕 Debug menu e overlay de performance (apenas debug) [M26]
12. 🆕 Depois do MVP: dados para 5 fases principais e 15 fases bônus de tower defense, desbloqueios e progresso individual salvo por `stage_id` [M33]
13. 🆕 Pacote QA (`docs/qa/requirements.csv`, `test-cases.csv`, execuções/evidências por build, checklist e relatório final) + candidato Android release assinado e validado conforme 6.1 [M36]
14. 🆕 Implementação em frentes IA isoladas, tarefas/contratos revisados e integração sequencial com evidências focais por frente; relatório agregado no commit final conforme 9.1 [M37]
15. 🆕 Baseline e relatório final de performance (`docs/performance/`) com memória, CPU, frame time, textura residente e tamanho do build nos perfis suportados [M38]

## 9. Etapas de implementação (ordem)

**Abordagem: vertical slice primeiro** (valida touch/drag no emulador cedo), depois a largura completa. 🆕 [M19] O slice é construído **sobre o core mínimo** (e não antes dele) para não virar código descartável.

**Definition of Done (DoD) por etapa (C1):** etapa só avança quando (a) código implementado e `--check-only` limpo, (b) testes GUT novos correspondentes verdes, (c) `validate_assets` sem faltantes, (d) smoke manual no emulador quando afetar UI/gameplay, (e) sem regressão de performance e (f) log limpo (0 `ERROR`/`missing`). Registrar resultados/evidências na matriz `docs/qa/` (6.1); testes são escritos e executados na própria etapa. **DoD local não equivale a conclusão do projeto:** o projeto permanece aberto até passar o gate integral de 6.1 com o escopo final completo.

0. 🆕 **Etapa 0 — Fundação [M02][M06][M07][M01][M34][M38]:** ler `license.txt` e registrar em `docs/licenses.md`; salvar prova das licenças dos packs de áudio (12.1) e imagens externas candidatas (2.3); auditar estilo, resolução e memória (2.2); fixar budgets de 3.8 e registrar baseline preliminar de CPU/RAM/GPU/APK; validar matemática da progressão (5.1), decidir layout (3.0) e fechar decisões da seção 14. Registrar cada candidato como aprovado ou rejeitado antes de copiar para o projeto.
1. Gravar `.ai\plan\01-merge-defense-game-plan.md`
2. Criar projeto Godot (versão estável 4.x fixada em `project.godot`, renderer Compatibility) + copiar seletivamente os assets Craftpix e os CC0 aprovados na auditoria 2.3 (com .import, compressão ETC2/ASTC e `exclude_filter`) + exceções da seção 12 (áudio e fonte)
3. 🆕 **Core mínimo [M19]:** `SimWorld` (caminho 1D, RNG injetado, tick fixo), `EventBus`, `GameState` (esqueleto), Resources de dados, `FrameLoader`, `object_pool` — com testes
4. **Vertical slice jogável:** board mínimo com 2 slots, 1 gato, 1 inimigo, merge manual, dano/moeda — validar drag & drop por toque no emulador. 🆕 **Gate [M07][M19]:** exportar um APK debug nesta etapa (valida export/keystore cedo), medir draw calls/memória/frame time e **decidir PNGs soltos vs. Json Atlas**
5. Core completo: autoloads restantes (SceneRouter, SaveSystem versionado + atômico, Localization, AudioManager, FeatureFlags), debug menu
6. Cenas: Splash → Menu → LevelSelect(1 nível) → Game (board, puxar/mesclar, ondas, base) → Win/Lose popups; pause menu; settings; credits; tutorial guiado; Shop, Upgrade e Addon screens
7. Sistemas: merge (C1..C15 + `tier_cap`), economia (run/bank, custo crescente, venda de gato, upgrade), addons, waves (pacing/banner/iniciar agora), targeting (4 estratégias), cerco (SIEGE com `siege_slots`), slow, enrage, melee (Guardian/Boxing), bullets 3 arquétipos (pool), juice, estrelas→gems, velocidade 2×, autosave/checkpoint
8. Balanceamento data-driven: `balance.csv` + `balance_sim.gd` (4 bots + sensibilidade + tier máximo)
9. Complementos de teste: propriedade + input simulado + mecânicas novas + auto-play headless + validate_assets + gdlint/gdformat (testes principais já existem desde as etapas anteriores)
10. Export Android final, AVDs (matriz 7), scripts, APK + validação manual no emulador (`-Verify`)
11. CI: `run_checks.ps1` local + workflow GitHub Actions (mesmo script)
12. `run_checks.ps1` final: check → lint → tests → validate → build → install → launch
13. **Conteúdo completo:** implementar dados/assets das cinco fases principais e 15 bônus; executar autoplay por seed em todas e sessão manual em cada `stage_id`; corrigir falhas e arquivar evidências.
14. **Gate de release [M36]:** congelar candidato; executar matriz integral 6.1 no commit final; gerar/instalar/verificar build Android release; produzir relatório final e checklist. Encerrar somente com todos os critérios PASS.

### 9.1 🆕 Desenvolvimento e testes em paralelo com IA [M37]

Usar agentes para aumentar a vazão de trabalho **sem compartilhar a mesma pasta de edição**. O usuário ou agente principal atua como **integrador**: mantém o plano/contratos, distribui tarefas, revisa resultados, resolve conflitos e decide a ordem de integração. Cada agente recebe uma tarefa pequena e fechada, executa em branch/worktree isolada, roda os testes da sua frente e entrega diff, arquivos alterados, comandos/resultados, evidências, limitações e riscos. Nenhum agente declara o jogo concluído; só o gate 6.1 aprova o build final.

**Frentes paralelas recomendadas, depois de congelar os contratos da etapa 0/core mínimo:**

| Frente/agente | Escopo independente | Limites de propriedade |
|---|---|---|
| **A — Simulação e economia** | `SimWorld`, merge, ondas, targeting, dano, moedas e APIs determinísticas | `scripts/sim/`, `scripts/economy/`, testes de unidade correspondentes; não alterar cenas ou arquivos globais de projeto |
| **B — UI, input e cenas** | HUD, board, drag/drop, menus, feedback visual e acessibilidade | `scenes/`, `scripts/ui/`, estilos/tema e testes de UI; consumir contratos documentados da Frente A |
| **C — Conteúdo e narrativa** | Resources/CSV das fases, progressão, textos PT-BR/EN, storyboard e integração dos assets permitidos | `data/`, `localization/`, `docs/narrative.md` e manifesto de conteúdo; não alterar runtime compartilhado |
| **D — QA e automação** | Plano/matriz de teste, testes GUT, scripts de verificação, casos de borda, relatório de cobertura e CI | `tests/`, `tools/qa/`, `docs/qa/` e workflow; não alterar código de produção para fazer um teste passar |

Esses caminhos são uma proposta: antes da distribuição, o integrador deve conferir a estrutura real do repositório, criar/ajustar `CODEOWNERS` ou mapa de propriedade e remover sobreposições. `project.godot`, autoloads, recursos globais, arquivos de lock, configurações de export e scripts centrais são **zona de integração**: apenas o integrador os altera, ou um agente recebe autorização exclusiva durante uma janela definida. Assets binários também têm um único responsável por importação/licença/manifesto.

**Sequência para habilitar o paralelismo:**

1. O integrador transforma o plano em tarefas com ID, objetivo, arquivos permitidos/proibidos, dependências, contrato de API, critérios de aceite, comando de teste e definição da evidência. Não delegar um objetivo vago como “faça o jogo”.
2. Congelar os contratos mínimos entre `SimWorld`, estado/save, dados das fases, cenas e eventos; manter interfaces/esquemas em documento versionado. Se o contrato mudar, pausar tarefas dependentes, publicar a nova versão e revalidar o que já foi feito.
3. Distribuir no máximo uma tarefa de escrita por worktree/branch, com propriedade de arquivos explícita. Para trabalho paralelo usar worktrees independentes; não abrir múltiplos agentes escrevendo no mesmo checkout/arquivo. Permitir trabalho simultâneo de implementação e escrita de testes quando os IDs de casos e contratos já estiverem definidos.
4. Cada frente roda `--check-only`, lint e seus testes focados; o agente QA pode criar/rodar testes da feature contra uma branch ou fixture conhecida. Um resultado verde isolado demonstra somente aquela revisão, nunca a integração nem a aprovação final.
5. O integrador revisa diff/licença/arquitetura, rejeita mudanças fora do escopo, integra uma frente por vez, resolve conflitos sem descartar testes e executa smoke/CI no commit resultante. Não integrar dois resultados baseados em APIs incompatíveis.
6. Depois que todas as frentes forem integradas, repetir a suíte completa, autoplay das 20 fases, regressão manual e gate da seção 6.1 no mesmo commit/candidato release. Repetir qualquer teste afetado por conflito, rebase, mudança de contrato, código, dados ou assets; só evidências desse candidato contam.

**Como iniciar no Codex:** abrir o projeto e pedir ao agente principal, por exemplo: “Leia o plano e a seção 9.1. Primeiro proponha contratos e tarefas sem sobreposição para simulação, UI, conteúdo e QA; não altere arquivos compartilhados. Depois distribua tarefas independentes em worktrees, aguarde cada resultado, revise e integre uma por vez, rode a CI integrada e atualize `docs/qa/` com evidências. Não declare concluído antes do gate 6.1.” O Codex pode não ter slots, ferramentas ou contexto suficientes para iniciar todas as frentes de uma vez; nesse caso, executar em lotes conforme dependências e capacidade disponível, sem misturar worktrees. Para um projeto ainda não implementado, comece pela etapa 0/core mínimo e contratos; depois delegue frentes independentes.

**Critérios de aceite do paralelismo:** toda tarefa tem responsável/agente e worktree/branch identificados; nenhum arquivo compartilhado foi editado por mais de uma frente em paralelo; interfaces usadas correspondem à versão aprovada; cada frente tem teste focal e revisão de diff; conflitos são registrados e resolvidos; a integração final tem CI verde e evidências do build final conforme 6.1. Paralelismo acelera execução, mas não reduz cobertura, revisão ou exigência de validação.

### 9.2 🆕 Priorização das mecânicas [M18]

Os grupos 🔴🟠🟡 citados na seção 11 não estavam definidos, e vários IDs (A*, B*, C*) vinham de uma versão anterior do plano. Definição (IDs A2/A6 e quaisquer outros não presentes neste arquivo devem ser reconciliados com a versão anterior):

| Grupo | Mecânicas |
|---|---|
| 🔴 **Núcleo** (sem isso não há jogo) | drag & drop + compra + merge C1..C15 (com `tier_cap`); ondas + pacing; base com HP; vitória/derrota; **cerco (A1)**; moedas; save versionado básico; localização |
| 🟠 **Importante** | venda de gato (A5) com desfazer; targeting 4 estratégias; addons; upgrade por gato (A8); pause menu; HP bars (B1); feedback de dano na base (B2); estrelas → gems (B4); autosave/checkpoint (B3); slow (A3); chefe + enrage (A7); tutorial; input simulado (C2) |
| 🟡 **Desejável** | melee Guardian/Boxing (A4); velocidade 2× (C3); granadas balísticas; partículas com gravidade; juice extra; "reduzir efeitos"; painel de info por long-press |

Ordem de entrega: slice → 🔴 → 🟠 → 🟡. Cortar de baixo para cima se o prazo apertar.

## 10. Critérios de aceitação

Os itens abaixo são gates de saída cumulativos, além da seção 6.1. A entrega final permanece aberta até todos estarem PASS, rastreados e evidenciados no mesmo candidato de release; marcos MVP podem ser aprovados separadamente, mas não encerram o desenvolvimento do escopo completo.

- `run_checks.ps1` passa de ponta a ponta (0 falhas, 0 warnings nos testes) e o workflow GitHub Actions verde
- **VFX do MVP:** feedback de drag/drop, merge, tiro/impacto, dano à base, banner de onda e popup de resultado; “Reduzir efeitos” funcional. VFX de chefe, enrage e recompensa avançada podem ser polidos depois do MVP (4.1).
- Assets de imagem da fonte principal Craftpix e dos candidatos visuais CC0 aprovados na seção 2.3; 🆕 [M25][M34] relatório de cobertura (usado/adiado/excluído/rejeitado) gerado e **0 faltantes** entre os "usados"; todo arquivo externo tem licença e origem registradas e passa pela prancha de consistência visual
- Fase 1 completa: 5 ondas regulares + escala de dificuldade + chefe; vitória (com estrelas 1–3) e derrota funcionais
- 🆕 [M01] **Cadeia C1..C15 implementada e testada** (merge de ponta a ponta validado por testes e debug menu); em jogo, o tier máximo alcançável é regulado por `tier_cap` e reportado pelo `balance_sim` (substitui "Merge C1..C15 funcionando" na fase, que seria impossível por matemática — seção 5.1)
- Compra (com moedas), loja, addons, popups, pause/settings, tutorial funcionando
- **Sons de áudio CC0 funcionando no jogo** (exceção aprovada — seção 12); 🆕 [M29] 100% dos arquivos de áudio listados em `audio_manifest.json` com licença permitida, 0 órfãos, orçamento de áudio ≤ 25 MB (valor-semente) e todos os eventos da tabela 12.1 com som
- 🆕 [M31] Tela de créditos cumpre todos os critérios da seção 12.2: atribuições, licença, assets usados e origem/link por fonte, em PT-BR/EN e disponível offline.
- 🆕 [M32] A fase 1 apresenta a premissa, o tutorial contextual, o chefe e os finais de vitória/derrota segundo 4.2; introdução pulável, sem cutscene longa, strings disponíveis em PT-BR/EN e nenhuma regra essencial apenas em texto narrativo.
- 🆕 [M33] O roadmap completo contém 5 fases principais e 15 bônus; cada bônus segue as regras de tower defense da seção 13.2, possui dados/ID próprios, desbloqueio e recompensa única testáveis. Esse conteúdo é pós-MVP.
- **Texturas comprimidas ETC2/ASTC funcionando corretamente no emulador Android**
- **Métricas (🆕 mensuráveis [M16][M38]):** no perfil low-end, PSS ≤ 256 MiB e texturas da fase ativa ≤ 128 MiB; CPU do thread principal p95 ≤ 8 ms/frame; frame p95 ≤ 16,7 ms e p99 ≤ 25 ms com pool ativo no pico da onda (sem travamentos > 100 ms fora de carregamento); APK ≤ 200 MB (meta 150 MB); troca de tela < 1 s; sem crash; **0 "missing asset"/`ERROR` no log do Godot e no logcat** (verificado por `-Verify`). Budgets definidos na seção 3.8 e evidenciados em `docs/performance/`.
- **Mecânicas novas funcionando:** cerco (com `siege_slots`), venda de gato (com desfazer), banner de onda + iniciar agora, slow, melee (Guardian/Boxing), enrage, HP bars, 0Bar..5Bar, estrelas→gems, velocidade 2×, autosave/checkpoint **no meio da onda e em `FOCUS_OUT`** (`[M04]`)
- 🆕 **Economia:** `run_coins` e `bank_coins` separadas e testadas; sem arbitragem; loja com itens mapeados (5.3)
- 🆕 **Balanceamento:** os 4 bots dentro das faixas-alvo; teste de sensibilidade ±10% verde (5.5)
- 🆕 **Acessibilidade:** "Reduzir efeitos" funcional; toggles de som/música/vibração respeitados em todo o jogo
- APK instala e abre no emulador "Redmi Note 14 Pro + 5G" via `build_install_play.ps1`
- 🆕 **[M36] Gate final:** relatório `docs/qa/final-validation-report.md` aprovado; 100% dos requisitos do escopo com caso e evidência PASS; campanha 5/5 e bônus 15/15 testadas manualmente e via simulação; AVDs + dispositivo físico Android validados; suíte/CI verde no commit do release; build release assinado instalado e verificado (instalação limpa e atualização); 0 FAIL/BLOCKED, 0 defeitos críticos/altos abertos, 0 licenças/assets sem prova e checklist de release completo.
- 🆕 **[M37] Paralelismo IA:** frentes trabalham em worktrees sem colisões; cada diff foi revisado e testado; nenhuma evidência isolada é tratada como integração; suíte e gate final completos passaram no commit único integrado.
- 🆕 **[M38] Eficiência:** no perfil low-end da seção 7, build release cumpre PSS ≤ 256 MiB, texturas residentes ≤ 128 MiB, CPU principal p95 ≤ 8 ms/frame, frame p95 ≤ 16,7 ms e p99 ≤ 25 ms; APK ≤ 200 MB; sem crescimento de memória/pools após três partidas e sem travamentos > 100 ms fora de carregamento. Relatório reproduzível em `docs/performance/` acompanha o candidato validado.

## 10.1 🆕 Critérios de Qualidade de Usabilidade (Heurísticas de Nielsen + Mobile Game UX)

Estes critérios servem como **checklist de qualidade** para revisão manual e validação de UX antes do gate final (6.1). Cada item deve ser testado no dispositivo/emulador e registrado como PASS/FAIL com evidência (screenshot/vídeo/log).

| ID | Critério | Como validar | Evidência esperada |
|----|----------|--------------|-------------------|
| **U01** | **Visibilidade do status do sistema** | HUD mostra fase, moedas, gems, ondas, HP base, velocidade 1×/2×, targeting ativo — sempre legível em 16:9 e 20:9 | Captura de tela de todas as 20 fases com HUD completo |
| **U02** | **Correspondência entre sistema e mundo real** | Termos: "Comprar", "Mesclar", "Vender", "Alvo", "Iniciar", "Pausar", "Continuar", "Reiniciar", "Sair" — linguagem do jogador, sem jargão técnico | Checklist de strings em PT-BR/EN (localization.csv) |
| **U03** | **Controle e liberdade do usuário** | Desfazer venda (3 s), pausar a qualquer momento, sair da partida com confirmação, cancelar drag soltando fora, voltar no menu com botão físico | Log de ações + vídeo demonstrando cada caso |
| **U04** | **Consistência e padrões** | Botões verdes = ação primária/confirmar; laranja = atenção/secundário; ícones consistentes (moeda, gem, onda, vida); mesmo layout de popups; feedback de toque em 100% dos botões | Guia de estilo UI + validação visual cross-phase |
| **U05** | **Prevenção de erros** | Board cheio desabilita compra; merge inválido destaca motivo; debounce 150 ms em compras; zona "Vender" explícita (não arrastar para fora); long-press 500 ms para info/venda | Testes automatizados 3.2 + vídeo de cada prevenção |
| **U06** | **Reconhecimento em vez de memorização** | Tooltip no merge mostra "dano atual → próximo"; painel de info por long-press; targeting mostra modo ativo; addons listam efeito numérico; tutorial contextual na fase 1 | Captura de cada tooltip/painel/tutorial |
| **U07** | **Flexibilidade e eficiência de uso** | Drag & drop fluido (fantasma + highlight); atalhos: toque duplo compra (com debounce), 2× para jogadores experientes, "iniciar agora" com bônus | Métricas: tempo para compra, merge, iniciar onda |
| **U08** | **Estética e design minimalista** | Sem elementos decorativos que competem com gameplay; safe areas respeitadas; "Reduzir efeitos" remove partículas decorativas; contraste 4.5:1 em textos | Relatório de auditoria visual (2.2) + teste "Reduzir efeitos" |
| **U09** | **Ajuda a reconhecer, diagnosticar e recuperar erros** | Mensagens claras: "Moedas insuficientes", "Slot ocupado", "Nível máximo atingido", "Merge requer mesmo nível" — com ícone + cor + som | Lista de mensagens de erro + teste de cada uma |
| **U10** | **Ajuda e documentação** | Tutorial guiado 30 s na fase 1; painel de info acessível; tela de créditos offline; settings com descrição de cada toggle | Vídeo do tutorial + checklist de ajuda |
| **U11** | **Acessibilidade (WCAG 2.1 AA mobile)** | "Reduzir efeitos" funcional; escala de texto 100/115/130%; não só cor para estado; toggles som/música/vibração respeitados; alvos de toque ≥ 48 dp | Relatório de acessibilidade + teste em device |
| **U12** | **Feedback tátil e sonoro** | Vibração no merge, dano na base, compra; sons em todos os botões/ações; pitch variation ±5% em SFX repetidos | Log de haptics + áudio gravado da sessão |
| **U13** | **Tolerância a interrupções** | Foco perdido → pausa + checkpoint; rotação 180° mantém layout; gesto de borda não dispara drag; ligação/notificação não quebram jogo | Teste de interrupção em cada fase |
| **U14** | **Onboarding progressivo** | Fase 1 ensina: comprar → posicionar → mesclar → targeting → addon → iniciar onda — sem parede de texto | Vídeo do onboarding + taxa de conclusão tutorial |
| **U15** | **Legibilidade em condições reais** | Testar sob luz solar (brilho máximo), luz baixa, com notch/punch-hole, com gesture navigation ativo | Fotos/vídeo em condições variadas |

## 10.2 🆕 Critérios de Qualidade de Jogabilidade (Game Design Quality)

Estes critérios avaliam a **experiência de jogo** — diversão, desafio justo, progressão satisfatória, profundidade estratégica. Validados via playtest manual + métricas do `balance_sim` + revisão de design.

| ID | Critério | Como validar | Métrica/evidência alvo |
|----|----------|--------------|------------------------|
| **G01** | **Curva de aprendizado suave** | Novato completa tutorial e vence fase 1 em ≤ 3 tentativas; entende merge, targeting, addons sem ajuda externa | Taxa de sucesso tutorial ≥ 90%; tempo até primeiro merge < 60 s |
| **G02** | **Clareza de causa e efeito** | Jogador identifica por que perdeu (base destruída, ouro gasto mal, targeting errado) e sabe o que mudar | Entrevista pós-playtest + heatmap de mortes |
| **G03** | **Agência e decisões significativas** | Pelo menos 3 escolhas estratégicas por onda: qual gato comprar, onde posicionar, merge ou economizar, targeting, addon, iniciar agora | Análise de árvore de decisão por onda |
| **G04** | **Feedback de progressão tangível** | Cada merge mostra aumento visual de dano (número + sprite); upgrade por gato reflete no DPS; estrelas → gems visíveis | Log de upgrades/merges + vídeo de progressão |
| **G05** | **Desafio justo (fair challenge)** | Derrotas sentem-se como "eu poderia ter feito melhor", não "o jogo trapaceou"; RNG determinístico por seed; sem one-shot inevitável | Bots: Ótimo ≥ 90% vitória; Passivo ≤ 10%; sensibilidade ±10% não inverte ordem |
| **G06** | **Pacing e ritmo** | Ondas têm preparação (3–5 s), ação (15–40 s), resolução; "iniciar agora" acelera sem pular preparação; chefe tem fase enrage distinta | Timeline de ondas + frame time p95 ≤ 16.7 ms |
| **G07** | **Variedade de situações** | 5 fases principais + 15 bônus com modificadores distintos (cerco, recursos limitados, horda); inimigos exigem targeting diferente | Matriz de fases (13.2) + playtest de cada bônus |
| **G08** | **Profundidade estratégica (emergência)** | Combinações: merge + targeting + addon + upgrade + melee criam builds distintas; não há "build dominante única" | Balance_sim: 4 bots com estratégias diferentes; tier máximo variado |
| **G09** | **Economia saudável (sem grind, sem quebrar)** | `run_coins` zeram a partida; `bank_coins` crescem com vitórias; custo crescente impede spam; sell_refund < 100% evita loop | Log de economia por partida; teste de propriedade "sem arbitragem" |
| **G10** | **Recompensas proporcionais ao esforço** | Estrelas 1–3 refletem desempenho (HP base, eficiência, não tempo real); gems escalam com estrelas; bônus "iniciar agora" vale o risco | Tabela de estrelas no balance.csv + playtest |
| **G11** | **Clareza de estado do jogo** | Jogador sabe sempre: onda atual/total, HP base, HP chefe, moedas, targeting, velocidade, addons equipados | Eye-tracking ou think-aloud em playtest |
| **G12** | **Satisfação de merge (core loop)** | Merge tem "juice" (pulo, partículas, som, glow, tooltip dano→próximo); resultado imediato visível; merge cascata fluido | Vídeo de merges em sequência + métrica de tempo merge→resultado < 400 ms |
| **G13** | **Boss fights memoráveis** | Chefe tem HP bar, enrage visual/mecânico, padrão de ataque único; derrota exige adaptação (targeting, positioning, addons) | Playtest chefe + taxa de vitória por bot |
| **G14** | **Rejogabilidade** | 3 estrelas incentivam replay; bônus desbloqueados pós-campanha; seeds diferentes variam composição de ondas | Retenção: % jogadores que rejogam fase 1 para 3 estrelas |
| **G15** | **Ausência de "dead ends"** | Board cheio nunca trava (botão desabilitado + feedback); venda sempre possível; merge sempre possível se houver par; sempre há ação válida | Testes de borda 3.2 + playtest prolongado |
| **G16** | **Equilíbrio risco/recompensa** | "Iniciar agora" dá coins extra mas reduz tempo de prep; addons custam run_coins mas dão poder; melee custa slot + coins | Análise de valor esperado por decisão |
| **G17** | **Progressão de longo prazo respeitada** | Upgrades permanentes (nível de compra, slots, melee, addons) sentem-se impactantes; C13–C15 alcançáveis no late game via progressão | balance_sim: tier máximo atinge C13+ no late game |
| **G18** | **Ausência de dominant strategy** | Nenhuma combinação (gato + addon + targeting) vence todas as situações sem pensamento; meta muda por fase/bônus | Balance_sim sensibilidade + playtest cross-phase |
| **G19** | **Clareza de affordances** | Slots aceitam drag (highlight); zona vender tem ícone lixeira; botão targeting cicla ícones; addon slots mostram vazio/ocupado | Auditoria visual + teste de usabilidade |
| **G20** | **Polimento "game feel"** | Screen shake só em eventos fortes; partículas não ocultam gameplay; números de dano legíveis; moedas com quique satisfatório; knockback visível | Vídeo de gameplay 5 min + checklist 4.1 |

## 11. Riscos e mitigações
| Risco | Mitigação |
|---|---|
| Godot 'última estável 4.x' pode ter breaking changes nas APIs Android | Fixar versão exata em `project.godot` + export templates; 🆕 [M19] validar export já na **etapa 4 (slice)**, não só na 10 |
| Cadeia de merge C1..C15 exige mais balanceamento | `balance.csv` data-driven + `balance_sim.gd` automatizado (seção 5.5) |
| 🆕 [M01] Parte da cadeia (C13–C15) é inalcançável com 12 slots por matemática | `tier_cap` por fase + nível de compra + slots extras + teste via debug menu (5.1) |
| AVD de perfil custom 'Redmi Note 14 Pro + 5G' pode falhar no setup | `setup_emulator.ps1` idempotente; fallback para AVD genérico em perfil landscape (ex.: 1920x1080) |
| PNGs soltos podem gerar muitos draw calls/memória no Android | 🆕 [M07] *Gate* de medição no slice; subamostragem de frames; Json Atlas do pack (34 atlas) como plano B |
| Exceções de assets externos (áudio/fonte) | Exceções documentadas na seção 12; fallback built-in do Godot sempre disponível; 🆕 licenças em `CREDITS` |
| Escopo de mecânicas cresceu (16 novas) — risco de prazo | Priorização na seção 9.2 (grupos 🔴 → 🟠 → 🟡 agora definidos); DoD por etapa corta atraso cedo |
| 🆕 [M02] Licença Craftpix pode proibir redistribuição dos fontes (repo público/CI) | Ler `license.txt` na Etapa 0; repo privado + Git LFS; CI em modo `--manifest-only` |
| 🆕 [M03] Build `--export-release` falha sem keystore release | Usar `--export-debug`; `keytool` no setup |
| 🆕 [M06] PNGs de UI com texto embutido quebram PT-BR/EN | Auditoria na Etapa 0; Label sobreposto ou ocultar o texto |
| 🆕 [M05] Orientação de `Area1..5` incompatível com o layout planejado | Auditoria + wireframe landscape e validação de crop (3.0) |
| 🆕 [M16] Emulador mascara problemas de GPU/memória do dispositivo real | Matriz de dispositivos (inclui low-end e físico); medir p95/p99, não média |
| 🆕 [M08] Acoplamento sim↔nós deixa `balance_sim` lento e frágil | Núcleo de sim puro (3.4) |
| 🆕 [M10] Economia confusa (moedas duplicadas) gera bugs de saldo | Duas contas explícitas + testes de propriedade |
| 🆕 [M29] Som com licença não comercial/atribuição escondida entra no jogo vendido | Só CC0/royalty-free comercial; `audio_manifest.json` + teste no CI; cópia da página de licença no dia do download; lista "não usar" (12.1) |

## 12. Premissas/explicitações (inclui decisões registradas)

- Godot **última versão estável 4.x** (decisão registrada — substitui o anterior 4.2.x LTS; mitigação na seção 11); versão exata fixada ao criar `project.godot`
- Keystore **debug** gerada **pelo script de setup via `keytool`** (🆕 [M03] — o Godot não a gera sozinho em modo headless); release requer keystore do usuário (fora de escopo)
- **Áudio — exceção aprovada:** packs de áudio externos de licença livre para uso comercial (**CC0 primeiro**), pois o pack Craftpix não inclui sons; toggles de som/música permanecem funcionais. 🆕 [M22] Créditos/licenças em `CREDITS` e na tela `credits`. 🆕 [M29] Catálogo concreto, mapeamento e regras de conformidade na seção 12.1.
- **Fonte — exceção aprovada:** Passion One (indicada pelo próprio pack via `Font Link.txt`) como primária + fonte built-in do Godot como fallback. 🆕 [M22] A Passion One é licenciada sob **SIL OFL**: incluir o texto da licença nos créditos/`docs/licenses.md`; verificar cobertura de glifos PT-BR (acentos) no teste de localização.
- **Addons:** mecânica definida na seção 5 (buffs compráveis em slots) — em escopo
- **HP bars, feedback de dano na base, enrage, loop estrelas→gems, velocidade 2×:** definidos na seção 4 (🆕 [M28] — antes duplicados nesta seção; mantida apenas a referência, conforme DRY)
- **`OrangeBTNAds` — 🆕 decisão registrada [M24]:** sem SDK de anúncios no escopo; o botão fica **oculto** atrás de `FeatureFlags.ads_enabled = false` (botão visível sem função é pior que ausente). Pode virar "Bônus diário"/"dobrar recompensa" em etapa futura.
- **CI:** GitHub Actions (`.github/workflows/ci.yml`) além do CI local `run_checks.ps1`; 🆕 [M02] repositório **privado**; assets via Git LFS ou modo `--manifest-only`
- MVP com uma fase jogável; roadmap pós-MVP: campanha de 5 fases + 15 fases bônus de tower defense (seção 13), com `LevelSelect`/save preparados para progresso por fase
- "Armas" do pedido = projéteis dos gatos (o pack não tem ítens de arma separados; `Uplogo*` representam upgrades — 🆕 [M10] possivelmente por gato, ver 5.4)
- 🆕 **[M27] Fora de escopo, mas registrado para não travar o futuro:** publicação na Play Store exige **AAB** (não APK), keystore de release/Play App Signing e o **target API vigente** na época da publicação (verificar a exigência atual); o *package id* `com.studio.mergedefense` é provisório e **não pode ser trocado depois de publicado** — decidir o definitivo antes.

### 12.1 🆕 Catálogo de áudio livre para uso comercial [M29]

Pesquisa feita em 08/10/2026. **Regra:** CC0 primeiro (uso comercial, modificação e incorporação em jogo vendido, sem crédito obrigatório). Não redistribuir os arquivos como pacote de áudio isolado; a permissão aqui é para uso como parte do jogo. Nunca NC (não comercial) nem SA (derivados com a mesma licença).

> **Limite da verificação:** as licenças abaixo foram conferidas em páginas de OpenGameArt, Godot Asset Library, itch.io e guias de terceiros; não abri cada arquivo de cada pack. Por isso a Etapa 0 exige **conferir a página oficial no dia do download e guardar uma cópia** (processo abaixo). Nomes exatos de arquivos serão escolhidos por audição.

#### A) Packs recomendados

| Pack | Autor/fonte | Licença | Uso no jogo | Onde |
|---|---|---|---|---|
| **Interface Sounds** (100 sons) | Kenney | CC0; crédito opcional | cliques, abas, popups, loja, confirmação | [Página oficial](https://kenney.nl/assets/interface-sounds) |
| **UI Audio** (50 sons) | Kenney | CC0 | botões/switches; segunda família de cliques para variar | [Página oficial](https://kenney.nl/assets/ui-audio) |
| **Impact Sounds** (130 sons) | Kenney | CC0 | acerto em inimigo, impacto de chefe, dano na base, "thud" do merge, golpes do cerco e melee | [Página oficial](https://kenney.nl/assets/impact-sounds) |
| **Music Jingles** (85 sons) | Kenney | CC0 | stingers de vitória, derrota, estrela, início de onda, novo gato desbloqueado | [Página oficial](https://kenney.nl/assets/music-jingles) |
| **RPG Audio** (50) / **Digital Audio** / **Sci-fi Sounds** | Kenney | CC0 nas páginas dos packs | candidatos a tiros/granada, passos e ataques; selecionar por audição | [RPG Audio](https://kenney.nl/assets/rpg-audio) · [Digital Audio](https://kenney.nl/assets/digital-audio) · [Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds) |
| **Short Loops Background Music Pack** (4 loops OGG) | hernandack / OpenGameArt | CC0; crédito apreciado | música opcional de menu/partida; escolher no máximo 1–2 loops após audição | [Página do pack](https://opengameart.org/content/short-loops-background-music-pack) |
| **The Essential Retro Video Game SFX Collection** (512 sons, WAV 44,1 kHz mono) | Juhani Junkala | CC0 | moedas (single/double/cluster), fanfarras (3), botões. **Estilo 8-bit:** usar só onde combinar com a arte HD (moedas e estrelas costumam funcionar) | `opengameart.org/content/512-sound-effects-8-bit-style` |
| **Tower Defense Theme** e **Tower Defense Theme 3** (loops) | DST | CC0 / domínio público | **música da fase** — o gênero do jogo | `opengameart.org/content/tower-defense-theme` · `opengameart.org/node/13660` |
| **Fantasy Game Music Tracks** (7 faixas, MP3) | kmontesdev | CC0 (conforme a página) | **menu, mapa de níveis e loja** (faixas calmas) | `kmontesdev.itch.io/7-fantasy-music-tracks` |
| **5 Chiptunes (Action)** | Juhani Junkala | CC0 | opcional: chefe/ondas finais. Chiptune pode destoar da arte — decisão 10 (seção 14) | `opengameart.org/content/5-chiptunes-action` |
| **FREE Music Loop Bundle** e variações | Tallbeard Studios | **varia por pack** (o pack Chiptune migrou para CC0 em jan/2024) | reserva de loops; só usar após conferir a página de cada pack | `tallbeard.itch.io` |

Fontes de **sons sob medida** (o que os packs não cobrem: miado, zumbi, explosão realista):
- **Freesound**, filtrando **somente CC0** (a licença é por arquivo)
- **Sonniss GDC Game Audio Bundle** — royalty-free para uso comercial, sem atribuição; os termos proíbem uso para treinar IA/ML. Ler os termos do bundle baixado

#### B) Mapeamento evento → som

Os nomes de arquivo finais ficam em `audio_manifest.json`. Para eventos frequentes, 2–3 variações + pitch ±5% (`[M22]`).

| Evento | Fonte sugerida | Observação |
|---|---|---|
| Clique de botão, abas, voltar | Kenney Interface Sounds / UI Audio | duas famílias: primário e secundário |
| Toggle som/música/vibração | Kenney UI Audio (switch) | |
| Pegar/soltar gato (drag) | Kenney Interface Sounds (snap) | volume baixo |
| Comprar gato/addon | Kenney Casino/RPG (candidato) | confirmar por audição |
| Sem saldo / ação inválida | Kenney Interface Sounds (tom de erro) | |
| Merge | Kenney Impact Sounds (thud suave) + brilho curto | |
| Merge de alto nível (C8+) | idem + stinger curto de Music Jingles | |
| Tiro reto / lento (slow) / granada | Kenney Digital ou Sci-fi (candidatos) | **limite de 4 vozes** simultâneas por som |
| Explosão da granada | Kenney Impact Sounds ou Freesound CC0 | |
| Acerto no inimigo | Kenney Impact Sounds (leve) | |
| Morte de inimigo | Kenney Impact Sounds; Freesound CC0 para o "zumbi" | |
| Cerco (golpe na base) / dano na base | Kenney Impact Sounds (pesado) | par com o flash vermelho; respeita "Reduzir efeitos" |
| Chefe aparece / enrage | Impact grave + stinger | |
| Moeda: quique e coleta | Juhani Junkala (Coins) | variações single/double |
| Início de onda / "iniciar agora" | Kenney Music Jingles | |
| Vitória / derrota / estrela | Kenney Music Jingles; Juhani Junkala (Fanfares) | estrela 1, 2 e 3 em tons crescentes |
| Miado de gato (merge, vitória) | Freesound **CC0** ou Sonniss | opcional; dá identidade |
| Música: menu / mapa / loja | kmontesdev Fantasy Tracks | loop calmo |
| Música: fase | DST Tower Defense Theme (1 e 3) | alternar entre ondas |
| Música: chefe | DST Theme 3 ou Juhani 5 Chiptunes (Action) | ver decisão 10 |

#### C) Não usar (ou só com regra)

| Fonte/licença | Motivo | Regra |
|---|---|---|
| BBC Sound Effects (RemArc) | não comercial | **proibido** |
| Qualquer CC-BY-NC / "non-commercial" | não permite jogo vendido | **proibido** |
| CC-BY-SA | derivados herdam a licença; risco real para jogo comercial | evitar |
| ZapSplat (plano gratuito) | exige crédito explícito | só se não houver CC0; crédito na tela `credits` |
| Incompetech e Soundimage.org | comercial permitido, mas com atribuição (CC BY 4.0 no Incompetech) | plano B com crédito |
| Pixabay Music/Sounds | licença própria (não CC0), comercial sem atribuição segundo guias, mas pode mudar | só se faltar CC0; guardar cópia da licença |
| Freesound sem filtro | licença por arquivo (CC0, CC-BY, NC…) | **somente CC0** |
| Sons ripados de outros jogos, filmes ou YouTube | sem direitos | **proibido** |

#### D) Processo de conformidade

1. **`audio_manifest.json`:** para cada arquivo, `file`, `source_url`, `author`, `license`, `license_url`, `downloaded_at`, `sha256`, `used_in`
2. **Prova da licença:** no dia do download, salvar a página (PDF/captura) em `docs/licenses/audio/` — as páginas mudam, e o repositório é privado (`[M02]`)
3. **Teste no CI** (seção 6): todo arquivo de áudio está no manifesto, com licença permitida (CC0 ou royalty-free comercial sem atribuição), sem órfãos e com hash correto
4. **Créditos:** CC0 não exige crédito, mas os autores e pacotes utilizados recebem crédito de cortesia na tela `credits`, junto dos grupos de assets, licença e link de origem (seção 12.2). A Kenney reserva o **logo** para projetos oficiais — não usar o logo.
5. **Formatos e orçamento:** SFX curtos em WAV ou OGG; música em OGG com loop; meta de **≤ 25 MB** de áudio (valor-semente). Os packs vêm em níveis de volume diferentes (a coleção da Juhani vem a −6 dB), então **normalizar o loudness** antes de ligar nos buses
6. **Curadoria:** cerca de 35–45 sons únicos cobrem a fase 1; escolher por audição no Etapa 6 (cenas) e fixar no manifesto

### 12.2 🆕 Tela de créditos, licenças e origem dos assets

A cena `credits` será uma tela acessível pelo menu principal e por Settings, com lista rolável e links externos acionados pelo jogador. Não exibir caminhos locais da máquina de desenvolvimento. Para cada fonte de conteúdo usada no build, mostrar:

- **Nome do asset/pacote e autor ou titular** (ex.: pack Craftpix, Kenney, Passion One/fontes, autores de música/SFX).
- **Quais assets estão incluídos** por grupo, com nomes ou identificadores suficientes para reconhecer o conteúdo (por exemplo, sprites de gatos/inimigos, interface, fonte e efeitos sonoros selecionados).
- **Licença** e resumo de atribuição exigida; link para o texto da licença quando aplicável.
- **Origem**: nome do site/loja e link direto para a página do pack ou autor. Assim o jogador consegue localizar o material original.
- Créditos obrigatórios aparecem com o texto exigido pela licença; créditos opcionais também podem aparecer, claramente como cortesia. A lista da tela é gerada a partir de `credits_manifest.json`/manifestos de assets e não digitada separadamente.

**Conteúdo mínimo:** Craftpix (packs principais, licença conforme `license.txt`, e freebies visuais usados, licença royalty-free comercial), pacotes visuais CC0 externos efetivamente usados (ex.: Kenney Particle Pack/Background Elements ou OpenGameArt Zombie; CC0 conforme a página do pack), pacotes de áudio usados, Passion One (SIL OFL), quaisquer outros áudios/fontes e o próprio jogo/equipe. Mostrar somente pacotes realmente presentes no build, sem creditar fontes avaliadas e rejeitadas. Para CC0, indicar “CC0 — uso livre, crédito não obrigatório” e manter o link de origem. Para fontes com atribuição, reproduzir a atribuição solicitada integralmente.

**Documentação offline:** incluir `CREDITS.md`/`docs/licenses.md` e cópias das licenças em `docs/licenses/`; o conteúdo deve corresponder à tela. A tela funciona sem conexão, exibe os links como texto e oferece botão para abri-los externamente. Manifesto registra pacote/arquivo, autor, licença, URL de origem, URL da licença e uso no jogo; `audio_manifest.json` permanece a fonte detalhada para áudio.

**Critérios de aceite:** todo asset de terceiros incluído no build tem entrada no manifesto e no catálogo da tela; nenhum asset sem licença verificada entra no build; todas as atribuições obrigatórias estão visíveis e completas; links abrem o destino correto; tela rolável é legível em landscape (16:9 e 20:9), localizável PT-BR/EN e acessível offline.

## 13. 🆕 Campanha e fases bônus pós-MVP [M25][M33][M35]

O MVP entrega a fase 1. O conteúdo completo planejado passa a ter **5 fases principais + 15 fases bônus = 20 fases**, usando as cinco áreas (`Area1..5`) e os novos assets gratuitos de 2.3. As fases bônus continuam sendo tower defense; os tilesets de plataforma só fornecem cenário/props e nunca alteram o percurso, a defesa da base ou a grade de torres. As fases são conteúdo pós-MVP e não bloqueiam a primeira entrega.

### 13.1 Campanha principal

- **5 fases principais**, uma por área: `Area1..5`, com chefe principal correspondente de `Boss 1..5`, dificuldade e `tier_cap` crescentes.
- Cada fase mantém o loop central: comprar/posicionar gatos-torre, mesclar, defender a base contra ondas que percorrem um caminho e derrotar um chefe.
- A história do farol e da névoa avança entre áreas; conclusão da fase 5 resolve o arco principal, com gancho opcional para futuras expansões.

| Fase | Cenário e papel narrativo | Assets gratuitos usados além do pack principal |
|---|---|---|
| **P1 — O primeiro sinal** (`Area1`) | Arredores da vila; tutorial de rota, torres, merge e primeira onda | Kenney Background Elements em props discretos; parallax CraftPix se combinar; Particle Pack em merge/tiros/recompensas |
| **P2 — Ruas interditadas** (`Area2`) | Travessia da cidade para recuperar sobreviventes | Plague Town em casas/placas/cercas; fundo horizontal em camadas; variantes de zumbi CraftPix; Particle Pack |
| **P3 — Cemitério da névoa** (`Area3`) | Descobrir a origem dos mortos e a primeira pista sobre o farol | Forbidden Graveyard + props/túmulos do Plague Town; variantes CraftPix; parallax compatível; Particle Pack |
| **P4 — Estrada da evacuação** (`Area4`) | Defender comboio/rota de suprimentos e revelar a sabotagem | Backgrounds horizontais e props Kenney aprovados; variantes CraftPix para escalada de inimigos; Particle Pack |
| **P5 — O farol** (`Area5`) | Defesa final do farol e encerramento do arco principal | Backgrounds horizontais em camadas, Kenney como decoração aprovada, todo o conjunto de VFX; inimigos CraftPix como elenco de elite |

Assets de fundo/parallax ficam atrás da rota; props da frente não podem cobrir inimigos, projéteis, hitboxes visuais, base nem slots. A composição deve preservar a leitura em landscape e seguir o orçamento de performance/mobile da seção 4.1.

### 13.2 Quinze fases bônus de tower defense

Criar **3 bônus por área (B1–B3)**, totalizando 15. Reutilizar cenário, inimigos e chefes disponíveis, mas definir composições, limites e regras próprias em `data/bonus_stages.csv`/`BonusStageData`; cada fase deve parecer um desafio distinto, não apenas repetir a campanha com HP maior.

| Variante por área | Regra de desafio (ajustada por área) | Foco estratégico |
|---|---|---|
| **B1 — Cerco** | Mais inimigos de cerco ou janelas de ataque curtas; base começa com HP reduzido | Prioridade de alvo, dano e proteção da base |
| **B2 — Reforços limitados** | Menos compras/recursos e board parcial bloqueado; ondas e chefe continuam obrigatórios | Merge eficiente e planejamento de slots |
| **B3 — Horda do chefe** | Composição temática de inimigos e chefe remixado (Boss 6/7 alternados; depois Boss 1–5), com pacing mais intenso | Sobreviver às ondas e preparar o board para o chefe |

### 13.2.1 Matriz de conteúdo das 15 fases bônus [M35]

Em cada área, B1/B2/B3 são três mapas/desafios distintos, mas todos preservam caminho, base, ondas, torres-gato, merge e chefe. Os modificadores são configurados em `bonus_stages.csv`; IDs exatos seguem `{area}_B1..B3`.

| Área / fases | B1 — Cerco | B2 — Reforços limitados | B3 — Horda do chefe |
|---|---|---|---|
| **Área 1** (`A1_B1..B3`) | Cerco leve à vila; props Kenney e partículas de impacto/base | Board reduzido em campo aberto; camadas de fundo aprovadas | Horda introdutória de CraftPix; Particle Pack em ataques e chefe |
| **Área 2** (`A2_B1..B3`) | Ruas da quarentena com Plague Town; ataques de cerco | **Feira de sobreviventes** com Free Market como decoração/fundo e slots bloqueados | Zumbis CraftPix + casal OpenGameArt (só se passar estilo); onda densa com VFX de fumaça/impacto |
| **Área 3** (`A3_B1..B3`) | Necrópole com Forbidden Graveyard e túmulos; base com HP reduzido | Ruínas/túmulos do Plague Town; recursos iniciais limitados | Horda zumbi mista CraftPix/OGA (OGA apenas pós-gate visual) + chefe remixado e Particle Pack |
| **Área 4** (`A4_B1..B3`) | Defesa da estrada de evacuação; inimigos de cerco e parallax | Board parcialmente bloqueado e ondas com pausa curta para merge | Variantes CraftPix em onda acelerada e chefe remixado; VFX com limite de partículas |
| **Área 5** (`A5_B1..B3`) | Cerco final ao farol; maior pressão sobre a base | Última reserva: recursos/slots limitados, mas rota e torres disponíveis | Horda final com todo o elenco aprovado de zumbis CraftPix e chefe; VFX de clímax |

**Uso total e rastreabilidade:** Particle Pack aparece em todas as 20 fases; Background Elements e fundos horizontais em fases principais e bônus em que passem a auditoria visual; Plague Town em P2/P3 e desafios de Área 2/3; Forbidden Graveyard em P3/A3; zumbis CraftPix desde P2 e nos desafios de horda; OpenGameArt apenas A2_B3/A3_B3 se o gate aprovar; Free Market em A2_B2. Se a auditoria excluir qualquer pacote condicional, remova-o das fases e dos créditos/manifestos — o catálogo de fases deve refletir somente assets efetivamente aprovados.

**Regras obrigatórias para cada bônus:** continua sendo tower defense com caminho, base defendida, ondas, torres-gato e merge; vitória exige derrotar todas as ondas e o chefe mantendo HP da base acima de zero. Não transformar em puzzle isolado, corrida, plataforma ou modo sem defesa de base. Pode haver restrição de recursos/slots como modificador, mas o jogador deve sempre ter decisão tática de torre/merge.

**Desbloqueio e recompensas:** liberar as três bônus de uma área após concluir sua fase principal. Recompensas únicas de primeira conclusão (moedas/gems conforme economia aprovada) e replay sem duplicar recompensa única; estrelas/medalhas registradas separadamente por `stage_id`. Não exigir pagamento ou anúncio para acessar bônus.

**Implementação data-driven:** `LevelSelect` lista campanha e bônus; cada fase é um `WaveData`/`BonusStageData` referenciado por ID, com área, chefe, seed/configuração de ondas, slots disponíveis, recursos iniciais, `tier_cap`, modificadores, unlock e recompensa. O save versionado mantém progresso por `stage_id`. Validar IDs/assets e testar que toda bônus tem caminho, base, pelo menos uma onda e chefe.

### 13.3 Outros itens pós-MVP

1. Modo infinito de tower defense, usando a mesma `SimWorld` + ranking local.
2. Json Atlas se o gate de performance do slice indicar ganho.
3. Monetização/ads apenas se decidido (ativar `FeatureFlags.ads_enabled` e `OrangeBTNAds`).
4. Telemetria local opcional — somente com consentimento e fora do escopo atual

## 14. 🆕 Decisões abertas para aprovação

Itens onde o plano agora traz uma **recomendação**, mas o ajuste muda escopo/regra de jogo e precisa do seu OK:

| # | Decisão | Recomendação |
|---|---|---|
| 1 | Como tratar C13–C15 (inalcançáveis com 12 slots) | `tier_cap` por fase + nível de compra + slots extras (5.1); cadeia completa implementada e testada |
| 2 | Moedas: uma conta ou duas (partida × cofre) | Duas contas (5.2) |
| 3 | Upgrade por gato (`Uplogo1..15`) ou global (A8 original) | Por gato, confirmando na inspeção visual |
| 4 | Licença CraftPix | Freebie comercial confirmado; manter snapshots da página do produto e de https://craftpix.net/file-licenses/, não expor fontes extraíveis |
| 5 | Orientação/layout mobile | Landscape (celular deitado) obrigatório; board 4×3 no painel esquerdo, rota/base no painel direito e controles nas faixas seguras; testar 16:9 e 20:9 |
| 6 | Mecânica do inimigo "suporte" (Reg 7–8) | Aura de velocidade ou cura em pulso |
| 7 | `OrangeBTNAds` | Oculto por feature flag |
| 8 | Venda de gato | Zona "Vender" explícita + desfazer 3 s (em vez de "arrastar para fora do board") |
| 9 | Meta de APK | ≤ 150 MB (teto de aceitação 200 MB) |
| 10 | Direção musical (`[M29]`) | Menu/loja calmos (kmontesdev, CC0) + fase com DST Tower Defense Theme (CC0); chiptune de Juhani Junkala só no chefe, ou sem chiptune se destoar da arte HD |




