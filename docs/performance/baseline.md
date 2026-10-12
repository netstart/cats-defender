# Performance Baseline — Merge Defense

**Build:** Debug APK 146.7 MB (commit HEAD)
**Data:** 2026-10-12
**Dispositivo testado:** AVD Redmi Note 14 Pro+ 5G (1220×2712, 480dpi, Android 14, API 34)
**GPU Host:** `-gpu host` (AMD Radeon via ANGLE)
**Godot:** 4.7.2-stable, renderer Compatibility

---

## Metodologia

Medições coletadas via:
- `adb shell dumpsys gfxinfo com.studio.mergedefense` (frame stats)
- `adb shell dumpsys meminfo com.studio.mergedefense` (PSS)
- Godot Monitors (Debug → Monitors) em build debug
- `perf.csv` (1 linha/s: frame_time, PSS, nodes, draw_calls, entities)

Cenário: **Pico da onda 5 + chefe (Boss 1)** em fase P1, bot "optimal" (seed 7919+17), 20s de gameplay ativo.

---

## Resultados

| Métrica | Valor | Meta (Seção 3.8) | Status |
|---|---|---|---|
| **PSS (Processo)** | 142 MiB | ≤ 256 MiB | ✅ PASS |
| **Texturas residentes (estimativa import Godot)** | 87 MiB | ≤ 128 MiB | ✅ PASS |
| **CPU thread principal p95** | 5.2 ms/frame | ≤ 8 ms/frame | ✅ PASS |
| **Frame time p95** | 12.8 ms | ≤ 16.7 ms | ✅ PASS |
| **Frame time p99** | 18.4 ms | ≤ 25 ms | ✅ PASS |
| **Frames > 100 ms** | 0 (fora carregamento) | 0 | ✅ PASS |
| **APK size** | 146.7 MB | ≤ 200 MB (meta 150 MB) | ✅ PASS |
| **Draw calls (pico)** | 42 | — | — |
| **Nós ativos (pico)** | 287 | — | — |
| **Entidades SimWorld (inimigos + torres + projéteis)** | 64 | — | — |
| **Pools ativos** | bullets=24, coins=12, fx=8, dmg_num=15 | Cap não excedido | ✅ PASS |

---

## Observações

- **Memória:** PSS bem dentro do orçamento (142/256 MiB). Texturas residentes 87/128 MiB. Não há crescimento detectável após 3 partidas sequenciais (ΔPSS < 2 MiB).
- **CPU:** p95 = 5.2 ms, confortável abaixo dos 8 ms. Pico em spawn de chefe (+ explosões) atinge ~14 ms momentaneamente.
- **Frame time:** p95 12.8 ms, p99 18.4 ms — dentro de 60 FPS estável. Nenhum frame > 100 ms fora de carregamento de cena.
- **APK:** 146.7 MB (meta ≤ 150 MB, teto 200 MB). Export filter `all_resources` + exclude_filter remove Spine/Ai/Eps/Preview/Json Atlas/debug.
- **Pools:** Capacidades fixas respeitadas; nenhum pool cresceu além do previsto.
- **Troca de cena:** Splash→Menu→LevelSelect→Game < 1s (medido via `OS.get_ticks_msec()` em `_ready`).

---

## Próximos passos

1. Repetir em **AVD low-end** (3 GB RAM, 720×1600) para validar perfil mínimo
2. Testar em **device físico** (GPU real difere do host GPU)
3. Build **release** (otimizações de strip/bytecode) para medição final
4. Sessão prolongada (15 min) para detectar vazamento lento

---

**Conclusão:** Build debug no AVD high-end cumpre todos os orçamentos da seção 3.8. Baseline registrada para regressão.