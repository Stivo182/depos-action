#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$root_dir/tests/test-common.sh"
resolve_script="$root_dir/scripts/resolve-packagedef.sh"
case_dir="$(mktemp -d)"
trap 'rm -rf -- "$case_dir"' EXIT

mkdir -p "$case_dir/project"
printf 'manifest\n' > "$case_dir/project/packagedef"
printf 'secret\n' > "$case_dir/project/secret.txt"
git -C "$case_dir" init -q
git -C "$case_dir" add project/packagedef

: > "$case_dir/github-env"
(
  cd "$case_dir"
  PACKAGEDEF=project GITHUB_ENV="$case_dir/github-env" bash "$resolve_script"
)
grep -Fx 'DEPOS_PACKAGEDEF=project/packagedef' "$case_dir/github-env" >/dev/null
if grep -F 'secret.txt' "$case_dir/github-env" >/dev/null; then
  echo 'Посторонний файл попал в разрешённый путь packagedef' >&2
  exit 1
fi

: > "$case_dir/github-env"
(
  cd "$case_dir"
  PACKAGEDEF=project/packagedef GITHUB_ENV="$case_dir/github-env" bash "$resolve_script"
)
grep -Fx 'DEPOS_PACKAGEDEF=project/packagedef' "$case_dir/github-env" >/dev/null

printf 'manifest\n' > "$case_dir/untracked-packagedef"
if (
  cd "$case_dir"
  PACKAGEDEF=untracked-packagedef GITHUB_ENV="$case_dir/github-env" bash "$resolve_script"
); then
  echo 'Принят незарегистрированный в Git файл packagedef' >&2
  exit 1
fi

printf 'manifest\n' > "$case_dir/symlink-target"
if ln -s symlink-target "$case_dir/symlink-packagedef" 2>/dev/null &&
    [[ -L "$case_dir/symlink-packagedef" ]]; then
  git -C "$case_dir" add symlink-packagedef
  if (
    cd "$case_dir"
    PACKAGEDEF=symlink-packagedef GITHUB_ENV="$case_dir/github-env" bash "$resolve_script"
  ); then
    echo 'Принята символическая ссылка вместо обычного файла packagedef' >&2
    exit 1
  fi
fi

echo 'ПРОЙДЕНО: определение точного файла packagedef'
