package "git"

copy_file ".gitignore" do
  source "config/.gitignore"
end

gitconfig = {
  core: {
    excludesFile: "~/.gitignore",
    editor: "vim",
    quotepath: "off"
  },
  color: {
    ui: "true"
  },
  push: {
    default: "simple"
  },
  pull: {
    rebase: "true"
  },
  submodule: {
    recurse: "true"
  },
  init: {
    defaultBranch: "main"
  }
}

gitconfig.each do |namespace, kv|
  kv.each do |key, value|
    full_key = "#{namespace}.#{key}"

    execute "git config --global #{full_key} #{value}" do
      not_if "[ $(git config --global #{full_key}) = #{value} ]"
    end
  end
end
