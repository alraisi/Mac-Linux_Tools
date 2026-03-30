#!/bin/bash

# ============================================================
#  Dev Tools Installer for macOS
#  Tools: git, homebrew, nodejs, python3, uv, docker, zsh (optional)
# ============================================================

set -e

# ---------- Colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ---------- Helpers ----------
info()    { echo -e "${CYAN}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[SKIP]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
banner()  { echo -e "\n${BOLD}${CYAN}===== $1 =====${NC}\n"; }

is_installed() { command -v "$1" &>/dev/null; }

# ---------- OS Check ----------
banner "macOS Check"
if [[ "$(uname)" != "Darwin" ]]; then
  error "This script is for macOS only. Detected: $(uname)"
fi

MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)

if [[ "$MACOS_MAJOR" -lt 11 ]]; then
  error "This script requires macOS 11 (Big Sur) or later. Detected: $MACOS_VERSION"
fi
success "Detected: macOS $MACOS_VERSION — compatible!"

# ============================================================
# 1. XCODE COMMAND LINE TOOLS (required for git & more)
# ============================================================
banner "1 / 7 — Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  warn "Xcode Command Line Tools already installed — skipping"
else
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  info "A dialog box should appear. Please complete the installation, then press Enter to continue..."
  read -rp "Press Enter once Xcode CLT installation is complete..."
  success "Xcode Command Line Tools installed"
fi

# ============================================================
# 2. HOMEBREW
# ============================================================
banner "2 / 7 — Homebrew"
if is_installed brew; then
  warn "Homebrew is already installed — skipping"
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH depending on chip (Apple Silicon vs Intel)
  ARCH=$(uname -m)
  if [[ "$ARCH" == "arm64" ]]; then
    BREW_PATH="/opt/homebrew/bin/brew"
    BREW_ENV_LINE="eval \"\$(/opt/homebrew/bin/brew shellenv)\""
  else
    BREW_PATH="/usr/local/bin/brew"
    BREW_ENV_LINE="eval \"\$(/usr/local/bin/brew shellenv)\""
  fi

  if [[ -f "$BREW_PATH" ]]; then
    eval "$("$BREW_PATH" shellenv)"
    # Add to both .zprofile and .bash_profile
    echo "$BREW_ENV_LINE" >> "$HOME/.zprofile"
    echo "$BREW_ENV_LINE" >> "$HOME/.bash_profile"
    success "Homebrew installed and added to PATH"
  else
    warn "Homebrew installed but path not found — you may need to add it manually"
  fi
fi

# Make sure brew is usable for the rest of the script
if is_installed brew; then
  eval "$(brew shellenv 2>/dev/null)" || true
fi

# ============================================================
# 3. GIT
# ============================================================
banner "3 / 7 — Git"
if is_installed git && [[ "$(git --version)" != *"Apple"* ]]; then
  warn "git (non-Apple) is already installed ($(git --version)) — skipping"
else
  info "Installing git via Homebrew..."
  brew install git
  success "git installed: $(git --version)"
fi

# ============================================================
# 4. NODE.JS (LTS via Homebrew)
# ============================================================
banner "4 / 7 — Node.js"
if is_installed node; then
  warn "Node.js is already installed ($(node --version)) — skipping"
else
  info "Installing Node.js LTS via Homebrew..."
  brew install node@lts 2>/dev/null || brew install node
  # Link node if needed
  brew link --overwrite node 2>/dev/null || true
  success "Node.js installed: $(node --version) | npm: $(npm --version)"
fi

# ============================================================
# 5. PYTHON 3
# ============================================================
banner "5 / 7 — Python 3"
if is_installed python3 && python3 --version &>/dev/null; then
  warn "Python 3 is already installed ($(python3 --version)) — skipping"
else
  info "Installing Python 3 via Homebrew..."
  brew install python3
  success "Python 3 installed: $(python3 --version)"
fi

# ============================================================
# 6. UV (Python package manager by Astral)
# ============================================================
banner "6 / 7 — uv"
if is_installed uv; then
  warn "uv is already installed ($(uv --version)) — skipping"
else
  info "Installing uv via official installer..."
  curl -LsSf https://astral.sh/uv/install.sh | sh

  # Add uv to PATH for current session
  export PATH="$HOME/.cargo/bin:$PATH"
  if ! grep -q '.cargo/bin' "$HOME/.zprofile" 2>/dev/null; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zprofile"
  fi
  if ! grep -q '.cargo/bin' "$HOME/.bash_profile" 2>/dev/null; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bash_profile"
  fi
  success "uv installed: $(uv --version 2>/dev/null || echo 'installed — restart terminal to verify')"
fi

# ============================================================
# 7. DOCKER (Docker Desktop via Homebrew Cask)
# ============================================================
banner "7 / 7 — Docker"
if is_installed docker; then
  warn "Docker is already installed ($(docker --version)) — skipping"
else
  info "Installing Docker Desktop via Homebrew..."
  brew install --cask docker

  info "Launching Docker Desktop for first-time setup..."
  open /Applications/Docker.app

  info "Docker Desktop is starting up. It may take a minute to become ready."
  info "Waiting for Docker daemon..."
  for i in {1..30}; do
    if docker info &>/dev/null 2>&1; then
      break
    fi
    sleep 3
    echo -n "."
  done
  echo ""

  if is_installed docker; then
    success "Docker installed: $(docker --version)"
  else
    warn "Docker Desktop installed but daemon not yet ready — open Docker.app to finish setup"
  fi
fi

# ============================================================
# OPTIONAL — ZSH + OH MY ZSH
# ============================================================
banner "Optional — Zsh + Oh My Zsh"
echo -e "${YELLOW}Would you like to install Oh My Zsh?${NC}"
echo -e "${CYAN}(Note: Zsh is the default shell on macOS — Oh My Zsh adds themes & plugins)${NC}"
read -rp "Install Oh My Zsh? [y/N]: " INSTALL_ZSH

if [[ "$INSTALL_ZSH" =~ ^[Yy]$ ]]; then
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    warn "Oh My Zsh is already installed — skipping"
  else
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    success "Oh My Zsh installed!"
    info "Restart your terminal to start using Oh My Zsh"
  fi
else
  info "Skipping Oh My Zsh installation"
fi

# ============================================================
# SUMMARY
# ============================================================
banner "Installation Summary"

declare -A TOOL_LABELS=(
  ["git"]="Git"
  ["brew"]="Homebrew"
  ["node"]="Node.js"
  ["python3"]="Python 3"
  ["uv"]="uv"
  ["docker"]="Docker"
)

for tool in git brew node python3 uv docker; do
  if is_installed "$tool"; then
    echo -e "  ${GREEN}✔${NC}  ${TOOL_LABELS[$tool]}"
  else
    echo -e "  ${RED}✘${NC}  ${TOOL_LABELS[$tool]} (not found in PATH — may need a new shell session)"
  fi
done

# Oh My Zsh check
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo -e "  ${GREEN}✔${NC}  Oh My Zsh"
else
  echo -e "  ${YELLOW}-${NC}  Oh My Zsh (skipped)"
fi

echo -e "\n${BOLD}${GREEN}All done! Restart your terminal to apply all PATH changes.${NC}\n"
