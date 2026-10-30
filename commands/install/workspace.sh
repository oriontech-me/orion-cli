#!/bin/bash
# Clona ou atualiza a pasta de trabalho de QA compartilhada pelo time
# (~/orion/qa-validation). É nela que cada pessoa abre o Claude Code para
# validar PRs, e onde o Sieve grava os aprendizados do time.
#
# Nunca mexe em trabalho local: se a pasta tiver alterações não commitadas
# (por exemplo, aprendizados novos do Sieve ainda não revisados), avisa e
# não atualiza.
set -e

REPO_URL="${1:-https://github.com/oriontech-me/qa-validation.git}"
WORKSPACE_DIR="$HOME/orion/qa-validation"

clone_failed() {
  echo "✗ Não foi possível clonar $REPO_URL."
  echo "  O repositório é privado. Configure o acesso uma vez e rode de novo:"
  echo "    gh auth login && gh auth setup-git"
  echo "  ou passe a URL SSH: orion install workspace git@github.com:oriontech-me/qa-validation.git"
  exit 1
}

echo "→ Pasta de trabalho de QA: $WORKSPACE_DIR"
if [[ ! -d "$WORKSPACE_DIR" ]]; then
  mkdir -p "$(dirname "$WORKSPACE_DIR")"
  git clone "$REPO_URL" "$WORKSPACE_DIR" || clone_failed
  echo "✔ Clonada."
elif [[ -n "$(git -C "$WORKSPACE_DIR" status --porcelain)" ]]; then
  echo "⚠ Há alterações não commitadas em $WORKSPACE_DIR — não atualizei."
  echo "  Revise o diff (git -C $WORKSPACE_DIR diff), commite ou descarte, e rode de novo."
  exit 0
else
  git -C "$WORKSPACE_DIR" pull --ff-only
  echo "✔ Atualizada."
fi

echo ""
echo "Próximos passos (uma vez por pessoa):"
echo "  1. cd $WORKSPACE_DIR && claude"
echo "  2. No Claude Code: /plugin marketplace add remark-so/sieve"
echo "                     /plugin install sieve@sieve"
echo "                     /sieve --attach"
