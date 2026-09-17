#!/bin/bash
# Lista as skills disponíveis no catálogo orion-claudecode-skills (nome +
# description, lidos do frontmatter de cada SKILL.md).
set -e

REPO_URL="${1:-https://github.com/andifilhohub/orion-claudecode-skills.git}"
CACHE_DIR="$HOME/orion/claudecode-skills"

echo "→ Sincronizando catálogo de skills..."
if [[ ! -d "$CACHE_DIR" ]]; then
  git clone "$REPO_URL" "$CACHE_DIR"
else
  git -C "$CACHE_DIR" fetch origin
  git -C "$CACHE_DIR" checkout main
  git -C "$CACHE_DIR" pull origin main
fi

SRC_SKILLS_DIR="$CACHE_DIR/skills"
if [[ ! -d "$SRC_SKILLS_DIR" ]]; then
  echo "✗ Diretório skills/ não encontrado em $REPO_URL"
  exit 1
fi

echo ""
echo "Skills disponíveis:"
echo ""

COUNT=0
for skill_dir in "$SRC_SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  dir_name=$(basename "$skill_dir")
  skill_md="${skill_dir}SKILL.md"

  if [[ -f "$skill_md" ]]; then
    name=$(sed -n 's/^name: *//p' "$skill_md" | head -1)
    description=$(sed -n 's/^description: *//p' "$skill_md" | head -1)
    [[ -z "$name" ]] && name="$dir_name"
    [[ -z "$description" ]] && description="(sem description no SKILL.md)"
  else
    name="$dir_name"
    description="(sem SKILL.md)"
  fi

  printf "  • %s\n    %s\n\n" "$name" "$description"
  COUNT=$((COUNT + 1))
done

echo "$COUNT skill(s) no catálogo."
echo ""
echo "Instalar uma ou algumas: orion install skills <global|project> --only <nome1,nome2>"
echo "Instalar todas:          orion install skills <global|project>"
