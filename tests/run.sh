#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_test() {
  local test_name="$1"
  shift

  if ! "$@"; then
    echo "ОШИБКА: тест не пройден: ${test_name}" >&2
    exit 1
  fi
}

run_test test-cleanup-pr bash "$script_dir/test-cleanup-pr.sh"
run_test test-prepare bash "$script_dir/test-prepare.sh"
run_test test-resolve-packagedef bash "$script_dir/test-resolve-packagedef.sh"
run_test test-format-pr bash "$script_dir/test-format-pr.sh"
run_test test-upgrade bash "$script_dir/test-upgrade.sh"
run_test test-workflow bash "$script_dir/test-workflow.sh"
run_test test-e2e-command bash "$script_dir/test-e2e-command.sh"
run_test onescript oneunit execute -d ./tests/onescript
