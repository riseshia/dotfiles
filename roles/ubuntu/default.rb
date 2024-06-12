include_role "base"

include_cookbook "git"
include_cookbook "bash"
include_cookbook "starship"
include_cookbook "tmux"
include_cookbook "nvim"

github_binary "fzf" do
  repository "junegunn/fzf"
  version "0.53.0"
  archive "fzf-#{fzf_version}-linux_amd64.tar.gz"
end

include_cookbook "jq"
# include_cookbook "github"
include_cookbook "rust"
include_cookbook "z"
# include_cookbook "awscli"

include_cookbook "rbenv"
include_cookbook "nodenv"
