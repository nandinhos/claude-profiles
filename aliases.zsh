# Claude Code profiles — estilo `codex --profile <nome>`
# Gerado por ~/projects/claude-profiles/setup.sh. Sourceado pelo ~/.zshrc.
# Forma-PREFIXO (CLAUDE_CONFIG_DIR=... claude): a var entra só no ambiente do claude
# (e seus filhos herdam). NUNCA usar `export ...; claude` aqui (vazaria para o shell).

# CLI devorq disponível no PATH (compartilhada por todos os profiles)
export PATH="$HOME/projects/devorq/bin:$PATH"

# 1) Metodologia/disciplina DEVORQ
#    Carrega o .env do HUB (DEVORQ_*/GITHUB_*) num SUBSHELL com set -a + exec:
#    as vars são exportadas só para este claude (e o devorq que rodar dentro dele);
#    nada vaza para o seu shell interativo. O .env é gitignored (segredos ficam locais).
alias claude-devorq='(set -a; . $HOME/projects/claude-profiles/.env 2>/dev/null; set +a; CLAUDE_CONFIG_DIR=$HOME/.claude-profiles/devorq exec claude)'

# 2) Stack Laravel/TALL (plugins mwguerra; Filament v5)
alias claude-tall='CLAUDE_CONFIG_DIR=$HOME/.claude-profiles/mwguerra-tall claude'

# 3) Código mínimo (ponytail; modo default full)
alias claude-lazy='CLAUDE_CONFIG_DIR=$HOME/.claude-profiles/ponytail PONYTAIL_DEFAULT_MODE=full claude'
