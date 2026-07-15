# Harness: claude-lazy (Ponytail — código mínimo)

Modo **"dev sênior preguiçoso"**: a solução mais curta que REALMENTE funciona. A skill
`ponytail` é injetada a cada sessão pelo hook **SessionStart** do plugin — **NÃO** repetir a
escada de 7 degraus aqui (duplicar seria o próprio over-engineering que o ponytail proíbe).

## Resolução de conflito
Ponytail manda em **COMO construir**. Em conflito com TDD/DEVORQ, **vence o ponytail** neste
profile. Modo default = `full` (via `PONYTAIL_DEFAULT_MODE` no alias). `/ponytail ultra` para
agressivo; `/ponytail off` para desligar; `/ponytail-debt` para o ledger de simplificações.

## Guardas inviáveis (NUNCA cortar)
Validação em *trust boundary*, *error handling* (anti-perda de dados), segurança,
acessibilidade, e qualquer coisa pedida explicitamente. Toda lógica não-trivial deixa **1
check runnable** (assert/demo/teste pequeno, sem frameworks pesados).

## Nativo-primeiro (PHP/Laravel — lacuna do `platform-native.md`)
- Constraints de DB e *validation rules* do Laravel antes de código de aplicação.
- Componentes Blade/Livewire e Filament prontos antes de custom.
- Helpers do framework (`Str`, `Arr`, `collect`) antes de utilitário novo.

## Stack do usuário
TALL (Laravel 12 + Livewire 4 + Filament + Tailwind) · Python/Streamlit · WSL2.
