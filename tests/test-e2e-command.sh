#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$root_dir/tests/test-common.sh"
workflow="$root_dir/.github/workflows/e2e-command.yml"

grep -F 'name: Команда запуска E2E' "$workflow" >/dev/null
grep -F 'name: Отправка команды тестирования' "$workflow" >/dev/null
grep -F 'uses: peter-evans/slash-command-dispatch@' "$workflow" >/dev/null
grep -F '"command": "test"' "$workflow" >/dev/null
grep -F '"permission": "admin"' "$workflow" >/dev/null
grep -F '"repository": "Stivo182/depos-action-e2e"' "$workflow" >/dev/null
grep -F 'E2E_DISPATCH_TOKEN' "$workflow" >/dev/null
grep -F '  issues: write' "$workflow" >/dev/null
# Выражение GitHub Actions проверяется как буквальный текст.
# shellcheck disable=SC2016
grep -F 'reaction-token: ${{ github.token }}' "$workflow" >/dev/null
if grep -F '  pull-requests: write' "$workflow" >/dev/null; then
  echo 'Workflow slash-команды выдаёт неиспользуемое право pull-requests: write' >&2
  exit 1
fi
if grep -F '"named_args": true' "$workflow" >/dev/null; then
  echo "Команда E2E всё ещё требует именованные аргументы" >&2
  exit 1
fi

readme="$root_dir/README.md"
grep -A30 -F '## Быстрый старт' "$readme" | grep -F 'permissions:' >/dev/null
grep -A30 -F '## Быстрый старт' "$readme" | grep -F 'contents: write' >/dev/null
grep -A30 -F '## Быстрый старт' "$readme" | grep -F 'pull-requests: write' >/dev/null
grep -F 'Contents: Read and write' "$readme" >/dev/null
if grep -F '## E2E-тестирование изменений' "$readme" >/dev/null; then
  echo 'README содержит внутреннюю инструкцию по E2E-тестированию' >&2
  exit 1
fi

echo "ПРОЙДЕНО: контракт workflow команды E2E"
