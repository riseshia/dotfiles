directory "#{ENV.fetch('HOME')}/bin" do
  owner node[:user]
end

include_cookbook "functions"
