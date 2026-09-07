#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow="$root_dir/.github/workflows/compatibility.yml"
action="$root_dir/action.yml"
upgrade_action="$root_dir/upgrade/action.yml"
attributes="$root_dir/.gitattributes"

grep -Fx '.depos-version text eol=lf' "$attributes" >/dev/null || {
  echo 'Для .depos-version не закреплены окончания строк LF' >&2
  exit 1
}

grep -F 'uses: docker://rhysd/actionlint:1.7.12' "$workflow" >/dev/null
grep -F 'shellcheck scripts/*.sh tests/*.sh tests/fakes/*' "$workflow" >/dev/null
grep -F 'bash tests/run.sh' "$workflow" >/dev/null
grep -F 'git diff --check' "$workflow" >/dev/null
grep -F 'name: Проверка совместимости' "$workflow" >/dev/null
grep -F 'name: Статические проверки' "$workflow" >/dev/null
grep -F 'name: Проверка workflow' "$workflow" >/dev/null
grep -F 'name: Проверка shell-скриптов' "$workflow" >/dev/null
grep -A4 -F 'uses: actions/checkout@v6.0.1' "$action" | grep -F 'clean: false' >/dev/null
grep -F 'scripts/prepare.sh' "$action" >/dev/null
grep -F 'scripts/format-pr.sh' "$action" >/dev/null
grep -F 'scripts/resolve-packagedef.sh' "$action" >/dev/null
grep -A3 -F 'message-prefix:' "$action" | grep -F 'default: build(deps)' >/dev/null
grep -A3 -F 'labels:' "$action" | grep -F 'default: dependencies' >/dev/null
# Выражение GitHub Actions проверяется как буквальный текст.
# shellcheck disable=SC2016
grep -F 'DEPOS_VERSION: ${{ inputs.depos-version }}' "$action" >/dev/null
if grep -A3 -F 'depos-version:' "$action" | grep -F 'default:' >/dev/null ||
    grep -A3 -F 'depos-version:' "$upgrade_action" | grep -F 'default:' >/dev/null; then
  echo 'Версия depos продублирована в метаданных Action' >&2
  exit 1
fi
# Выражения GitHub Actions проверяются как буквальный текст.
# shellcheck disable=SC2016
grep -F 'ref: ${{ env.DEPOS_BASE }}' "$action" >/dev/null
# shellcheck disable=SC2016
grep -F 'base: ${{ env.DEPOS_BASE }}' "$action" >/dev/null
# Переменная должна раскрываться в workflow, а не в этом тесте.
# shellcheck disable=SC2016
grep -F 'git diff --check "origin/${BASE_REF}...HEAD"' "$workflow" >/dev/null
grep -F 'uses: ./upgrade' "$workflow" >/dev/null

for example in "$root_dir"/examples/*.yml; do
  grep -F 'permissions:' "$example" >/dev/null
  if grep -F 'uses: actions/checkout@v5' "$example" >/dev/null; then
    echo "В примере осталась устаревшая версия actions/checkout: ${example}" >&2
    exit 1
  fi
done

common="$root_dir/scripts/common.sh"
grep -F "DEPOS_MANAGED_MARKER='<!-- depos-action: managed pull request -->'" "$common" >/dev/null
if grep -F '<!-- depos-action: managed pull request -->' "$action" "$root_dir/scripts/cleanup-pr.sh" >/dev/null; then
  echo 'Маркер управляемого PR продублирован за пределами common.sh' >&2
  exit 1
fi

echo "ПРОЙДЕНО: контракт workflow совместимости"
