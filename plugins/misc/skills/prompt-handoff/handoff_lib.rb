# frozen_string_literal: true

# prompt-handoff - 세션 로그 파싱 / 토큰화 / 마스킹의 공유 부분.
#
# collect 와 token 이 require_relative 로 읽는다.
# 실행 대상이 아니라 라이브러리이므로 shebang / 실행 비트를 붙이지 않는다.

require "date"
require "digest"
require "fileutils"
require "json"
require "securerandom"
require "time"

module HandoffLib
  module_function

  PROJECTS_DIR = File.expand_path("~/.claude/projects")
  SALT_PATH = File.expand_path("~/.config/prompt-handoff/salt")

  # typed/queued 만이 직접 타이핑한 발화다.
  # system 은 hook 주입, sdk 는 서브에이전트, nil 은 tool_result 이므로 제외한다.
  HUMAN_PROMPT_SOURCES = %w[typed queued].freeze

  Prompt = Data.define(:at, :project, :text)
  Redaction = Data.define(:text, :count)

  # --- 세션 로그 ---

  def parse_line(line)
    JSON.parse(line)
  rescue JSON::ParserError
    nil
  end

  def human_prompt?(record)
    return false unless record["type"] == "user"
    return false if record["isSidechain"]
    return false unless HUMAN_PROMPT_SOURCES.include?(record["promptSource"])

    record.dig("message", "content").is_a?(String)
  end

  def prompts_in(path, range:)
    File.foreach(path).filter_map do |line|
      record = parse_line(line)
      next unless record && human_prompt?(record)

      # 로그의 timestamp 는 UTC 다. 관측 대상은 Shia 의 하루이므로 현지 시각으로 옮긴다.
      at = Time.iso8601(record.fetch("timestamp")).getlocal
      next unless range.cover?(at)

      Prompt.new(at:, project: File.basename(record["cwd"].to_s), text: record.dig("message", "content"))
    end
  end

  def load_prompts(range:)
    # 세션 파일의 mtime 은 마지막 활동 시각이므로, 그보다 오래된 파일엔 대상 발화가 없다.
    Dir.glob("#{PROJECTS_DIR}/*/*.jsonl")
       .select { File.mtime(_1) >= range.begin }
       .flat_map { prompts_in(_1, range:) }
       .sort_by(&:at)
  end

  # 관측의 한 주는 일요일부터 토요일까지다.
  def week_range(weeks_ago)
    today = Date.today
    sunday = today - today.wday - (weeks_ago * 7)
    start = Time.new(sunday.year, sunday.month, sunday.day)

    start...(start + (7 * 86_400))
  end

  def recent_range(days)
    now = Time.now

    (now - (days * 86_400))...now
  end

  # --- 토큰 ---

  # 같은 고유명사가 회차를 넘어 같은 토큰이 되어야 kagami 가 반복을 볼 수 있다.
  # 그 일관성의 근거가 이 salt 뿐이므로, 이미 있으면 절대 다시 만들지 않는다.
  def salt
    @salt ||= File.exist?(SALT_PATH) ? File.read(SALT_PATH).strip : create_salt
  end

  def create_salt
    FileUtils.mkdir_p(File.dirname(SALT_PATH), mode: 0o700)
    value = SecureRandom.hex(32)
    # perm 은 생성 시에만 적용된다. 여기 도달했다는 것은 파일이 없었다는 뜻이다.
    File.write(SALT_PATH, "#{value}\n", perm: 0o600)
    value
  end

  def token(kind, value)
    digest = Digest::SHA256.hexdigest("#{salt}\0#{kind}\0#{value.strip.downcase}")

    "<#{kind}-#{digest[0, 6]}>"
  end

  # --- 마스킹 ---

  ARN = /arn:aws[\w-]*:[^\s"'`,)\]}]+/
  UUID = /\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i
  AWS_ACCOUNT_ID = /\b\d{12}\b/
  AWS_ACCESS_KEY = /\b(?:AKIA|ASIA|AGPA|AIDA|AROA|ANPA)[0-9A-Z]{12,}\b/
  IPV4 = /\b\d{1,3}(?:\.\d{1,3}){3}\b/
  EMAIL = /\b[\w.+-]+@[\w-]+(?:\.[\w-]+)+\b/
  URL = %r{\b[a-z][\w+.-]*://\S+}i
  JWT = /\beyJ[\w-]+\.[\w-]+\.[\w-]+/
  LONG_HEX = /\b[0-9a-f]{32,}\b/i
  PHONE = /\b\d{2,4}-\d{3,4}-\d{4}\b/

  # 순서가 규칙의 일부다. ARN 은 안쪽에 UUID 와 12자리 계정 ID 를 품을 수 있어서,
  # 좁은 규칙을 먼저 돌리면 ARN 이 파편으로 쪼개진 채 반쯤 남는다. 넓은 것부터 지운다.
  REDACTIONS = [
    [ARN, "<arn>"],
    [UUID, "<uuid>"],
    [AWS_ACCOUNT_ID, "<aws-account>"],
    [AWS_ACCESS_KEY, "<aws-key>"],
    [IPV4, "<ip>"],
    [EMAIL, "<email>"],
    [URL, "<url>"],
    [JWT, "<jwt>"],
    [LONG_HEX, "<hex>"],
    [PHONE, "<phone>"]
  ].freeze

  def redact(text)
    count = 0
    masked = REDACTIONS.reduce(text) do |acc, (pattern, placeholder)|
      acc.gsub(pattern) do
        count += 1
        placeholder
      end
    end

    Redaction.new(text: masked, count:)
  end

  # 규칙에 걸리지 않았지만 사람이 눈으로 봐야 할 줄.
  # 사내 고유명사는 형태가 제각각이라 정규식으로 못 잡는다. 대신 자주 끼는 모양만 걸러 올린다.
  ACRONYM = /[A-Z]{2,}/
  DOMAINISH = /\w+\.(?:com|jp|net|io|dev|internal|local)\b/i
  DIGIT_RUN = /\d{4,}/

  def suspect?(text)
    text.match?(ACRONYM) || text.match?(DOMAINISH) || text.match?(DIGIT_RUN)
  end

  def paste_placeholder(text)
    "[붙여넣음 #{format("%.1f", text.bytesize / 1024.0)}KB]"
  end
end
