#!/bin/bash

# ============================================================
#  Dev Tools Installer for Ubuntu 20.04+
#  Tools: git, homebrew, nodejs, bun, python3, uv, docker desktop, zsh (optional)
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
banner "Ubuntu Version Check"
. /etc/os-release
UBUNTU_VERSION="${VERSION_ID}"
MAJOR_VERSION=$(echo "$UBUNTU_VERSION" | cut -d. -f1)

if [[ "$ID" != "ubuntu" || "$MAJOR_VERSION" -lt 20 ]]; then
  error "This script requires Ubuntu 20.04 or later. Detected: $PRETTY_NAME"
fi
success "Detected: $PRETTY_NAME — compatible!"

# ---------- Update apt ----------
banner "Updating apt"
sudo apt-get update -y && sudo apt-get upgrade -y
success "apt updated"

# ============================================================
# 1. GIT
# ============================================================
banner "1 / 8 — Git"
if is_installed git; then
  warn "git is already installed ($(git --version)) — skipping"
else
  sudo apt-get install -y git
  success "git installed: $(git --version)"
fi

# ============================================================
# 2. HOMEBREW
# ============================================================
banner "2 / 8 — Homebrew"
if is_installed brew; then
  warn "Homebrew is already installed — skipping"
else
  info "Installing Homebrew dependencies..."
  sudo apt-get install -y build-essential procps curl file
  info "Running Homebrew installer..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for current session and shell profile
  BREW_PREFIX="/home/linuxbrew/.linuxbrew"
  if [[ -d "$BREW_PREFIX" ]]; then
    eval "$("$BREW_PREFIX/bin/brew" shellenv)"
    echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> "$HOME/.bashrc"
    echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> "$HOME/.profile"
    success "Homebrew installed and added to PATH"
  else
    warn "Homebrew installed but path not found — you may need to add it manually"
  fi
fi

# ============================================================
# 3. NODE.JS (via NodeSource LTS)
# ============================================================
banner "3 / 8 — Node.js"
if is_installed node; then
  warn "Node.js is already installed ($(node --version)) — skipping"
else
  info "Adding NodeSource LTS repository..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
  success "Node.js installed: $(node --version) | npm: $(npm --version)"
fi

# ============================================================
# 4. BUN
# ============================================================
banner "4 / 8 — Bun"
if is_installed bun; then
  warn "Bun is already installed ($(bun --version)) — skipping"
else
  info "Installing Bun via official installer..."
  curl -fsSL https://bun.sh/install | bash

  # Add bun to PATH for current session
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  if ! grep -q '.bun/bin' "$HOME/.bashrc"; then
    echo 'export BUN_INSTALL="$HOME/.bun"' >> "$HOME/.bashrc"
    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$HOME/.bashrc"
  fi
  success "Bun installed: $(bun --version 2>/dev/null || echo 'installed — restart terminal to verify')"
fi

# ============================================================
# 5. PYTHON 3
# ============================================================
banner "5 / 8 — Python 3"
if is_installed python3; then
  warn "Python 3 is already installed ($(python3 --version)) — skipping"
else
  sudo apt-get install -y python3 python3-pip python3-venv
  success "Python 3 installed: $(python3 --version)"
fi

# ============================================================
# 6. UV (Python package manager by Astral)
# ============================================================
banner "6 / 8 — uv"
if is_installed uv; then
  warn "uv is already installed ($(uv --version)) — skipping"
else
  info "Installing uv via official installer..."
  curl -LsSf https://astral.sh/uv/install.sh | sh

  # Add uv to PATH for current session
  export PATH="$HOME/.cargo/bin:$PATH"
  if ! grep -q '.cargo/bin' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
  fi
  success "uv installed: $(uv --version)"
fi

# ============================================================
# 7. DOCKER DESKTOP (GUI + CLI)
# ============================================================
banner "7 / 8 — Docker Desktop (GUI + CLI)"

if is_installed docker && [[ -d "/opt/docker-desktop" ]]; then
  warn "Docker Desktop is already installed ($(docker --version)) — skipping"
