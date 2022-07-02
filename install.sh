#!/bin/sh

set -e

if [ "$(uname)" = 'Darwin' ]; then
  # Start from brew install which check xcode command-line tool availability.
  # Ref: https://github.com/Homebrew/install/blob/dee8df98bfb65588007c666034c6e1ad0733b1b6/install.sh#L626-L633
  if ! command -v brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# Prepare dotfile repository
REPO_CLONE_DIR="$HOME/.dotfiles_src"
DEPLOY_DEST_DIR="$HOME/.dotfiles"

if [ ! -d "$REPO_CLONE_DIR" ]; then
  echo "'$REPO_CLONE_DIR' dir isn't exist."
  git clone https://github.com/riseshia/dotfiles.git "$REPO_CLONE_DIR"
else
  echo "'$REPO_CLONE_DIR' dir exist. Skip repository cloning. Instead, update dotfiles source."
  cd "$REPO_CLONE_DIR" && git fetch && git reset --hard origin/main
fi

if ! [ -h "$REPO_CLONE_DIR/bin/mitamae" ]; then
  echo "mitamae isn't installed. Let's install."
  "$REPO_CLONE_DIR/bin/setup_mitamae"
else
  echo "mitamae is already installed. Skip install."
fi

# Deploy dotfiles
mkdir -p "$DEPLOY_DEST_DIR"

# Apply dotfiles
cd "$REPO_CLONE_DIR" && bin/dotfiles upgrade
