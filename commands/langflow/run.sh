#!/bin/bash
set -e

MODE=$1
REF=$2

BASE_DIR="$HOME/orion"
PROJECT_DIR="$BASE_DIR/langflow"

if [[ -z "$MODE" ]]; then
  echo "Uso:"
  echo "  orion langflow run <branch>"
  echo "  orion langflow run pr <PR_NUMBER>"
  exit 1
fi

# Compatibilidade: se só passou 1 argumento, assume branch
if [[ -z "$REF" ]]; then
  REF="$MODE"
  MODE="branch"
fi

echo "➡ Preparando ambiente para Langflow ($MODE: $REF)..."

# -----------------------------------------------------------------------------
# 1. Dependências básicas
# -----------------------------------------------------------------------------
if ! command -v git >/dev/null 2>&1; then
  echo "→ Instalando git..."
  apt update && apt install -y git
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "→ Instalando curl..."
  apt update && apt install -y curl
fi

# -----------------------------------------------------------------------------
# 2. UV
# -----------------------------------------------------------------------------
if ! command -v uv >/dev/null 2>&1; then
  echo "→ Instalando uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

# -----------------------------------------------------------------------------
# 3. Python
# -----------------------------------------------------------------------------
if ! command -v python3 >/dev/null 2>&1; then
  echo "→ Instalando Python..."
  apt update && apt install -y python3 python3-venv python3-pip
fi

# -----------------------------------------------------------------------------
# 4. Node + npm
# -----------------------------------------------------------------------------
if ! command -v npm >/dev/null 2>&1; then
  echo "→ Instalando Node.js e npm..."
  apt update && apt install -y nodejs npm
fi

# -----------------------------------------------------------------------------
# 5. Clone Langflow
# -----------------------------------------------------------------------------
mkdir -p "$BASE_DIR"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "→ Clonando Langflow..."
  git clone https://github.com/langflow-ai/langflow.git "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

echo "→ Atualizando código..."
git fetch origin

if [[ "$MODE" == "pr" ]]; then
  PR_NUMBER="$REF"
  LOCAL_BRANCH="pr-$PR_NUMBER"

  echo "→ Rodando PR #$PR_NUMBER"

  git fetch origin "pull/$PR_NUMBER/head:$LOCAL_BRANCH"
  git checkout "$LOCAL_BRANCH"

else
  BRANCH="$REF"
  git checkout .
  git checkout "$BRANCH"
  git pull origin "$BRANCH"
fi

# -----------------------------------------------------------------------------
# 6. Python env
# -----------------------------------------------------------------------------
if [[ ! -d ".venv" ]]; then
  echo "→ Criando ambiente Python..."
  uv venv
fi

source .venv/bin/activate

echo "→ Instalando dependências Python..."
uv pip install -U -e ".[all]"

# -----------------------------------------------------------------------------
# 7. Frontend build
# -----------------------------------------------------------------------------
echo "→ Construindo frontend..."
cd src/frontend
npm ci
npm run build
cd ../..

# -----------------------------------------------------------------------------
# 8. Sync frontend → backend
# -----------------------------------------------------------------------------
BUILD_DIR=""
[ -d src/frontend/dist ]  && BUILD_DIR=src/frontend/dist
[ -d src/frontend/build ] && BUILD_DIR=src/frontend/build

TARGET=src/backend/base/langflow/frontend
mkdir -p "$TARGET"
rm -rf "$TARGET"/*
cp -r "$BUILD_DIR"/* "$TARGET"/

# -----------------------------------------------------------------------------
# 9. Run Langflow
# -----------------------------------------------------------------------------
echo ""
echo "✔ Ambiente pronto!"
echo "➡ Iniciando Langflow..."
echo ""

uv run langflow run --host 0.0.0.0 --port 7860 --env-file .env
