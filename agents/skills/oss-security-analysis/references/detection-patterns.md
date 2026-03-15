# Security Detection Patterns

Detailed patterns for identifying security threats in codebases.

## Network Exfiltration Patterns

### HTTP/HTTPS Requests

```bash
# JavaScript/TypeScript
grep -rE "(fetch|axios|request|http\.get|https\.get)\s*\(" --include="*.js" --include="*.ts"

# Python
grep -rE "(requests\.(get|post)|urllib|httplib|aiohttp)" --include="*.py"

# Ruby
grep -rE "(Net::HTTP|HTTParty|Faraday|RestClient)" --include="*.rb"
```

### Hardcoded URLs/IPs

```bash
# IP addresses
grep -rE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"

# Suspicious domains
grep -rE "(ngrok\.io|pastebin\.com|requestbin|webhook\.site)"
```

### WebSocket Connections

```bash
grep -rE "(new WebSocket|ws://|wss://|socket\.io)"
```

## File System Access Patterns

### Sensitive File Paths

```bash
# SSH/AWS credentials
grep -rE "(~/.ssh|~/.aws|\.env|credentials|\.netrc)"

# Browser data
grep -rE "(Chrome|Firefox|Safari).*(cookies|history|passwords)"

# System files
grep -rE "(/etc/passwd|/etc/shadow|/etc/hosts)"
```

### File Operations

```bash
# Node.js
grep -rE "(fs\.(read|write|unlink|rmdir)|readFileSync|writeFileSync)"

# Python
grep -rE "(open\(|os\.(remove|unlink)|shutil\.(rmtree|copy))"
```

## Code Execution Patterns

### Dynamic Execution

```bash
# JavaScript
grep -rE "\b(eval|Function|setTimeout|setInterval)\s*\("

# Python
grep -rE "\b(eval|exec|compile|__import__)\s*\("

# Ruby
grep -rE "\b(eval|instance_eval|class_eval|send)\s*\("
```

### Shell Execution

```bash
# Node.js
grep -rE "(child_process|exec|spawn|execSync)"

# Python
grep -rE "(subprocess|os\.system|os\.popen|commands\.)"

# Ruby
grep -rE "(system|exec|%x|backticks|\`)"
```

### Deserialization

```bash
# Python pickle
grep -rE "(pickle\.load|yaml\.load\(|marshal\.load)"

# PHP
grep -rE "(unserialize|json_decode.*\$_)"

# Java
grep -rE "(ObjectInputStream|readObject)"
```

## Obfuscation Patterns

### Base64 Encoding

```bash
# Long base64 strings (>50 chars)
grep -rE "[A-Za-z0-9+/]{50,}={0,2}"

# atob/btoa usage
grep -rE "(atob|btoa|base64\.(encode|decode))"
```

### String Manipulation

```bash
# Character code building
grep -rE "(fromCharCode|String\.fromCharCode|chr\()"

# Split/reverse tricks
grep -rE "\.split\(\s*['\"].*['\"]\s*\)\.reverse\(\)"
```

## Credential Patterns

### Hardcoded Secrets

```bash
# API keys (generic pattern)
grep -rE "(api[_-]?key|apikey|secret[_-]?key)\s*[:=]\s*['\"][^'\"]{10,}"

# AWS keys
grep -rE "(AKIA|ABIA|ACCA|ASIA)[A-Z0-9]{16}"

# Private keys
grep -rE "-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"
```

### Environment Access

```bash
# Excessive env access
grep -rE "(process\.env|os\.environ|ENV\[)"
```

## Install Script Patterns

### Package.json Scripts

```bash
# Suspicious npm scripts
grep -rE "(preinstall|postinstall|prepublish).*:(curl|wget|bash|sh|eval)"
```

### Setup.py Patterns

```bash
# Python setup with execution
grep -rE "(cmdclass|install_requires.*subprocess)"
```

## False Positive Mitigation

### Context Indicators

Legitimate use cases to consider:

- Test files (mock data, fixtures)
- Documentation examples
- Development utilities (webpack, babel configs)
- Logging and debugging code
- Configuration templates

### Scoring Adjustments

Reduce severity when:

- Pattern is in test directory
- File is clearly documentation
- Pattern is commented out
- Surrounding code provides legitimate context
