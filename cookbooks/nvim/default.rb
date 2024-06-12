package "neovim"

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
