#!/usr/bin/env bash
# setup.sh — monta (idempotente) os 3 profiles isolados do Claude Code via CLAUDE_CONFIG_DIR.
# Estratégia A1 (instalação isolada por profile). Ver PLANO.md.
# Rodar 2x não deve duplicar nem quebrar. NÃO modifica ~/.claude (só lê credentials/settings).
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$HOME/.claude-profiles"
BASE_CLAUDE="$HOME/.claude"
DEVORQ_REPO="$HOME/projects/devorq"

# Versões pinadas (reprodutibilidade — ver VERSIONS.md). Bump deliberado: editar aqui.
PLAYWRIGHT_MCP_VERSION="${PLAYWRIGHT_MCP_VERSION:-0.0.77}"

log()  { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
head() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

require() { command -v "$1" >/dev/null 2>&1 || { warn "binário ausente: $1"; return 1; }; }
require claude || { echo "claude não está no PATH"; exit 1; }
require jq     || exit 1

jq_set() { # <file> <filter>  — edita JSON idempotente
  local f="$1" filter="$2" tmp; tmp="$(mktemp)"
  jq "$filter" "$f" > "$tmp" && mv "$tmp" "$f"
}

emit_base() { # <profile_dir>  — base enxuta a partir do template versionado
  local prof="$1"
  mkdir -p "$prof/skills"
  if [ ! -f "$prof/.credentials.json" ] && [ -f "$BASE_CLAUDE/.credentials.json" ]; then
    cp -p "$BASE_CLAUDE/.credentials.json" "$prof/.credentials.json" && log "credentials copiadas"
  fi
  # settings: SEMPRE mescla o template curado sobre o profile (re-sync), preservando
  # enabledPlugins/extraKnownMarketplaces/includeCoAuthoredBy/mcpServers do profile.
  # Assim, editar templates/settings.base.json e re-rodar o setup PROPAGA a mudança.
  local cur="$prof/settings.json" src=/dev/null tmp
  [ -f "$cur" ] && src="$cur"
  tmp="$(mktemp)"
  if jq -n --slurpfile tpl "$REPO/templates/settings.base.json" \
          --slurpfile cur "$src" -f "$REPO/lib/merge-settings.jq" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$cur"; log "settings.json mesclado do template (re-sync)"
  else
    rm -f "$tmp"; warn "merge de settings falhou — settings.json preservado"
  fi
}

add_marketplace() { # <profile_dir> <repo>
  local prof="$1" repo="$2"
  if CLAUDE_CONFIG_DIR="$prof" claude plugin marketplace list 2>/dev/null | grep -q "$repo"; then
    log "marketplace já registrado: $repo"
  else
    log "marketplace add: $repo"
    CLAUDE_CONFIG_DIR="$prof" claude plugin marketplace add "$repo" </dev/null 2>&1 | sed 's/^/    /'
  fi
}

install_plugin() { # <profile_dir> <plugin@marketplace>
  local prof="$1" spec="$2"
  if CLAUDE_CONFIG_DIR="$prof" claude plugin list 2>/dev/null | grep -q "$spec"; then
    log "plugin já instalado: $spec"
  else
    log "plugin install: $spec"
    CLAUDE_CONFIG_DIR="$prof" claude plugin install "$spec" </dev/null 2>&1 | sed 's/^/    /'
  fi
}

add_mcp_playwright() { # <profile_dir>  — reconcilia a versão pinada (não só "existe?")
  local prof="$1" spec="@playwright/mcp@$PLAYWRIGHT_MCP_VERSION" have=""
  [ -f "$prof/.claude.json" ] && have="$(jq -r '.mcpServers.playwright.args // [] | join(" ")' "$prof/.claude.json" 2>/dev/null)"
  if printf '%s' "$have" | grep -qF "$spec"; then
    log "MCP playwright já em $PLAYWRIGHT_MCP_VERSION"; return
  fi
  if [ -n "$have" ]; then
    warn "MCP playwright divergente ($have) — reconciliando p/ $PLAYWRIGHT_MCP_VERSION"
    CLAUDE_CONFIG_DIR="$prof" claude mcp remove --scope user playwright </dev/null >/dev/null 2>&1 || true
  fi
  log "MCP add: playwright ($spec, scope user)"
  CLAUDE_CONFIG_DIR="$prof" claude mcp add --scope user playwright -- npx -y "$spec" </dev/null 2>&1 \
    | sed 's/^/    /' || warn "claude mcp add playwright falhou — verificar manualmente"
}

# ---------------------------------------------------------------- profile: devorq
setup_devorq() {
  head "claude-devorq (metodologia/disciplina)"
  local prof="$PROFILES_DIR/devorq"
  [ -d "$DEVORQ_REPO" ] || { warn "$DEVORQ_REPO ausente — clonando"; git clone https://github.com/nandinhos/devorq "$DEVORQ_REPO" 2>&1 | sed 's/^/    /'; }
  emit_base "$prof"
  # 9 skills DEVORQ (cópia com re-sync; symlink fica como otimização opcional)
  local n=0
  for d in "$DEVORQ_REPO"/skills/*/; do
    [ -d "$d" ] || continue
    local name; name="$(basename "$d")"
    rm -rf "$prof/skills/$name"; cp -r "$d" "$prof/skills/$name"; n=$((n+1))
  done
  log "$n skills DEVORQ copiadas (re-sync)"
  # CLAUDE.md = header + `devorq rules export claude`
  local tmp; tmp="$(mktemp -d)"
  ( cd "$tmp" && "$DEVORQ_REPO/bin/devorq" rules export claude >/dev/null 2>&1 )
  if [ -f "$tmp/CLAUDE.md" ]; then
    cat "$REPO/templates/devorq-header.CLAUDE.md" "$tmp/CLAUDE.md" > "$prof/CLAUDE.md"
    log "CLAUDE.md gerado (header + rules export)"
  else
    warn "export claude não gerou CLAUDE.md — fallback: concatena rules/*.md"
    cp "$REPO/templates/devorq-header.CLAUDE.md" "$prof/CLAUDE.md"
    for r in agent-discipline commit-convention manual-commit; do
      [ -f "$DEVORQ_REPO/rules/$r.md" ] && { printf '\n' >> "$prof/CLAUDE.md"; cat "$DEVORQ_REPO/rules/$r.md" >> "$prof/CLAUDE.md"; }
    done
  fi
  rm -rf "$tmp"
  # commits sem Co-Authored-By
  jq_set "$prof/settings.json" '.includeCoAuthoredBy = false'
  log "includeCoAuthoredBy = false"
}

# ---------------------------------------------------------------- profile: mwguerra-tall
setup_mwguerra() {
  head "claude-tall (Laravel/TALL — Filament v5)"
  local prof="$PROFILES_DIR/mwguerra-tall"
  emit_base "$prof"
  add_marketplace "$prof" "mwguerra/claude-code-plugins"   # name: mwguerra-marketplace
  add_marketplace "$prof" "mwguerra/plugins"               # name: mwguerra-plugins
  for spec in \
      test-specialist@mwguerra-marketplace \
      code@mwguerra-marketplace \
      reverb-specialist@mwguerra-marketplace \
      docs-specialist@mwguerra-marketplace \
      error-memory@mwguerra-marketplace \
      docker-specialist@mwguerra-marketplace \
      laravel@mwguerra-plugins ; do
    install_plugin "$prof" "$spec"
  done
  add_mcp_playwright "$prof"
  cp "$REPO/templates/claude-tall.CLAUDE.md" "$prof/CLAUDE.md" && log "CLAUDE.md TALL escrito"
}

# ---------------------------------------------------------------- profile: ponytail
setup_ponytail() {
  head "claude-lazy (código mínimo — ponytail)"
  local prof="$PROFILES_DIR/ponytail"
  emit_base "$prof"
  add_marketplace "$prof" "DietrichGebert/ponytail"
  install_plugin "$prof" "ponytail@ponytail"
  cp "$REPO/templates/ponytail.CLAUDE.md" "$prof/CLAUDE.md" && log "CLAUDE.md mínimo escrito"
}

main() {
  head "Profiles dir: $PROFILES_DIR"
  setup_devorq
  setup_mwguerra
  setup_ponytail
  head "Concluído"
  echo "  Ative no ~/.zshrc:  source ~/projects/claude-profiles/aliases.zsh"
  echo "  Aliases: claude-devorq · claude-tall · claude-lazy"
}
main "$@"
