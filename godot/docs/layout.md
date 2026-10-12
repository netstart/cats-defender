# Layout landscape (3.0, M05)

Canvas de referência: **1200×540**, `stretch=canvas_items`, `aspect=keep`, orientação
`sensor_landscape` (aceita os dois lados; portrait desligado).

```
┌──────────────────────────────────────────────────────────────┐
│ HUD (y 0..56):  moedas · gems · onda · prep timer · pausa     │
├──────────────────────────────┬───────────────────────────────┤
│ BOARD (x 0..480)             │ ROTA (x 480..1180, lane y≈315)│
│  grade 4×3, slot 112×110     │ inimigos: x = 480 + p·700     │
│                              │ base: x ≈ 1140 (barras 0..5)  │
├──────────────────────────────┴───────────────────────────────┤
│ AÇÃO (y 478..536): comprar · guardian/boxing · 1×/2× · onda   │
└──────────────────────────────────────────────────────────────┘
```

- Zona "Vender": painel temporário no canto superior direito do board durante drag (3.2).
- Alvos de toque ≥ 48 dp (botões de ação têm 56 px de altura no canvas de 540 px de altura;
  a 480 dpi 1 dp ≈ 3 px no canvas de 540→2712 px aprox. ×5; dentro do mínimo).
- Safe area: embarcado pelo stretch `keep` (barras laterais em 20:9) — sem controles nas
  margens de 24 dp das bordas (gesture navigation).
- Aspect ratios alvo: 16:9 (2.39 em 1220×2712) validado em AVD; safe areas respeitadas.
- Números canônicos em `scripts/game/game.gd` (constantes `BOARD_*`, `ROUTE_*`).
