#!/usr/bin/env bash
set -e

DOTDIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname)" in
  Darwin) arch=mac ;;
  *)      arch=linux ;;
esac

# Directories
mkdir -p ~/bin ~/.config ~/.dotfiles ~/.config/mise ~/.local/bin ~/.claude

# Packages
if [ "$arch" = "mac" ]; then
  brew install bash shellcheck git tmux envchain

  BREW_BASH="$(brew --prefix)/bin/bash"
  if ! grep -q "$BREW_BASH" /etc/shells; then
    echo "$BREW_BASH" | sudo tee -a /etc/shells
  fi
  if [ "$SHELL" != "$BREW_BASH" ]; then
    chsh -s "$BREW_BASH"
  fi
else
  sudo apt install -y bash shellcheck git tmux unzip
fi

# Symlinks: files
ln -sf "$DOTDIR/bash/dotbash" ~/.dotfiles/.dotbash
ln -sf "$DOTDIR/tmux/tmux.conf" ~/.tmux.conf
ln -sf "$DOTDIR/misc/gitignore" ~/.gitignore
ln -sf "$DOTDIR/misc/starship.toml" ~/.config/starship.toml
ln -sf "$DOTDIR/misc/mise.toml" ~/.config/mise/config.toml
ln -sf "$DOTDIR/misc/default-gems" ~/.default-gems
ln -sf "$DOTDIR/misc/default-npm-packages" ~/.default-npm-packages
ln -sf "$DOTDIR/claude/CLAUDE.md" ~/.claude/CLAUDE.md

# Symlinks: directories
ln -snf "$DOTDIR/bash/profile.d" ~/.dotfiles/bash_profile.d
ln -snf "$DOTDIR/bash/commands" ~/.dotfiles/bash_commands
ln -snf "$DOTDIR/nvim" ~/.config/nvim

# Bash profile
if ! grep -q '.dotbash' ~/.bash_profile 2>/dev/null; then
  echo "source \$HOME/.dotfiles/.dotbash" >> ~/.bash_profile
fi
if ! grep -q 'mise activate' ~/.bash_profile 2>/dev/null; then
  echo 'eval "$($HOME/.local/bin/mise activate bash)"' >> ~/.bash_profile
fi

# Git
git config --global core.excludesFile ~/.gitignore
git config --global core.editor nvim
git config --global core.quotepath off
git config --global color.ui true
git config --global push.default simple
git config --global pull.rebase true
git config --global submodule.recurse true
git config --global init.defaultBranch main

# Neovim: packer.nvim
PACKER_DIR="$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
if [ ! -d "$PACKER_DIR" ]; then
  git clone https://github.com/wbthomason/packer.nvim.git "$PACKER_DIR"
fi

# Rust
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# z
Z_DIR="$HOME/repos/rupa/z"
if [ ! -d "$Z_DIR" ]; then
  mkdir -p "$HOME/repos/rupa"
  git clone https://github.com/rupa/z.git "$Z_DIR"
fi

# Claude Code plugins & MCP servers
if command -v claude >/dev/null 2>&1; then
  if ! claude plugin marketplace list | grep -q riseshia-dotfiles; then
    claude plugin marketplace add riseshia/dotfiles
  fi
  claude plugin install shia-guides@riseshia-dotfiles
  claude plugin install misc@riseshia-dotfiles

  # playwright-cli is npm-distributed (no longer a Claude plugin marketplace).
  # It installs skills into ./.claude/skills of the cwd, so run from $HOME
  # to land them in the user-level ~/.claude/skills.
  if command -v playwright-cli >/dev/null 2>&1; then
    (cd "$HOME" && playwright-cli install --skills)
  fi

  claude mcp get aws-knowledge-mcp-server >/dev/null 2>&1 || \
    claude mcp add -s user aws-knowledge-mcp-server -t http \
      https://knowledge-mcp.global.api.aws

  # Registers the skill-reminder hook in ~/.claude/settings.json.
  if command -v ruby >/dev/null 2>&1; then
    ruby "$DOTDIR/claude/update-settings.rb"
  fi
fi

# Linux-only
if [ "$arch" = "linux" ]; then
  # win32yank: UTF-8-safe clipboard for tmux on WSL (clip.exe mangles Korean)
  if grep -qi microsoft /proc/version && [ ! -f ~/.local/bin/win32yank.exe ]; then
    curl -fSL -o /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
    unzip -o /tmp/win32yank.zip win32yank.exe -d /tmp
    install -m 755 /tmp/win32yank.exe ~/.local/bin/win32yank.exe
  fi

  if [ ! -f ~/.local/bin/alp ]; then
    curl -fSL -o /tmp/alp_linux_amd64.tar.gz https://github.com/tkuchiki/alp/releases/download/v1.0.21/alp_linux_amd64.tar.gz
    tar xzf /tmp/alp_linux_amd64.tar.gz -C /tmp
    mv /tmp/alp ~/.local/bin/alp
    chmod +x ~/.local/bin/alp
  fi
fi
