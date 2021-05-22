#!/bin/sh

set -e

if [ "$(uname)" = 'Darwin' ]; then
  # Start from brew install which check xcode command-line tool availability.
  # Ref: https://github.com/Homebrew/install/blob/dee8df98bfb65588007c666034c6e1ad0733b1b6/install.sh#L626-L633
  if ! command -v brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

DEPLOY_DEST_DIR="$HOME/.dotfiles"
if [ ! -d "$DEPLOY_DEST_DIR" ]; then
  echo "'$DEPLOY_DEST_DIR' dir isn't exist."
  git clone https://github.com/riseshia/dotfiles.git "$DEPLOY_DEST_DIR"
else
  echo "'$DEPLOY_DEST_DIR' dir exist. Skip repository cloning. Instead, update dotfiles source."
  cd "$DEPLOY_DEST_DIR" && git fetch && git reset --hard origin/main
fi

if ! [ -h "$DEPLOY_DEST_DIR/bin/mitamae" ]; then
  echo "mitamae isn't installed. Let's install."
  "$DEPLOY_DEST_DIR/bin/setup_mitamae"
else
  echo "mitamae is already installed. Skip install."
fi

PATH=$PATH:$HOME/.dotfiles/bin dotfiles upgrade
