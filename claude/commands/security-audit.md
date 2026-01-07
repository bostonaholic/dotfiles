---
name: security-audit
model: opus
description: Perform comprehensive security and privacy audit of a codebase, especially for newly cloned repositories
---

# Security and Privacy Audit Command

Autonomously perform a comprehensive security and privacy audit of a codebase. This is particularly useful after cloning an open source repository to verify it's safe to run locally.

## Arguments

$ARGUMENTS

### Supported Arguments

- **path** (optional): Path to the codebase to audit
  - If omitted, audits the current working directory
  - Example: `/security-audit ./path/to/repo`

- **--quick** (optional): Perform a faster, less thorough audit
  - Skips dependency deep-dive and some heuristic checks
  - Example: `/security-audit --quick`

- **--focus `<area>`** (optional): Focus on specific risk area
  - Areas: `network`, `filesystem`, `credentials`, `dependencies`, `execution`
  - Example: `/security-audit --focus network`

### Argument Parsing

Parse arguments to extract:

- Path: First non-flag argument (defaults to current directory)
- Quick mode: Check for `--quick` flag
- Focus area: Extract value after `--focus` flag

## Overview

This command invokes the `security-privacy-auditor` agent to coordinate specialized sub-agents:

1. **File Discovery**: Enumerate and categorize all files in the repository
2. **Static Analysis**: Scan for malicious patterns across multiple risk categories
3. **Dependency Analysis**: Check for vulnerable or suspicious packages
4. **Configuration Review**: Examine Docker, CI/CD, and infrastructure configs
5. **Synthesis**: Correlate findings and generate final report card

## What It Detects

**Network and Data Exfiltration:**

- Outbound HTTP/HTTPS to external URLs
- Hardcoded IP addresses or suspicious domains
- WebSocket connections
- Email sending capabilities
- Encoded data transmission

**File System Access:**

- Reading sensitive files (~/.ssh, ~/.aws, credentials)
- Browser data access (cookies, passwords)
- Unexpected file operations

**Code Execution Risks:**

- eval(), exec(), dynamic code execution
- Shell command execution
- Deserialization vulnerabilities

**Obfuscation:**

- Base64 encoded strings
- String concatenation hiding keywords
- Minified code without source maps

**Credentials:**

- Hardcoded API keys, tokens, passwords
- Keychain/credential store access

## Usage Examples

```bash
# Audit current directory
/security-audit

# Audit a specific repository
/security-audit ./newly-cloned-repo

# Quick scan for immediate red flags
/security-audit --quick

# Focus on network exfiltration risks
/security-audit --focus network

# Combine options
/security-audit ./repo --focus credentials
```

## Agent Invocation

Invoke the `security-privacy-auditor` agent:

```yaml
agent: security-privacy-auditor
model: opus
context:
  path: [extracted path or current directory]
  quick_mode: [true/false based on --quick flag]
  focus_area: [extracted focus or null for full audit]
  arguments: "$ARGUMENTS"
```

The orchestrator will:

- Launch file discovery sub-agent
- Dispatch analysis sub-agents for each risk category
- Run dependency vulnerability checks
- Synthesize findings across all phases
- Generate final security report card

## Report Card Output

The audit produces a letter grade from A to F:

- **A (90-100):** No significant concerns. Safe to run locally.
- **B (80-89):** Minor concerns, low risk. Review flagged items.
- **C (70-79):** Moderate concerns. Investigate before use.
- **D (60-69):** Significant concerns. Multiple suspicious patterns.
- **F (<60):** Critical risks. Evidence of malicious intent.

## Expected Output

```text
🔍 Starting Security and Privacy Audit...

📁 Phase 1: File Discovery
  └─ Found 342 files across 47 directories
  └─ High-risk files: 3 shell scripts, 1 binary

🔬 Phase 2: Static Analysis
  ├─ Network patterns: Analyzing...
  ├─ File system access: Analyzing...
  ├─ Code execution: Analyzing...
  └─ Obfuscation: Analyzing...

📦 Phase 3: Dependency Analysis
  └─ Checking 45 dependencies...

⚙️  Phase 4: Configuration Review
  └─ Examining CI/CD and Docker configs...

📊 Phase 5: Synthesis

═══════════════════════════════════════════════
SECURITY AUDIT REPORT CARD
═══════════════════════════════════════════════

Overall Score: B (84/100)

Risk Categories:
  • Data Exfiltration: Low
  • Malicious Code: Low
  • Privacy Violation: Medium
  • Dependency Risk: Low

Critical Findings: None

Warnings:
  ⚠️  src/analytics.js:42 - Sends usage data to external endpoint
  ⚠️  package.json - postinstall script executes shell command

Safe to Run? YES (with noted warnings)

Recommendations:
  1. Review analytics data collection scope
  2. Audit postinstall script contents
═══════════════════════════════════════════════
```

## Notes

- Uses Opus model for comprehensive analysis
- Sub-agents run in parallel where possible
- Findings include exact file paths and line numbers
- False positives are minimized through context analysis
- Critical findings trigger immediate reporting
