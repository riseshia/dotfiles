# For handling various nodebrew root path
result = run_command("which nodebrew", error: false)
nodebrew_root_path =
  if result.exit_status == 0
    result.stdout.strip.split("/current/").first
  else
    "$HOME/.nodebrew"
  end
nodebrew_bin_path = "NODEBREW_ROOT=#{nodebrew_root_path} #{nodebrew_root_path}/current/bin/nodebrew"

execute "Install nodebrew" do
  not_if "test #{nodebrew_root_path}"
  command "curl -L git.io/nodebrew | perl - setup"
end

define :nodejs do
  version = params[:name]

  execute "#{nodebrew_bin_path} install #{version}" do
    not_if "#{nodebrew_bin_path} ls | grep -q '#{version}'"
  end

  execute "#{nodebrew_bin_path} use #{version}" do
    only_if "#{nodebrew_bin_path} ls | grep -q 'current: none'"
  end
end
