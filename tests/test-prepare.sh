#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$root_dir/tests/test-common.sh"
prepare_script="$root_dir/scripts/prepare.sh"
case_dir="$(mktemp -d)"
trap 'rm -rf -- "$case_dir"' EXIT

run_prepare() {
  : > "$case_dir/github-env"
  TARGET="${1:-latest}" \
    PACKAGEDEF="${2:-packagedef}" \
    BRANCH="${3:-}" \
    BASE="${4:-}" \
    DEFAULT_BASE=main \
    CURRENT_REF=main \
    RUNNER_TEMP="$case_dir/runner-temp" \
    RUNNER_OS=Linux \
    GITHUB_ENV="$case_dir/github-env" \
    bash "$prepare_script"
}

run_prepare latest './fixtures\packagedef' ''
grep -Fx 'DEPOS_BRANCH=depos/bump-deps/latest' "$case_dir/github-env" >/dev/null
grep -Fx 'DEPOS_BRANCH_IS_DEFAULT=true' "$case_dir/github-env" >/dev/null
grep -Fx 'DEPOS_BASE=main' "$case_dir/github-env" >/dev/null
grep -Fx 'DEPOS_PACKAGEDEF=fixtures/packagedef' "$case_dir/github-env" >/dev/null
grep -Fx "DEPOS_REPORT_PATH=$case_dir/runner-temp/depos-packages.json" "$case_dir/github-env" >/dev/null

run_prepare minor packagedef 'automation/dependencies'
grep -Fx 'DEPOS_BRANCH=automation/dependencies' "$case_dir/github-env" >/dev/null
grep -Fx 'DEPOS_BRANCH_IS_DEFAULT=false' "$case_dir/github-env" >/dev/null

run_prepare patch packagedef '' develop
grep -Fx 'DEPOS_BASE=develop' "$case_dir/github-env" >/dev/null
grep -Fx 'DEPOS_BRANCH=depos/bump-deps/patch/develop' "$case_dir/github-env" >/dev/null

if run_prepare invalid packagedef ''; then
  echo 'Принято недопустимое значение target' >&2
  exit 1
fi

if run_prepare latest '../packagedef' ''; then
  echo 'Принят путь с выходом в родительский каталог' >&2
  exit 1
fi

if run_prepare latest $'packagedef\nDEPOS_BASE=attacker' ''; then
  echo 'Принят путь с переводом строки' >&2
  exit 1
fi

if run_prepare latest packagedef 'invalid branch'; then
  echo 'Принято недопустимое имя ветки' >&2
  exit 1
fi

if run_prepare latest packagedef '' 'invalid base'; then
  echo 'Принято недопустимое имя базовой ветки' >&2
  exit 1
fi

echo 'ПРОЙДЕНО: сценарии подготовки входных параметров'
