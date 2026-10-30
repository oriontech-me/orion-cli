#!/bin/bash
set -e

echo "Instalando Orion CLI..."

# Detectar OS
UNAME=$(uname)

###############################################################################
# 1. MACOS SETUP
###############################################################################
if [ "$UNAME" = "Darwin" ]; then
  echo "→ Detected macOS"

  # Homebrew check
  if ! command -v brew >/dev/null 2>&1; then
    echo "→ Homebrew não encontrado. Instalando..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH automatically
    if [ -d "/opt/homebrew/bin" ]; then
      echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zprofile
      export PATH="/opt/homebrew/bin:$PATH"
    fi
  fi

  echo "→ Instalando dependências via brew..."
  brew install git node python uv || true

  # Diretório do CLI
  ORION_HOME="$HOME/orion-cli"
  rm -rf "$ORION_HOME"
  git clone https://github.com/oriontech-me/orion-cli.git "$ORION_HOME"

  # Link binário
  mkdir -p "$HOME/.local/bin"
  ln -sf "$ORION_HOME/bin/orion" "$HOME/.local/bin/orion"
  chmod +x "$ORION_HOME/bin/orion"

  # Garantir PATH
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zprofile
    export PATH="$HOME/.local/bin:$PATH"
  fi

  echo "✔ Orion CLI instalado no macOS!"
  echo "Execute: orion langflow run main"
  exit 0
fi

###############################################################################
# 2. LINUX SETUP
###############################################################################
echo "→ Detected Linux"

# Execução non-interactive
export DEBIAN_FRONTEND=noninteractive
export TZ=America/Sao_Paulo

apt-get update -y
apt-get install -y --no-install-recommends tzdata

echo "→ Instalando dependências no Linux..."
apt-get install -y git curl build-essential nodejs python3 python3-pip

# Diretório do CLI
ORION_HOME="$HOME/orion-cli"
rm -rf "$ORION_HOME"
git clone https://github.com/oriontech-me/orion-cli.git "$ORION_HOME"

# Criar link global
ln -sf "$ORION_HOME/bin/orion" /usr/local/bin/orion
chmod +x "$ORION_HOME/bin/orion"
chmod -R +x "$ORION_HOME/commands"

echo "✔ Orion CLI instalado no Linux!"
echo "Execute: orion langflow run main"
exit 0
