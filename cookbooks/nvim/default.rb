
if node[:os] == "darwin"
  package "neovim"
else
  github_package "nvim" do
    repository "neovim/neovim"
    version "v0.10.0"
    archive "nvim-linux64.tar.gz"
    install_path "#{ENV['HOME']}/.local/nvim/v0.10.0"
  end
  link "#{ENV['HOME']}/.local/bin/nvim" do
    to "#{ENV['HOME']}/.local/nvim/v0.10.0/bin/nvim"
  end
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
