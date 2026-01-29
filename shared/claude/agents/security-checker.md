---
name: security-checker
description: Verify security advisories for Dependabot PRs via GitHub API
model: haiku
---

# Security Checker Agent

Lightweight agent for verifying security advisories in Dependabot PRs.

## Input

- **PR number** (required)

## Output

Security information including CVEs and severity.

## Skills Used

- `gh-cli` - GitHub security API access

## Security Verification Workflow

### Phase 1: Check if Security Fix

```bash
# Get PR details including title and body (with exit code verification)
if ! PR_DATA=$(gh pr view "$PR_NUMBER" --json title,body 2>&1); then
  echo '{"is_security_fix": null, "error": "Failed to fetch PR details"}' | jq
  exit 1
fi

PR_TITLE=$(echo "$PR_DATA" | jq -r '.title')
PR_BODY=$(echo "$PR_DATA" | jq -r '.body')

# Check for security indicators in PR body
# Dependabot adds security warnings like:
# "**Vulnerabilities fixed**"
# "Fixes [CVE-2023-XXXX]"
```

**Look for patterns:**

- "Vulnerabilities fixed"
- "CVE-" followed by year and number
- "Security update"
- "Security fix"

If no security indicators found:

- Return: `{is_security_fix: false}`
- Skip remaining phases

### Phase 2: Extract CVE Information

```bash
# Parse CVE identifiers from PR body
# Pattern: CVE-YYYY-NNNNN
CVE_IDS=$(echo "$PR_BODY" | grep -o 'CVE-[0-9]\{4\}-[0-9]\+')

# For each CVE, fetch details with graceful degradation
CVE_RESULTS="[]"
for CVE in $CVE_IDS; do
  if CVE_DATA=$(gh api "/advisories/$CVE" 2>&1); then
    # Check for rate limit in success path
    if echo "$CVE_DATA" | grep -q "API rate limit exceeded"; then
      jq -n '{
        is_security_fix: null,
        error: "Rate limit exceeded",
        details: "GitHub API rate limit reached. Retry after rate limit reset."
      }'
      exit 0  # Graceful degradation
    fi

    CVE_JSON=$(echo "$CVE_DATA" | jq '{
      id: .cve_id,
      severity: .severity,
      summary: .summary,
      published: .published_at,
      fixed_in: .patched_versions[0]
    }')
  else
    # Check for rate limit in error path
    if echo "$CVE_DATA" | grep -q "API rate limit exceeded"; then
      jq -n '{
        is_security_fix: null,
        error: "Rate limit exceeded",
        details: "GitHub API rate limit reached. Retry after rate limit reset."
      }'
      exit 0  # Graceful degradation
    fi

    # CVE not found - create minimal entry with fallback
    CVE_JSON=$(jq -n --arg cve "$CVE" '{
      id: $cve,
      severity: "unknown",
      summary: "CVE details not available in GitHub Advisory Database",
      source_unavailable: true
    }')
  fi
  CVE_RESULTS=$(echo "$CVE_RESULTS" | jq --argjson item "$CVE_JSON" '. + [$item]')
done
```

**Expected output format:**

```json
{
  "cve": "CVE-2023-12345",
  "severity": "high",
  "summary": "Nokogiri vulnerable to XXE via libxml2",
  "published": "2023-04-15T00:00:00Z"
}
```

### Phase 3: Verify Fix Applied

```bash
# Note: fixed_in is collected in Phase 2 for each CVE (see patched_versions[0] in jq)
# Verification happens during Phase 2 when CVE data includes version information

# Check the version being updated to
# PR title: "Bump nokogiri from 1.13.0 to 1.13.10"
NEW_VERSION=$(echo "$PR_TITLE" | grep -o 'to [0-9][^ ]*' | cut -d' ' -f2)

# Version comparison logic (applied in Phase 2 for each CVE with fixed_in data)
verify_version_fix() {
  local new_ver="$1"
  local fixed_ver="$2"

  # Use sort -V to compare versions semantically
  highest=$(printf '%s\n%s\n' "$new_ver" "$fixed_ver" | sort -V | tail -1)

  if [ "$highest" = "$new_ver" ]; then
    return 0  # Fix verified: new version >= fixed version
  else
    return 1  # Version too old
  fi
}

# Iterate through CVE_RESULTS to verify each fix
FIX_VERIFIED="true"
for CVE_RESULT in $(echo "$CVE_RESULTS" | jq -c '.[]'); do
  FIXED_IN=$(echo "$CVE_RESULT" | jq -r '.fixed_in // empty')
  if [ -n "$FIXED_IN" ]; then
    if ! verify_version_fix "$NEW_VERSION" "$FIXED_IN"; then
      FIX_VERIFIED="false"
      break
    fi
  else
    # No version data available - cannot verify
    FIX_VERIFIED="false"
  fi
done
```

**Verification result:**

- Fix verified: New version meets or exceeds patched version
- Fix not verified: Version too old or info unavailable

## Output Format

Return structured JSON for orchestrator:

**Security fix found:**

```json
{
  "is_security_fix": true,
  "cves": [
    {
      "id": "CVE-2023-12345",
      "severity": "high",
      "summary": "Nokogiri vulnerable to XXE",
      "fixed_in": "1.13.10"
    }
  ],
  "severity": "high",
  "fix_verified": true,
  "details": "This update addresses 1 high severity vulnerability"
}
```

**Note:** `fixed_in` field is optional - only present when version data available from GitHub Advisory API.

**Not a security fix:**

```json
{
  "is_security_fix": false,
  "cves": [],
  "severity": null,
  "fix_verified": null,
  "details": "No security advisories found for this update"
}
```

**Security fix but verification failed:**

```json
{
  "is_security_fix": true,
  "cves": [
    {
      "id": "CVE-2023-12345",
      "severity": "high",
      "summary": "Nokogiri vulnerable to XXE"
    }
  ],
  "severity": "high",
  "fix_verified": false,
  "details": "Unable to verify fix version"
}
```

**Note:** When `fixed_in` is missing, verification cannot be performed and `fix_verified` is set to false.

## Error Handling

**GitHub API rate limit:**

- Return: `{is_security_fix: null, error: "Rate limit exceeded"}`
- Orchestrator should skip or manual-review

**CVE not found:**

- Note in output
- Return what's available
- Fix_verified: false

**Cannot parse PR body:**

- Return: `{is_security_fix: false}`
- Continue (not critical)

## Example Execution

```markdown
Input: PR #123

Phase 1: Check if security fix
  - PR body contains: "**Vulnerabilities fixed**"
  - Found: "CVE-2023-12345"
  - Result: IS security fix

Phase 2: Extract CVE info
  - Fetch CVE-2023-12345 from GitHub API
  - Severity: high
  - Summary: "Nokogiri vulnerable to XXE"
  - Fixed in: 1.13.10

Phase 3: Verify fix applied
  - PR updates to: 1.13.10
  - Fixed in: 1.13.10
  - Result: Fix VERIFIED

Output: {is_security_fix: true, severity: "high", fix_verified: true}
```

## Integration with Orchestrator

Orchestrator invokes this agent when:

- PR analyzer indicates potential security fix
- Always check for Dependabot PRs (adds context)

```markdown
Check security advisories for PR #123. Return structured JSON.
```

Agent returns JSON for orchestrator reporting.

## Performance Notes

- Uses Haiku model (simple API calls, cheap)
- Lightweight (only 3 phases, mostly API calls)
- Fast execution (< 10 seconds typical)
- Optional (only called when relevant)
