# Merges the skill-reminder hook definitions into ~/.claude/settings.json,
# preserving keys Claude Code writes at runtime (permissions, enabledPlugins,
# effortLevel, ...).
#
# Merge rules:
#   - Hashes are deep-merged; these definitions win on scalar conflicts,
#     live-only keys are kept.
#   - Hook-event arrays are merged by `_id` (our group replaces the matching
#     live group; live-only groups are preserved). Legacy groups without `_id`
#     are matched structurally so they are not duplicated on first run. `_id`
#     is kept in the output so it round-trips on subsequent runs.
#   - Other arrays are unioned, base order first.
require 'json'

TARGET = File.expand_path('~/.claude/settings.json')
HOOK_SCRIPT = File.expand_path('skill-reminder.rb', __dir__)
AWS_ADMIN_GUARD_SCRIPT = File.expand_path('aws-admin-guard.rb', __dir__)

def hook_command
  { 'type' => 'command', 'command' => "ruby #{HOOK_SCRIPT}" }
end

def aws_admin_guard_command
  { 'type' => 'command', 'command' => "ruby #{AWS_ADMIN_GUARD_SCRIPT}" }
end

def desired_settings
  {
    'hooks' => {
      'UserPromptSubmit' => [
        { '_id' => 'skill-reminder', 'hooks' => [hook_command] },
      ],
      'PreToolUse' => [
        {
          '_id' => 'skill-reminder',
          'matcher' => 'Write|Edit|MultiEdit|Update',
          'hooks' => [hook_command],
        },
        {
          '_id' => 'aws-admin-guard',
          'matcher' => 'Bash',
          'hooks' => [aws_admin_guard_command],
        },
      ],
    },
  }
end

def deep_merge(base, over)
  return merge_hash(base, over) if base.is_a?(Hash) && over.is_a?(Hash)
  return merge_array(base, over) if base.is_a?(Array) && over.is_a?(Array)
  over
end

def merge_hash(base, over)
  out = base.dup
  over.each do |key, value|
    out[key] = base.key?(key) ? deep_merge(base[key], value) : value
  end
  out
end

def merge_array(base, over)
  return upsert_groups(base, over) if (base + over).all? { |e| e.is_a?(Hash) }
  base | over
end

# Identifies hook groups by `_id`, falling back to structural equality so legacy
# groups predating the `_id` convention are updated in place instead of duplicated.
def upsert_groups(base, over)
  result = base.dup
  over.each do |group|
    index = match_index(result, group)
    if index
      result[index] = group
    else
      result << group
    end
  end
  result
end

def match_index(groups, group)
  id = group['_id']
  if id
    by_id = groups.index { |g| g.is_a?(Hash) && g['_id'] == id }
    return by_id if by_id
  end
  shape = without_id(group)
  groups.index { |g| g.is_a?(Hash) && without_id(g) == shape }
end

def without_id(group)
  group.reject { |key, _| key == '_id' }
end

def load_existing
  return {} unless File.exist?(TARGET)
  JSON.parse(File.read(TARGET))
end

def write_atomically(path, data)
  tmp = "#{path}.#{Process.pid}.tmp"
  File.write(tmp, "#{JSON.pretty_generate(data)}\n")
  File.rename(tmp, path)
end

merged = deep_merge(load_existing, desired_settings)
write_atomically(TARGET, merged)
puts "Updated #{TARGET}"
