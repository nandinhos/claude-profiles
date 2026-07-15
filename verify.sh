#!/usr/bin/env bash
# verify.sh — smoke test dos 3 profiles do Claude Code (invariantes do PLANO §10).
# Read-only: NÃO monta nem altera profiles (isso é o setup.sh). Sai != 0 se algum
# invariante falhar (WARN não falha). Use após ./setup.sh e em CI.
#
#   ./verify.sh          # checagens de filesystem + JSON + drift de settings (rápido, seguro)
#   ./verify.sh --deep   # + `claude plugin list` / `claude mcp list` (lento; pode pedir trust)
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$HOME/.claude-profiles"
TEMPLATE="$REPO/templates/settings.base.json"
DEEP=0; [ "${1:-}" = "--deep" ] && DEEP=1

# chaves curadas cujo valor DEVE bater com o template (detector do débito #1)
CURATED_KEYS=(model effortLevel language theme statusLine)
EXPECTED_DEVORQ_SKILLS=9
TALL_PLUGINS=(test-specialist code reverb-specialist docs-specialist error-memory docker-specialist laravel)

pass=0; fail=0; warn=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; pass=$((pass+1)); }
no()   { printf '  \033[31m✗\033[0m %s\n' "$*"; fail=$((fail+1)); }
wn()   { printf '  \033[33m!\033[0m %s\n' "$*"; warn=$((warn+1)); }
head() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

command -v jq >/dev/null 2>&1 || { echo "jq ausente — abortando"; exit 2; }
[ -f "$TEMPLATE" ] || { echo "template ausente: $TEMPLATE"; exit 2; }

json_ok() { jq empty "$1" >/dev/null 2>&1; }

# compara uma chave curada do settings do profile contra o template
check_curated() { # <settings.json> <profile>
  local f="$1" prof="$2" k tv dv
  for k in "${CURATED_KEYS[@]}"; do
    tv="$(jq -cS ".${k} // null" "$TEMPLATE")"
    dv="$(jq -cS ".${k} // null" "$f" 2>/dev/null || echo null)"
    if [ "$tv" = "$dv" ]; then
      ok "$prof: settings.$k em dia com o template"
    else
      no "$prof: settings.$k DIVERGE do template (débito #1 — settings não re-sincroniza)"
    fi
  done
}

# invariantes comuns a todo profile
check_base() { # <profile-name>
  local prof="$1"
  local dir="$PROFILES_DIR/$prof"
  local s="$dir/settings.json"
  head "profile: $prof"
  [ -d "$dir" ] || { no "$prof: diretório ausente ($dir)"; return; }
  ok "$prof: diretório existe"
  if [ -f "$s" ] && json_ok "$s"; then ok "$prof: settings.json é JSON válido"
  else no "$prof: settings.json ausente ou inválido"; return; fi
  if [ -s "$dir/CLAUDE.md" ]; then ok "$prof: CLAUDE.md presente e não-vazio"
  else no "$prof: CLAUDE.md ausente ou vazio"; fi
  [ -f "$dir/.credentials.json" ] || wn "$prof: sem .credentials.json (1º \`claude\` pedirá login)"
  check_curated "$s" "$prof"
}

# ------------------------------------------------------------------- globais
head "ambiente"
if command -v devorq >/dev/null 2>&1; then ok "CLI devorq no PATH"; else no "CLI devorq NÃO está no PATH (aliases.zsh sourceado?)"; fi
if grep -qs 'claude-profiles/aliases.zsh' "$HOME/.zshrc"; then ok ".zshrc faz source de aliases.zsh"; else wn "sem source de aliases.zsh no seu .zshrc"; fi
if json_ok "$TEMPLATE"; then ok "templates/settings.base.json é JSON válido"; else no "template inválido"; fi

# ------------------------------------------------------------------- devorq
check_base devorq
if [ -d "$PROFILES_DIR/devorq/skills" ]; then
  n=$(find "$PROFILES_DIR/devorq/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)
  if   [ "$n" -eq 0 ]; then no "devorq: 0 skills copiadas"
  elif [ "$n" -eq "$EXPECTED_DEVORQ_SKILLS" ]; then ok "devorq: $n skills (esperado $EXPECTED_DEVORQ_SKILLS)"
  else wn "devorq: $n skills (esperado $EXPECTED_DEVORQ_SKILLS — resync do devorq?)"; fi
else no "devorq: sem diretório skills/"; fi
if jq -e '.includeCoAuthoredBy == false' "$PROFILES_DIR/devorq/settings.json" >/dev/null 2>&1; then
  ok "devorq: includeCoAuthoredBy = false"
else no "devorq: includeCoAuthoredBy != false (Co-Authored-By pode vazar)"; fi

# ------------------------------------------------------------------- tall
check_base mwguerra-tall

# ------------------------------------------------------------------- ponytail
check_base ponytail

# ------------------------------------------------------------------- deep (opcional)
if [ "$DEEP" -eq 1 ]; then
  head "deep: plugins & MCP (via claude — lento)"
  tall_list="$(CLAUDE_CONFIG_DIR="$PROFILES_DIR/mwguerra-tall" claude plugin list 2>/dev/null || true)"
  for p in "${TALL_PLUGINS[@]}"; do
    if printf '%s\n' "$tall_list" | grep -q "$p"; then ok "tall: plugin $p instalado"; else no "tall: plugin $p AUSENTE"; fi
  done
  if CLAUDE_CONFIG_DIR="$PROFILES_DIR/mwguerra-tall" claude mcp list 2>/dev/null | grep -qi playwright; then
    ok "tall: MCP playwright configurado"; else no "tall: MCP playwright ausente"; fi
  if CLAUDE_CONFIG_DIR="$PROFILES_DIR/ponytail" claude plugin list 2>/dev/null | grep -q ponytail; then
    ok "ponytail: plugin ponytail instalado"; else no "ponytail: plugin ponytail ausente"; fi
fi

# ------------------------------------------------------------------- resumo
head "resumo"
printf '  \033[32m%d ok\033[0m · \033[33m%d warn\033[0m · \033[31m%d fail\033[0m\n' "$pass" "$warn" "$fail"
[ "$fail" -eq 0 ] || { echo; echo "  → há invariantes quebrados. Rode ./setup.sh e verifique novamente."; exit 1; }
echo; echo "  → todos os invariantes OK."
