# HANDOFF — Projeto: Criação de Profiles isolados do Claude Code

> ⏳ **Documento histórico congelado (2026-06-29).** Investigação do mecanismo que
> precedeu a montagem. Já executado — a **fonte viva** é o [`README.md`](README.md).
> Mantido como referência do "porquê"; não edite para atualizar operação.

> **Para o próximo LLM/sessão:** este arquivo é autocontido. Leia-o inteiro antes de
> agir. O usuário (nandodev) vai, a partir daqui, passar os comandos e as
> necessidades específicas de cada profile. **Não comece a criar nada antes de ele
> responder às perguntas da seção 11.**

- **Data do handoff:** 2026-06-29
- **Autor da investigação:** sessão anterior do Claude Code (projeto catalogar/v2)
- **Status:** investigação técnica concluída e validada empiricamente. Falta a fase de
  execução (definir e montar os profiles).

---

## 1. Objetivo do projeto

Reproduzir no **Claude Code** o conceito de `codex --profile <nome>` do OpenAI Codex CLI:
ter vários **"harnesses" / perfis isolados**, cada um com seu próprio conjunto de
**skills, agents/subagents, hooks, plugins, MCP servers e settings**, e abrir o Claude
Code escolhendo qual perfil usar — **sem reconfigurar a cada projeto**.

Cada profile representa um estilo/contexto de trabalho diferente (ex.: um harness para
Python, outro para Laravel/TALL, outro para frontend design), cada um com sua própria
"forma de programar".

Frase original do usuário (Codex, para referência da ergonomia desejada):
> `codex --profile nando-harness` → abre o Codex com plugins, skills e hooks próprios.

---

## 2. Contexto do usuário

- Vem do Codex CLI, já usa profiles lá. Conhece o conceito.
- Quer trocar de "harness" por **contexto/stack**, não por projeto.
- Stacks recorrentes (inferidas do ambiente dele): Laravel 12 + Livewire 4 + Filament +
  Tailwind (TALL), Python/Streamlit, frontend design premium.
- Ambiente: **WSL2 (Linux)**, shell **zsh** (`~/.zshrc`).
- Padrão de diretórios de projeto: `~/projects/<nome>`.

---

## 3. Ambiente confirmado (empírico nesta máquina)

| Item | Valor |
|------|-------|
| Versão Claude Code | **2.1.195** |
| Binário (symlink) | `~/.local/bin/claude` |
| Binário real | `~/.local/share/claude/versions/2.1.195` (~244 MB, compilado) |
| Diretório de config padrão | `~/.claude/` |
| Login | via arquivo `~/.claude/.credentials.json` (471 bytes, modo `600`) |
| Shell rc | `~/.zshrc` |
| OS | Linux 6.18 (WSL2), zsh |

---

## 4. Descobertas técnicas — validadas empiricamente

> ⚠️ **Importante:** um subagente "claude-code-guide" afirmou que `CLAUDE_CONFIG_DIR`
> **NÃO existe**. Isso está **ERRADO**. Foi refutado por inspeção direta do binário.
> Confie na verificação empírica abaixo, não na doc que o subagente consultou.

### 4.1. Não existe flag `--profile` nativa
O Claude Code **não** tem uma flag `--profile <nome>` como o Codex. Confirmado.

### 4.2. `CLAUDE_CONFIG_DIR` EXISTE ✅ (esta é a peça-chave)
Variável de ambiente que **desloca todo o diretório `~/.claude`** para outro caminho.
Isola **tudo de uma vez**: settings, skills, agents, hooks, plugins, MCP, memória,
sessões, credenciais, knowledge, commands. É o equivalente real (e mais completo) a um
"profile".

**Como foi confirmado:**
```bash
grep -ao "CLAUDE_CONFIG_DIR" ~/.local/share/claude/versions/2.1.195
# → retornou múltiplas ocorrências (string presente no binário compilado)
```

**Uso:**
```bash
CLAUDE_CONFIG_DIR=~/.claude-profiles/<nome> claude
```

### 4.3. Outras flags relevantes confirmadas no binário
- `--settings <arquivo.json | json-inline>` — sobrescreve **apenas chaves de settings**
  (model, permissions, env, hooks). **Não** troca skills nem agents.
- `--mcp-config <arquivo.json>` — carrega MCP servers de um arquivo específico.
- `--strict-mcp-config` — usa **apenas** o `--mcp-config` (ignora descoberta automática).
- `--setting-sources user,project,local` — controla quais níveis de settings carregar.

### 4.4. Hierarquia de settings (precedência, alta → baixa)
1. Managed (organizacional — não aplicável aqui)
2. Flags de CLI (`--settings`, etc.)
3. `.claude/settings.local.json` (projeto, pessoal/gitignored)
4. `.claude/settings.json` (projeto, versionado)
5. `~/.claude/settings.json` (usuário/global)

