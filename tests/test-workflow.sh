#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$root_dir/tests/test-common.sh"
workflow="$root_dir/.github/workflows/compatibility.yml"
action="$root_dir/action.yml"
upgrade_action="$root_dir/upgrade/action.yml"
attributes="$root_dir/.gitattributes"
gitignore="$root_dir/.gitignore"
github_client="$root_dir/src/pr/Классы/КлиентGitHub.os"
project_packagedef="$root_dir/packagedef"

grep -Fx '.depos-version text eol=lf' "$attributes" >/dev/null || {
  echo 'Для .depos-version не закреплены окончания строк LF' >&2
  exit 1
}
grep -Fx '/oscript_modules/' "$gitignore" >/dev/null

grep -F 'uses: docker://rhysd/actionlint:1.7.12' "$workflow" >/dev/null
grep -F 'shellcheck scripts/*.sh tests/*.sh tests/fakes/*' "$workflow" >/dev/null
grep -F 'bash tests/run.sh' "$workflow" >/dev/null
grep -F 'git diff --check' "$workflow" >/dev/null
grep -F 'name: Проверка совместимости' "$workflow" >/dev/null
grep -F 'name: Статические проверки' "$workflow" >/dev/null
grep -F 'name: Проверка workflow' "$workflow" >/dev/null
grep -F 'name: Проверка shell-скриптов' "$workflow" >/dev/null
grep -A4 -F 'uses: actions/checkout@v7.0.1' "$action" | grep -F 'clean: false' >/dev/null
grep -F 'scripts/prepare.sh' "$action" >/dev/null
grep -F 'scripts/format-pr.os' "$action" >/dev/null
grep -F 'opm install -l' "$action" >/dev/null
# Команда Action проверяется как буквальный текст.
# shellcheck disable=SC2016
grep -F 'cd "$ACTION_PATH"' "$action" >/dev/null
grep -F 'scripts/resolve-packagedef.sh' "$action" >/dev/null
grep -A3 -F 'message-prefix:' "$action" | grep -F 'default: build(deps)' >/dev/null
grep -A3 -F 'labels:' "$action" | grep -F 'default: dependencies' >/dev/null
# Выражение GitHub Actions проверяется как буквальный текст.
# shellcheck disable=SC2016
grep -F 'DEPOS_VERSION: ${{ inputs.depos-version }}' "$action" >/dev/null
# shellcheck disable=SC2016
grep -F 'GH_TOKEN: ${{ inputs.token }}' "$action" >/dev/null
# shellcheck disable=SC2016
grep -F 'TARGET: ${{ inputs.target }}' "$action" >/dev/null
# shellcheck disable=SC2016
grep -F 'DEPOS_PACKAGEDEF: ${{ env.DEPOS_PACKAGEDEF }}' "$action" >/dev/null
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
if [[ "$(grep -Fc 'uses: otymko/setup-onescript@v1.5.1' "$workflow")" -ne 2 ]]; then
  echo 'OneScript должен устанавливаться перед прямым вызовом upgrade Action' >&2
  exit 1
fi
grep -F 'opm install -l --dev' "$workflow" >/dev/null
grep -F 'opm install oneunit' "$workflow" >/dev/null
grep -F 'oneunit execute -d ./tests/onescript' "$root_dir/tests/run.sh" >/dev/null
grep -F '.ЗависитОт("semver", "1.1.1")' "$project_packagedef" >/dev/null
grep -F '.ЗависитОт("1connector", "2.3.3")' "$project_packagedef" >/dev/null
grep -F '.ЗависитОт("url", "0.2.0")' "$project_packagedef" >/dev/null
grep -F '.РазработкаЗависитОт("oneunit")' "$project_packagedef" >/dev/null
grep -Fx 'lib.additional=../oscript_modules' "$root_dir/scripts/oscript.cfg" >/dev/null
grep -Fx 'lib.additional=../../oscript_modules' "$root_dir/tests/onescript/oscript.cfg" >/dev/null
grep -F '#Использовать 1connector' "$github_client" >/dev/null
if grep -F 'Новый HTTPСоединение' "$github_client" >/dev/null; then
  echo 'Клиент GitHub обходит 1connector и создаёт HTTPСоединение напрямую' >&2
  exit 1
fi

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
