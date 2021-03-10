#!/bin/sh
set -e

if [ ! -d $HOME/dotfiles ]; then
  echo "Cloning dotfile repository..."
  git clone https://github.com/riseshia/dotfiles.git ~/.dotfiles
fi

