# Code Review

I'm performing a systematic code review using the code-reviewer agent and the systematic-code-review skill. This review applies first principles, legendary programmer standards, and 2025 industry best practices.

## What to review?

Provide one of:

- **PR number**: `/code-review 123` - Reviews GitHub PR #123
- **Branch name**: `/code-review feature-branch` - Reviews branch against main
- **Commit range**: `/code-review HEAD~3..HEAD` - Reviews last 3 commits
- **Files**: `/code-review path/to/file.js` - Reviews specific files

If no argument provided, I'll ask what you want reviewed.

## Review Process

The code-reviewer agent will:

1. **Understand the review target** - Fetch code changes and assess scope
2. **Load review framework** - Confirm systematic-code-review skill is available
3. **Execute systematic review** - Follow 9-step methodology with principle integration
4. **Provide feedback** - Structured Conventional Comments (praise → issues → suggestions → questions)
5. **Make decision** - Clear approval status with rationale
6. **Report completion** - Summary with key findings displayed in terminal

## Review Depth

The review depth adapts to change size following industry best practices:

- **Small (< 200 lines)**: Full detailed review of every line
- **Medium (200-400 lines)**: Full detailed review (industry sweet spot)
- **Medium-Large (400-1000 lines)**: Focus on high-impact areas (consider splitting)
- **Large (> 1000 lines)**: Architectural review only (strong recommendation to split)

**Note**: Google engineering culture is built on small, incremental diffs. The sweet spot for effective code review is 200-400 lines.

## Expected Output

You'll receive:

- **Praise** - At least one sincere recognition of good practices
- **Issues** - Concrete problems with blocking/non-blocking distinction and specific locations
- **Suggestions** - Improvements with principle/pattern attribution
- **Questions** - Clarifications when needed
- **Approval decision** - APPROVE / APPROVE WITH NITS / REQUEST CHANGES

All feedback uses Conventional Comments format with:

- **File location first** - Each comment starts with file path and line number: `[src/auth.py:45]`
- Explicit labels (praise, issue, suggestion, todo, question, thought, chore, note)
- Decorations for severity (blocking, non-blocking) and domains (security, performance, tests, readability, maintainability)
- Principle attribution (Rich Hickey, John Carmack, Joe Armstrong, Alan Kay, Donald Knuth, Barbara Liskov, John Ousterhout)
- Pattern names when applicable (Fowler refactoring patterns)

### Example Format

```text
[src/auth.py:45]
**issue (blocking, security)**: SQL injection vulnerability.
We are interpolating user input directly into this SQL query.
Following Joe Armstrong's isolation principle, this could expose the entire database.
Suggest switching to parameterized queries.
```

The file location appears first, followed by the conventional comment that can be used directly in code review.

**Review is displayed in terminal only - never posted to GitHub automatically.**

---

What would you like me to review?
