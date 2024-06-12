archive = node[:os] == "darwin" ? "nvim-macos-arm64.tar.gz" : "nvim-linux64.tar.gz"

github_package "nvim" do
  repository "neovim/neovim"
  version "v0.10.0"
  archive archive
  install_path "/opt/nvim"
end

link_directory ".config/nvim" do
  source "config/nvim"
end

clone_github_repo "packer" do
  repository "wbthomason/packer.nvim"
  clone_path "#{ENV['HOME']}/.local/share/nvim/site/pack/packer/start/packer.nvim"
end

link_directory ".config/nvim/colors" do
  source "config/vim-colors"
end
