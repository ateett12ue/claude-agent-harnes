---
description: Install or update the Claude Modules harness (agents, commands, skills, CLAUDE.md, settings) into the current project.
argument-hint: "[target-dir]  (defaults to the project root)"
allowed-tools: Bash(curl:*), Bash(bash:*), Bash(jq:*), Bash(cat:*), Bash(ls:*), Bash(test:*)
---

You are installing/updating the **Claude Modules** harness into a project.

**Target directory:** use `$ARGUMENTS` if provided, otherwise the current project root (`$CLAUDE_PROJECT_DIR`, falling back to `$PWD`).

The installer is idempotent — it always pulls the latest from
`github.com/ateett12ue/claude-agent-harnes`, copies `agents/`, `commands/`,
`skills/` into `.claude/`, writes the managed `CLAUDE.md` (backing up any
existing one to `CLAUDE.md.orig`), and deep-merges `settings.json` +
`settings.local.json` without clobbering the user's own permissions or hooks.

## Steps

1. Run the installer with the Bash tool, streaming its output. Pass the target
   directory as an argument when the user supplied one:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/ateett12ue/claude-agent-harnes/main/install.sh | bash -s -- "${ARGUMENTS:-${CLAUDE_PROJECT_DIR:-$PWD}}"
   ```

2. Verify the result:
   - `.claude/agents`, `.claude/commands`, `.claude/skills` exist.
   - `CLAUDE.md` exists at the project root and its first line contains
     `claude-modules:managed`.
   - `.claude/settings.json` parses as JSON and still contains any
     pre-existing permissions/hooks the project already had.

3. Summarize what was added vs. merged, note if an existing `CLAUDE.md` was
   preserved as `CLAUDE.md.orig`, and remind the user to **restart Claude Code**
   in this project so the `SessionStart` hook runs (graph build + CLAUDE.md
   backup).

If the install fails (e.g. network error, missing `jq`), report the exact error
and the manual fallback: clone the repo and run `install.sh` directly.
