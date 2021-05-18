include_role 'base'

include_cookbook 'git'
include_cookbook 'gh'
include_cookbook 'bash'
include_cookbook 'starship'
include_cookbook 'tmux'
include_cookbook 'vim'
include_cookbook 'fzf'
include_cookbook 'jq'
include_cookbook 'ripgrep'
include_cookbook 'rust'
include_cookbook 'z'
include_cookbook 'rbenv'
ruby '3.0.0' do
  as_global true
end
include_cookbook 'nodebrew'
nodejs 'v16.1.0'
