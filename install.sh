#!/bin/sh
set -e

DEPLOY_DEST_DIR="$HOME/.dotfiles"
if [ ! -d $DEPLOY_DEST_DIR ]; then
  echo "'$DEPLOY_DEST_DIR' dir isn't exist."
  git clone https://github.com/riseshia/dotfiles.git $DEPLOY_DEST_DIR
else
  echo "'$DEPLOY_DEST_DIR' dir exist. Skip repository cloning."
fi

echo "Update dotfiles source."
cd $DEPLOY_DEST_DIR && git pull -f origin main

if ! command -v dotfiles; then
  echo "dotfiles manager isn't installed. Let's setup."
  $DEPLOY_DEST_DIR/bin/setup_dotfiles
else
  echo "dotfiles manager is already installed. Skip install."
fi

PATH=$PATH:$HOME/.dotfiles/bin dotfiles upgrade
