execute "install starship" do
  not_if "command -v starship"
  command "curl -sS https://starship.rs/install.sh | sh"
end

copy_file ".config/starship.toml" do
  source "config/.starship.toml"
end
