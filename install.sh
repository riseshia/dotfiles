#!/bin/sh
set -e

DEPLOY_DEST_DIR="$HOME/.dotfiles"
if [ ! -d $DEPLOY_DEST_DIR ]; then
  echo "'$DEPLOY_DEST_DIR' dir isn't exist."
  git clone https://github.com/riseshia/dotfiles.git $DEPLOY_DEST_DIR
else
  echo "'$DEPLOY_DEST_DIR' dir exist. Skip repository cloning."
fi

