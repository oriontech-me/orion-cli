#!/bin/bash
# Desinstala a biblioteca de skills do Claude Code padronizadas pela Orion.
#
# Reverte exatamente o que 'orion install skills' fez, sem tocar em nada que
# não veio do catálogo:
#   - skills/       -> remove as pastas cujo nome existe no catálogo
#   - CLAUDE.md     -> remove só o bloco delimitado por marcadores
#   - settings.json -> remove só as chaves/itens de array que vieram do
#                       catálogo (deep-subtract); valores que já existiam
#                       antes nunca são tocados
set -e

SCOPE=$1

if [[ "$SCOPE" != "global" && "$SCOPE" != "project" ]]; then
  echo "Uso: orion uninstall skills <global|project>"
  echo "  global  -> remove de ~/.claude"
  echo "  project -> remove de ./.claude e ./CLAUDE.md"
  exit 1
fi

CLAUDE_MD_BEGIN="<!-- orion-skills:begin (gerenciado por orion-claudecode-skills, não edite manualmente entre estas marcações) -->"
CLAUDE_MD_END="<!-- orion-skills:end -->"

CACHE_DIR="$HOME/orion/claudecode-skills"
if [[ ! -d "$CACHE_DIR" ]]; then
  echo "✗ Catálogo não encontrado em $CACHE_DIR — nada parece ter sido instalado por aqui."
  exit 1
fi

SRC_SKILLS_DIR="$CACHE_DIR/skills"
CLAUDE_MD_SRC="$CACHE_DIR/claude/CLAUDE.md"
SETTINGS_SRC="$CACHE_DIR/claude/settings.json"

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

echo "→ Removendo skills do catálogo..."
COUNT=0
if [[ -d "$SRC_SKILLS_DIR" ]]; then
  for skill_dir in "$SRC_SKILLS_DIR"/*/; do
    name=$(basename "$skill_dir")
    if [[ -d "$SKILLS_TARGET_DIR/$name" ]]; then
      rm -rf "${SKILLS_TARGET_DIR:?}/$name"
      COUNT=$((COUNT + 1))
      echo "  ✔ removida: $name"
    fi
  done
fi
echo "✔ $COUNT skill(s) removida(s) de $SKILLS_TARGET_DIR"

if [[ -f "$CLAUDE_MD_TARGET" ]] && grep -qF "$CLAUDE_MD_BEGIN" "$CLAUDE_MD_TARGET"; then
  echo "→ Removendo bloco Orion de: $CLAUDE_MD_TARGET"
  awk -v begin="$CLAUDE_MD_BEGIN" -v end="$CLAUDE_MD_END" '
    $0 == begin { skip=1; next }
    $0 == end { skip=0; next }
    skip { next }
    { print }
  ' "$CLAUDE_MD_TARGET" > "$CLAUDE_MD_TARGET.orion.tmp"
  mv "$CLAUDE_MD_TARGET.orion.tmp" "$CLAUDE_MD_TARGET"
  echo "  ✔ bloco removido (resto do arquivo preservado)"
else
  echo "  – nenhum bloco Orion encontrado em $CLAUDE_MD_TARGET"
fi

if [[ -f "$SETTINGS_TARGET" && -f "$SETTINGS_SRC" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "⚠ jq não encontrado — pulando reversão de settings.json (instale com: brew install jq)"
  else
    echo "→ Revertendo settings.json em: $SETTINGS_TARGET"
    jq -n --slurpfile base "$SETTINGS_TARGET" --slurpfile overlay "$SETTINGS_SRC" '
      def subtract(base; overlay):
        if (base|type) == "object" and (overlay|type) == "object" then
          reduce (overlay|keys_unsorted[]) as $k (base;
            if (base|has($k)) then
              (base[$k]) as $bv | (overlay[$k]) as $ov |
              if ($bv|type) == "object" and ($ov|type) == "object" then
                .[$k] = subtract($bv; $ov)
              elif ($bv|type) == "array" and ($ov|type) == "array" then
                .[$k] = ($bv - $ov)
              else
                .
              end
            else . end)
        else base end;
      subtract($base[0]; $overlay[0])
    ' > "$SETTINGS_TARGET.orion.tmp"
    mv "$SETTINGS_TARGET.orion.tmp" "$SETTINGS_TARGET"
    echo "  ✔ itens de array adicionados pelo catálogo removidos (o resto do arquivo foi preservado)"
    echo "  ⚠ campos escalares que o catálogo definia não são removidos automaticamente (não dá pra saber com certeza se vieram do catálogo ou já existiam) — revise manualmente se precisar"
  fi
fi

echo ""
echo "✔ Desinstalação concluída."
