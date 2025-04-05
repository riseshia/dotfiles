include_role "base"

include_cookbook "git"
include_cookbook "bash"
include_cookbook "starship"
include_cookbook "tmux"
include_cookbook "nvim"
include_cookbook "rust"
include_cookbook "z"

github_binary "alp" do
  repository "tkuchiki/alp"
  version "v1.0.21"
  archive "alp_linux_amd64.tar.gz"
end
