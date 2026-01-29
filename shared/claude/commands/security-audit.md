---
name: security-audit
model: opus
description: Perform comprehensive security and privacy audit of a codebase, especially for newly cloned repositories
---

# Security and Privacy Audit Command

Autonomously perform a comprehensive security audit of a codebase. Useful after
cloning an open source repository to verify it's safe to run locally.

## Arguments

$ARGUMENTS

### Supported Arguments

- **path** (optional): Path to audit (defaults to current directory)
- **--quick**: Faster, less thorough audit
- **--focus `<area>`**: Focus on specific risk area
  - Areas: `network`, `filesystem`, `credentials`, `dependencies`, `execution`

### Examples

```bash
/security-audit                          # Audit current directory
/security-audit ./newly-cloned-repo      # Audit specific path
/security-audit --quick                  # Quick scan for red flags
/security-audit --focus network          # Focus on network exfiltration
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

The orchestrator uses the `security-analysis` skill and coordinates:

1. **File Discovery**: Enumerate and categorize repository files
2. **Static Analysis**: Scan using skill detection patterns
3. **Dependency Analysis**: Check for vulnerable/suspicious packages
4. **Configuration Review**: Examine Docker, CI/CD configs
5. **Synthesis**: Generate report card with A-F scoring

## Expected Output

Report card with:

- Overall score (A-F)
- Risk categories (Data Exfiltration, Malicious Code, Privacy, Dependencies)
- Critical findings with file paths and code snippets
- Recommendations
- Safe to Run? verdict (YES/NO/CONDITIONAL)

## Notes

- Uses Opus model for comprehensive analysis
- Sub-agents run in parallel where possible
- Critical findings trigger immediate reporting
- See `security-analysis` skill for detection patterns and scoring details
