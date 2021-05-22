define :link_file, source: nil do
  source = params[:source] || params[:name]
  remote_file File.join(ENV['HOME'], params[:name]) do
    source File.expand_path("../../../config/#{source}", __FILE__)
    user node[:user]
  end
end

define :link_directory, source: nil do
  source = params[:source] || params[:name]

  link File.join(ENV['HOME'], params[:name]) do
    to File.expand_path("../../../#{source}", __FILE__)
    user node[:user]
    force true
  end
end
