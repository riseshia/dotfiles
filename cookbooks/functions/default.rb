define :copy_file, source: nil do
  source = params[:source] || params[:name]
  remote_file File.join(ENV['HOME'], params[:name]) do
    source File.join(ENV.fetch("DOTFILE_SRC_PATH"), source)
    user node[:user]
  end
end

define :link_directory, source: nil do
  source = params[:source] || params[:name]
  target_dir = File.join(ENV['HOME'], params[:name])
  src_dir = File.join(ENV.fetch("DOTFILE_SRC_PATH"), source)

  link target_dir do
    # Note: link resource don't support -n options for link. so we need to check it manually.
    only_if %Q|test -h #{target_dir} && [ $(readlink #{target_dir} != #{src_dir} ] && rm #{target_dir}|
    to src_dir
    user node[:user]
    force true
  end
end
