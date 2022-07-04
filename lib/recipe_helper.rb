MItamae::RecipeContext.class_eval do
  def include_cookbook(name)
    root_dir = File.expand_path("..", __dir__)
    include_recipe File.join(root_dir, "cookbooks", name, "default")
  end

  def include_role(name)
    root_dir = File.expand_path("..", __dir__)
    include_recipe File.join(root_dir, "roles", name, "default")
  end

  def has_command?(name)
    run_command("command -v #{name}").exit_status == 0
  end
end
