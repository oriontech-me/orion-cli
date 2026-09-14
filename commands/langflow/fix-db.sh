#!/bin/bash
# Corrige o erro "Multiple head revisions are present" do Alembic no Langflow.
set -e

PROJECT_DIR="${1:-$HOME/orion/langflow}"
ALEMBIC_INI="$PROJECT_DIR/src/backend/base/langflow/alembic.ini"
ALEMBIC_WORK_DIR="$PROJECT_DIR/src/backend/base/langflow"
ALEMBIC="$PROJECT_DIR/.venv/bin/alembic"

if [[ ! -f "$ALEMBIC_INI" ]]; then
  echo "[erro] alembic.ini não encontrado em $ALEMBIC_INI"
  echo "Uso: orion langflow fix-db [caminho-do-langflow]"
  exit 1
fi

if [[ ! -f "$ALEMBIC" ]]; then
  ALEMBIC="alembic"
fi

echo "[fix-db] Langflow: $PROJECT_DIR"
echo ""

cd "$ALEMBIC_WORK_DIR"

echo "[1/3] Heads atuais:"
"$ALEMBIC" heads || true

echo ""
echo "[2/3] Criando migração de merge..."
"$ALEMBIC" merge heads -m "merge_multiple_heads"

echo ""
echo "[3/3] Rodando upgrade para o head..."
"$ALEMBIC" upgrade head

echo ""
echo "[fix-db] Banco de dados atualizado com sucesso."
