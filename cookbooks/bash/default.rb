package "bash"
package "shellcheck"

brew_bash_path = "$(brew --prefix)/bin/bash"

# brew install bash and link it to /usr/local/bin/bash. so we need to add it to /etc/shells for chsh.
execute "add bash from brew to /etc/shells" do
  not_if %Q|grep -q "#{brew_bash_path}" /etc/shells|
  command "echo \"#{brew_bash_path}\" | sudo tee -a /etc/shells"
end

execute "change default shell to bash" do
  not_if %Q|test $SHELL = "#{brew_bash_path}"|
  command %Q|chsh -s "#{brew_bash_path}"|
end

execute "add 'source .dotbash' to bash_profile" do
  not_if "grep -q '.dotbash' ~/.bash_profile"
  command "echo 'source #{ENV.fetch('HOME')}/.dotfiles/.dotbash' >> ~/.bash_profile"
end
link_file ".alacritty.yml"

link_file ".dotfiles/.dotbash" do
  source ".dotbash"
end

link_directory ".dotfiles/bash_profile.d" do
  source "config/bash_profile.d"
end
link_directory ".dotfiles/bash_commands" do
  source "config/bash_commands"
end
