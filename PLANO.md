# PLANO — 3 Profiles isolados do Claude Code (DEVORQ · MWGuerra · Ponytail)

> ⏳ **Documento histórico congelado (2026-06-29).** Registra o plano e as decisões da
> montagem inicial. Detalhes operacionais podem ter evoluído — a **fonte viva** é o
> [`README.md`](README.md) + o próprio `setup.sh`/`aliases.zsh`. Não edite para "atualizar";
> só para corrigir fatos históricos.

> Continuação do [`HANDOFF.md`](HANDOFF.md). O handoff provou o **mecanismo**
> (`CLAUDE_CONFIG_DIR` + aliases). Este documento define **o conteúdo de cada
> profile** a partir da análise profunda das 3 fontes + verificação empírica
> adicional + crítica adversarial.

- **Data:** 2026-06-29
- **Método:** workflow multiagente (1 análise por fonte + verificador empírico do
  mecanismo + síntese + crítica adversarial refute-first).
- **Status:** ✅ **EXECUTADO em 2026-06-29** — os 3 profiles foram montados e validados
  (ver seção 0). `setup.sh` idempotente confirmado (2ª execução: zero duplicação).

---

## 0. ✅ Execução realizada (2026-06-29)

Artefatos criados em `~/projects/claude-profiles/`: `setup.sh` (idempotente), `aliases.zsh`,
`templates/{settings.base.json, devorq-header.CLAUDE.md, claude-tall.CLAUDE.md,
ponytail.CLAUDE.md}`. `~/.zshrc` agora faz `source aliases.zsh`.

| Profile | Dir | Tamanho | Conteúdo | Smoke validado |
|---|---|---|---|---|
| `claude-devorq` | `~/.claude-profiles/devorq` | 504K | 9 skills DEVORQ (cópia) · CLAUDE.md (header+`rules export`) · `includeCoAuthoredBy=false` | discovery: Claude **lista as 9 skills** ✓ · commit-msg hook: Co-Authored-By **banido**, `[feat] (x):` rejeitado, `feat(core):` **passa** |
| `claude-tall` | `~/.claude-profiles/mwguerra-tall` | 12M | 7 plugins (test-specialist, code, reverb-specialist, docs-specialist, error-memory, docker-specialist, **laravel=Filament v5**) · Playwright MCP (user-scope) | `plugin list`=7 ✓ · `mcp list` playwright ✓ Connected |
| `claude-lazy` | `~/.claude-profiles/ponytail` | 5.5M | plugin ponytail (6 skills + 6 cmds + 3 hooks) · CLAUDE.md mínimo | boot headless → flag `.ponytail-active`=`full` criado (hook always-on **OK**) |

**Isolamento confirmado:** o `~/.claude` real ficou intocado (manteve seus 14 plugins; `ponytail@ponytail` ausente lá).
**Uso:** abrir novo terminal (ou `source ~/.zshrc`) e rodar `claude-devorq` / `claude-tall` / `claude-lazy` de qualquer projeto.

> As seções 1–10 abaixo são o plano/decisões que guiaram a execução (mantidas como referência).

---

## 1. Resumo executivo — os 3 profiles

| Profile (alias) | Config dir | Fonte | Natureza | O que é |
|---|---|---|---|---|
| **`claude-devorq`** | `~/.claude-profiles/devorq` | DEVORQ v3.8.5 (`nandinhos/devorq_v3`) | CLI bash no PATH **+** 9 skills | Harness de **metodologia/disciplina**: gates G0→G7, scope-guard, lições, handoffs, disciplina Karpathy |
| **`claude-tall`** | `~/.claude-profiles/mwguerra-tall` | `mwguerra/claude-code-plugins` (marketplace) | Plugins nativos do Claude Code | Harness de **stack Laravel/TALL**: especialistas Filament/Pest/Reverb/Docker com docs embutidas |
| **`claude-lazy`** | `~/.claude-profiles/ponytail` | `DietrichGebert/ponytail` (plugin) | Plugin + hooks always-on | Harness de **comportamento**: código mínimo, anti-over-engineering, escada de 7 degraus |

> **As três fontes têm naturezas DIFERENTES** — esse é o ponto central que muda a
> montagem de cada profile:
> - **DEVORQ** não é plugin do Claude Code. É uma **CLI bash** (fica no PATH, *fora*
>   do config dir) + **skills** (SKILL.md) que o agente carrega. Estado por-projeto
>   via `devorq init`.
> - **MWGuerra** é um **marketplace de plugins** nativo: `marketplace add` + `plugin
>   install` gravam **dentro** do config dir.
> - **Ponytail** é um **plugin com hooks always-on** que injetam a ruleset a cada
>   sessão; instala via `/plugin`, também **dentro** do config dir.

