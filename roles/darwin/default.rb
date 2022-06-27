include_role 'base'

include_cookbook 'git'
include_cookbook 'github'
include_cookbook 'bash'
include_cookbook 'starship'
include_cookbook 'tmux'
include_cookbook 'vim'
include_cookbook 'nvim'
include_cookbook 'fzf'
include_cookbook 'jq'
include_cookbook 'ripgrep'
include_cookbook 'rust'
include_cookbook 'z'
include_cookbook 'envchain'
include_cookbook 'rbenv'

ruby '3.1.2' do
  as_global true
end
include_cookbook 'nodebrew'
nodejs 'v16.1.0'
