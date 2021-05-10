package 'rbenv'

define :ruby, as_global: false do
  version = params[:name]
  execute "Install Ruby #{version} via ruby-build" do
    not_if "rbenv versions | grep -q '#{version}'"
    command "rbenv install #{version}"
  end

  if params[:as_global]
    execute "Set #{version} as global Ruby" do
      not_if "rbenv global | grep -q '#{version}'"
      command "rbenv global #{version}"
    end
  end
end
