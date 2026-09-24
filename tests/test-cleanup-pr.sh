#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$root_dir/tests/test-common.sh"
fake_bin="$root_dir/tests/fakes"
cleanup_script="$root_dir/scripts/cleanup-pr.sh"
tests_run=0

fail() {
  echo "ОШИБКА: $*" >&2
  exit 1
}

assert_log_contains() {
  local expected="$1"
  grep -F -- "$expected" "$GH_CALL_LOG" >/dev/null ||
    fail "expected gh call containing: $expected"
}

assert_log_not_contains() {
  local unexpected="$1"
  if grep -F -- "$unexpected" "$GH_CALL_LOG" >/dev/null; then
    fail "unexpected gh call containing: $unexpected"
  fi
}

new_case() {
  case_dir="$(mktemp -d)"
  export GH_CALL_LOG="$case_dir/gh.log"
  : > "$GH_CALL_LOG"
  export PATH="$fake_bin:$ORIGINAL_PATH"
  unset GH_DEFAULT_PR_NUMBER GH_MANAGED_PR_NUMBER GH_PR_JSON GH_REF_EXISTS
  unset GH_PR_CLOSE_EXIT GH_DELETE_EXIT GH_REF_LIST_FAIL
}

run_cleanup() {
  DEPOS_BRANCH="$1" \
    DEPOS_BRANCH_IS_DEFAULT="$2" \
    DEPOS_BASE="${3:-main}" \
    GH_REPO="Stivo182/depos-action-e2e" \
    bash "$cleanup_script"
}

finish_case() {
  rm -rf -- "$case_dir"
  tests_run=$((tests_run + 1))
}

ORIGINAL_PATH="$PATH"
trap '[[ -z "${case_dir:-}" ]] || rm -rf -- "$case_dir"' EXIT

new_case
export GH_PR_JSON='[{"number":88,"body":"Создан вручную"}]'
export GH_REF_EXISTS=true
run_cleanup "depos/bump-deps/latest" true
assert_log_not_contains "pr close"
assert_log_not_contains "api -X DELETE"
finish_case

new_case
export GH_PR_JSON='[{"number":17,"body":"<!-- depos-action: managed pull request -->"}]'
run_cleanup "depos/bump-deps/latest" true
assert_log_contains "pr close 17"
assert_log_contains "--base main"
assert_log_not_contains "api -X DELETE"
finish_case

new_case
export GH_REF_EXISTS=true
run_cleanup "depos/bump-deps/latest" true
assert_log_contains "api repos/Stivo182/depos-action-e2e/git/matching-refs/heads/depos/bump-deps/latest --paginate"
assert_log_contains "api -X DELETE repos/Stivo182/depos-action-e2e/git/refs/heads/depos/bump-deps/latest"
finish_case

new_case
export GH_REF_LIST_FAIL=true
if run_cleanup "depos/bump-deps/latest" true; then
  fail "cleanup succeeded after branch lookup failed"
fi
assert_log_not_contains "api -X DELETE"
finish_case

new_case
export GH_MANAGED_PR_NUMBER=23
run_cleanup "automation/dependencies" false
assert_log_contains "managed pull request"
assert_log_contains "--base main"
assert_log_contains "pr close 23"
finish_case

new_case
export GH_MANAGED_PR_NUMBER=31
run_cleanup "automation/dependencies" false develop
assert_log_contains "--base develop"
assert_log_contains "pr close 31"
finish_case

new_case
export GH_DEFAULT_PR_NUMBER=99
run_cleanup "feature/existing" false
assert_log_contains "managed pull request"
assert_log_not_contains "pr close"
assert_log_not_contains "api -X DELETE"
finish_case

new_case
run_cleanup "release/existing" false
assert_log_not_contains "pr close"
assert_log_not_contains "api -X DELETE"
finish_case

new_case
export GH_MANAGED_PR_NUMBER=17
export GH_PR_CLOSE_EXIT=7
if run_cleanup "depos/bump-deps/latest" true; then
  fail "cleanup succeeded after gh pr close failed"
fi
assert_log_contains "pr close 17"
finish_case

echo "ПРОЙДЕНО: сценариев очистки - ${tests_run}"
