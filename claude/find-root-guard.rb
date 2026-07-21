# Block `find /` scans that walk the whole filesystem from root.
require 'json'

input = JSON.parse($stdin.read)
command = input.dig('tool_input', 'command').to_s

# find / の直後が空白か行末のときだけ拾う。find /usr や find . は対象外。
exit 0 unless command =~ %r{(?:^|[;&|]\s*)(?:sudo\s+)?find\s+/(?:\s|$)}

puts JSON.generate(
  'hookSpecificOutput' => {
    'hookEventName' => 'PreToolUse',
    'permissionDecision' => 'deny',
    'permissionDecisionReason' => "Don't scan the whole filesystem with `find /`. Narrow the search path, or use a faster tool like fd/rg."
  }
)
