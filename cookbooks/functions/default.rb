define :copy_file, source: nil do
  source = params[:source] || params[:name]
  remote_file File.join(ENV["HOME"], params[:name]) do
    source File.join(ENV.fetch("DOTFILE_SRC_PATH"), source)
    owner node[:user]
  end
end

define :link_directory, source: nil do
  source = params[:source] || params[:name]
  target_dir = File.join(ENV["HOME"], params[:name])
  src_dir = File.join(ENV.fetch("DOTFILE_SRC_PATH"), source)

  execute "Link #{params[:name]} to #{src_dir}" do
    # NOTE: link resource don't support -n options for link. so we need to check it manually.
    test_script = %[
      (! test -e #{target_dir}) ||
      ([ $(readlink #{target_dir}) != #{src_dir} ])
    ]
    only_if test_script

    command "ln -nsf #{src_dir} #{target_dir}"
    user node[:user]
  end
end

define :clone_github_repo, repository: nil, clone_path: nil do
  url = "git@github.com:/#{params[:repository]}.git"
  clone_path = params[:clone_path]
  clone_base_dir = clone_path.split("/")[0..-2].join("/")

  directory clone_base_dir do
    owner node[:user]
  end
  execute "git clone #{url} #{clone_path}" do
    not_if "test -d #{clone_path}"
  end
end

define :github_package, version: nil, repository: nil, archive: nil, install_path: nil do
  install_path = params[:install_path]
  install_path_parent = install_path.split("/")[0..-2].join("/")
  archive = params[:archive]
  url = "https://github.com/#{params[:repository]}/releases/download/#{params[:version]}/#{archive}"

  if archive.end_with?(".zip")
    package "unzip" do
      not_if "which unzip"
    end
    extract = "unzip -o"
    extract_dir = archive.sub(".zip", "")
  elsif archive.end_with?(".tar.gz")
    extract = "tar xvzf"
    extract_dir = archive.sub(".tar.gz", "")
  else
    raise "unexpected ext archive: #{archive}"
  end

  directory install_path_parent do
    owner node[:user]
  end
  execute "curl -fSL -o /tmp/#{archive} #{url}" do
    not_if "test -d #{install_path}"
    user node[:user]
  end
  execute "#{extract} /tmp/#{archive}" do
    not_if "test -d #{install_path}"
    cwd "/tmp"
    user node[:user]
  end
  execute "mv /tmp/#{extract_dir} #{install_path}" do
    not_if "test -d #{install_path}"
    user node[:user]
  end
end

define :github_binary, version: nil, repository: nil, archive: nil, binary_path: nil do
  cmd = params[:name]
  bin_dir = "#{ENV['HOME']}/.local/bin"
  bin_path = "#{bin_dir}/#{cmd}"
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

  directory bin_dir do
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
