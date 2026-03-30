# 🧰 Mac-Linux_Tools

> One script to rule them all, one script to find them, one script to install them all and in the terminal bind them.

You just got a fresh Mac or Ubuntu machine and you're ready to start vibe coding... but wait — you don't have Git. Or Node. Or Python. Or Docker. Or literally anything useful.

**Don't panic.** We got you.

This repo contains installer scripts that set up your entire dev environment in one go. No Googling "how to install homebrew" at 2 AM. No copy-pasting from 17 different Stack Overflow answers. Just run one script and go make a coffee ☕.

---

## 🤔 What Gets Installed?

| Tool | What It Does | Why You Need It |
|------|-------------|-----------------|
| **Git** | Version control | So you can blame other people for bugs |
| **Homebrew** | Package manager | The app store your terminal deserves |
| **Node.js** | JavaScript runtime | Because the world runs on JavaScript (sorry) |
| **Bun** | Fast JS runtime & bundler | Node.js but it had an energy drink |
| **Python 3** | Python interpreter | For AI, scripting, and pretending you're a data scientist |
| **uv** | Python package manager | pip but *fast* — like, stupidly fast |
| **Docker** | Container platform | "Works on my machine" → "Works on every machine" |
| **Zsh + Oh My Zsh** | Fancy shell | Makes your terminal look like a hacker movie (optional) |

---

## 🚀 Quick Start

### "I Know What a Terminal Is"

#### On macOS:

```bash
# 1. Open Terminal (press Cmd + Space, type "Terminal", hit Enter)
# 2. Run this:

git clone https://github.com/alraisi/Mac-Linux_Tools.git
cd Mac-Linux_Tools
chmod +x install_tools_macos.sh
./install_tools_macos.sh
```

#### On Ubuntu:

```bash
# 1. Open Terminal (press Ctrl + Alt + T)
# 2. Run this:

git clone https://github.com/alraisi/Mac-Linux_Tools.git
cd Mac-Linux_Tools
chmod +x install_tools.sh
./install_tools.sh
```

---

### "What's a Terminal?" (GUI Version)

No judgment. We made a version with buttons and checkboxes just for you. 💛

#### On macOS:

```bash
# 1. Open Terminal (press Cmd + Space, type "Terminal", hit Enter)
#    Yes, you still need the terminal for this one step. Life is cruel.

git clone https://github.com/alraisi/Mac-Linux_Tools.git
cd Mac-Linux_Tools
chmod +x install_tools_gui_macos.sh
./install_tools_gui_macos.sh
```

You'll get nice pop-up dialogs where you can pick what to install. Point. Click. Done.

#### On Ubuntu:

```bash
# 1. Open Terminal (press Ctrl + Alt + T)

git clone https://github.com/alraisi/Mac-Linux_Tools.git
cd Mac-Linux_Tools
chmod +x install_tools_gui_ubuntu.sh
./install_tools_gui_ubuntu.sh
```

A beautiful window with checkboxes will appear. Check the tools you want, hit OK, and watch the progress bar do its thing.

---

## 📁 What's in the Box?

```
Mac-Linux_Tools/
├── install_tools.sh              # CLI installer for Ubuntu
├── install_tools_macos.sh        # CLI installer for macOS
├── install_tools_gui_ubuntu.sh   # GUI installer for Ubuntu (Zenity)
├── install_tools_gui_macos.sh    # GUI installer for macOS (AppleScript)
└── README.md                     # You are here 👋
```

| Script | Platform | Interface | Best For |
|--------|----------|-----------|----------|
| `install_tools.sh` | Ubuntu 20.04+ | Terminal | People who wear hoodies and have strong opinions about text editors |
| `install_tools_macos.sh` | macOS 11+ | Terminal | Same people, but with a MacBook |
| `install_tools_gui_ubuntu.sh` | Ubuntu 20.04+ | GUI (Zenity) | People who prefer clicking things |
| `install_tools_gui_macos.sh` | macOS 11+ | GUI (AppleScript) | People who just want it to work |

---

## 🧠 FAQ (Frequently Anxious Questions)

**Q: Will this break my computer?**
A: No. Each tool checks if it's already installed before doing anything. It's like a polite houseguest that doesn't rearrange your furniture.

**Q: Do I need to install everything?**
A: Nope! The GUI version lets you pick and choose. The CLI version installs everything except Zsh (that one asks first, because we have boundaries).

**Q: I don't have Git yet. How do I `git clone`?**
A: Good catch, genius. Here's the workaround:

On **macOS**: The first time you run `git` in Terminal, macOS will offer to install Xcode Command Line Tools for you. Say yes, wait, then clone.

On **Ubuntu**:
```bash
sudo apt-get install -y git
```
Then clone. Or just download the ZIP from GitHub like it's 2010.

**Q: It says "Permission denied" when I run the script!**
A: You forgot the magic words:
```bash
chmod +x install_tools_macos.sh    # or whichever script
./install_tools_macos.sh
```

**Q: Something failed. What do I do?**
A: Don't cry. Check the summary at the end — it tells you exactly what worked and what didn't. Usually it's a network issue. Try again. If it keeps failing, [open an issue](https://github.com/alraisi/Mac-Linux_Tools/issues) and we'll help.

**Q: Can I run this on Windows?**
A: No. But you can install WSL (Windows Subsystem for Linux) and then run the Ubuntu script. Or just buy a Mac. (We're kidding. Mostly.)

---

## ⚙️ System Requirements

| Platform | Minimum Version |
|----------|----------------|
| **macOS** | 11.0 (Big Sur) or later |
| **Ubuntu** | 20.04 (Focal Fossa) or later |

**Docker Desktop on Ubuntu** additionally requires:
- x86_64 (amd64) architecture
- KVM virtualization support (check your BIOS)

---

## 🤝 Contributing

Found a bug? Want to add another tool? PRs are welcome!

Just please don't add Vim. We don't want people to get stuck and never leave.

---

## 📜 License

Do whatever you want with it. Seriously. Go wild. Install all the things.

---

*Built with ❤️ and way too much coffee by humans and Claude.*
