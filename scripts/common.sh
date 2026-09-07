#!/usr/bin/env bash

# Переменная используется скриптами, подключающими этот общий файл.
# shellcheck disable=SC2034
readonly DEPOS_MANAGED_MARKER='<!-- depos-action: managed pull request -->'

validate_target() {
  local target="$1"

  case "$target" in
    latest|minor|patch) ;;
    *)
      echo "::error title=Некорректный target::Допустимые значения: latest, minor, patch. Получено: ${target}"
      return 1
      ;;
  esac
}
