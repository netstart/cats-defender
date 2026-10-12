# Merge Defense — O Último Refúgio

Clone de *Plants vs. Zombies* com gatos (Merge Defense), feito em **Godot 4.7.2** para Android,
usando o pack [Craftpix Free Cartoon Cat Defense Game Asset Kit](https://craftpix.net/freebies/free-cartoon-cat-defense-game-asset-kit/).

## Como testar localmente (Godot)

```powershell
powershell -File tools\run_godot.ps1
```

Abre o jogo na janela do Godot (o executável portátil já está em `godot-bin/`).
Para abrir no **editor** do Godot: executar `godot-bin\Godot_v4.7.2-stable_win64.exe` e importar a pasta `godot/`.

## Como testar no emulador Android

```powershell
powershell -File tools\run_android.ps1        # inicia o AVD e instala/mostra o jogo
powershell -File tools\run_android.ps1 -Build # compila o APK antes
```

O AVD **Redmi_Note_14_Pro_Plus_5G** (1220x2712, 480dpi, Android 14) é criado por
`tools\setup_emulator.ps1`. `tools\build_install_play.ps1` executa o fluxo completo
(validar assets → testes → build → emulador → instalar → abrir), com `-Verify` para
logcat + screenshot. APK debug fica em `build/merge-defense-debug.apk`.

## Controles (telas no celular deitado / landscape)

- **Comprar Gato**: toque em "Comprar Gato" (custo cresce a cada compra da partida).
- **Posicionar/merge**: pressione e arraste um gato para outro slot.
  Soltar em slot vazio = mover; em gato do **mesmo nível** = merge; nível diferente = troca.
  Arraste até a zona **VENDER** para vender (desfazer em 3 s).
- **Toque rápido em um gato**: alterna o alvo (first/last/strongest/closest); **toque longo** abre info (dano/alcance/DPS).
- **Guardian/Boxing**: unidades melee na frente da base (desbloqueáveis na oficina).
- **Ondas**: cada onda tem pausa de preparação; **"Iniciar Onda!"** antecipa e paga bônus.
- **1×/2×**: velocidade da simulação. Botão de engrenagem: pausa/settings.

## Estrutura

- `godot/` — projeto Godot (cenas, scripts, dados, assets)
- `godot-bin/` — Godot 4.7.2 portátil (execute `run_godot.ps1`)
- `tools/` — scripts de build/teste/emulador
- `reports/` — relatórios (balance, logcat, screenshots)
- `docs/` — QA, licenças, narrativa, toolchain

## Testes e CI

```powershell
powershell -File tools\run_checks.ps1
```

Suíte headless: `godot --headless --path godot -s res://tests/run_tests.gd`
Balanceamento: `godot --headless --path godot -s res://scripts/balance_sim.gd -- --stage P1 --seeds 30`

## Conteúdo

5 fases principais (P1–P5) + 15 fases bônus (A{1..5}_B{1..3}) — 20 estágios,
todos tower defense com caminho, base, ondas, merge e chefe.
