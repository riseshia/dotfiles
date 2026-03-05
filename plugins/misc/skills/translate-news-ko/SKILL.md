# Translate English News to Korean

You are a skill that translates English Ruby news articles to Korean for the ruby-lang.org website.

## Workflow

Follow these steps in order:

1. **Get the file path from the user**
   - Ask the user which English news file they want to translate
   - The file should be in the format: `en/news/_posts/YYYY-MM-DD-title.md`

2. **Read the file and create a branch**
   - Read the English news file
   - Extract the article title from the frontmatter
   - Create an appropriate branch name based on the title (e.g., `tr-ruby-3-4-7-ko`)
   - Switch to the new branch: `git checkout -b {branch_name}`

3. **Copy the file to Korean directory**
   - Copy the file from `en/news/_posts/` to `ko/news/_posts/` with the same filename
   - Example: `cp en/news/_posts/2025-10-07-ruby-3-4-7-released.md ko/news/_posts/2025-10-07-ruby-3-4-7-released.md`
   - Commit this change with message: `cp {en,ko}/news/_posts/2025-10-07-ruby-3-4-7-released.md`

4. **Translate the article**
   - Read recent Korean news translations to understand the style and terminology:
     - Check 3-5 recent files in `ko/news/_posts/`
     - Note common terms and their translations
   - Translate the article following these rules:
     - **CRITICAL: Maintain the same line count as the original file** (for diff readability)
       - If a sentence spans multiple lines in the original, you can translate it together but split it appropriately to match the line count
       - Use `wc -l` to verify line counts match between original and translation
     - Use consistent terminology from past translations
     - Maintain a formal but friendly tone
     - Keep proper nouns in English (e.g., Ruby, RubyGems, Bundler)
     - Translate technical terms consistently:
       - "release" → "릴리스"
       - "bug fix" → "버그 수정"
       - "security" → "보안"
       - "vulnerability" → "취약점"
       - "recommend" → "권장합니다"
       - "contribution" → "기여"
     - Update the frontmatter:
       - Change `lang: en` to `lang: ko`
       - Add `translator: "shia"`
       - Translate the `title` field to Korean
       - Keep other fields unchanged

5. **Verify line count matches original**
   - Compare line counts: `wc -l en/news/_posts/{filename} ko/news/_posts/{filename}`
   - If line counts don't match, adjust the translation to match
   - This is MANDATORY for diff readability

6. **Grammar check with hanspell-cli**
   - Run: `cat ko/news/_posts/{filename} | hanspell-cli`
   - Review and apply suggested corrections
   - Make any necessary adjustments

7. **Commit the translation**
   - Commit the translated file with message: `Translate "{article title}" (ko)`
   - Include the Claude Code footer in commit message
   - If you made changes after the initial commit (e.g., line count adjustments), amend the commit

8. **Push and provide PR URL**
   - Push the branch: `git push -u origin {branch_name}`
   - Extract the PR creation URL from the git push output
   - Provide the user with:
     - The PR creation URL
     - PR title (use the last commit message)
     - PR body template:
       ```
       :link: https://github.com/ruby/www.ruby-lang.org/issues/3461
       Translation of: https://github.com/ruby/www.ruby-lang.org/blob/master/en/news/_posts/{filename}
       Actual diff is: {last_commit_hash}
       ```
   - DO NOT use `gh pr create --web`, just provide the URL and information

## Important Notes

- **MANDATORY: The translated file must have the same number of lines as the original** (for diff readability)
- Always check existing translations for consistent terminology
- Preserve all markdown formatting, links, and code blocks
- Keep the date format unchanged in the frontmatter
- Do not translate URLs or file paths
- The translation should sound natural in Korean while maintaining technical accuracy
- After pushing, provide only the PR URL and template information - do not create the PR automatically
