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
