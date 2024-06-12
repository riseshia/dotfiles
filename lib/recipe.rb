include_recipe "recipe_helper"

node.reverse_merge!(
  os: run_command("uname").stdout.strip.downcase,
  user: ENV["SUDO_USER"] || ENV["USER"]
)
include_role node[:platform]
