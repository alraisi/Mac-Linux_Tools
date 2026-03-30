#!/bin/bash

# ============================================================
#  Dev Tools GUI Installer for macOS
#  A beginner-friendly graphical installer using AppleScript dialogs
#  Tools: xcode cli, homebrew, git, nodejs, bun, python3, uv, docker, zsh
# ============================================================

# ---------- Helpers ----------
is_installed() { command -v "$1" &>/dev/null; }

SUCCEEDED=()
FAILED=()

show_dialog() {
  osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with title \"Dev Tools Installer\" with icon note" 2>/dev/null
}

show_error() {
  osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with title \"Dev Tools Installer\" with icon stop" 2>/dev/null
}

show_notification() {
  osascript -e "display notification \"$1\" with title \"Dev Tools Installer\" subtitle \"$2\"" 2>/dev/null
}

# ---------- OS Check ----------
if [[ "$(uname)" != "Darwin" ]]; then
  echo "ERROR: This script is for macOS only."
  exit 1
fi

MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)

if [[ "$MACOS_MAJOR" -lt 11 ]]; then
  show_error "This installer requires macOS 11 (Big Sur) or later.\n\nDetected: macOS $MACOS_VERSION"
  exit 1
fi

# ---------- Welcome ----------
WELCOME_RESULT=$(osascript -e '
  display dialog "Welcome to Dev Tools Installer for macOS!\n\nThis will help you install common development tools on your Mac.\n\nDetected: macOS '"$MACOS_VERSION"'" buttons {"Cancel", "Continue"} default button "Continue" with title "Dev Tools Installer" with icon note
' 2>/dev/null)

if [[ $? -ne 0 ]]; then exit 0; fi

# ---------- Tool Selection ----------
SELECTION=$(osascript -e '
  set toolList to {"Xcode CLI Tools", "Homebrew", "Git", "Node.js", "Bun", "Python 3", "uv", "Docker", "Zsh + Oh My Zsh"}
  set selectedTools to choose from list toolList with title "Select Tools" with prompt "Choose which tools to install:" default items {"Xcode CLI Tools", "Homebrew", "Git", "Node.js", "Bun", "Python 3", "uv", "Docker"} with multiple selections allowed
  if selectedTools is false then
    return "CANCELLED"
  end if
  set AppleScript'\''s text item delimiters to "|"
  return selectedTools as text
' 2>/dev/null)

if [[ "$SELECTION" == "CANCELLED" || -z "$SELECTION" ]]; then
  show_dialog "No tools selected. Exiting."
  exit 0
fi

# Parse selection into flags
INSTALL_XCODE=false; INSTALL_BREW=false; INSTALL_GIT=false; INSTALL_NODE=false
INSTALL_BUN=false; INSTALL_PYTHON=false; INSTALL_UV=false; INSTALL_DOCKER=false
INSTALL_ZSH=false

IFS='|' read -ra SELECTED <<< "$SELECTION"
for item in "${SELECTED[@]}"; do
  # Trim whitespace
  item=$(echo "$item" | xargs)
  case "$item" in
    "Xcode CLI Tools") INSTALL_XCODE=true ;;
    "Homebrew")        INSTALL_BREW=true ;;
    "Git")             INSTALL_GIT=true ;;
    "Node.js")         INSTALL_NODE=true ;;
    "Bun")             INSTALL_BUN=true ;;
    "Python 3")        INSTALL_PYTHON=true ;;
    "uv")              INSTALL_UV=true ;;
    "Docker")          INSTALL_DOCKER=true ;;
    "Zsh + Oh My Zsh") INSTALL_ZSH=true ;;
  esac
done

# Auto-include dependencies
if ($INSTALL_GIT || $INSTALL_NODE || $INSTALL_PYTHON || $INSTALL_DOCKER) && ! $INSTALL_BREW; then
  if ! is_installed brew; then
    INSTALL_BREW=true
    show_notification "Homebrew auto-added" "Required by selected tools"
  fi
