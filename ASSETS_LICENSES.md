# Licenças de Assets — Cats Defender

## Assets gerados proceduralmente (CC0 — domínio público)
Gerados por `tools/build_atlas.py`, `tools/build_fx.py` e `tools/build_audio.py`
(Pillow + síntese de ondas). São originais do projeto e licenciados CC0:

- `assets/art/atlases/*.png` + `atlas_index.json` — sprites de gatos (15), inimigos (8),
  Cat Guardian (boss) e CatBoxing, gerados proceduralmente.
- `assets/art/sprites/bullets/*.png`, `assets/art/fx/*.png`, `assets/art/ui/icons/*.png`.
- `assets/audio/sfx/*.wav`, `assets/audio/music/*.wav` — síntese procedural.

## Assets planejados (pack craftpix-ne "Merge Cats Defender")
O plano de produção prevê o pack pago **"Merge Cats Defender" (craftpix.ne)**:
15 gatos, Cat Guardian, CatBoxing, 8+ inimigos, cenário, balas, explosões e UI.
Ao adquirir o pack: colocar frames em `assets/art/raw/<personagem>/<anim>/` e rodar
`python tools/build_atlas.py` — os atlases reais substituem os placeholders sem
mudança de código. Licença comercial CraftPix (registrar o comprovante aqui).

## Fontes de assets externos gratuitos (a integrar quando necessário)
- **Kenney.nl** — "game-icons", "UI Pack", "particle pack" — **CC0**.
- **Freesound.org / Pixabay** — SFX adicionais — **CC0** (verificar licença por arquivo).
- **incompetech (Kevin MacLeod)** — músicas — **CC-BY 4.0** (atribuição obrigatória).
- **Luckiest Guy (Google Fonts)** — fonte cartoon — **Apache License 2.0**.

## Código
MIT — ver `LICENSE`.
