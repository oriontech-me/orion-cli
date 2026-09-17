#!/bin/bash
# Lista as skills disponíveis no catálogo orion-claudecode-skills: nome +
# breve descrição, uma por linha.
set -e

REPO_URL="${1:-https://github.com/oriontech-me/orion-claudecode-skills.git}"
CACHE_DIR="$HOME/orion/claudecode-skills"
MAX_DESC=80

if [[ ! -d "$CACHE_DIR" ]]; then
  git clone -q "$REPO_URL" "$CACHE_DIR"
else
  git -C "$CACHE_DIR" fetch -q origin
  git -C "$CACHE_DIR" checkout -q main
  git -C "$CACHE_DIR" pull -q origin main
fi

SRC_SKILLS_DIR="$CACHE_DIR/skills"
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
    description=$(sed -n 's/^description: *//p' "$skill_md" | head -1)
    [[ -z "$name" ]] && name="$dir_name"
    [[ -z "$description" ]] && description="(sem description)"
  else
    name="$dir_name"
    description="(sem SKILL.md)"
  fi

  if [[ ${#description} -gt $MAX_DESC ]]; then
    description="${description:0:$((MAX_DESC - 1))}…"
  fi

  printf "%-22s %s\n" "$name" "$description"
done
