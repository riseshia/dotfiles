include_cookbook "rbenv"

ruby "3.1.2" do
  as_global true
end

link_directory ".config/rubocop" do
  source "config/rubocop"
end
