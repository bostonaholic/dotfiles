---
name: oss-security-analysis
description: This skill should be used when the user asks to "audit this repo", "is this safe to run", "security audit", "check this clone", "audit security", "check for vulnerabilities", "scan for malicious code", "analyze security risks", "detect data exfiltration", or mentions security patterns, threat detection, or codebase safety assessment.
---

# OSS Security Analysis Skill

End-to-end audit workflow for evaluating the safety of open-source
repositories before running them locally. Covers pre-run safety, dependency
analysis, install script inspection, codebase pattern scanning, and report
generation.

## Audit Workflow

Run these five phases in order. Stop and report immediately if Phase 1
reveals critical risks. Otherwise complete all phases before scoring.

### Phase 1: Pre-Run Safety Check

**Goal:** Determine if it is safe to install dependencies or execute any
code from the repo. Do this BEFORE running any install or build commands.

1. **Identify the ecosystem** — look for `package.json`, `Gemfile`,
   `requirements.txt`, `pyproject.toml`, `Cargo.toml`, `go.mod`,
   `Makefile`, `CMakeLists.txt`, `setup.py`, `setup.cfg`.
2. **Check install hooks** (see Phase 3 details) — if install hooks run
   shell commands, flag them before proceeding.
3. **Check for Makefiles or build scripts** that execute on clone/setup —
   `Makefile` default targets, `configure` scripts, `.github/workflows/`
   that run on `pull_request`.
4. **Verdict:** Is it safe to install dependencies?
   - YES — proceed to Phase 2.
   - CONDITIONAL — install with `--ignore-scripts` (npm) or equivalent
     flag, then continue.
   - NO — report immediately, skip remaining phases.

### Phase 2: Dependency Analysis

**Goal:** Assess third-party dependency risk.

1. **Lockfile review** — check for lockfile presence (`package-lock.json`,
   `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`, `poetry.lock`,
   `Cargo.lock`, `go.sum`). Missing lockfiles increase supply-chain risk.
2. **Known CVEs** — run the ecosystem's audit tool if available:
   - Node.js: `npm audit --json` or `yarn audit --json`
   - Ruby: `bundle audit check` (if `bundler-audit` is available) or
     review `Gemfile.lock` manually
   - Python: `pip-audit` or `safety check`
   - Rust: `cargo audit`
   - Go: `govulncheck ./...`
   If the audit tool is not installed, note it and review lockfile entries
   manually for known-bad packages.
3. **Dependency count and freshness** — flag projects with very large
   dependency trees, unmaintained packages (no updates in 2+ years), or
   packages with very few downloads/stars.
4. **Typosquatting check** — compare package names against well-known
   packages for single-character substitutions or common misspellings.

### Phase 3: Install Script Inspection

**Goal:** Identify code that runs automatically during install or build.

#### Node.js / npm
- `preinstall`, `postinstall`, `prepare`, `prepublish` scripts in
  `package.json` — flag any that invoke `curl`, `wget`, `bash`, `sh`,
  `node -e`, or download remote content.
- Check `.npmrc` for `ignore-scripts=false` or custom registry URLs.

#### Python
- `setup.py` — look for `cmdclass` overrides, subprocess calls,
  or imports of `setuptools.command.install`.
- `pyproject.toml` — check `[tool.setuptools]` and build system hooks.

#### Ruby
- `Gemfile` — look for gems installed from git URLs (not rubygems.org).
- Gem extensions (`extconf.rb`, `Rakefile` in gem directories) that
  compile native code.

#### Rust / Go / C
- `build.rs` (Rust) — check for network calls or shell execution.
- `Makefile` / `CMakeLists.txt` — review default targets, `install`
  targets, and any `$(shell ...)` invocations.
- Go `generate` directives — `//go:generate` that run arbitrary commands.

### Phase 4: Codebase Pattern Scan

**Goal:** Detect malicious patterns, data exfiltration, and privacy
violations in the source code itself.

Use the detection categories and patterns below. For detailed regex/grep
patterns, consult `references/detection-patterns.md`.

#### Detection Categories

##### Network and Data Exfiltration

Patterns indicating unauthorized data transmission:

- Outbound HTTP/HTTPS requests to external URLs
- WebSocket connections to unknown endpoints
- DNS lookups to suspicious domains
- Email sending capabilities
- File upload mechanisms
- Encoded/encrypted data transmission
- Hardcoded IP addresses or domains

##### File System Access

Patterns indicating sensitive file access:

- Reading credential files (~/.ssh, ~/.aws, ~/.env, tokens)
- Accessing browser data (cookies, history, saved passwords)
- Reading system configuration files
- Unexpected file write operations
- Access to other applications' data directories

##### Code Execution Risks

Patterns enabling arbitrary code execution:

- Dynamic code evaluation (eval, exec, Function constructor)
- Shell command spawning (subprocess, spawn, popen)
- Dynamic imports or require statements
- Deserialization of untrusted data
- Template injection vulnerabilities

##### Obfuscation and Evasion

Patterns hiding malicious intent:

- Base64 encoded strings (especially URLs or commands)
- Hex-encoded payloads
- String concatenation to hide keywords
- Minified code without source maps
- Encrypted or packed code sections
- Anti-debugging techniques

##### Credential and Secret Handling

Patterns exposing sensitive data:

- Hardcoded API keys, tokens, or passwords
- Environment variable access patterns
- Keychain/credential store access
- Clipboard monitoring

### Phase 5: Report Generation

**Goal:** Produce a structured report with a clear safety verdict.

#### Output Format

1. **Executive Summary**: 2-3 sentence overview
2. **Overall Score**: Letter grade with numeric score
3. **Phase Results**:
   - Pre-run safety: PASS / CONDITIONAL / FAIL
   - Dependency analysis: finding count by severity
   - Install scripts: CLEAN / FLAGGED (with details)
   - Pattern scan: finding count by category
4. **Risk Categories**: Rating per category (Low/Medium/High/Critical)
5. **Critical Findings**: Highest-severity issues with evidence
6. **Warnings**: Medium-severity items
7. **Informational**: Low-severity or contextual findings
8. **Recommendations**: Specific mitigation actions
9. **Safe to Run?**: Clear YES / NO / CONDITIONAL verdict with conditions

#### Report Card Scoring

Generate a letter grade from A to F:

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | No significant concerns. Safe to run locally. |
| B | 80-89 | Minor concerns, low risk. Review flagged items. |
| C | 70-79 | Moderate concerns. Investigate before use. |
| D | 60-69 | Significant concerns. Multiple suspicious patterns. |
| F | <60 | Critical risks. Evidence of malicious intent. |

Scoring deductions:
- Critical finding: -25 points each
- High-risk finding: -10 points each
- Medium-risk finding: -5 points each
- Low-risk finding: -2 points each
- Missing lockfile: -5 points
- Install hooks with shell execution: -10 points
- Known CVEs (critical/high): -10 points each
- Known CVEs (medium/low): -3 points each

Start from 100 and subtract. Floor at 0.

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
- Known CVEs with available patches

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
- **Fail fast on critical**: If clear malicious code is found, report
  immediately without completing remaining phases
- **Ecosystem awareness**: Different ecosystems have different norms —
  native extensions in Ruby gems are common, postinstall scripts in npm
  packages less so

## Additional Resources

### Reference Files

For detailed grep/regex patterns, consult:

- **`references/detection-patterns.md`** - Comprehensive regex and grep
  patterns for all detection categories, install script inspection, and
  false positive mitigation
