#!/bin/bash
# Lista as skills disponíveis no catálogo orion-claudecode-skills: nome +
# breve descrição, uma por linha.
set -e

REPO_URL="${1:-https://github.com/oriontech-me/orion-claudecode-skills.git}"
CACHE_DIR="$HOME/orion/claudecode-skills"
MAX_DESC=80

if [[ ! -d "$CACHE_DIR" ]]; then
  if ! git clone -q "$REPO_URL" "$CACHE_DIR"; then
    echo "✗ Não foi possível clonar $REPO_URL."
    echo "  O catálogo é privado. Configure o acesso uma vez: gh auth login && gh auth setup-git"
    exit 1
  fi
else
  if [[ -n "$(git -C "$CACHE_DIR" status --porcelain)" ]]; then
    echo "✗ $CACHE_DIR tem alterações não commitadas; commite ou descarte antes de listar."
    exit 1
  fi
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
