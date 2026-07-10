# Reminds Claude to load the shia-guides:code-style skill before editing code.
# Handles both UserPromptSubmit (general nudge, once per session) and
# PreToolUse on Write/Edit (per-language nudge at the moment a file is touched).
# State is kept per session so each reminder fires at most once.
require 'json'
require 'fileutils'

input = JSON.parse($stdin.read)
event = input['hook_event_name']
session = input['session_id'] || 'unknown'

state_dir = File.join(Dir.home, '.cache', 'claude-skill-reminder')
FileUtils.mkdir_p(state_dir)

# Prune old session state so this directory doesn't grow forever.
stale_before = Time.now - (7 * 24 * 60 * 60)
Dir.glob(File.join(state_dir, '*.json')).each do |path|
  File.delete(path) if File.mtime(path) < stale_before
end

state_path = File.join(state_dir, "#{session}.json")
reminded = File.exist?(state_path) ? JSON.parse(File.read(state_path)) : []

def emit(event, context)
  puts JSON.generate('hookSpecificOutput' => { 'hookEventName' => event, 'additionalContext' => context })
end

def mark(reminded, state_path, *keys)
  File.write(state_path, JSON.generate((reminded + keys).uniq))
end

# Maps a file path to the code-style reference(s) whose conventions apply.
def langs_for(path)
  langs = []
  case File.extname(path)
  when '.rb', '.rake', '.gemspec'
    langs << 'ruby'
    langs << 'rails' if path =~ %r{(^|/)(app|config|db|spec)/} || File.basename(path) == 'Gemfile'
  when '.tf', '.tfvars'
    langs << 'terraform'
  when '.ts', '.tsx', '.mts', '.cts'
    langs << 'typescript'
  when '.rs'
    langs << 'rust'
  end
  langs << 'rails' if File.basename(path) == 'Gemfile'
  langs.uniq
end

case event
when 'UserPromptSubmit'
  unless reminded.include?('prompt')
    emit(event, 'This environment provides the shia-guides:code-style skill ' \
      '(ruby, rails, terraform, typescript, rust conventions). Before writing or editing code in any ' \
      'of these languages, load the shia-guides:code-style skill first if it has not been loaded yet ' \
      'this session — its conventions override your defaults.')
    mark(reminded, state_path, 'prompt')
  end
when 'PreToolUse'
  path = input.dig('tool_input', 'file_path')
  exit 0 unless path
  pending = langs_for(path) - reminded
  exit 0 if pending.empty?
  list = pending.map { |lang| "reference/#{lang}.md" }.join(', ')
  emit(event, "Editing #{File.basename(path)}: load the shia-guides:code-style skill first if not " \
    "already loaded this session, and follow its #{list} conventions for this change.")
  mark(reminded, state_path, *pending)
end
