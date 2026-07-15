# lib/merge-settings.jq — mescla o template curado (fonte da verdade) sobre o
# settings.json de um profile, PRESERVANDO as chaves que o template omite de
# propósito por pertencerem ao runtime do profile (plugins, marketplaces, etc.).
#
# Uso:
#   jq -n --slurpfile tpl templates/settings.base.json \
#         --slurpfile cur "$prof/settings.json" \
#         -f lib/merge-settings.jq
#   # (num profile ainda sem settings.json, passe --slurpfile cur /dev/null)
#
# Semântica (shallow merge, template vence):
#   - TODAS as chaves curadas do template são aplicadas a cada execução
#     (model, effortLevel, language, theme, statusLine, permissions, env, ...):
#     re-rodar o setup PROPAGA edições do template — corrige o débito
#     "settings congelado após criação" (emit_base fazia copy-if-absent).
#   - As chaves em $preserve, se presentes no profile, são MANTIDAS do profile
#     (o template não as versiona; são gravadas por `claude plugin install`,
#     `claude mcp add`, ou por jq_set no setup).
#
# Nota: `permissions` pertence ao template (fonte da verdade). Ajustes manuais
# de permissão feitos num profile são revertidos no próximo setup — para
# torná-los permanentes, versione-os em templates/settings.base.json.

($tpl[0]) as $t
| ($cur[0] // {}) as $c
| ["enabledPlugins", "extraKnownMarketplaces", "includeCoAuthoredBy", "mcpServers"] as $preserve
| $t + ($c | to_entries | map(select(.key as $k | $preserve | index($k))) | from_entries)
