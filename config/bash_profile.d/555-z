# z config
[ -f $(brew --prefix)/etc/profile.d/z.sh ] && . $(brew --prefix)/etc/profile.d/z.sh

# Override z with fzf
unalias z 2> /dev/null
z() {
  if [[ $# -gt 0 ]]; then
    _z "$@"
  else
    cd "$(_z -l 2>&1 | awk '{print $2}' |  fzf --tac --inline-info --no-sort --preview 'ls {-1}')" || return
  fi
}
