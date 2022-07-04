package "nodenv"

define :nodejs, as_global: false do
  version = params[:name]
  execute "Install Nodejs #{version} via node-build" do
    not_if "nodenv versions | grep -q '#{version}'"
    command "nodenv install #{version}"
  end

  if params[:as_global]
    execute "Set #{version} as global Nodejs" do
      not_if "nodenv global | grep -q '#{version}'"
      command "nodenv global #{version}"
    end
  end
end