fi

if $INSTALL_BREW && ! $INSTALL_XCODE; then
  if ! xcode-select -p &>/dev/null; then
    INSTALL_XCODE=true
    show_notification "Xcode CLI Tools auto-added" "Required by Homebrew"
  fi
fi

# Count total steps
TOTAL=0
$INSTALL_XCODE  && ((TOTAL++))
$INSTALL_BREW   && ((TOTAL++))
$INSTALL_GIT    && ((TOTAL++))
$INSTALL_NODE   && ((TOTAL++))
$INSTALL_BUN    && ((TOTAL++))
$INSTALL_PYTHON && ((TOTAL++))
$INSTALL_UV     && ((TOTAL++))
$INSTALL_DOCKER && ((TOTAL++))
$INSTALL_ZSH    && ((TOTAL++))

STEP=0

# ---------- Installation ----------

# --- Xcode CLI Tools ---
if $INSTALL_XCODE; then
  ((STEP++))
  show_notification "Step $STEP of $TOTAL" "Installing Xcode CLI Tools..."
  if xcode-select -p &>/dev/null; then
    SUCCEEDED+=("Xcode CLI Tools (already installed)")
  else
    xcode-select --install 2>/dev/null
    osascript -e '
      display dialog "Xcode Command Line Tools installation has been triggered.\n\nPlease complete the installation in the system dialog that appeared, then click OK to continue." buttons {"OK"} default button "OK" with title "Dev Tools Installer" with icon note
    ' 2>/dev/null
    if xcode-select -p &>/dev/null; then
      SUCCEEDED+=("Xcode CLI Tools")
    else
      FAILED+=("Xcode CLI Tools: installation may not have completed")
    fi
  fi
fi

# --- Homebrew ---
if $INSTALL_BREW; then
  ((STEP++))
  show_notification "Step $STEP of $TOTAL" "Installing Homebrew..."
  if is_installed brew; then
    SUCCEEDED+=("Homebrew (already installed)")
  else
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null 2>/dev/null; then
      ARCH=$(uname -m)
      if [[ "$ARCH" == "arm64" ]]; then
        BREW_PATH="/opt/homebrew/bin/brew"
        BREW_ENV_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'
      else
        BREW_PATH="/usr/local/bin/brew"
        BREW_ENV_LINE='eval "$(/usr/local/bin/brew shellenv)"'
      fi
      if [[ -f "$BREW_PATH" ]]; then
        eval "$("$BREW_PATH" shellenv)"
        echo "$BREW_ENV_LINE" >> "$HOME/.zprofile"
        echo "$BREW_ENV_LINE" >> "$HOME/.bash_profile"
      fi
      SUCCEEDED+=("Homebrew")
    else
      FAILED+=("Homebrew: installation failed")
    fi
  fi
  # Ensure brew is usable
  if is_installed brew; then
    eval "$(brew shellenv 2>/dev/null)" || true
  fi
fi

# --- Git ---
if $INSTALL_GIT; then
  ((STEP++))
  show_notification "Step $STEP of $TOTAL" "Installing Git..."
  if is_installed git && [[ "$(git --version)" != *"Apple"* ]]; then
    SUCCEEDED+=("Git (already installed)")
  else
    if brew install git 2>/dev/null; then
      SUCCEEDED+=("Git")
    else
      FAILED+=("Git: brew install failed")
    fi
  fi
fi

# --- Node.js ---
if $INSTALL_NODE; then
  ((STEP++))
  show_notification "Step $STEP of $TOTAL" "Installing Node.js..."
  if is_installed node; then
    SUCCEEDED+=("Node.js (already installed)")
  else
    if brew install node@lts 2>/dev/null || brew install node 2>/dev/null; then
      brew link --overwrite node 2>/dev/null || true
      SUCCEEDED+=("Node.js")
    else
      FAILED+=("Node.js: brew install failed")
    fi
  fi
