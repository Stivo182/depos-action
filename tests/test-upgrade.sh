#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case_dir="$(mktemp -d)"
trap 'rm -rf -- "$case_dir"' EXIT
original_path="$PATH"

action_dir="$case_dir/action"
mkdir -p "$action_dir/scripts"
cp "$root_dir/scripts/upgrade.sh" "$root_dir/scripts/common.sh" "$action_dir/scripts/"
printf '9.8.7\n' > "$action_dir/.depos-version"
upgrade_script="$action_dir/scripts/upgrade.sh"

fake_bin="$case_dir/bin"
mkdir -p "$fake_bin"

cat > "$fake_bin/opm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'opm %s\n' "$*" >> "$CALL_LOG"
if [[ "${1:-}" == '-v' ]]; then
  printf '%s\n' "${FAKE_OPM_VERSION:-1.3.0}"
fi
SH

cat > "$fake_bin/depos" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'depos %s\n' "$*" >> "$CALL_LOG"
SH
chmod +x "$fake_bin/opm" "$fake_bin/depos"

windows_bin="$case_dir/windows-bin"
mkdir -p "$windows_bin"

cat > "$windows_bin/opm.bat" <<'SH'
: <<'BATCH'
@echo off
bash "%~f0" --bash %*
exit /b %errorlevel%
BATCH
if [[ "${1:-}" == '--bash' ]]; then
  shift
fi
printf 'opm %s\n' "$*" >> "$CALL_LOG"
if [[ "${1:-}" == '-v' ]]; then
  printf '1.3.0\n'
fi
SH

cat > "$windows_bin/depos.bat" <<'SH'
: <<'BATCH'
@echo off
bash "%~f0" --bash %*
exit /b %errorlevel%
BATCH
if [[ "${1:-}" == '--bash' ]]; then
  shift
fi
printf 'depos %s\n' "$*" >> "$CALL_LOG"
SH
chmod +x "$windows_bin/opm.bat" "$windows_bin/depos.bat"

export CALL_LOG="$case_dir/calls.log"
export PATH="$fake_bin:$PATH"
: > "$CALL_LOG"

PACKAGEDEF='fixtures/packagedef' \
  FILTER='autumn-*' \
  TARGET=minor \
  OUTPUT='report.json' \
  RUNNER_OS=Linux \
  bash "$upgrade_script"

grep -Fx 'opm install depos@9.8.7' "$CALL_LOG" >/dev/null || {
  echo 'Версия depos по умолчанию не прочитана из .depos-version' >&2
  exit 1
}
grep -Fx 'depos upgrade --manifest fixtures/packagedef --filter autumn-* --target minor --output report.json' "$CALL_LOG" >/dev/null

: > "$CALL_LOG"
DEPOS_VERSION=1.2.3 bash "$upgrade_script"
grep -Fx 'opm install depos@1.2.3' "$CALL_LOG" >/dev/null || {
  echo 'Параметр depos-version не переопределил закреплённую версию' >&2
  exit 1
}

: > "$CALL_LOG"
PATH="$windows_bin:$original_path" RUNNER_OS=Windows bash "$upgrade_script"
grep -Fx 'opm install depos@9.8.7' "$CALL_LOG" >/dev/null || {
  echo 'Windows-обёртка opm.bat не использована' >&2
  exit 1
}
grep -Fx 'depos upgrade --manifest packagedef --target latest' "$CALL_LOG" >/dev/null || {
  echo 'Windows-обёртка depos.bat не использована' >&2
  exit 1
}

: > "$CALL_LOG"
TARGET=major bash "$upgrade_script"
grep -Fx 'depos upgrade --manifest packagedef --target major' "$CALL_LOG" >/dev/null

echo 'ПРОЙДЕНО: запуск depos upgrade'
