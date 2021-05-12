package "vim"

vim_config_dir = "#{ENV.fetch('HOME')}/.vim"
directory vim_config_dir do
  owner node[:user]
end

minpac_repository_url = "https://github.com/k-takata/minpac.git"

execute "Install minpac for vim" do
  not_if "test -d #{vim_config_dir}/pack"
  command "git clone #{minpac_repository_url} #{vim_config_dir}/pack/minpac/opt/minpac"
end

dotfile ".vimrc"
dotfile ".vim/coc-settings.json" do
  source "coc-settings.json"
end

link "#{vim_config_dir}/colors" do
  to File.expand_path("../../../config/vim-colors", __FILE__)
  user node[:user]
  force true
end
