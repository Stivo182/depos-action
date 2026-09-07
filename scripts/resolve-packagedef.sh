#!/usr/bin/env bash
set -euo pipefail

: "${PACKAGEDEF:?Переменная PACKAGEDEF обязательна}"
: "${GITHUB_ENV:?Переменная GITHUB_ENV обязательна}"

resolved_path="$PACKAGEDEF"
if [[ -d "$resolved_path" ]]; then
  resolved_path="${resolved_path%/}/packagedef"
fi

if [[ ! -f "$resolved_path" ]]; then
  echo "::error title=Не найден packagedef::Файл не существует: ${resolved_path}"
  exit 1
fi

if [[ -L "$resolved_path" ]]; then
  echo "::error title=Недопустимый packagedef::Символическая ссылка не может использоваться как packagedef: ${resolved_path}"
  exit 1
fi

if ! git ls-files --error-unmatch -- "$resolved_path" >/dev/null 2>&1; then
  echo "::error title=Незарегистрированный packagedef::Файл должен находиться под контролем Git: ${resolved_path}"
  exit 1
fi

echo "DEPOS_PACKAGEDEF=${resolved_path}" >> "$GITHUB_ENV"
