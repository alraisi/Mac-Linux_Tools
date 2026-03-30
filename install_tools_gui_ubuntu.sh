#!/bin/bash

# ============================================================
#  Dev Tools GUI Installer for Ubuntu 20.04+
#  A beginner-friendly graphical installer using Zenity
#  Tools: git, homebrew, nodejs, bun, python3, uv, docker desktop, zsh
# ============================================================

# ---------- Helpers ----------
is_installed() { command -v "$1" &>/dev/null; }

SUCCEEDED=()
FAILED=()

log_result() {
  local tool="$1" exit_code="$2" msg="$3"
  if [[ "$exit_code" -eq 0 ]]; then
    SUCCEEDED+=("$tool")
  else
    FAILED+=("$tool: $msg")
  fi
}

# ---------- Ensure zenity is available ----------
if ! is_installed zenity; then
  sudo apt-get install -y zenity 2>/dev/null
  if ! is_installed zenity; then
    echo "ERROR: Could not install zenity. Please install it manually: sudo apt-get install zenity"
    exit 1
  fi
fi

# ---------- OS Check ----------
. /etc/os-release 2>/dev/null
UBUNTU_VERSION="${VERSION_ID}"
MAJOR_VERSION=$(echo "$UBUNTU_VERSION" | cut -d. -f1)

if [[ "$ID" != "ubuntu" || "$MAJOR_VERSION" -lt 20 ]]; then
  zenity --error --title="Unsupported System" \
    --text="This installer requires Ubuntu 20.04 or later.\n\nDetected: ${PRETTY_NAME:-Unknown}" \
    --width=350
  exit 1
fi

# ---------- Welcome ----------
zenity --info --title="Dev Tools Installer for Ubuntu" \
  --text="Welcome!\n\nThis installer will help you set up your Ubuntu development environment with common tools.\n\nDetected: $PRETTY_NAME" \
  --width=420 --height=220

if [[ $? -ne 0 ]]; then exit 0; fi

# ---------- Tool Selection ----------
SELECTION=$(zenity --list --checklist \
  --title="Select Tools to Install" \
  --text="Choose which development tools to install:" \
  --column="Install" --column="Tool" --column="Description" \
  TRUE  "Git"             "Version control system" \
  TRUE  "Homebrew"        "Package manager for Linux" \
  TRUE  "Node.js"         "JavaScript runtime (LTS)" \
  TRUE  "Bun"             "Fast JavaScript runtime & bundler" \
  TRUE  "Python 3"        "Python interpreter & pip" \
  TRUE  "uv"              "Fast Python package manager" \
  TRUE  "Docker Desktop"  "Container platform (GUI + CLI)" \
  FALSE "Zsh + Oh My Zsh" "Enhanced shell with plugins" \
  --separator="|" --width=520 --height=420)

if [[ -z "$SELECTION" ]]; then
  zenity --info --title="Cancelled" --text="No tools selected. Exiting." --width=250
  exit 0
fi

# Parse selection into flags
INSTALL_GIT=false; INSTALL_BREW=false; INSTALL_NODE=false; INSTALL_BUN=false
INSTALL_PYTHON=false; INSTALL_UV=false; INSTALL_DOCKER=false; INSTALL_ZSH=false

IFS='|' read -ra SELECTED <<< "$SELECTION"
for item in "${SELECTED[@]}"; do
  case "$item" in
    "Git")             INSTALL_GIT=true ;;
    "Homebrew")        INSTALL_BREW=true ;;
    "Node.js")         INSTALL_NODE=true ;;
    "Bun")             INSTALL_BUN=true ;;
    "Python 3")        INSTALL_PYTHON=true ;;
    "uv")              INSTALL_UV=true ;;
    "Docker Desktop")  INSTALL_DOCKER=true ;;
    "Zsh + Oh My Zsh") INSTALL_ZSH=true ;;
  esac
done

# Count selected tools for progress calculation
TOTAL=0
$INSTALL_GIT    && ((TOTAL++))
$INSTALL_BREW   && ((TOTAL++))
$INSTALL_NODE   && ((TOTAL++))
$INSTALL_BUN    && ((TOTAL++))
$INSTALL_PYTHON && ((TOTAL++))
$INSTALL_UV     && ((TOTAL++))
$INSTALL_DOCKER && ((TOTAL++))
$INSTALL_ZSH    && ((TOTAL++))

