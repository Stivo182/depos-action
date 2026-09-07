#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$script_dir/common.sh"

: "${DEPOS_BRANCH:?Переменная DEPOS_BRANCH обязательна}"
: "${DEPOS_BRANCH_IS_DEFAULT:?Переменная DEPOS_BRANCH_IS_DEFAULT обязательна}"
: "${DEPOS_BASE:?Переменная DEPOS_BASE обязательна}"
: "${GH_REPO:?Переменная GH_REPO обязательна}"

pr_match=$(gh pr list \
  --head "$DEPOS_BRANCH" \
  --base "$DEPOS_BASE" \
  --state open \
  --json number,body \
  --jq "
    (map(select((.body // \"\") | contains(\"${DEPOS_MANAGED_MARKER}\"))) | .[0].number // null) as \$managed
    | if \$managed != null then \"managed:\(\$managed)\"
      elif length > 0 then \"unmanaged\"
      else \"\"
      end")

if [[ "$pr_match" == managed:* ]]; then
  pr_number="${pr_match#managed:}"
  gh pr close "$pr_number" \
    --comment "Закрыт автоматически, так как обновления в packagedef отсутствуют или уже применены." \
    --delete-branch
  exit 0
fi

if [[ "$pr_match" == "unmanaged" ]]; then
  echo "Ветка ${DEPOS_BRANCH} оставлена без изменений: открытый Pull Request не содержит маркер depos-action."
  exit 0
fi

if [[ "$DEPOS_BRANCH_IS_DEFAULT" != "true" ]]; then
  echo "Пользовательская ветка ${DEPOS_BRANCH} оставлена без изменений: управляемый Pull Request не найден."
  exit 0
fi

if ! branch_refs=$(gh api \
    "repos/${GH_REPO}/git/matching-refs/heads/${DEPOS_BRANCH}" \
    --paginate \
    --jq '.[].ref'); then
  echo "::error title=Ошибка очистки::Не удалось проверить существование ветки ${DEPOS_BRANCH}."
  exit 1
fi

if grep -Fx "refs/heads/${DEPOS_BRANCH}" <<< "$branch_refs" >/dev/null; then
  gh api -X DELETE "repos/${GH_REPO}/git/refs/heads/${DEPOS_BRANCH}"
fi
