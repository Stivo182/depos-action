#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$script_dir/test-cleanup-pr.sh"
bash "$script_dir/test-prepare.sh"
bash "$script_dir/test-resolve-packagedef.sh"
bash "$script_dir/test-format-pr.sh"
bash "$script_dir/test-upgrade.sh"
bash "$script_dir/test-workflow.sh"
bash "$script_dir/test-e2e-command.sh"
oneunit execute -d ./tests/onescript
