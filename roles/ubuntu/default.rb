include_role "base"

include_cookbook "git"
include_cookbook "bash"
include_cookbook "starship"
include_cookbook "tmux"
include_cookbook "nvim"
include_cookbook "jq"
include_cookbook "rust"
include_cookbook "z"

github_binary "fzf" do
  repository "junegunn/fzf"
  version "0.53.0"
  archive "fzf-0.53.0-linux_amd64.tar.gz"
end

github_binary "delta" do
  repository "dandavison/delta"
  version "0.18.2"
  archive "delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz"
  binary_path "delta-0.18.2-x86_64-unknown-linux-gnu/delta"
end

github_binary "alp" do
  repository "tkuchiki/alp"
  version "v1.0.21"
  archive "alp_linux_amd64.tar.gz"
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
