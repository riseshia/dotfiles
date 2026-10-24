---
name: translate-news-ko
description: Translate English ruby-lang.org news posts into Korean, keeping the line count identical for diff review, then push a branch and prepare the PR. Takes an upstream PR link or an en/news/_posts file path. Use when the user asks to translate a Ruby news article to Korean.
argument-hint: "{pr link} | {target file path}"
user-invocable: true
---

# Translate English News to Korean

Arguments: $ARGUMENTS

## Workflow

Follow these steps in order:

1. **Identify the source files from the arguments**
   - PR link (`https://github.com/ruby/www.ruby-lang.org/pull/{num}`, or just `#{num}` / `{num}`):
     list its files with `gh pr view {num} --repo ruby/www.ruby-lang.org --json files -q '.files[].path'`
     and translate every `en/news/_posts/*.md` in it. Ignore `_data/` changes.
   - File path (`en/news/_posts/YYYY-MM-DD-title.md`, or just the filename): translate that file.
     There is no source PR.
   - Several arguments may be given; handle each PR as its own branch, and file paths together on one branch.
   - Extra instructions may follow in free text (e.g. "draft PR까지"); honor them.
   - If no argument is given, ask.

2. **Create a branch**
   - `git fetch origin` and branch from `origin/master`: `git checkout -b {branch_name} origin/master`
   - Branch name from the main article's title (e.g. `tr-ruby-4-0-9-ko`, `tr-resolv-cve-2026-80212-ko`).
   - One branch per source PR. All files of that PR go on the same branch.
   - When preparing several branches, run each `git checkout -b` as its own command and confirm with
     `git branch --show-current` before committing. A failed checkout (e.g. due to uncommitted files)
     otherwise silently puts the commits on the previous branch.

3. **Copy each file to the Korean directory**
   - For each file: `cp en/news/_posts/{file} ko/news/_posts/{file}` and commit it alone with message
     `cp {en,ko}/news/_posts/{file}`

4. **Translate the article**
   - Read 3-5 recent files in `ko/news/_posts/` of the same kind (release post, security advisory, ...).
   - **Grep past translations for every non-trivial term** before choosing a translation, and follow the
     majority usage. Previous translations of the same topic (e.g. an earlier advisory for the same gem,
     or a post this article links to) take priority. Known choices:
     - "release" → "릴리스", "bug fix" → "버그 수정", "security" → "보안", "vulnerability" → "취약점",
       "recommend" → "권장합니다", "contribution" → "기여"
     - "double free" → "중복 할당 해제"
     - "security maintenance phase" → "보안 유지보수 단계", "series" → "버전대"
     - "CVE identifier" → "CVE 번호", "advisory" → "보안 권고", "default gem" → "기본 젬"
     - "Please see the topic(s) below for details." → "자세한 내용은 아래 항목을 참조하세요."
     - "Please see the GitHub releases for further details." → "자세한 내용은 [GitHub 릴리스](...)를 참조하세요."
     - Section headings: "Affected versions" → "해당 버전", "Recommended action" → "권장 조치",
       "Credits" → "도움을 준 사람", "History" → "수정 이력", "Download" → "다운로드",
       "Release Comment" → "릴리스 코멘트"
     - History line: `* 2026-10-23 03:11:22 (UTC) 최초 공개`
   - Rules:
     - Keep the same line count as the original so the en/ko diff stays readable
     - Write natural Korean, not translationese. Restructure sentences rather than mirroring English
       syntax (e.g. not "원격 코드 실행으로 이어지게 할 수 있음을 발견" but "악용하면 원격 코드를 실행할 수 있다는 것을 발견").
     - Keep proper nouns in English (Ruby, RubyGems, Bundler, GitLab, ...)
     - Frontmatter: `lang: en` → `lang: ko`, add `translator: "shia"`, translate `title`, keep the rest.
   - **Internal links**: rewrite `{% link en/news/... %}` to `{% link ko/news/... %}`, and reuse the Korean
     title of the linked post as link text. Keep the ko path even if that translation does not exist yet
     (the build fails until it lands); check with `ls`/`git ls-tree origin/master` and tell the user which
     linked posts are missing a Korean translation, offering to translate them.

5. **Verify line count matches original**
   - `wc -l en/news/_posts/{file} ko/news/_posts/{file}`, and adjust until they are equal.

6. **Proofread**
   - Run `cat ko/news/_posts/{file} | hanspell-cli`. It sometimes fails partway with a server error;
     if so, rerun on the remaining lines (`sed -n 'N,$p' ...`) so every line gets checked.
   - Ignore these known false positives, which conflict with existing translations:
     author names (e.g. "k0 kubun"), "릴리스 되었습니다" (keep "릴리스되었습니다"),
     number + unit spacing (e.g. "255옥텟"), and suggestions identical to the input.
   - **Check particles after Latin text, numbers, and code**:
     `grep -oE "[A-Za-z0-9\`)\]]+(은|는|이|가|을|를|과|와|으로|로)[ ,.]" {file} | sort -u`
     Decide by the Korean pronunciation of the last syllable: `input` = 인풋 (받침 ㅅ) → "과",
     `3.3.13` = 삼 → "이/을", `4.0.9` = 구 → "가", `resolv` = 리졸브 → "를". Spell out the final
     syllable's jamo before deciding; do not guess.
   - Reread the whole translation once for naturalness and consistency with the terms above.

7. **Commit the translation**
   - One commit per file, message `Translate "{article title}" (ko)`, with the Claude Code footer.
   - To fix a translation after committing, use `git commit --fixup={sha}` then
     `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash {base}` so each file keeps exactly one cp commit and
     one translate commit. Force-push with `--force-with-lease`. SHAs change, so give the user the new ones.

8. **Push and open the PR**
   - `git push -u origin {branch_name}`
   - PR title: the translate commit message (for multiple files, the release post's one).
   - PR body:
     ```
     :link: https://github.com/ruby/www.ruby-lang.org/issues/3461
     Translate: #{source PR number}
     Actual diff:
     - {file}: {full SHA of its translate commit}
     ```
     One `- {file}: {sha}` line per translated file. Without a source PR, replace the `Translate:` line with
     `Translation of: https://github.com/ruby/www.ruby-lang.org/blob/master/en/news/_posts/{file}`.
   - If the user allows it, create a draft PR:
     `gh pr create --repo ruby/www.ruby-lang.org --draft --head riseshia:{branch_name} --base master --title ... --body ...`
     Otherwise give the PR creation URL from the push output plus the title and body.

## Important Notes

- Preserve all markdown formatting, links, tables, and code blocks
- Keep the date format unchanged in the frontmatter
- Do not translate URLs or file paths
