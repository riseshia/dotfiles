# Block aws cli calls when the profile contains "admin".
require 'json'

input = JSON.parse($stdin.read)
command = input.dig('tool_input', 'command').to_s

# env var の代入（AWS_PROFILE=xxx など）が aws の前に付く形も許容する
exit 0 unless command =~ /(?:^|[;&|]\s*)(?:\w+=\S+\s+)*aws\s/

# --profile と AWS_PROFILE= の両方からプロファイル名を集める
profiles = command.scan(/--profile[= ]+(\S+)/).flatten
profiles += command.scan(/(?:^|[;&|]\s*|\s)AWS_PROFILE=(\S+)/).flatten
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
