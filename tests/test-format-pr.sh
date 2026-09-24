#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
format_script="$root_dir/scripts/format-pr.os"
case_dir="$(mktemp -d)"
trap 'rm -rf -- "$case_dir"' EXIT

show_diagnostics() {
  local exit_code="$?"

  echo "Проверка формирования Pull Request завершилась ошибкой на строке ${BASH_LINENO[0]}." >&2
  if [[ -f "$case_dir/github-output" ]]; then
    echo 'Содержимое GITHUB_OUTPUT:' >&2
    cat "$case_dir/github-output" >&2
  fi

  exit "$exit_code"
}

trap show_diagnostics ERR

run_format() {
  : > "$case_dir/github-output"
  REPORT="$1" \
    MESSAGE_PREFIX="${2:-}" \
    DEPOS_PACKAGEDEF='packagedef' \
    TARGET='latest' \
    GH_TOKEN='' \
    GITHUB_OUTPUT="$case_dir/github-output" \
    oscript "$format_script"
}

cat > "$case_dir/report.json" <<'JSON'
[
  {"packageName":"semver","minVersionBefore":"1.0.0","minVersionAfter":"1.1.0"},
  {"packageName":"autumn","minVersionBefore":"3.0.0","minVersionAfter":"3.1.0"},
  {"packageName":"oint","minVersionBefore":"1.0.0","minVersionAfter":"2.0.0"}
]
JSON

run_format "$case_dir/report.json" 'build(deps)'
grep -E $'^title<<depos_[[:alnum:]_]+\r?$' "$case_dir/github-output" >/dev/null
grep -F 'build(deps): Bump semver 1.0.0 → 1.1.0, autumn 3.0.0 → 3.1.0 and 1 more package' "$case_dir/github-output" >/dev/null
grep -F '<!-- depos-action: managed pull request -->' "$case_dir/github-output" >/dev/null
grep -F '| Dependency | Update | Type | Links |' "$case_dir/github-output" >/dev/null
# Markdown-разметка проверяется как буквальный текст.
# shellcheck disable=SC2016
grep -F '| [oint](https://github.com/oscript-library/oint) | `1.0.0` → `2.0.0` | ⚠️ major |' "$case_dir/github-output" >/dev/null
grep -F '[Hub](https://hub.oscript.io/package/semver)' "$case_dir/github-output" >/dev/null
# HTML-разметка проверяется как буквальный текст.
# shellcheck disable=SC2016
grep -F '<sub>Created automatically by [depos-action](https://github.com/Stivo182/depos-action) · file _packagedef_</sub>' "$case_dir/github-output" >/dev/null
if grep -F 'body<<EOF' "$case_dir/github-output" >/dev/null; then
  echo 'Для тела Pull Request используется фиксированный разделитель EOF' >&2
  exit 1
fi

if run_format "$case_dir/report.json" $'build\ninjected=value'; then
  echo 'Многострочный префикс принят для формирования Pull Request' >&2
  exit 1
fi

printf '[]\n' > "$case_dir/empty.json"
if run_format "$case_dir/empty.json"; then
  echo 'Пустой отчёт принят для формирования Pull Request' >&2
  exit 1
fi

printf '{"packageName":"semver"}\n' > "$case_dir/object.json"
if run_format "$case_dir/object.json"; then
  echo 'Объект вместо массива принят для формирования Pull Request' >&2
  exit 1
fi

printf '[{"packageName":"semver"}]\n' > "$case_dir/incomplete.json"
if run_format "$case_dir/incomplete.json"; then
  echo 'Неполная запись отчёта принята для формирования Pull Request' >&2
  exit 1
fi

echo 'ПРОЙДЕНО: формирование Pull Request'
