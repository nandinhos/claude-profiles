# VERSIONS — referências pinadas (lockfile manual)

Registro das versões/commits known-good que o `setup.sh` monta. Bump é **deliberado**:
edite aqui + no ponto indicado, rode `./setup.sh && ./verify.sh`.

> **Por que manual:** `claude plugin install <p>@<marketplace>` puxa o **HEAD** do
> marketplace — não há sintaxe de pin nativa. Este arquivo é a fonte da verdade do
> "o que era conhecido-bom"; para travar de fato um marketplace, dê `git -C <cache>
> checkout <commit>` no cache do profile antes do install (ver "Como travar" abaixo).

## Pinado

| Componente | Versão / commit | Onde bumpar | Fonte |
|---|---|---|---|
| **Playwright MCP** | `0.0.77` | `PLAYWRIGHT_MCP_VERSION` em `setup.sh` | `npm view @playwright/mcp version` |
| **mwguerra-marketplace** | `965b237` | HEAD do marketplace (ver "Como travar") | `mwguerra/claude-code-plugins` |
| **mwguerra-plugins** (Filament v5) | `7bab128` | idem | `mwguerra/plugins` |
| **ponytail** | `c4d1925` | idem | `DietrichGebert/ponytail` |
| **DEVORQ CLI** | `v4.1.0` (HEAD `182cc93`) de `~/projects/devorq` | `git pull` no repo | `nandinhos/devorq` |

> Data do snapshot: 2026-07-15. (Repo renomeado `devorq_v3` → `devorq`; profile re-sincronizado de v3.8.5 para v4.1.0.)

## Como travar um marketplace num commit (opcional)

Cache dos marketplaces: `~/.claude-profiles/<profile>/plugins/marketplaces/<nome>/`.

```bash
P=~/.claude-profiles/mwguerra-tall/plugins/marketplaces
git -C "$P/mwguerra-plugins" checkout 7bab128    # trava antes do install
```

## Como bumpar deliberadamente

1. **Playwright:** `npm view @playwright/mcp version` → atualize `PLAYWRIGHT_MCP_VERSION`
   em `setup.sh` e a tabela acima.
2. **Marketplace:** `git -C <cache> pull` → anote o novo `rev-parse --short HEAD` aqui.
3. Rode `./setup.sh && ./verify.sh --deep` e valide.
