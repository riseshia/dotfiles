package "libyaml"
package "openssl"

clone_github_repo "rbenv" do
  repository "rbenv/rbenv"
  clone_path "#{ENV['HOME']}/.rbenv"
end

clone_github_repo "ruby-build" do
  repository "rbenv/ruby-build"
  clone_path "#{ENV['HOME']}/.rbenv/plugins/ruby-build"
end

copy_file ".gemrc" do
  source "config/.gemrc"
end
