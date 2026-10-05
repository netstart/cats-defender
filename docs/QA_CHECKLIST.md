# QA Checklist — Cats Defender (device Android)

## Performance
- [ ] FPS ≥ 50 com 30 inimigos ativos (modo merge, fase 20+)
- [ ] Zero alocação por frame no loop quente (projéteis/dano via pool)
- [ ] Sem crash após 20 min de jogo contínuo (leak de nós)

## Telas e input
- [ ] Conteúdo legível com notch (safe margins)
- [ ] Pausa ao receber ligação (tree.paused) e retomada correta
- [ ] Rotação travada em landscape
- [ ] Drag & drop de merge funciona com toque (multitouch ignorado fora do slot)

## Áudio e haptics
- [ ] Música de batalha/menu com duck em pause
- [ ] Volumes Master/Music/SFX persistem entre sessões
- [ ] Vibração leve em kill/merge (Android Vibrate)

## Fluxo
- [ ] 30 fases merge completáveis com save/estrelas persistentes
- [ ] 10 fases TD desbloqueadas após fase 5 do merge
- [ ] Transições com fade + dicas de loading
- [ ] Game over → retry / menu funcionais
