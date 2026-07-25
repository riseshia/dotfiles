# Block envchain calls, which would unlock Keychain secrets into the command env.
require 'json'

input = JSON.parse($stdin.read)
command = input.dig('tool_input', 'command').to_s

# env var の代入（FOO=bar など）が envchain の前に付く形も許容する
exit 0 unless command =~ /(?:^|[;&|]\s*)(?:\w+=\S+\s+)*envchain(?:\s|$)/

puts JSON.generate(
  'hookSpecificOutput' => {
    'hookEventName' => 'PreToolUse',
    'permissionDecision' => 'deny',
    'permissionDecisionReason' => "Don't use envchain. It pulls secrets out of the Keychain into the command env. Ask user to run it themselves when it is really needed."
  }
)
