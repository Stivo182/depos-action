#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$script_dir/common.sh"

: "${REPORT:?Переменная REPORT обязательна}"
: "${GITHUB_OUTPUT:?Переменная GITHUB_OUTPUT обязательна}"

if [[ ! -s "$REPORT" ]]; then
  echo "::error title=Отсутствует отчёт depos::Файл отчёта не создан или пуст: ${REPORT}"
  exit 1
fi

if ! jq -e '
  type == "array" and
  length > 0 and
  all(.[];
    (.packageName | type == "string" and length > 0) and
    (.minVersionBefore | type == "string" and length > 0) and
    (.minVersionAfter | type == "string" and length > 0)
  )
' "$REPORT" >/dev/null; then
  echo "::error title=Некорректный отчёт depos::Ожидался непустой массив обновлений с именами пакетов и версиями."
  exit 1
fi

if [[ "${MESSAGE_PREFIX:-}" == *$'\n'* || "${MESSAGE_PREFIX:-}" == *$'\r'* ]]; then
  echo "::error title=Некорректный message-prefix::Префикс не должен содержать переводы строк."
  exit 1
fi

write_output() {
  local name="$1"
  local value="$2"
  local delimiter="depos_${RANDOM}_${RANDOM}_${PPID}"

  while grep -Fqx "$delimiter" <<< "$value"; do
    delimiter="${delimiter}_x"
  done

  {
    printf '%s<<%s\n' "$name" "$delimiter"
    printf '%s\n' "$value"
    printf '%s\n' "$delimiter"
  } >> "$GITHUB_OUTPUT"
}

title=$(jq -r --arg prefix "${MESSAGE_PREFIX:-}" '
  (if $prefix != "" then $prefix + ": " else "" end) +
  "Bump " +
  (.[0:2]
    | map("\(.packageName) \(.minVersionBefore) → \(.minVersionAfter)")
    | join(", ")
  ) +
  (if length > 2
    then " and \(length - 2) more package" +
      (if length - 2 > 1 then "s" else "" end)
    else ""
  end)
' "$REPORT")

body="$DEPOS_MANAGED_MARKER"$'\n'"$(jq -r '
    .[]
    | "- **\(.packageName)**: \(.minVersionBefore) → \(.minVersionAfter)\n" +
      "([repo](https://github.com/oscript-library/\(.packageName)) · " +
      "[hub](https://hub.oscript.io/package/\(.packageName)))"
  ' "$REPORT")"

write_output title "$title"
write_output body "$body"
