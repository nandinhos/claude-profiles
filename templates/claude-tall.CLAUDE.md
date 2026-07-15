# Harness: claude-tall (Laravel 12 + Livewire 4 + Filament v5 + Tailwind)

Profile isolado para desenvolvimento backend/TALL, com especialistas via plugins mwguerra.

## Filament = v5 (decisão do projeto)
Para Filament, use a skill `laravel:filament-conventions` (plugin `laravel@mwguerra-plugins`,
v5 — inclui `references/filament-5-recipes.md`) **+** o **laravel-boost MCP** (vem por-projeto
do `.mcp.json` de cada repo Laravel). **NÃO** usar padrões de Filament v4 (o
`filament-specialist` do mwguerra, que é v4, foi deixado de fora deste profile de propósito).

## Convenções (estilo mwguerra)
- Planejar antes de implementar.
- Criar arquivos Laravel/Filament via **Artisan** (`php artisan make:...`), nunca à mão.
- Garantir testes (**Pest**) verdes antes de commitar; rodar em paralelo quando possível.

## Plugins do núcleo (este profile)
`test-specialist` (Pest), `code` (production-ready, usa Playwright MCP), `reverb-specialist`
(broadcasting/real-time), `docs-specialist`, `error-memory`, `docker-specialist`, e
`laravel` (Laravel + Filament **v5**).

## Stack / ambiente
WSL2 · php (`/usr/bin/php`) · composer · `pint` via `vendor/bin/pint` (por-projeto) ·
sqlite3 · node v22 · Playwright MCP via `npx @playwright/mcp` (rodar `npx playwright install`
para baixar browsers na 1ª vez que usar `code`/E2E).