# ---------- Sudo password upfront ----------
zenity --info --title="Administrator Access" \
  --text="Some tools require administrator (sudo) access.\nYou may be prompted for your password in the terminal." \
  --width=380 --height=150
sudo -v

# ---------- Installation with Progress ----------
STEP=0
calc_pct() { echo $(( (STEP * 100) / TOTAL )); }

(
  # --- apt update ---
  echo "# Updating package lists..."
  echo "2"
  sudo apt-get update -y &>/dev/null

  # --- Git ---
  if $INSTALL_GIT; then
    ((STEP++))
    echo "$(calc_pct)"
    echo "# Installing Git..."
    if is_installed git; then
      SUCCEEDED+=("Git (already installed)")
    else
      if sudo apt-get install -y git &>/dev/null; then
        SUCCEEDED+=("Git")
      else
        FAILED+=("Git: apt install failed")
      fi
    fi
  fi

  # --- Homebrew ---
  if $INSTALL_BREW; then
    ((STEP++))
    echo "$(calc_pct)"
    echo "# Installing Homebrew (this may take a few minutes)..."
    if is_installed brew; then
      SUCCEEDED+=("Homebrew (already installed)")
    else
      sudo apt-get install -y build-essential procps curl file &>/dev/null
      if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>/dev/null; then
        BREW_PREFIX="/home/linuxbrew/.linuxbrew"
        if [[ -d "$BREW_PREFIX" ]]; then
          eval "$("$BREW_PREFIX/bin/brew" shellenv)"
          echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> "$HOME/.bashrc"
          echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> "$HOME/.profile"
        fi
        SUCCEEDED+=("Homebrew")
      else
        FAILED+=("Homebrew: installation failed")
      fi
    fi
  fi

  # --- Node.js ---
  if $INSTALL_NODE; then
    ((STEP++))
    echo "$(calc_pct)"
    echo "# Installing Node.js (LTS)..."
    if is_installed node; then
      SUCCEEDED+=("Node.js (already installed)")
    else
      if curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - &>/dev/null && \
         sudo apt-get install -y nodejs &>/dev/null; then
        SUCCEEDED+=("Node.js")
      else
        FAILED+=("Node.js: installation failed")
      fi
    fi
  fi

  # --- Bun ---
  if $INSTALL_BUN; then
    ((STEP++))
    echo "$(calc_pct)"
    echo "# Installing Bun..."
    if is_installed bun; then
      SUCCEEDED+=("Bun (already installed)")
    else
      if curl -fsSL https://bun.sh/install | bash &>/dev/null; then
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        if ! grep -q '.bun/bin' "$HOME/.bashrc"; then
          echo 'export BUN_INSTALL="$HOME/.bun"' >> "$HOME/.bashrc"
          echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$HOME/.bashrc"
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
    echo "$(calc_pct)"
    echo "# Installing Python 3..."
    if is_installed python3; then
      SUCCEEDED+=("Python 3 (already installed)")
    else
      if sudo apt-get install -y python3 python3-pip python3-venv &>/dev/null; then
        SUCCEEDED+=("Python 3")
      else
        FAILED+=("Python 3: installation failed")
      fi
    fi
  fi

  # --- uv ---
  if $INSTALL_UV; then
    ((STEP++))
    echo "$(calc_pct)"
    echo "# Installing uv..."
    if is_installed uv; then
      SUCCEEDED+=("uv (already installed)")
    else
      if curl -LsSf https://astral.sh/uv/install.sh | sh &>/dev/null; then
        export PATH="$HOME/.cargo/bin:$PATH"
        if ! grep -q '.cargo/bin' "$HOME/.bashrc"; then
          echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
        fi
        SUCCEEDED+=("uv")
      else
        FAILED+=("uv: installation failed")
      fi
    fi
  fi

  # --- Docker Desktop ---
  if $INSTALL_DOCKER; then
    ((STEP++))
    echo "$(calc_pct)"
    echo "# Installing Docker Desktop (this may take several minutes)..."
    if is_installed docker && [[ -d "/opt/docker-desktop" ]]; then
      SUCCEEDED+=("Docker Desktop (already installed)")
    else
      ARCH=$(dpkg --print-architecture)
      if [[ "$ARCH" != "amd64" ]]; then
        FAILED+=("Docker Desktop: requires x86_64 (amd64), detected $ARCH")
      elif ! grep -q -E 'vmx|svm' /proc/cpuinfo; then
        FAILED+=("Docker Desktop: KVM virtualization not supported")
      else
        sudo apt-get install -y ca-certificates curl gnupg lsb-release \
          qemu-system-x86 qemu-utils pass uidmap &>/dev/null

        if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
          sudo apt-get install -y gnome-terminal &>/dev/null
        fi

        sudo apt-get install -y cpu-checker &>/dev/null
        sudo modprobe kvm &>/dev/null || true
        grep -q 'vendor_id.*Intel' /proc/cpuinfo && sudo modprobe kvm_intel 2>/dev/null || sudo modprobe kvm_amd 2>/dev/null
        sudo chmod 666 /dev/kvm 2>/dev/null || true

        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
          | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
          https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
          | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update -y &>/dev/null
        sudo apt-get install -y docker-ce-cli docker-compose-plugin &>/dev/null

        DOCKER_DEB="/tmp/docker-desktop.deb"
        curl -fsSL "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb" -o "$DOCKER_DEB" 2>/dev/null
        if sudo apt-get install -y "$DOCKER_DEB" &>/dev/null; then
          rm -f "$DOCKER_DEB"
          if [[ "$MAJOR_VERSION" -ge 24 ]]; then
            sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0 &>/dev/null
            echo 'kernel.apparmor_restrict_unprivileged_userns=0' \
              | sudo tee /etc/sysctl.d/99-docker-desktop.conf > /dev/null
          fi
          sudo usermod -aG docker "$USER"
          SUCCEEDED+=("Docker Desktop")
        else
          rm -f "$DOCKER_DEB"
          FAILED+=("Docker Desktop: .deb installation failed")
        fi
      fi
    fi
  fi

  # --- Zsh + Oh My Zsh ---
  if $INSTALL_ZSH; then
    ((STEP++))
    echo "$(calc_pct)"
    echo "# Installing Zsh + Oh My Zsh..."
    if is_installed zsh; then
      SUCCEEDED+=("Zsh (already installed)")
    else
      if sudo apt-get install -y zsh &>/dev/null; then
        SUCCEEDED+=("Zsh")
      else
        FAILED+=("Zsh: installation failed")
      fi
    fi

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
      SUCCEEDED+=("Oh My Zsh (already installed)")
    else
      if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &>/dev/null; then
        SUCCEEDED+=("Oh My Zsh")
      else
        FAILED+=("Oh My Zsh: installation failed")
      fi
    fi
  fi

  echo "100"
  echo "# Installation complete!"

  # Write results to temp files so the parent shell can read them
  printf '%s\n' "${SUCCEEDED[@]}" > /tmp/devtools_gui_ok.txt
  printf '%s\n' "${FAILED[@]}" > /tmp/devtools_gui_fail.txt

) | zenity --progress \
    --title="Installing Dev Tools" \
    --text="Preparing..." \
    --percentage=0 \
    --auto-close \
    --width=450 --height=150

# Check if user cancelled the progress dialog
if [[ $? -ne 0 ]]; then
  zenity --warning --title="Cancelled" --text="Installation was cancelled." --width=250
  rm -f /tmp/devtools_gui_ok.txt /tmp/devtools_gui_fail.txt
  exit 0
fi

# ---------- Summary ----------
SUMMARY=""

if [[ -f /tmp/devtools_gui_ok.txt ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && SUMMARY+="  ✔  $line\n"
  done < /tmp/devtools_gui_ok.txt
fi

if [[ -f /tmp/devtools_gui_fail.txt ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && SUMMARY+="  ✘  $line\n"
  done < /tmp/devtools_gui_fail.txt
fi

rm -f /tmp/devtools_gui_ok.txt /tmp/devtools_gui_fail.txt

if [[ -z "$SUMMARY" ]]; then
  SUMMARY="All selected tools were already installed."
fi

zenity --info --title="Installation Summary" \
  --text="$SUMMARY\n\nRestart your terminal to apply all PATH changes." \
  --width=480 --height=350

exit 0
