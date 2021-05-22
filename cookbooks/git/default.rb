package 'git'

copy_file '.gitconfig' do
  source 'config/.gitconfig'
end
copy_file '.gitignore' do
  source 'config/.gitignore'
end
