#!/bin/bash
# Instala/atualiza a biblioteca de skills do Claude Code padronizadas pela Orion.
set -e

SCOPE=$1
REPO_URL="${2:-https://github.com/andifilhohub/orion-claudecode-skills.git}"

if [[ "$SCOPE" != "global" && "$SCOPE" != "project" ]]; then
  echo "Uso: orion skills install <global|project> [repo_url]"
  echo "  global  -> instala em ~/.claude/skills (vale para qualquer projeto)"
  echo "  project -> instala em ./.claude/skills (vale só para o repositório atual)"
  exit 1
fi

CACHE_DIR="$HOME/orion/claudecode-skills"

echo "→ Sincronizando catálogo de skills..."
if [[ ! -d "$CACHE_DIR" ]]; then
  git clone "$REPO_URL" "$CACHE_DIR"
else
  git -C "$CACHE_DIR" fetch origin
  git -C "$CACHE_DIR" checkout main
  git -C "$CACHE_DIR" pull origin main
fi

SRC_DIR="$CACHE_DIR/skills"
if [[ ! -d "$SRC_DIR" ]]; then
  echo "✗ Diretório skills/ não encontrado em $REPO_URL"
  exit 1
fi

if [[ "$SCOPE" == "global" ]]; then
  TARGET_DIR="$HOME/.claude/skills"
else
  if [[ ! -d ".git" ]]; then
    echo "✗ 'project' precisa ser rodado na raiz de um repositório git."
    exit 1
  fi
  TARGET_DIR="$(pwd)/.claude/skills"
fi

mkdir -p "$TARGET_DIR"

echo "→ Instalando em: $TARGET_DIR"
COUNT=0
for skill_dir in "$SRC_DIR"/*/; do
  name=$(basename "$skill_dir")
  rm -rf "${TARGET_DIR:?}/$name"
  cp -r "$skill_dir" "$TARGET_DIR/$name"
  COUNT=$((COUNT + 1))
  echo "  ✔ $name"
done

echo ""
echo "✔ $COUNT skill(s) instalada(s)/atualizada(s) em: $TARGET_DIR"
