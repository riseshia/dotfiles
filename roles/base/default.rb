directory "#{ENV.fetch('HOME')}/bin" do
  owner node[:user]
end

directory "#{ENV.fetch('HOME')}/.config" do
  owner node[:user]
end

include_cookbook "functions"
include_cookbook "dotfiles"
