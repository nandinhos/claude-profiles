# Harness: claude-devorq (DEVORQ — metodologia/disciplina)

Profile isolado para desenvolvimento com a metodologia **DEVORQ** (gates G0→G7,
scope-guard anti-over-engineering, captura de lições, handoffs entre sessões, disciplina
Karpathy). A CLI `devorq` está no PATH (compartilhada por todos os profiles). As 9 skills
DEVORQ estão neste profile.

## Por-projeto (OBRIGATÓRIO antes de usar num repo)
Rode no repo alvo:
- `devorq rules bootstrap` — instala o git `commit-msg` hook (valida o formato e bane
  Co-Authored-By) + aplica as regras essenciais.
- `devorq init` — inicializa o estado `.devorq/` do projeto.

## Commits
Formato **no-espaço** `tipo(escopo): descrição` (ex.: `feat(core): adiciona X`), em pt-BR,
**sem Co-Authored-By** (já desativado via `includeCoAuthoredBy=false` no settings deste
profile). As regras DEVORQ abaixo são a fonte da verdade.

---