fi

# --- Bun ---
if $INSTALL_BUN; then
  ((STEP++))
  show_notification "Step $STEP of $TOTAL" "Installing Bun..."
  if is_installed bun; then
    SUCCEEDED+=("Bun (already installed)")
  else
    if curl -fsSL https://bun.sh/install | bash 2>/dev/null; then
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"
      if ! grep -q '.bun/bin' "$HOME/.zprofile" 2>/dev/null; then
        echo 'export BUN_INSTALL="$HOME/.bun"' >> "$HOME/.zprofile"
        echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$HOME/.zprofile"
      fi
      if ! grep -q '.bun/bin' "$HOME/.bash_profile" 2>/dev/null; then
        echo 'export BUN_INSTALL="$HOME/.bun"' >> "$HOME/.bash_profile"
        echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$HOME/.bash_profile"
      fi
      SUCCEEDED+=("Bun")
    else
      FAILED+=("Bun: installation failed")
    fi
  fi
fi

# --- Python 3 ---
if $INSTALL_PYTHON; then
  ((STEP++))
  show_notification "Step $STEP of $TOTAL" "Installing Python 3..."
  if is_installed python3 && python3 --version &>/dev/null; then
    SUCCEEDED+=("Python 3 (already installed)")
  else
    if brew install python3 2>/dev/null; then
      SUCCEEDED+=("Python 3")
    else
      FAILED+=("Python 3: brew install failed")
    fi
  fi
fi

# --- uv ---
if $INSTALL_UV; then
  ((STEP++))
  show_notification "Step $STEP of $TOTAL" "Installing uv..."
  if is_installed uv; then
    SUCCEEDED+=("uv (already installed)")
  else
    if curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null; then
      export PATH="$HOME/.cargo/bin:$PATH"
      if ! grep -q '.cargo/bin' "$HOME/.zprofile" 2>/dev/null; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zprofile"
      fi
      if ! grep -q '.cargo/bin' "$HOME/.bash_profile" 2>/dev/null; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bash_profile"
      fi
      SUCCEEDED+=("uv")
    else
      FAILED+=("uv: installation failed")
    fi
  fi
fi

# --- Docker ---
if $INSTALL_DOCKER; then
  ((STEP++))
  show_notification "Step $STEP of $TOTAL" "Installing Docker Desktop..."
  if is_installed docker; then
    SUCCEEDED+=("Docker (already installed)")
  else
    if brew install --cask docker 2>/dev/null; then
      open /Applications/Docker.app 2>/dev/null
      show_notification "Docker Desktop" "Starting up — please complete first-time setup"
      SUCCEEDED+=("Docker")
    else
      FAILED+=("Docker: brew cask install failed")
    fi
  fi
fi

# --- Zsh + Oh My Zsh ---
if $INSTALL_ZSH; then
  ((STEP++))
  show_notification "Step $STEP of $TOTAL" "Installing Oh My Zsh..."
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    SUCCEEDED+=("Oh My Zsh (already installed)")
  else
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null; then
      SUCCEEDED+=("Oh My Zsh")
    else
      FAILED+=("Oh My Zsh: installation failed")
    fi
  fi
fi

# ---------- Summary ----------
SUMMARY=""

for item in "${SUCCEEDED[@]}"; do
  SUMMARY+="  ✔  $item\n"
done

for item in "${FAILED[@]}"; do
  SUMMARY+="  ✘  $item\n"
done

if [[ -z "$SUMMARY" ]]; then
  SUMMARY="All selected tools were already installed."
fi

SUMMARY+="\\nRestart your terminal to apply all PATH changes."

osascript -e "display dialog \"Installation Complete!\\n\\n${SUMMARY}\" buttons {\"OK\"} default button \"OK\" with title \"Dev Tools Installer\" with icon note" 2>/dev/null

exit 0
