# Judges the friction of a Claude Code session and prints a short verdict.
# Two stages: a cheap regex pre-scan hints which recent turns looked rough,
# then a fresh `claude -p` reads the window and judges. The fresh context is
# the whole point — the in-session model rating its own conversation has a
# blind spot (it thinks it is doing fine).
#
# Usage: ruby friction-check.rb <session.jsonl> [--last=N]
# Comments are in English to match the sibling hooks in this directory.
require 'json'
require 'open3'

WINDOW = (ARGV.find { |a| a.start_with?('--last=') }&.split('=', 2)&.last || 12).to_i
MODEL = ARGV.find { |a| a.start_with?('--model=') }&.split('=', 2)&.last || 'sonnet'
VOTES = (ARGV.find { |a| a.start_with?('--votes=') }&.split('=', 2)&.last || 1).to_i
# FP-averse default: a turn must be flagged by ~70% of runs (4/5) to survive.
MINVOTES = (ARGV.find { |a| a.start_with?('--minvotes=') }&.split('=', 2)&.last || [(VOTES * 0.7).ceil, 1].max).to_i
path = ARGV.find { |a| !a.start_with?('--') }
abort 'usage: friction-check.rb <session.jsonl> [--last=N]' unless path && File.exist?(path)

# Same signal set the one-off friction analysis used. These only hint the judge;
# the LLM makes the call, because a raw regex hit is not itself friction.
CORRECTION = Regexp.union(/\bno\b/i, /\bstop\b/i, /\bwait\b/i, /wrong/i, /아니/, /다시/, /말고/, /잘못/, /틀렸/, /違う/, /なんで/)
INTERRUPT = /interrupted by user/i
APOLOGY = Regexp.union(/\bsorry\b/i, /apolog/i, /죄송/, /미안/, /すみません/, /申し訳/)

def text_of(msg)
  content = msg.is_a?(Hash) ? msg['content'] : nil
  return content.to_s if content.is_a?(String)
  return '' unless content.is_a?(Array)

  content.filter_map do |block|
    next unless block.is_a?(Hash)

    case block['type']
    when 'text' then block['text']
    when 'tool_use' then "[tool:#{block['name']}]"
    when 'tool_result'
      body = block['content']
      body.is_a?(Array) ? body.map { |x| x.is_a?(Hash) ? x['text'] : x }.join(' ') : body.to_s
    end
  end.join(' ')
end

# Assistant prose only — drop tool_use and thinking so the judged window is the
# actual conversation, not tool-call noise.
def assistant_text(msg)
  content = msg.is_a?(Hash) ? msg['content'] : nil
  return content.to_s if content.is_a?(String)
  return '' unless content.is_a?(Array)

  content.filter_map { |block| block['text'] if block.is_a?(Hash) && block['type'] == 'text' }.join(' ')
end

# A real human turn, not a tool_result or a synthetic task-notification.
def human?(row)
  source = row['promptSource']
  (source == 'typed' || source == 'queued' || row.dig('origin', 'kind') == 'human') &&
    row.dig('origin', 'kind') != 'task-notification'
end

rows = File.foreach(path).filter_map { |line| JSON.parse(line) rescue nil }

# Group into exchanges keyed by human turns: one user turn can spawn many
# tool/thinking rows, so windowing by raw rows fills the window with
# assistant-only noise and hides the user's messages. Window by exchange.
exchanges = []
rows.each do |row|
  if row['type'] == 'user' && human?(row)
    exchanges << { user: text_of(row['message']).gsub(/\s+/, ' ').strip, assistant: [] }
  elsif row['type'] == 'assistant' && !exchanges.empty?
    prose = assistant_text(row['message']).gsub(/\s+/, ' ').strip
    exchanges.last[:assistant] << prose unless prose.empty?
  end
end
window = exchanges.last(WINDOW)
abort 'no conversation turns found' if window.empty?

# Stage 1: format the window and collect cheap signal hints.
lines = []
hints = []
window.each_with_index do |ex, i|
  user = ex[:user].length > 600 ? "#{ex[:user][0, 600]} […truncated]" : ex[:user]
  asst = ex[:assistant].join(' ')
  asst = "#{asst[0, 700]} […truncated]" if asst.length > 700
  lines << "[#{i}|U] #{user}"
  lines << "[#{i}|A] #{asst}" unless asst.empty?

  hit = []
  hit << 'correction' if ex[:user][0, 150] =~ CORRECTION
  hit << 'interrupt' if ex[:user] =~ INTERRUPT
  hints << "exchange #{i}: #{hit.join(',')}" unless hit.empty?
  hints << "exchange #{i}: apology" if asst =~ APOLOGY
