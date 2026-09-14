#!/bin/bash
# Instala/atualiza a biblioteca de skills do Claude Code padronizadas pela Orion.
#
# Além das skills, sincroniza (sem nunca apagar o que já existe):
#   - CLAUDE.md      -> mescla um bloco delimitado por marcadores; conteúdo do
#                        usuário fora dos marcadores nunca é tocado.
#   - settings.json  -> deep-merge aditivo via jq: chaves/valores que já
#                        existem no arquivo do usuário são preservados;
#                        arrays recebem apenas os itens novos (sem duplicar).
set -e

SCOPE=$1
REPO_URL="${2:-https://github.com/andifilhohub/orion-claudecode-skills.git}"

if [[ "$SCOPE" != "global" && "$SCOPE" != "project" ]]; then
  echo "Uso: orion skills install <global|project> [repo_url]"
  echo "  global  -> instala em ~/.claude (vale para qualquer projeto)"
  echo "  project -> instala em ./.claude e ./CLAUDE.md (vale só para o repositório atual)"
  exit 1
fi

CLAUDE_MD_BEGIN="<!-- orion-skills:begin (gerenciado por orion-claudecode-skills, não edite manualmente entre estas marcações) -->"
CLAUDE_MD_END="<!-- orion-skills:end -->"

merge_claude_md() {
  local src="$1" target="$2"
  mkdir -p "$(dirname "$target")"
  touch "$target"

  if grep -qF "$CLAUDE_MD_BEGIN" "$target"; then
    awk -v begin="$CLAUDE_MD_BEGIN" -v end="$CLAUDE_MD_END" -v srcfile="$src" '
      $0 == begin { print; while ((getline line < srcfile) > 0) print line; skip=1; next }
      $0 == end { print; skip=0; next }
      skip { next }
      { print }
    ' "$target" > "$target.orion.tmp"
    mv "$target.orion.tmp" "$target"
  else
    {
      [ -s "$target" ] && echo ""
      echo "$CLAUDE_MD_BEGIN"
      cat "$src"
      echo "$CLAUDE_MD_END"
    } >> "$target"
  fi
}

merge_settings_json() {
  local src="$1" target="$2"
  mkdir -p "$(dirname "$target")"

  if [[ ! -f "$target" ]]; then
    cp "$src" "$target"
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "⚠ jq não encontrado — pulando merge de settings.json (instale com: brew install jq)"
    return
  fi

  jq -n --slurpfile base "$target" --slurpfile overlay "$src" '
    def deepmerge(base; overlay):
      if (base|type) == "object" and (overlay|type) == "object" then
        reduce (overlay|keys_unsorted[]) as $k (base;
          if (base|has($k)) then .[$k] = deepmerge(base[$k]; overlay[$k])
          else .[$k] = overlay[$k]
          end)
      elif (base|type) == "array" and (overlay|type) == "array" then
        base + (overlay - base)
      else
        base
      end;
    deepmerge($base[0]; $overlay[0])
  ' > "$target.orion.tmp"
  mv "$target.orion.tmp" "$target"
}

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

if [[ "$SCOPE" == "global" ]]; then
  SKILLS_TARGET_DIR="$HOME/.claude/skills"
  CLAUDE_MD_TARGET="$HOME/.claude/CLAUDE.md"
  SETTINGS_TARGET="$HOME/.claude/settings.json"
else
  if [[ ! -d ".git" ]]; then
    echo "✗ 'project' precisa ser rodado na raiz de um repositório git."
    exit 1
  fi
  SKILLS_TARGET_DIR="$(pwd)/.claude/skills"
  CLAUDE_MD_TARGET="$(pwd)/CLAUDE.md"
  SETTINGS_TARGET="$(pwd)/.claude/settings.json"
fi

mkdir -p "$SKILLS_TARGET_DIR"

echo "→ Instalando skills em: $SKILLS_TARGET_DIR"
COUNT=0
for skill_dir in "$SRC_SKILLS_DIR"/*/; do
  name=$(basename "$skill_dir")
  rm -rf "${SKILLS_TARGET_DIR:?}/$name"
  cp -r "$skill_dir" "$SKILLS_TARGET_DIR/$name"
  COUNT=$((COUNT + 1))
  echo "  ✔ $name"
done
echo "✔ $COUNT skill(s) instalada(s)/atualizada(s)"

CLAUDE_MD_SRC="$CACHE_DIR/claude/CLAUDE.md"
if [[ -f "$CLAUDE_MD_SRC" ]]; then
  echo "→ Mesclando CLAUDE.md em: $CLAUDE_MD_TARGET"
  merge_claude_md "$CLAUDE_MD_SRC" "$CLAUDE_MD_TARGET"
fi

SETTINGS_SRC="$CACHE_DIR/claude/settings.json"
if [[ -f "$SETTINGS_SRC" ]]; then
  echo "→ Mesclando settings.json em: $SETTINGS_TARGET"
  merge_settings_json "$SETTINGS_SRC" "$SETTINGS_TARGET"
fi

echo ""
echo "✔ Instalação concluída."