---

## 2. Mecanismo — confirmado empiricamente nesta máquina

Claude Code **2.1.195**; binário em `~/.local/share/claude/versions/` (**global**,
compartilhado por todos os profiles — auto-update vale para todos; só a config diverge).

- ✅ **`CLAUDE_CONFIG_DIR` isola tudo** (34 ocorrências no binário; testado em dir vazio →
  `claude mcp list` retornou "No MCP servers configured"). Realoca **`~/.claude/` E o
  `~/.claude.json`** (que normalmente vive no HOME). Isolamento total.
- ✅ **Instalar plugins por-profile é isolado** (dir vazio → "No marketplaces / No
  plugins"). Plugins persistem em `$CLAUDE_CONFIG_DIR/plugins/{marketplaces,cache}/`.
- ✅ **Instalação non-interactive FUNCIONA (testado neste plano):** num shell **sem TTY**,
  `CLAUDE_CONFIG_DIR=/tmp/probe claude plugin marketplace add DietrichGebert/ponytail` +
  `claude plugin install ponytail@ponytail` completaram **sem prompt** ("✔ Successfully
  added/installed"), gravando `extraKnownMarketplaces` + `enabledPlugins` no
  `settings.json` do probe e `known_marketplaces.json` runtime. O `~/.claude` real ficou
  intocado (0 ocorrências). → **O `setup.sh` pode usar o caminho imperativo direto.**
- 🔑 **Instalação é DESACOPLADA da habilitação:** os arquivos do plugin ficam em
  `plugins/`; o liga/desliga fica em `settings.json → enabledPlugins`; o registro de
  marketplaces extra fica em `settings.json → extraKnownMarketplaces` (e/ou
  `plugins/known_marketplaces.json` runtime). **Não existe** `plugins/config.json`.
- ✅ **Forma do alias = PREFIXO, não `export`** (correção do advisor): use
  `CLAUDE_CONFIG_DIR=... claude`. A atribuição-prefixo entra **só no ambiente do `claude`**
  (e os filhos — hooks/MCP/plugins — herdam dele), o que satisfaz a constraint do binário
  "subprocess CLAUDE_CONFIG_DIR matches the parent" (claude→filhos). Usar `export
  CLAUDE_CONFIG_DIR=...; claude` num alias seria **bug**: o `export` vazaria a var para o
  shell interativo *depois* que o claude sai, e o próximo `claude` simples usaria o profile
  errado em silêncio. (Se algum dia precisar da var visível ao shell: `'(export ...; exec claude)'`.)
- **MCP vem de 4 fontes:** (1) user-scope em `~/.claude.json → mcpServers` — **isolado**
  por profile (começa vazio: stitch/context7 globais somem); (2) project-scope
  `.mcp.json` **no repo** — **compartilhado** entre profiles (o `laravel-boost` por-repo
  vem daqui), mas pede *trust* 1× por profile; (3) MCP embutido em plugin — segue a
  habilitação; (4) `--mcp-config`/`--strict-mcp-config`. **Playwright MCP não é embutido**
  em nenhum plugin do mwguerra.
- **Auth isolada:** `.credentials.json` vive dentro do config dir → cada profile novo
  pede `claude login` (ou copiar o arquivo). MCP com OAuth (ClickUp, MWGuerra Blog,
  stitch) re-logam por profile.

---

## 3. Arquitetura comum aos 3 profiles

**Estratégia A1 (instalação isolada por-profile).** Os 437M de `plugins/` do `~/.claude`
atual são de OUTRAS suítes (maestro/scribe/claude-mem/superpowers) que **nenhum** destes 3
profiles instala. Footprint real estimado dos 3: **~25–30M** (devorq ~0 com symlinks;
mwguerra ~8.5M + docs Filament 2.4M; ponytail 3.3M). A2 (store compartilhado via symlink)
não compensa nessa escala — descartada.

**Base-esqueleto curada (NÃO `cp -r` cego).** Cada profile parte de uma base leve. Pontos
críticos vindos da crítica adversarial:
- **`settings.json` vem de um TEMPLATE versionado no repo** (já despido), **não** derivado
  do `~/.claude/settings.json` vivo — senão o setup não é reprodutível em máquina limpa.
  O template mantém `model=opus[1m]`, `effortLevel=xhigh`, `language=Português`,
  `defaultMode`, `theme` e um subconjunto curado de `permissions`. **Remove**:
  `enabledPlugins{14}`, `extraKnownMarketplaces`, o **hook `context-mode-cache-heal.mjs`**
  (aponta para caminhos externos `opencode` e falha em todo launch sem context-mode) **e o
  `statusLine` elaborado** (aponta para script externo que pode não existir no profile).
- **`CLAUDE.md` por-profile** (cada profile escreve o seu; o global mistura mandato
  DEVORQ + commit com-espaço + Laravel-Boost, que conflitam entre profiles).
- **`skills/` só da própria fonte** (isolamento por-fonte é o objetivo).
- **Nunca copiar** `projects/`, `cache/`, `plugins/` pesados, `sessions/`.
- **`.credentials.json`** copiado (evita relogar) — *não* versionado no repo (segredo).

**Fora do config dir (nível SO, no `~/.zshrc`, compartilhado por todos):** clone do
`devorq_v3` + `PATH`; binários no PATH (`php/composer/pest/pint`, `sqlite3`, `jq`,
`node` v22.22.1 via nvm — herdado pelo alias em zsh interativo —, `gh`, `bun/python3` se
necessário).

---

## 4. Os 3 profiles em detalhe

### 4.1. `claude-devorq` — metodologia/disciplina
- **Alias (forma atual):** carrega o `.env` do HUB num subshell (`set -a; . .env; set +a`)
  e faz `exec claude` com `CLAUDE_CONFIG_DIR` — as vars não vazam pro shell interativo.
  Ver `aliases.zsh` (evoluiu do `CLAUDE_CONFIG_DIR=... claude` simples no commit c5c97ac).
- **Conteúdo:**
  - `skills/` → **cópia** das 9 skills de `~/projects/devorq_v3/skills/*` (ddd-deep-domain,
    scope-guard, grill-with-docs, env-context, project-foundation, devorq-mode,
    devorq-auto, devorq-code-review, security-hardening). **Default = cópia** (robusto,
    ~470KB), com re-sync no `git pull` da CLI. **Symlink** é otimização opcional (zero
    duplicação) a validar no TUI — não há subcomando headless para listar skills e
    confirmar que a descoberta segue symlink (`claude --help` só expõe `/skill-name` e
    `--disable-slash-commands`), então não arriscamos o symlink como default.
  - `CLAUDE.md` → gerado por `devorq rules export claude` (disciplina Karpathy +
    convenção de commit no-espaço `tipo(escopo):` + proibição de Co-Authored-By).
  - `settings.json` → template base + `includeCoAuthoredBy=false` (chave confirmada no
    binário) + permissions para `devorq *`, `git *`, `jq`, `python3`.
  - **Sem** plugins, agents nem MCP por padrão (context7 opcional).
- **Fora do config dir (1× na máquina):** `git clone https://github.com/nandinhos/devorq_v3 ~/projects/devorq_v3`
  + `export PATH="$HOME/projects/devorq_v3/bin:$PATH"`. A CLI exige o repo inteiro
  (lib/+skills/+scripts/) e é a mesma para todos os profiles.
- **Por-projeto (documentar no CLAUDE.md):** rodar `devorq init` em cada repo alvo (cria
  `.devorq/` + o git `commit-msg` hook). *Não* é responsabilidade do config dir.
- **Correção da crítica (furo #1):** **NÃO** usar `devorq rules export claude > CLAUDE.md`.
  A função `export_claude` (lib/rules.sh) **não escreve em stdout** — grava em
  `${PWD}/CLAUDE.md` e ecoa só `[OK] Export claude: ...`. O redirect produziria um
  CLAUDE.md com a linha de status apenas. **Correto:** `cd ~/.claude-profiles/devorq && ~/projects/devorq_v3/bin/devorq rules export claude` (ele cria `./CLAUDE.md` ali).
- **Simplificação da crítica:** o "override de commit" elaborado é **redundante** — o
  profile não herda o CLAUDE.md global, e o próprio `commit-convention.md` exportado já
  traz o formato no-espaço + "sem Co-Authored-By". Basta o export + `includeCoAuthoredBy=false`.
- **Validação:** skills devorq aparecem e **nenhuma outra**; `devorq --version`→3.8.5;
  num repo de teste, commit com Co-Authored-By é **banido** pelo hook e `feat(core): x` passa.

### 4.2. `claude-tall` — stack Laravel/TALL (mwguerra)
- **Alias:** `alias claude-tall='CLAUDE_CONFIG_DIR=$HOME/.claude-profiles/mwguerra-tall claude'`
- **Filament = v5 (DECIDIDO):** o `filament-specialist` do mwguerra (**v4**) fica **FORA**.
  O Filament v5 é coberto pela sua skill `laravel:filament-conventions` (copiada para
  `skills/` deste profile) **+ laravel-boost MCP** (docs v5 por-projeto via `.mcp.json` do
  repo). Isso atende os 5 projetos v5 e evita guidance v4 errada.
- **Subconjunto de plugins (núcleo TALL):** `test-specialist` (Pest — inclui
  `/test:filament`), `reverb-specialist`, `code`, `e2e-test-specialist`,
  `docker-specialist`. **Genéricos úteis:** `docs-specialist`, `error-memory`.
  - **Subconjunto MÍNIMO para começar:** test-specialist + code + reverb-specialist +
    docs-specialist + error-memory (Filament via skill v5 + boost, não via plugin).
  - **Excluir** (pessoais/conteúdo, hooks pesados ou exigem `bun`): article-writer,
    post-development, board, secretary, obsidian-vault → eventual 4º profile "pessoal".
  - **Condicionais:** `laravel-package-developer` só se publicar pacotes (traz hook que
    roda **Pint em cada Write/Edit**) — **e está com o `source` quebrado no
    marketplace.json** (aponta para pasta inexistente; correção da crítica #4: o problema
    é *source path*, não nome — manter fora por ora); `docker-local` só se usar o CLI dele.
- **MCP:** declarar **Playwright MCP** no profile (`code`, `e2e-test-specialist`
  dependem) + context7 opcional.
- **`CLAUDE.md`:** específico TALL (o CLAUDE.md do repo mwguerra **não** é auto-aplicado;
  copiar manualmente as convenções desejadas: planejar antes, criar arquivos via Artisan,
  testes verdes antes do commit).
- **Binários no PATH:** php/composer/pint, sqlite3, jq; python3 só se incluir
  e2e/laravel-package.
- **Simplificação da crítica:** a "colisão taskmanager/prd-builder vs maestro" é
  **espúria** aqui — a base é despida e o profile instala **só** mwguerra; a suíte maestro
  vive na base global, que **não** é herdada. Removido das decisões.
- **Validação:** `claude plugin list` mostra exatamente o subconjunto; comandos
  `/filament:resource`, `/test:generate-pest-test` aparecem; `claude mcp list` mostra
  playwright; o hook de Pint **não** está ativo (laravel-package fora).

### 4.3. `claude-lazy` — código mínimo (ponytail)
- **Alias:** `alias claude-lazy='CLAUDE_CONFIG_DIR=$HOME/.claude-profiles/ponytail PONYTAIL_DEFAULT_MODE=full claude'` (duas atribuições-prefixo, ambas herdadas pelo `claude`)
- **Conteúdo:** plugin `ponytail@ponytail` (6 skills + 6 comandos `/ponytail*` + 3 hooks:
  SessionStart injeta a SKILL.md filtrada por modo e escreve o flag
  `$CLAUDE_CONFIG_DIR/.ponytail-active`; SubagentStart reinjeta em cada subagente Task;
  UserPromptSubmit = mode-tracker). Instalado via `/plugin`, **dentro** do config dir.
- **NÃO copiar `skills/` à mão** (perde os hooks always-on, que são o produto). **NÃO**
  usar `npm install` (caminho OpenCode) nem o `ponytail-mcp` (desnecessário no Claude Code).
- **Modo default SÓ via `PONYTAIL_DEFAULT_MODE` no alias** — **nunca** via
  `~/.config/ponytail/config.json` (XDG **global**, vaza entre todos os profiles).
- **`CLAUDE.md` MÍNIMO:** **não** repetir a escada de 7 degraus (o SessionStart já injeta
  a SKILL.md toda sessão — duplicar seria o próprio over-engineering que o ponytail
  proíbe). Conter só: identidade do profile; nota de modo default; regra de conflito
  (ponytail manda em "como construir"; vence TDD/DEVORQ **neste** profile); contexto de
  stack (TALL / Python-Streamlit / WSL2); 3–4 linhas "nativo-primeiro" para PHP/Laravel
  (lacuna do `platform-native.md`, que não cobre PHP).
- **Validação:** após SessionStart, o flag `.ponytail-active` é criado (prova que o hook
  disparou via node; se não, fallback: semear CLAUDE.md com a ruleset do AGENTS.md);
  `/ponytail` reporta `full`; mexer no modo aqui **não** afeta outros profiles.
- **Nota da crítica:** os hooks têm `; exit 0` → falha de node é engolida em silêncio. A
  **única** prova de funcionamento é o flag `.ponytail-active`.

---

## 5. Artefatos a versionar em `~/projects/claude-profiles`

1. **`setup.sh`** — idempotente, A1. Funções: `emit_base <nome>` (cria dir; copia
   `.credentials.json` se faltar; **gera settings.json a partir do template versionado** +
   merge por-profile via `jq`); `setup_devorq` (clone/pull devorq_v3; **copia** as 9 skills com re-sync;
   `cd profile && devorq rules export claude`; `includeCoAuthoredBy=false`); `setup_mwguerra`
   (marketplace add + loop de install do subconjunto + Playwright MCP + CLAUDE.md TALL);
   `setup_ponytail` (marketplace add + install + CLAUDE.md mínimo). **Cada operação
   guardada** (dir existe? marketplace registrado? plugin instalado? skill em dia?) →
   rodar 2× não duplica. As chamadas usam o **prefixo** `CLAUDE_CONFIG_DIR=$PROFILES_DIR/<nome> claude plugin ...` (verificado non-interactive).
2. **`aliases.zsh`** — os 3 aliases na **forma-prefixo** (`CLAUDE_CONFIG_DIR=... claude`; o
   lazy acrescenta `PONYTAIL_DEFAULT_MODE=full` como 2ª atribuição-prefixo) + o `export
   PATH` do devorq_v3/bin (esse `export` é correto — var de shell, não de profile).
   `~/.zshrc` faz `source ~/projects/claude-profiles/aliases.zsh`.
3. **`templates/`** — `settings.base.json` (já despido, **versionado** — correção #3),
   `claude-tall.CLAUDE.md`, `ponytail.CLAUDE.md`, `devorq-commit-override.md` (se decidir
   manter o reforço). **`lib/merge-settings.jq`** para os merges por-profile.

**Reprodutibilidade:** clonar este repo noutra máquina + `./setup.sh` + `source aliases.zsh`
recria os 3 profiles. `.credentials.json` não versionado (1º `claude` pode pedir login).

---

## 6. Correções aplicadas (da crítica adversarial — veredito: *sólido-com-ressalvas*)

| # | Furo encontrado | Correção aplicada |
|---|---|---|
| 1 | `devorq rules export claude >` grava só a linha de status (export escreve em `PWD/CLAUDE.md`) | `cd profile && devorq rules export claude` (sem redirect) |
| 2 | Install non-interactive de plugins não testado (era load-bearing) | ✅ **RESOLVIDO neste plano** — probe isolado confirmou que `marketplace add` + `plugin install` rodam **sem prompt** sem TTY. `setup.sh` usa caminho imperativo; fallback declarativo (`extraKnownMarketplaces`+`enabledPlugins`) fica como backup |
| 3 | `emit_base` derivava do `~/.claude/settings.json` vivo → não reprodutível | **Versionar `settings.base.json` template**; jq só para merge por-profile |
| 4 | `laravel-package-developer`: diagnóstico errado ("nome divergente") | É **source path quebrado** no marketplace.json; manter o plugin fora (já era opcional) |
| — | Override de commit redundante (profile não herda global) | Simplificado: export + `includeCoAuthoredBy=false` bastam |
| — | Colisão taskmanager/prd-builder espúria | Removida (base despida + só mwguerra) |
| — | Sobreposição conceitual devorq×lazy | Assumida: ambos são "como construir"; `claude-tall` é o ortogonal claro |

---

## 7. Riscos principais
- ~~Instalação non-interactive~~ → ✅ **RESOLVIDO** (testado: roda sem prompt sem TTY).
- **Base despida:** `cp` cego carrega `enabledPlugins{14}` + hook context-mode + statusLine
  externo → referências penduradas e hooks que falham. **Sempre emitir do template.**
- **Isolamento total:** profile novo perde onboarding, *trust* por projeto, mcpServers
  user-scope e credenciais → re-login/re-trust.
- **Vazamento XDG do ponytail:** modo default só via `PONYTAIL_DEFAULT_MODE` no alias.
- **Symlink de skills (devorq):** validar que a descoberta segue symlink; senão, cópia.
- **node nos hooks (ponytail):** risco baixo (nvm herdado pelo alias); prova = flag.
- **Auto-install do marketplace oficial no 1º start TUI** (flags
  `officialMarketplaceAutoInstall*`): não ocorreu via CLI; verificar no 1º `claude` interativo.

---

## 8. Decisões

### 8.1. ✅ DECIDIDO — Filament v5 no claude-tall
**Decisão (2026-06-29):** o `mwguerra/filament-specialist` (v4) fica **FORA** do claude-tall.
O Filament v5 é coberto pela skill `laravel:filament-conventions` (copiada para o profile) +
**laravel-boost MCP**. Motivo: 5 dos 8 projetos do usuário (e os mais novos) são v5; o plugin
v4 daria guidance errada. Reflexo aplicado na seção 4.2.

### 8.2. Defaults seguros já adotados (mudáveis a qualquer momento)
- `laravel-package-developer` (Packagist) → **fora** (evita o hook Pint global; source
  quebrado no marketplace).
- HUB VPS PostgreSQL do DEVORQ → **off** (só liga se você controla a VPS).
- ponytail modo default → **`full`** (ultra poda animações/glassmorphism — não combinar
  com design premium).
- `.credentials.json` → **copiado** para cada profile (evita relogar).
- 4º profile "pessoal" (secretary/obsidian/board/article-writer/post-development) →
  **adiado** (foge do recorte 3-por-fonte; criável depois).

### 8.3. A confirmar na execução (não bloqueiam o plano)
- Binários no PATH do WSL p/ claude-tall: `php/composer/pest/pint`, `sqlite3`, `jq` (✓),
  `node` (✓ v22.22.1); `python3`/`bun` só se incluir e2e/conteúdo. Playwright MCP a declarar.
- Quais assets pessoais (`knowledge/stacks/laravel-livewire4.md`, skills
  `nando-design`/`laravel-frontend-design`, `systematic-debugging`) levar a **quais**
  profiles (não aparecem num config dir isolado).

---

## 9. Ordem de execução (quando aprovado)
0. ~~Passo 0 — PROBE~~ → ✅ **JÁ FEITO neste plano:** install non-interactive confirmado
   (imperativo); skills via cópia (symlink fica como otimização opcional); hook do
   `devorq rules bootstrap` confirmado. Execução pode começar direto no passo 1.
1. Versionar `setup.sh` + `aliases.zsh` + `templates/` + `lib/merge-settings.jq` (escrever, sem rodar).
2. Testar `emit_base` num dir descartável (settings despido correto).
3. Montar **claude-devorq** (mais barato): clone+PATH + 9 symlinks + CLAUDE.md (export) +
   `includeCoAuthoredBy=false`. Validar.
4. Montar **claude-tall**: emit_base + marketplace add + install do núcleo + Playwright MCP
   + CLAUDE.md. Validar.
5. Montar **claude-lazy**: emit_base + marketplace add + install + CLAUDE.md mínimo + alias.
   Validar flag `.ponytail-active`.
6. Aliases em `aliases.zsh`; `source` no `~/.zshrc`; novo terminal; validar cada alias.
7. Rodar `setup.sh` 2ª vez → confirmar idempotência.
8. (Futuro) 4º profile pessoal; transporte de assets pessoais.

---

## 10. Validações empíricas — estado
- [x] **Install non-interactive** sem prompt sem TTY → **CONFIRMADO** (probe ponytail).
- [x] **Hook `commit-msg`** → **CONFIRMADO** instalado por `devorq::rules::install_commit_msg_hook`
      via `devorq rules bootstrap` (e `workflow.sh`); regex `^[a-z]+\([a-z]+\):` + ban de
      Co-Authored-By. Usar `devorq rules bootstrap` no repo (garantido); `devorq init` é
      documentado como bootstrap mas o `bootstrap` explícito é o caminho certo.
- [x] **Descoberta de skills via symlink** → **resolvido por decisão**: default = cópia
      (não há subcomando headless p/ confirmar symlink); symlink fica como otimização opcional.
- [ ] **Auto-install do marketplace oficial** no 1º start **TUI** de cada profile (não
      ocorre via CLI; verificar no 1º `claude` interativo).
- [ ] **statusLine** do template não aponta para script inexistente (curar no template).
