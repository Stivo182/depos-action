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

resolve_command() {
  local name="$1"
  local candidate extension

  if candidate=$(command -v "$name" 2>/dev/null); then
    printf '%s\n' "$candidate"
    return 0
  fi

  if [[ "${RUNNER_OS:-}" == "Windows" ]]; then
    for extension in .bat .cmd .exe; do
      if candidate=$(command -v "${name}${extension}" 2>/dev/null); then
        printf '%s\n' "$candidate"
        return 0
      fi
    done
  fi

  return 1
}
