#!/usr/bin/env bash

report_test_failure() {
  local exit_code="$1"
  local command="$2"
  local line="$3"

  echo "ОШИБКА: ${BASH_SOURCE[1]}:${line}: команда завершилась с кодом ${exit_code}: ${command}" >&2
  return "$exit_code"
}

trap 'report_test_failure "$?" "$BASH_COMMAND" "$LINENO"' ERR
