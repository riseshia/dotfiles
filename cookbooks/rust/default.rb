execute "install rustup" do
  only_if "command -v rustup"
  command "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
end
