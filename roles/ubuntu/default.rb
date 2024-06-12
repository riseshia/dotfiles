include_role "base"

include_cookbook "git"
include_cookbook "bash"
include_cookbook "starship"
include_cookbook "tmux"
include_cookbook "nvim"
include_cookbook "jq"
include_cookbook "rust"
include_cookbook "z"
include_cookbook "rbenv"
include_cookbook "nodenv"

github_binary "fzf" do
  repository "junegunn/fzf"
  version "0.53.0"
  archive "fzf-0.53.0-linux_amd64.tar.gz"
end

github_package "gh" do
  repository "cli/cli"
  version "v2.50.0"
  archive "gh_2.50.0_linux_amd64.tar.gz"
  install_path "#{ENV['HOME']}/.local/gh/2.50.0"
end
link "#{ENV['HOME']}/.local/bin/gh" do
  to "#{ENV['HOME']}/.local/gh/2.50.0/bin/gh"
end

# include_cookbook "awscli"
