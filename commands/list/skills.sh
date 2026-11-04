#!/bin/bash
# Lista as skills disponíveis no catálogo orion-claudecode-skills: nome +
# breve descrição, uma por linha.
set -e

REPO_URL="${1:-https://github.com/oriontech-me/orion-claudecode-skills.git}"
MAX_DESC=80

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/catalog.sh"
catalog_sync "$REPO_URL"

SRC_SKILLS_DIR="$CATALOG_SRC/skills"
if [[ ! -d "$SRC_SKILLS_DIR" ]]; then
  echo "✗ Diretório skills/ não encontrado em $REPO_URL"
  exit 1
fi

for skill_dir in "$SRC_SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  dir_name=$(basename "$skill_dir")
  skill_md="${skill_dir}SKILL.md"

  if [[ -f "$skill_md" ]]; then
    name=$(sed -n 's/^name: *//p' "$skill_md" | head -1)
    # Aceita description numa linha só ou em bloco YAML (">-", ">", "|", "|-").
    description=$(awk '
      /^description:/ {
        v = $0; sub(/^description:[ \t]*/, "", v)
        if (v ~ /^[>|]-?$/) { block = 1; v = ""; next }
        print v; exit
      }
      block && /^[ \t]+/ { l = $0; sub(/^[ \t]+/, "", l); v = (v == "" ? l : v " " l); next }
      block { print v; exit }
    ' "$skill_md")
    [[ -z "$name" ]] && name="$dir_name"
    [[ -z "$description" ]] && description="(sem description)"
  else
    name="$dir_name"
    description="(sem SKILL.md)"
  fi

  if [[ ${#description} -gt $MAX_DESC ]]; then
    description="${description:0:$((MAX_DESC - 1))}…"
  fi

  printf "%-26s %s\n" "$name" "$description"
done