else
  # --- 6a. Check architecture (Docker Desktop requires x86_64) ---
  ARCH=$(dpkg --print-architecture)
  if [[ "$ARCH" != "amd64" ]]; then
    error "Docker Desktop requires an x86_64 (amd64) system. Detected: $ARCH"
  fi

  # --- 6b. Check Ubuntu version (22.04 or 24.04 officially supported) ---
  if [[ "$MAJOR_VERSION" -lt 22 ]]; then
    warn "Docker Desktop officially supports Ubuntu 22.04+. You are on $PRETTY_NAME."
    warn "Proceeding, but you may encounter issues."
  fi

  # --- 6c. Install base dependencies ---
  info "Installing Docker Desktop dependencies..."
  sudo apt-get install -y ca-certificates curl gnupg lsb-release \
    qemu-system-x86 qemu-utils pass uidmap

  # --- 6d. Install gnome-terminal (required if not on GNOME desktop) ---
  if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
    info "Non-GNOME desktop detected — installing gnome-terminal (required by Docker Desktop)..."
    sudo apt-get install -y gnome-terminal
    success "gnome-terminal installed"
  else
    info "GNOME desktop detected — gnome-terminal not required, skipping"
  fi

  # --- 6e. Check and enable KVM virtualization ---
  info "Checking KVM virtualization support..."
  if ! grep -q -E 'vmx|svm' /proc/cpuinfo; then
    error "KVM virtualization not supported on this CPU. Docker Desktop requires KVM."
  fi

  sudo apt-get install -y cpu-checker
  if ! kvm-ok &>/dev/null; then
    error "KVM is not available. Please enable virtualization in your BIOS/UEFI settings."
  fi
  success "KVM virtualization is supported"

  # Load KVM kernel modules
  sudo modprobe kvm
  grep -q 'vendor_id.*Intel' /proc/cpuinfo && sudo modprobe kvm_intel || sudo modprobe kvm_amd
  sudo chmod 666 /dev/kvm
  info "KVM kernel modules loaded"

  # --- 6f. Add Docker's apt repository (provides docker-ce-cli dependency) ---
  info "Adding Docker's apt repository..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y docker-ce-cli docker-compose-plugin

  # --- 6g. Download and install Docker Desktop .deb package ---
  info "Downloading latest Docker Desktop .deb package..."
  DOCKER_DESKTOP_URL="https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb"
  DOCKER_DEB="/tmp/docker-desktop.deb"
  curl -fsSL "$DOCKER_DESKTOP_URL" -o "$DOCKER_DEB"

  info "Installing Docker Desktop..."
  sudo apt-get install -y "$DOCKER_DEB" || true  # apt shows a known harmless error, we ignore it
  rm -f "$DOCKER_DEB"

  # --- 6h. Enable unprivileged namespaces (required on Ubuntu 24.04+) ---
  if [[ "$MAJOR_VERSION" -ge 24 ]]; then
    info "Configuring unprivileged namespaces for Ubuntu 24.04+..."
    sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
    echo 'kernel.apparmor_restrict_unprivileged_userns=0' \
      | sudo tee /etc/sysctl.d/99-docker-desktop.conf > /dev/null
    success "Unprivileged namespaces configured"
  fi

  # --- 6i. Post-install: add user to docker group ---
  info "Adding current user to docker group..."
  sudo usermod -aG docker "$USER"

  success "Docker Desktop installed!"
  warn "NOTE: Launch Docker Desktop from your Applications menu or run: systemctl --user start docker-desktop"
  warn "NOTE: Log out and back in (or run 'newgrp docker') to use Docker CLI without sudo"
fi

# ============================================================
# 8. ZSH + OH MY ZSH (Optional)
# ============================================================
banner "8 / 8 — Zsh + Oh My Zsh (Optional)"
echo -e "${YELLOW}Would you like to install Zsh and Oh My Zsh?${NC}"
read -rp "Install Zsh + Oh My Zsh? [y/N]: " INSTALL_ZSH

if [[ "$INSTALL_ZSH" =~ ^[Yy]$ ]]; then
  if is_installed zsh; then
    warn "Zsh is already installed — skipping zsh install"
  else
    sudo apt-get install -y zsh
    success "Zsh installed: $(zsh --version)"
  fi

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    warn "Oh My Zsh is already installed — skipping"
  else
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    success "Oh My Zsh installed!"
    info "To set Zsh as your default shell, run: chsh -s \$(which zsh)"
  fi
else
  info "Skipping Zsh + Oh My Zsh installation"
fi

# ============================================================
# SUMMARY
# ============================================================
banner "Installation Summary"
tools=("git" "brew" "node" "bun" "python3" "uv" "docker" "zsh")
labels=("Git" "Homebrew" "Node.js" "Bun" "Python 3" "uv" "Docker" "Zsh")

for i in "${!tools[@]}"; do
  if is_installed "${tools[$i]}"; then
    echo -e "  ${GREEN}✔${NC}  ${labels[$i]}"
  else
    echo -e "  ${RED}✘${NC}  ${labels[$i]} (not found in PATH — may need a new shell session)"
  fi
done

echo -e "\n${BOLD}${GREEN}All done! Restart your terminal to apply all PATH changes.${NC}\n"
