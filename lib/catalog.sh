#!/bin/bash
# Acesso ao catálogo de skills (oriontech-me/orion-claudecode-skills),
# compartilhado por `install skills`, `uninstall skills` e `list skills`.
#
# O clone em ~/orion/claudecode-skills é também a pasta de trabalho do time:
# nela se edita skills, se abre PR e o Sieve grava os aprendizados. Por isso
# o orion NUNCA troca de branch nem altera arquivos dela para instalar. Ele
# atualiza origin, extrai skills/ e claude/ de origin/main numa pasta
# temporária (CATALOG_SRC) e instala a partir dali.

CACHE_DIR="$HOME/orion/claudecode-skills"
CATALOG_URL_DEFAULT="https://github.com/oriontech-me/orion-claudecode-skills.git"
CATALOG_SRC=""

catalog_sync() {
  local repo_url="${1:-$CATALOG_URL_DEFAULT}"

  if [[ ! -d "$CACHE_DIR" ]]; then
    mkdir -p "$(dirname "$CACHE_DIR")"
    if ! git clone -q "$repo_url" "$CACHE_DIR"; then
      echo "✗ Não foi possível clonar $repo_url." >&2
      echo "  O catálogo é privado. Configure o acesso uma vez e rode de novo:" >&2
      echo "    gh auth login && gh auth setup-git" >&2
      echo "  ou passe a URL SSH do catálogo (git@github.com:oriontech-me/orion-claudecode-skills.git) como último argumento." >&2
      exit 1
    fi
  elif ! git -C "$CACHE_DIR" fetch -q origin; then
    echo "⚠ Não consegui atualizar o catálogo (sem rede ou sem acesso?). Usando a última versão baixada de origin/main." >&2
  fi

  if ! git -C "$CACHE_DIR" rev-parse -q --verify origin/main >/dev/null; then
    echo "✗ origin/main não encontrada em $CACHE_DIR." >&2
    exit 1
  fi

  CATALOG_SRC="$(mktemp -d)"
  trap 'rm -rf "$CATALOG_SRC"' EXIT
  if ! ( set -o pipefail; git -C "$CACHE_DIR" archive origin/main skills claude | tar -x -C "$CATALOG_SRC" ); then
    echo "✗ Não consegui extrair skills/ e claude/ de origin/main em $CACHE_DIR." >&2
    exit 1
  fi

  # Mantém a pasta de trabalho em dia só quando é seguro: main, sem alterações.
  if [[ "$(git -C "$CACHE_DIR" rev-parse --abbrev-ref HEAD)" == "main" && -z "$(git -C "$CACHE_DIR" status --porcelain)" ]]; then
    git -C "$CACHE_DIR" merge -q --ff-only origin/main || true
  else
    echo "ℹ $CACHE_DIR não foi atualizada (outra branch ou alterações pendentes). Usei origin/main; rode git pull ali quando quiser." >&2
  fi
}
