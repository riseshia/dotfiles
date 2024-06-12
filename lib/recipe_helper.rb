MItamae::RecipeContext.class_eval do
  def include_cookbook(name)
    root_dir = File.expand_path("../..", __FILE__)
    include_recipe File.join(root_dir, "cookbooks", name, "default")
  end

  def include_role(name)
    root_dir = File.expand_path("../..", __FILE__)
    include_recipe File.join(root_dir, "roles", name, "default")
  end

  def has_command?(name)
    run_command("command -v #{name}").exit_status == 0
  end
end

# github_binary "rbenv" do
#   repository "rbenv/rbenv"
#   version "v1.2.0"
#   archive "ghq_#{node[:os]}_amd64.zip"
#   binary_path "ghq_#{node[:os]}_amd64/ghq"
# end

define :github_binary, version: nil, repository: nil, archive: nil, binary_path: nil do
  cmd = params[:name]
  bin_path = "#{node[:home]}/bin/#{cmd}"
  archive = params[:archive]
  url = "https://github.com/#{params[:repository]}/releases/download/#{params[:version]}/#{archive}"

  if archive.end_with?(".zip")
    package "unzip" do
      not_if "which unzip"
    end
    extract = "unzip -o"
  elsif archive.end_with?(".tar.gz")
    extract = "tar xvzf"
  else
    raise "unexpected ext archive: #{archive}"
  end

  directory "#{node[:home]}/bin" do
    owner node[:user]
  end
  execute "curl -fSL -o /tmp/#{archive} #{url}" do
    not_if "test -f #{bin_path}"
  end
  execute "#{extract} /tmp/#{archive}" do
    not_if "test -f #{bin_path}"
    cwd "/tmp"
  end
  execute "mv /tmp/#{params[:binary_path] || cmd} #{bin_path} && chmod +x #{bin_path}" do
    not_if "test -f #{bin_path}"
  end
end
