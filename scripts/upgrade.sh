#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$script_dir/common.sh"

package_def="${PACKAGEDEF:-packagedef}"
filter="${FILTER:-}"
target="${TARGET:-latest}"
depos_version="${DEPOS_VERSION:-}"
if [[ -z "$depos_version" ]]; then
  version_file="$script_dir/../.depos-version"
  if [[ ! -f "$version_file" ]]; then
    echo "::error title=Не найдена версия depos::Отсутствует файл ${version_file}."
    exit 1
  fi
  depos_version="$(<"$version_file")"
fi

if [[ -z "$depos_version" || "$depos_version" == *$'\n'* || "$depos_version" == *$'\r'* ]]; then
  echo "::error title=Некорректная версия depos::Версия должна быть указана одной непустой строкой."
  exit 1
fi
output="${OUTPUT:-}"
min_opm_version="${MIN_OPM_VERSION:-1.3.0}"

version_ge() {
  local left="$1"
  local right="$2"
  local -a left_parts right_parts
  local i l r

  IFS='.' read -r -a left_parts <<< "$left"
  IFS='.' read -r -a right_parts <<< "$right"

  for i in 0 1 2; do
    l="${left_parts[$i]:-0}"
    r="${right_parts[$i]:-0}"

    if (( 10#$l > 10#$r )); then
      return 0
    fi
    if (( 10#$l < 10#$r )); then
      return 1
    fi
  done

  return 0
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

validate_target "$target"

if ! opm_command=$(resolve_command opm); then
  echo "::error title=Не найден opm::otymko/setup-onescript должен установить opm перед запуском depos-action."
  exit 1
fi

current_opm_version="$("$opm_command" -v 2>&1 | grep -Eo '[0-9]+[.][0-9]+[.][0-9]+' | head -n1 || true)"
if [[ -z "$current_opm_version" ]] || ! version_ge "$current_opm_version" "$min_opm_version"; then
  echo "Обновление opm до версии ${min_opm_version} или новее..."
  "$opm_command" install opm
  hash -r
fi

"$opm_command" install "depos@${depos_version}"

if ! depos_command=$(resolve_command depos); then
  echo "::error title=Не найден depos::opm не создал команду depos после установки пакета."
  exit 1
fi

cmd=("$depos_command" upgrade)

if [[ -n "$package_def" ]]; then
  cmd+=(--manifest "$package_def")
fi

if [[ -n "$filter" ]]; then
  cmd+=(--filter "$filter")
fi

cmd+=(--target "$target")

if [[ -n "$output" ]]; then
  output_arg="$output"
  if [[ "${RUNNER_OS:-}" == "Windows" ]] && command -v cygpath >/dev/null 2>&1; then
    output_arg="$(cygpath -w "$output")"
  fi
  cmd+=(--output "$output_arg")
fi

"${cmd[@]}"
