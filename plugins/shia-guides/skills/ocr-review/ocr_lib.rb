# OCR Review - 共有 git ヘルパ / porcelain パーサ
#
# preprocess / file-context の両エントリポイントが require_relative でロードする。
# 実行対象ではなくライブラリのため shebang / 実行ビットは付けない。
#
# 設計方針（todo.md 根本原因 A/B への対処）:
#   - 全 git 実行を repo ルート (`git rev-parse --show-toplevel`) に -C で固定
#     → CWD 相対パスの無言失敗を根絶。
#   - 常に `-c core.quotePath=false` を付与
#     → 非 ASCII パスの C-エスケープ破損を根絶。
#   - `-z` NUL 終端で name-status / numstat をパース
#     → rename の誤パース・空白/タブを含むパスの破損を根絶。
#   - diff-base トークンは `-` 始まりを拒否し、`--` で end-of-options を明示
#     → git オプションインジェクションを根絶。
#   - ref 解決の失敗は静かに HEAD へ倒さず明示的に abort。

require "open3"

module OcrLib
  module_function

  # repo ルートの絶対パス。全 git 実行の基準。
  def repo_root
    @repo_root ||= begin
      out, st = Open3.capture2("git", "rev-parse", "--show-toplevel")
      abort "ocr-review: not inside a git repository" unless st.success?
      out.strip
    end
  end

  # git を repo ルート固定 + quotePath 無効で実行し [stdout, status] を返す。
  # stderr は破棄する（失敗時は呼び出し側が独自メッセージで abort するため）。
  def git(*args)
    out, _err, st = Open3.capture3("git", "-C", repo_root, "-c", "core.quotePath=false", *args)
    [out, st]
  end

  # 失敗時に abort する git 実行。
  def git!(*args)
    out, st = git(*args)
    abort "ocr-review: `git #{args.join(' ')}` failed" unless st.success?
    out
  end

  # diff 系の共通フラグを付けて git を実行。
  def git_diff(*args)
    git("diff", "--no-ext-diff", "--no-textconv", "--no-color", "--find-renames", *args)
  end

  # diff-base トークンを git diff の引数配列へ変換する。
  # `--staged` のみフラグとして許可し、それ以外の `-` 始まりは拒否（インジェクション対策）。
  def diff_base_args(diff_base)
    return ["--staged"] if diff_base == "--staged"
    if diff_base.start_with?("-")
      abort "ocr-review: refusing option-like diff base: #{diff_base}"
    end
    [diff_base]
  end

  # ref が `-` 始まりでないことを保証（引数として git に渡す前の検証）。
  def assert_safe_ref!(ref)
    if ref.nil? || ref.empty? || ref.start_with?("-")
      abort "ocr-review: invalid ref: #{ref.inspect}"
    end
    ref
  end

  # ref が実在するか（rev-parse --verify）。存在しなければ false。
  def ref_exists?(ref)
    assert_safe_ref!(ref)
    _out, st = git("rev-parse", "--verify", "--quiet", "#{ref}^{commit}", "--")
    st.success?
  end

  # merge-base を返す。失敗時は静かにフォールバックせず abort。
  def merge_base!(ref, head = "HEAD")
    assert_safe_ref!(ref)
    out, st = git("merge-base", ref, head, "--")
    unless st.success?
      abort "ocr-review: could not compute merge-base of #{ref} and #{head}"
    end
    out.strip
  end

  # origin/HEAD → main → master の順でデフォルトブランチ名を解決。
  # いずれも存在しなければ nil（呼び出し側が明示エラーにする）。
  def default_branch
    out, st = git("symbolic-ref", "refs/remotes/origin/HEAD")
    return out.strip.sub(%r{\Arefs/remotes/origin/}, "") if st.success? && !out.strip.empty?
    ["main", "master"].each do |b|
      return b if ref_exists?(b)
    end
    nil
  end

  # `git diff -z --name-status` を構造化配列へパースする。
  # 返り値: [{status:, path:, old:}] （old は rename/copy 時のみ）
  def parse_name_status(base_args)
    out, _st = git_diff("-z", "--name-status", *base_args, "--")
    tokens = out.split("\0")
    entries = []
    i = 0
    while i < tokens.length
      status = tokens[i]
      break if status.nil? || status.empty?
      i += 1
      if status.start_with?("R") || status.start_with?("C")
        old = tokens[i]
        new = tokens[i + 1]
        i += 2
        entries << { status: status, old: old, path: new }
      else
        entries << { status: status, path: tokens[i] }
        i += 1
      end
    end
    entries
  end

  # `git diff -z --numstat` をパースし {path => changed_lines} と binary path 集合を返す。
  # 返り値: [stat_map(Hash path=>Integer), binary_paths(Array)]
  def parse_numstat(base_args)
    out, _st = git_diff("-z", "--numstat", *base_args, "--")
    tokens = out.split("\0")
    stat_map = {}
    binary_paths = []
    i = 0
    while i < tokens.length
      field = tokens[i]
      break if field.nil? || field.empty?
      added, deleted, path = field.split("\t", 3)
      i += 1
      # rename/copy は path 欄が空で、続く 2 トークンが old/new
      if path.nil? || path.empty?
        # tokens[i] = old, tokens[i+1] = new
        path = tokens[i + 1]
        i += 2
      end
      if added == "-" || deleted == "-"
        binary_paths << path
      else
        stat_map[path] = added.to_i + deleted.to_i
      end
    end
    [stat_map, binary_paths]
  end
end