> Observação: `CLAUDE_CONFIG_DIR` muda **qual** `~/.claude` é o nível "usuário/global".
> Os níveis de projeto continuam vindo do diretório do projeto onde o `claude` é aberto.

---

## 5. Mecanismo escolhido para os profiles

**`CLAUDE_CONFIG_DIR` + aliases de shell.** É o único que isola skills/agents/hooks/
plugins/MCP de verdade. As flags da seção 4.3 são **complemento**, não substituto
(não trocam skills nem agents).

Modelo mental:
```
codex --profile nando-harness
        ≈
CLAUDE_CONFIG_DIR=~/.claude-profiles/nando-harness claude
```

---

## 6. Estrutura real de `~/.claude` (o que será isolado)

Conteúdo atual relevante e **impacto de cópia** (medido nesta máquina):

| Item | O que é | Tamanho | Copiar para o profile? |
|------|---------|---------|------------------------|
| `settings.json` / `settings.local.json` | configurações | pequeno | ✅ sim (base, depois ajustar) |
| `.credentials.json` | login OAuth | 471 B | ✅ sim (evita relogar) |
| `CLAUDE.md` | instruções globais do usuário | pequeno | ✅ sim (ou customizar por profile) |
| `skills/` | skills do usuário | **2.3M** | ✅ barato — copiar e podar |
| `hooks/` | hooks | pequeno | ✅ sim (por profile) |
| `commands/` | slash commands | pequeno | ✅ sim |
| `knowledge/` | base de conhecimento por stack | pequeno | ✅ sim |
| `plugins/` | plugins instalados | **437M** ⚠️ | ❌ **NÃO** copiar cego — ver 7 |
| `projects/` | memória + sessões + histórico | **382M** ⚠️ | ❌ **NÃO** copiar — começar limpo |
| `cache/`, `backups/`, `file-history/`, `image-cache/`, `paste-cache/`, `shell-snapshots/`, `debug/`, `daemon/`, `sessions/` | runtime/cache | variável | ❌ não copiar (recriados sozinhos) |

> **Não existe** pasta `~/.claude/agents/` no topo nesta máquina — agents custom
> provavelmente vêm via **plugins**. Confirmar com o usuário se ele tem agents próprios.

> **Conclusão de disco:** `cp -r ~/.claude <profile>` cego custaria **~820M+ por
> profile** (plugins 437M + projects 382M). **Evitar.** Usar a estratégia enxuta (seção 7).

---

## 7. Estratégias de criação de profile (com trade-offs)

### Estratégia A — Enxuta (RECOMENDADA)
Copiar só o leve e instalar plugins sob demanda em cada profile.
```bash
PROF=~/.claude-profiles/<nome>
mkdir -p "$PROF"
# itens leves:
cp ~/.claude/.credentials.json "$PROF"/           # evita relogar
cp ~/.claude/settings.json      "$PROF"/           # base; ajustar depois
cp ~/.claude/CLAUDE.md          "$PROF"/           # ou escrever um específico
cp -r ~/.claude/skills          "$PROF"/   2>/dev/null  # 2.3M; podar depois
cp -r ~/.claude/hooks           "$PROF"/   2>/dev/null
cp -r ~/.claude/commands        "$PROF"/   2>/dev/null
cp -r ~/.claude/knowledge       "$PROF"/   2>/dev/null
# plugins/MCP: instalar/declarar só o que o profile precisa (NÃO copiar os 437M)
# memória (projects/) começa vazia e isolada — desejável.
```
- ✅ Disco enxuto, isolamento real, memória limpa por profile.
- ⚠️ Plugins precisam ser reinstalados por profile (decidir quais em cada um).

### Estratégia B — Clone completo
`cp -r ~/.claude ~/.claude-profiles/<nome>` e depois podar.
- ✅ Rápido de partir (herda tudo, inclusive plugins).
- ❌ ~820M+ por profile; carrega memória/sessões antigas; precisa limpar `projects/`,
  `cache/`, etc. depois.

### Estratégia C — Híbrida (plugins compartilhados via symlink)
Profile enxuto + `ln -s ~/.claude/plugins <profile>/plugins`.
- ✅ Não duplica os 437M.
- ❌ **Quebra o isolamento de plugins** (mexer num afeta todos). Só usar se os plugins
  forem realmente comuns a todos os profiles.

> **Default sugerido:** Estratégia A. Decidir caso a caso se algum plugin pesado e comum
> justifica a C.

---

## 8. Receita de uso + aliases

