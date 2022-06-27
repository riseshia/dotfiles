package "neovim"

link_directory ".config/nvim" do
  source "config/nvim"
end

packer_repository_url = "https://github.com/wbthomason/packer.nvim"
nvim_config_dir = "~/.local/share/nvim/site/pack/packer/start/packer.nvim"

execute "Install packer for vim" do
  not_if "test -d #{nvim_config_dir}"
  command "git clone --depth 1 #{packer_repository_url} #{nvim_config_dir}"
end

link_directory ".config/nvim/colors" do
  source "config/vim-colors"
end
