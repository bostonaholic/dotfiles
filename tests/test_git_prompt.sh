#!/bin/bash
################################################################################
# Git Prompt -- Acceptance Tests
#
# DESCRIPTION:
#   Verifies zsh/zshrc wires git's git-prompt.sh into the prompt for a person
#   at an interactive shell, and skips it in agent shells.
#
# USAGE:
#   ./tests/test_git_prompt.sh   (or run the whole suite via: scripts/test)
#
################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_MARKERS=(CLAUDECODE CLAUDE_CODE_ENTRYPOINT AI_AGENT CURSOR_AGENT CODEX_SANDBOX DOTFILES_AGENT_SHELL)
UNSET=()
for m in "${AGENT_MARKERS[@]}"; do UNSET+=(-u "$m"); done

probe() {
    env "${UNSET[@]}" "$@" ZDOTDIR=/nonexistent /bin/zsh -ic "
        source '$REPO_ROOT/zsh/zshenv'; source '$REPO_ROOT/zsh/zshrc'
        cd '$REPO_ROOT'; (( \${+functions[dotfiles_git_prompt]} )) && dotfiles_git_prompt
        print -r -- \"hooks=\$precmd_functions\"; print -r -- \"PS1=\$PS1\"" 2>/dev/null
}

fails=0
person="$(probe)"
if [[ "$person" == *"hooks=dotfiles_git_prompt"* && "$person" == *"PS1=%m:%~ ("* ]]; then
    echo "  PASS  person shell shows git branch in prompt"
else
    echo "  FAIL  person shell: $person"; fails=1
fi

agent="$(probe CLAUDECODE=1)"
if [[ "$agent" != *dotfiles_git_prompt* ]]; then
    echo "  PASS  agent shell skips git prompt"
else
    echo "  FAIL  agent shell: $agent"; fails=1
fi

exit "$fails"
