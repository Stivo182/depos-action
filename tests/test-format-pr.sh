#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
format_script="$root_dir/scripts/format-pr.sh"
case_dir="$(mktemp -d)"
trap 'rm -rf -- "$case_dir"' EXIT

run_format() {
  : > "$case_dir/github-output"
  REPORT="$1" \
    MESSAGE_PREFIX="${2:-}" \
    GITHUB_OUTPUT="$case_dir/github-output" \
    bash "$format_script"
}

cat > "$case_dir/report.json" <<'JSON'
[
  {"packageName":"semver","minVersionBefore":"1.0.0","minVersionAfter":"1.1.0"},
  {"packageName":"autumn","minVersionBefore":"3.0.0","minVersionAfter":"3.1.0"},
  {"packageName":"oint","minVersionBefore":"1.0.0","minVersionAfter":"2.0.0"}
]
JSON

run_format "$case_dir/report.json" 'build(deps)'
grep -E '^title<<depos_[[:alnum:]_]+$' "$case_dir/github-output" >/dev/null
grep -Fx 'build(deps): Bump semver 1.0.0 → 1.1.0, autumn 3.0.0 → 3.1.0 and 1 more package' "$case_dir/github-output" >/dev/null
grep -F '<!-- depos-action: managed pull request -->' "$case_dir/github-output" >/dev/null
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
