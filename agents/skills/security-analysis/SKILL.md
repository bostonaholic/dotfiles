---
name: security-analysis
description: This skill should be used when the user asks to "audit security", "check for vulnerabilities", "scan for malicious code", "analyze security risks", "detect data exfiltration", or mentions security patterns, threat detection, or codebase safety assessment.
---

# Security Analysis Skill

Provides expertise in detecting security threats, malicious patterns, and
privacy violations in codebases.

## Purpose

Equip agents with patterns and techniques for:

- Detecting malicious code patterns and data exfiltration
- Identifying privacy-violating behaviors
- Assessing codebase security risks
- Generating actionable security reports

## When to Use

- Auditing newly cloned repositories before running locally
- Reviewing code for security vulnerabilities
- Analyzing dependencies for suspicious behavior
- Generating security report cards

## Detection Categories

### Network and Data Exfiltration

Patterns indicating unauthorized data transmission:

- Outbound HTTP/HTTPS requests to external URLs
- WebSocket connections to unknown endpoints
- DNS lookups to suspicious domains
- Email sending capabilities
- File upload mechanisms
- Encoded/encrypted data transmission
- Hardcoded IP addresses or domains

### File System Access

Patterns indicating sensitive file access:

- Reading credential files (~/.ssh, ~/.aws, ~/.env, tokens)
- Accessing browser data (cookies, history, saved passwords)
- Reading system configuration files
- Unexpected file write operations
- Access to other applications' data directories

### Code Execution Risks

Patterns enabling arbitrary code execution:

- eval(), exec(), or dynamic code execution
- Shell command execution (child_process, subprocess, os.system)
- Dynamic imports or require statements
- Deserialization of untrusted data
- Template injection vulnerabilities

### Obfuscation and Evasion

Patterns hiding malicious intent:

- Base64 encoded strings (especially URLs or commands)
- Hex-encoded payloads
- String concatenation to hide keywords
- Minified code without source maps
- Encrypted or packed code sections
- Anti-debugging techniques

### Credential and Secret Handling

Patterns exposing sensitive data:

- Hardcoded API keys, tokens, or passwords
- Environment variable access patterns
- Keychain/credential store access
- Clipboard monitoring

## Report Card Scoring

Generate a letter grade from A to F:

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | No significant concerns. Safe to run locally. |
| B | 80-89 | Minor concerns, low risk. Review flagged items. |
| C | 70-79 | Moderate concerns. Investigate before use. |
| D | 60-69 | Significant concerns. Multiple suspicious patterns. |
| F | <60 | Critical risks. Evidence of malicious intent. |

## Risk Classification

### Critical (Immediate Report)

- Clear evidence of malicious code
- Active data exfiltration mechanisms
- Credential theft patterns
- Remote code execution backdoors

### High Risk

- Multiple suspicious patterns combined
- Obfuscated network communication
- Unauthorized file access to sensitive paths
- Install/postinstall scripts with shell execution

### Medium Risk

- Single suspicious pattern with legitimate use case possible
- Overly broad file access permissions
- Deprecated security practices

### Low Risk

- Minor security hygiene issues
- Missing best practices
- Informational findings

## Analysis Principles

- **Context matters**: A network library making HTTP requests is expected;
  a date formatter doing so is suspicious
- **Minimize false positives**: Distinguish between capability and intent
- **Consider attack chains**: Multiple low-severity findings may combine
  into high-severity risks
- **Preserve evidence**: Include exact file paths, line numbers, and code
  snippets for all findings
- **Fail fast on critical**: If clear malicious code is found, report immediately

## Output Format

Structure findings as:

1. **Executive Summary**: 2-3 sentence overview
2. **Overall Score**: Letter grade with numeric score
3. **Risk Categories**: Rating per category (Low/Medium/High/Critical)
4. **Critical Findings**: Highest-severity issues with evidence
5. **Warnings**: Medium-severity items
6. **Informational**: Low-severity or contextual findings
7. **Recommendations**: Specific mitigation actions
8. **Safe to Run?**: Clear YES/NO/CONDITIONAL verdict

## Additional Resources

### Reference Files

For detailed patterns, consult:

- **`references/detection-patterns.md`** - Comprehensive regex and grep patterns
