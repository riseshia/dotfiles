include_cookbook "rbenv"

ruby "3.2.2" do
  as_global true
end

link_directory ".config/rubocop" do
  source "config/rubocop"
end

link_directory ".config/solargraph" do
  source "config/solargraph"
end
