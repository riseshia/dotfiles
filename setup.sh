#!/usr/bin/env bash
set -e

DOTDIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname)" in
  Darwin) arch=mac ;;
  *)      arch=linux ;;
esac

# Directories
mkdir -p ~/bin ~/.config ~/.dotfiles ~/.config/nvim ~/.config/mise ~/.local/bin

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
  sudo apt install -y bash shellcheck git tmux
fi

# Symlinks: files
ln -sf "$DOTDIR/config/.dotbash" ~/.dotfiles/.dotbash
ln -sf "$DOTDIR/config/.tmux.conf" ~/.tmux.conf
ln -sf "$DOTDIR/config/.gitignore" ~/.gitignore
ln -sf "$DOTDIR/config/.starship.toml" ~/.config/starship.toml
ln -sf "$DOTDIR/config/mise.toml" ~/.config/mise/config.toml
ln -sf "$DOTDIR/config/.default-gems" ~/.default-gems
ln -sf "$DOTDIR/config/.default-npm-packages" ~/.default-npm-packages

# Symlinks: directories
ln -snf "$DOTDIR/config/bash_profile.d" ~/.dotfiles/bash_profile.d
ln -snf "$DOTDIR/config/bash_commands" ~/.dotfiles/bash_commands
ln -snf "$DOTDIR/config/nvim" ~/.config/nvim
ln -snf "$DOTDIR/config/vim-colors" ~/.config/nvim/colors

# Bash profile
if ! grep -q '.dotbash' ~/.bash_profile 2>/dev/null; then
  echo "source \$HOME/.dotfiles/.dotbash" >> ~/.bash_profile
fi
if ! grep -q 'mise activate' ~/.bash_profile 2>/dev/null; then
  echo 'eval "$($HOME/.local/bin/mise activate bash)"' >> ~/.bash_profile
fi

# Git
git config --global core.excludesFile ~/.gitignore
git config --global core.editor vim
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

# Linux-only
if [ "$arch" = "linux" ]; then
  if [ ! -f ~/.local/bin/alp ]; then
    curl -fSL -o /tmp/alp_linux_amd64.tar.gz https://github.com/tkuchiki/alp/releases/download/v1.0.21/alp_linux_amd64.tar.gz
    tar xzf /tmp/alp_linux_amd64.tar.gz -C /tmp
    mv /tmp/alp ~/.local/bin/alp
    chmod +x ~/.local/bin/alp
  fi
fi
