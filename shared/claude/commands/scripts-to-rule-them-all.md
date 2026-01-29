---
name: scripts-to-rule-them-all
model: sonnet
description: Implement GitHub's 'scripts-to-rule-them-all' pattern for any project by detecting its architecture and creating standardized scripts
---

# Scripts to rule them all

Implement GitHub's 'scripts-to-rule-them-all' pattern for the current project. First, detect the project's architecture by examining configuration files (package.json, Gemfile, requirements.txt, Cargo.toml, etc.) and identify:

- Primary language and framework
- Package manager and dependency system
- Build, test, and run commands
- Development server approach

Then create all seven standard scripts (bootstrap, setup, update, server, test, console, cibuild) in a `script/` directory. Each script should:

- Use the project's native toolchain and commands
- Be idempotent and platform-agnostic
- Include dependency checks appropriate to the detected stack
- Call other scripts as needed (setup→bootstrap, update→bootstrap)
- Provide clear feedback about what they're doing

Adapt each script's implementation to match the project's conventions while maintaining the standardized interface.