Para cada profile criado, adicionar um alias em `~/.zshrc`:
```bash
# ~/.zshrc — Profiles do Claude Code (estilo `codex --profile`)
alias claude-py='CLAUDE_CONFIG_DIR=~/.claude-profiles/python-strict claude'
alias claude-laravel='CLAUDE_CONFIG_DIR=~/.claude-profiles/laravel-tall claude'
alias claude-front='CLAUDE_CONFIG_DIR=~/.claude-profiles/frontend-design claude'
```
Uso (de qualquer projeto):
```bash
cd ~/projects/qualquer-coisa
claude-laravel        # abre com skills/agents/hooks/plugins/MCP do harness Laravel
```
Após editar o `.zshrc`: `source ~/.zshrc` (ou abrir novo terminal).

---

## 9. Cuidados / armadilhas conhecidas

1. **Login:** copiar `.credentials.json` evita relogar em cada profile. Se o token
   expirar/rotacionar, pode ser preciso `claude` → login em cada profile, ou recopiar o
   arquivo do `~/.claude` principal.
2. **Memória isolada:** cada profile terá sua própria memória/sessões (`projects/`).
   Geralmente desejável — mas o histórico do `~/.claude` principal **não** aparece nos
   profiles.
3. **Atualização de versão:** o binário do `claude` é **compartilhado** (fica em
   `~/.local/share/claude/`, fora do config dir). `CLAUDE_CONFIG_DIR` só afeta config,
   então atualizar o Claude Code vale para todos os profiles automaticamente. ✅
4. **Espaço em disco:** ver seção 6/7 — não copiar `plugins/` (437M) e `projects/`
   (382M) cegamente.
5. **`CLAUDE.md` global:** o `~/.claude/CLAUDE.md` atual tem padrões do usuário (Laravel
   Boost MCP, DEVORQ, etc.). Decidir, por profile, se herda esse CLAUDE.md ou usa um
   enxuto/específico.
6. **MCP servers:** alguns MCP exigem auth interativa e podem não funcionar em runs
   headless. Declarar os MCP de cada profile no `.mcp.json`/`settings` dentro do
   `CLAUDE_CONFIG_DIR` correspondente, ou via `--mcp-config`.

---

## 10. Alternativa leve (quando NÃO precisa trocar skills/agents)

Se um cenário só precisar variar settings/MCP (não skills/agents), dá pra evitar profile
inteiro:
```bash
alias claude-staging='claude \
  --settings   ~/.claude/perfis/staging.json \
  --mcp-config ~/.claude/perfis/mcp-staging.json \
  --strict-mcp-config \
  --setting-sources user,project'
```
Limitação: **não troca skills nem agents**. Para harnesses completos, usar
`CLAUDE_CONFIG_DIR` (seções 5–8).

---

## 11. ❓ O que falta DECIDIR (perguntar ao usuário antes de executar)

O usuário disse que, a partir deste handoff, vai passar os comandos e necessidades.
Coletar dele:

1. **Quantos profiles** e o **nome** de cada um (sugestões: `python-strict`,
   `laravel-tall`, `frontend-design`).
2. Para **cada** profile:
   - **Skills** que entram (e quais podar das atuais).
   - **Agents/subagents** próprios.
   - **Hooks** (ex.: formatação, lint, mensagens de Stop).
   - **Plugins** a instalar (lembrar do custo de disco; quais são realmente necessários).
   - **MCP servers** (ex.: laravel-boost, context7, playwright, stitch...).
   - **Settings**: model, effort, permissions (allow/deny), env vars.
   - **CLAUDE.md**: herdar o global ou escrever um específico do harness.
3. **Estratégia de criação:** A (enxuta, default), B (clone) ou C (híbrida com symlink de
   plugins)?
4. **Onde versionar** estes profiles (este repo `~/projects/claude-profiles`)? Ex.: um
   script `setup.sh` que recria os profiles + um `aliases.zsh` para dar `source`.

---

## 12. Primeiros passos sugeridos para a próxima sessão

1. Ler este handoff.
2. Fazer ao usuário as perguntas da seção 11 (usar AskUserQuestion quando fizer sentido).
3. Propor um **script idempotente** (`setup.sh`) neste repo que monta os profiles via
   Estratégia A, e um `aliases.zsh` com os aliases — assim os profiles são reproduzíveis
   e versionáveis, não só comandos soltos.
4. Executar para o primeiro profile, validar abrindo `CLAUDE_CONFIG_DIR=... claude` e
   conferindo que skills/plugins/MCP esperados aparecem.
5. Repetir para os demais.

---

## 13. Referências rápidas (comandos de verificação)

```bash
# versão e caminho
claude --version
which claude

# confirmar que CLAUDE_CONFIG_DIR é reconhecido (string no binário)
grep -ao "CLAUDE_CONFIG_DIR" ~/.local/share/claude/versions/*/

# estrutura e tamanhos do config atual
ls -la ~/.claude
du -sh ~/.claude/plugins ~/.claude/projects ~/.claude/skills

# testar um profile (depois de criado)
CLAUDE_CONFIG_DIR=~/.claude-profiles/<nome> claude
```
