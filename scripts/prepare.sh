#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$script_dir/common.sh"

: "${TARGET:?Переменная TARGET обязательна}"
: "${PACKAGEDEF:?Переменная PACKAGEDEF обязательна}"
: "${RUNNER_TEMP:?Переменная RUNNER_TEMP обязательна}"
: "${GITHUB_ENV:?Переменная GITHUB_ENV обязательна}"

validate_target "$TARGET"

if [[ "$PACKAGEDEF" == *$'\n'* || "$PACKAGEDEF" == *$'\r'* ]]; then
  echo "::error title=Некорректный packagedef::Путь не должен содержать переводы строк."
  exit 1
fi

depos_base="${BASE:-${DEFAULT_BASE:-${CURRENT_REF:-}}}"
if [[ -z "$depos_base" ]] || ! git check-ref-format --branch "$depos_base" >/dev/null 2>&1; then
  echo "::error title=Некорректный base::Недопустимое имя базовой ветки: ${depos_base:-<пусто>}"
  exit 1
fi

package_def="${PACKAGEDEF//\\//}"
while [[ "$package_def" == ./* ]]; do
  package_def="${package_def#./}"
done

if [[ -z "$package_def" || "$package_def" == /* || "$package_def" == //* || "$package_def" =~ ^[A-Za-z]:/ ]]; then
  echo "::error title=Некорректный packagedef::Укажите относительный путь внутри репозитория."
  exit 1
fi

IFS='/' read -r -a path_parts <<< "$package_def"
for path_part in "${path_parts[@]}"; do
  if [[ "$path_part" == ".." ]]; then
    echo "::error title=Некорректный packagedef::Путь не должен содержать сегменты '..'."
    exit 1
  fi
done

if [[ -n "${BRANCH:-}" ]]; then
  depos_branch="$BRANCH"
elif [[ -z "${DEFAULT_BASE:-}" || "$depos_base" == "$DEFAULT_BASE" ]]; then
  # Для основной ветки сохраняется совместимость с ранее созданными Pull Request.
  depos_branch="depos/bump-deps/${TARGET}"
else
  # Отдельное имя не позволяет разным базовым веткам перезаписывать один Pull Request.
  depos_branch="depos/bump-deps/${TARGET}/${depos_base}"
fi
depos_branch_is_default=false
if [[ -z "${BRANCH:-}" ]]; then
  depos_branch_is_default=true
fi

if ! git check-ref-format --branch "$depos_branch" >/dev/null 2>&1; then
  echo "::error title=Некорректный branch::Недопустимое имя ветки: ${depos_branch}"
  exit 1
fi

runner_temp="$RUNNER_TEMP"
if [[ "${RUNNER_OS:-}" == "Windows" ]]; then
  runner_temp="$(cygpath -u "$runner_temp")"
fi

{
  echo "DEPOS_BRANCH=${depos_branch}"
  echo "DEPOS_BRANCH_IS_DEFAULT=${depos_branch_is_default}"
  echo "DEPOS_BASE=${depos_base}"
  echo "DEPOS_PACKAGEDEF=${package_def}"
  echo "DEPOS_REPORT_PATH=${runner_temp%/}/depos-packages.json"
} >> "$GITHUB_ENV"
