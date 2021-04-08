export PATH="$HOME/.dotfiles/bin:${PATH}"

eval "$(rbenv init -)"
# eval "$(pyenv init -)"

export EDITOR=vim

# Path to the bash it configuration
# export BASH_IT="$HOME/.bash_it"

# Lock and Load a custom theme file
# location /.bash_it/themes/
# export BASH_IT_THEME='minimal'

# Don't check mail when opening terminal.
unset MAILCHECK

# Set this to false to turn off version control status checking within the prompt for all themes
export SCM_CHECK=true

# Load Bash It
# source $BASH_IT/bash_it.sh

# alias
alias be='bundle exec'
alias c='clear'
alias deploy='bundle exec cap production deploy'
alias q='exit'
# alias gb='git branch'
# alias gc='git commit'
# alias gd='git diff HEAD'
alias gg='git grep -n'
alias gpull='git pull origin'
alias gpu='git pull upstream master'
alias gpush='git push origin'
alias gpp='gpu && gpush'
# alias gs='git status'
# alias run_pg='pg_ctl -D /usr/local/var/postgres start'
alias v='vim'
alias ls='ls -alh'

# custom functions
# export PATH="$HOME/.bash_functions:${PATH}"

# brew git
export PATH="$(brew --prefix)/share/git-core/contrib/diff-highlight:${PATH}"

# yarn
# export PATH="$HOME/.yarn/bin:${PATH}"

# rust
source "$HOME/.cargo/env"

# tab autocompletion with cycle style
bind TAB:menu-complete

# python
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# z
[ -f $(brew --prefix)/etc/profile.d/z.sh ] && . $(brew --prefix)/etc/profile.d/z.sh
