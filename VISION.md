# Vision

This repo sets up a machine so coding agents can do software engineering on it
with as little waiting and as few interruptions as possible. The person's job
is to start agents, review their output and merge it. Configuration for writing
code by hand is out of scope.

## Who the repo serves

1. Coding agents: Claude Code, Codex, Antigravity and Cursor,
   running on this Mac and in Linux cloud sessions.
2. The person supervising them: starting sessions, reading diffs, getting
   notified when an agent finishes or needs input.

## What a change must do

Accept a change when it does at least one of these:

- Removes a prompt, editor, pager or permission dialog that stops an agent
  until a person answers.
- Makes a command an agent runs faster or available in more shells, including
  a non-login `zsh -c` and a fresh Linux machine.
- Gives every agent tool the same instructions, skills, plugins and MCP
  servers from one declaration in this repo.
- Lets more agents work at the same time without overwriting each other's
  work: worktrees, no shared mutable state.
- Tells the person sooner that an agent finished, failed or is waiting.
- Blocks an action the global instructions forbid, such as an unsigned commit.

## What does not belong

- Editor, IDE and terminal-emulator configuration, themes and keybindings.
- Aliases or functions that change what an existing command does in an agent
  shell.
- Any install step that needs a person at the keyboard when a non-interactive
  path exists.
- A second copy of a list that `dotfiles.yaml` already declares.

tmux and vim stay: tmux hosts agent sessions, and vim is the fallback for the
few edits the person makes by hand.

## How to check a change

- `scripts/test` passes, and new behavior has a test in `tests/`.
- A claim about speed comes with a measurement, before and after.
- The change works with no tty and with an empty environment
  (`env -i HOME=$HOME zsh -c ...`).