end

prompt = <<~PROMPT
  You are an external, skeptical judge of "friction" in a Claude Code conversation.
  Below are the most recent #{window.size} turns ([n|U]=user, [n|A]=assistant).

  Definition of friction: NOT the assistant's errors themselves, but the extra cost the user
  pays to keep the conversation aligned (both sides understanding the same thing). Score by this
  recovery cost, not by error count. (A short wrong answer fixed in one line = low friction; a wall
  of text that buries where it went wrong = high friction.)

  Look for both kinds:
  - Local: a single divergence the user must catch, correct, and realign — emit as per-turn items.
    넘겨짚기 (concluded without reading / misreading given material) / 장황 (a wall for a short ask) /
    성급·과잉 (did more than asked, or acted before checking) / 미해결 (an ambiguity or contradiction being carried).
  - Global: the exchange itself isn't meshing — talking past each other, the same thing re-asked, no
    convergence, the user's replies getting shorter/annoyed. A trend across the whole window, not one
    point. This is the `conversation` field.

  Report only friction you can back with a verbatim quote — do not invent friction to pad the list; a turn with no provable friction is fine.
  Text ending in "[…truncated]" was shortened for display; it is not the assistant trailing off — do not flag it as an incomplete answer.

  regex hints (reference only; a hit is not itself friction): #{hints.empty? ? 'none' : hints.join(' / ')}

  --- conversation ---
  #{lines.join("\n")}
  --- end ---

  List the items FIRST (evidence before any summary). Output exactly one JSON object, no other text. Korean labels; write `why` and `pin_now` in Korean:
  {"items": [{"turn": n, "kind": "넘겨짚기|장황|성급|과잉|미해결|기타", "quote": "verbatim from that turn", "why": "one line, Korean"}],
   "conversation": "정렬됨|드리프트|붕괴",
   "pin_now": "one line in Korean: the ambiguity/contradiction to pin down now, or empty string"}
PROMPT

# Stage 2: a fresh claude -p judges (array args, no shell). With VOTES>1 run K in
# parallel and vote by turn — self-consistency filters run-to-run variance; a
# turn survives only if >= MINVOTES runs flagged it. Bias errors survive by design.
def judge(prompt, model)
  out, err, status = Open3.capture3('claude', '-p', '--model', model, prompt)
  return nil unless status.success? && (json = out[/\{.*\}/m])

  JSON.parse(json)
rescue StandardError
  nil
end

verdicts = if VOTES > 1
             Array.new(VOTES) { Thread.new { judge(prompt, MODEL) } }.map(&:value).compact
           else
             [judge(prompt, MODEL)].compact
           end
abort 'judge calls all failed' if verdicts.empty?

by_turn = Hash.new { |h, k| h[k] = [] }
verdicts.each { |v| Array(v['items']).each { |it| by_turn[it['turn']] << it } }

items = by_turn.select { |_, its| its.size >= MINVOTES }.map do |turn, its|
  kind = its.map { |i| i['kind'] }.tally.max_by { |_, c| c }.first
  rep = its.find { |i| i['kind'] == kind } || its.first
  { 'turn' => turn, 'kind' => kind, 'quote' => rep['quote'], 'why' => rep['why'], 'votes' => its.size }
end.sort_by { |i| i['turn'] }

conv = verdicts.map { |v| v['conversation'] }.compact.tally.max_by { |_, c| c }&.first
pin = verdicts.map { |v| v['pin_now'].to_s.strip }.reject(&:empty?).tally.max_by { |_, c| c }&.first.to_s

score = [items.size * 2, 10].min   # from evidence, not asked of the model → stable
tag = VOTES > 1 ? " · #{VOTES}표 중 #{MINVOTES}+ 채택" : ''
puts "마찰 #{score}/10 · 대화: #{conv}#{tag}"
puts '→ 멈추고 정렬 재구축 필요' if conv == '붕괴'
items.each do |item|
  vtag = VOTES > 1 ? " (#{item['votes']}/#{VOTES})" : ''
  puts "  [#{item['turn']}] #{item['kind']}#{vtag}: #{item['why']}"
  puts "        “#{item['quote']}”"
end
puts "\n지금 짚을 것: #{pin}" unless pin.strip.empty?
