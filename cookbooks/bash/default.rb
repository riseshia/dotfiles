package "bash"

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
  script = "source ~/.dotfiles/config/.dotbash"
  not_if "grep -q '#{script}' ~/.bash_profile"
  command "echo '#{script}' >> ~/.bash_profile"
end
dotfile ".alacritty.yml"
