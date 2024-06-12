clone_github_repo "nodenv" do
  repository "nodenv/nodenv"
  clone_path "#{ENV['HOME']}/.nodenv"
end

clone_github_repo "node-build" do
  repository "nodenv/node-build"
  clone_path "#{ENV['HOME']}/.nodenv/plugins/node-build"
end
