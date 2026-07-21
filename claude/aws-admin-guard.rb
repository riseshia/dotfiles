# Block aws cli calls when --profile contains "admin".
require 'json'

input = JSON.parse($stdin.read)
command = input.dig('tool_input', 'command').to_s

exit 0 unless command =~ /(?:^|[;&|]\s*)aws\s/

profiles = command.scan(/--profile[= ]+(\S+)/).flatten
exit 0 if profiles.empty?

admin_profile = profiles.find { |p| p.gsub(/['"]/, '').downcase.include?('admin') }
exit 0 unless admin_profile

puts JSON.generate(
  'hookSpecificOutput' => {
    'hookEventName' => 'PreToolUse',
    'permissionDecision' => 'deny',
    'permissionDecisionReason' => "Don't try to use admin permissions. Ask user when you really need this."
  }
)
