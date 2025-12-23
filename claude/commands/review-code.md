---
name: review-code
description: Conduct thorough code review using systematic evaluation criteria
---

# Review Code Command

Conduct thorough code review using systematic evaluation criteria

## Additional Context

$ARGUMENTS

**Instructions for using additional context:**

- If a **PR link or number** is provided, use the `gh-cli` skill to fetch PR details with `gh pr view <number>`
- If a **branch name** is provided, use it as the comparison target instead of `main`
- If a **focus area** is specified (e.g., "focus on tests", "check security"), prioritize that aspect during review
- If **no arguments** are provided, proceed with standard review against `main` branch

## Overview

The review command provides a structured approach to code review, ensuring consistency and completeness in evaluating code changes.

## Review Process

### STEP 1: Verify Prerequisites

```bash
# Ensure environment is up to date
dev up

# Ensure clean working state
git status

# Verify all tests pass with Sorbet runtime checks
dev test SORBET_TRACES=1 SORBET_RUNTIME=1
```

**CRITICAL**: Do not review code with failing tests or uncommitted changes

### STEP 2: Understand the Change

1. **Read the Pull Request Description**
   - If a PR link or number was provided, use the `gh-cli` skill to fetch the description
   - Identify the problem being solved
   - Understand the approach taken
   - Note any specific review requests from the PR or from the additional context above

2. **Check the Diff Scope**

   ```bash
   # Use the branch from additional context if provided, otherwise default to main
   git diff <base-branch>...HEAD --stat
   ```

   - Verify changes match PR description
   - Identify unexpected modifications
   - If a focus area was specified, identify files most relevant to that focus

### STEP 3: Apply Review Criteria

Evaluate each changed file against:

#### A. Correctness

- [ ] Logic implements stated requirements
- [ ] Edge cases are handled
- [ ] No obvious bugs or errors
- [ ] Data integrity is maintained

#### B. Clarity

- [ ] Code intent is self-evident
- [ ] Names accurately describe purpose
- [ ] Complex logic has explanatory comments
- [ ] No misleading implementations

#### C. Consistency

- [ ] Follows existing patterns in codebase
- [ ] Uses established conventions
- [ ] Matches project style guide
- [ ] Integrates smoothly with surrounding code

#### D. Testability

- [ ] New code has appropriate test coverage
- [ ] Tests are clear and comprehensive
- [ ] Test names describe behavior
- [ ] No test interdependencies

### STEP 4: Performance and Security Check

1. **Performance Considerations**
   - Look for N+1 queries
   - Check for unnecessary iterations
   - Identify potential memory issues
   - Verify appropriate data structure usage

2. **Security Review**
   - No hardcoded credentials
   - Input validation present
   - SQL injection prevention
   - XSS protection in place

### STEP 5: Run Automated Checks

```bash
# Run all checks
dev check
```

### STEP 6: Provide Feedback

Structure feedback using:

```markdown
## Review Summary

### ✅ Strengths
- [Positive aspect 1]
- [Positive aspect 2]

### 🔍 Required Changes
1. **[Issue]** - [File:Line]
   - Problem: [Description]
   - Suggestion: [How to fix]

### 💡 Suggestions (Optional)
1. **[Improvement]** - [File:Line]
   - Consider: [Alternative approach]

### ❓ Questions
1. [Clarification needed about...]

### 🤖 Automated Check Results
- Style: [Pass/Fail]
- Types: [Pass/Fail]
- Security: [Pass/Fail]
```

## Best Practices

1. **Review in Multiple Passes**
   - First pass: Understand the change
   - Second pass: Detailed evaluation
   - Third pass: Holistic assessment

2. **Focus on Important Issues**
   - Prioritize bugs over style
   - Address security before performance
   - Fix correctness before optimization

3. **Be Constructive**
   - Explain why something is problematic
   - Provide specific improvement suggestions
   - Acknowledge good decisions
