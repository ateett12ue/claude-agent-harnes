# Claude Modules

Hey folks 👋

This is the `.claude/` setup I use to turn Claude Code from a chatbot into a real **engineering harness** — drop it into any project and go.

**What's inside:**
- 🧠 **Agents** — focused sub-workers for locating, analyzing, and researching code
- ⚡ **Commands** — slash workflows for the full loop: research → plan → implement → validate → handoff
- 🛠️ **Skills** — reference playbooks for debugging, reviewing, refactoring, and building UI
- ⚙️ **settings.json** — permissions + hooks, so you stop blindly approving every prompt
- 🌐 **Code-graph integration** — Claude explores your codebase *structurally* instead of grepping blindly

## 📄 Read the full walkthrough

I wrote up the whole thing on Medium — the why, the how, and how it all fits together:

**→ [How to make Claude Code smarter: the `.claude` folder setup I use in VS Code](https://medium.com/@ateet.tiwari1012/how-to-make-claude-code-smarter-the-claude-folder-setup-i-use-in-vs-code-2889657289cf)**


## 🚀 Quick start

### One command (recommended)

From the root of any project, run:

```bash
curl -fsSL https://raw.githubusercontent.com/ateett12ue/claude-agent-harnes/main/install.sh | bash
```

That's it. The installer (idempotent — safe to re-run to update):

- copies `agents/`, `commands/`, `skills/` into `.claude/`
- writes the managed `CLAUDE.md` to the repo root (any existing one is backed up to `CLAUDE.md.orig`)
- deep-merges `settings.json` + `settings.local.json` into `.claude/` **without** clobbering permissions/hooks you already have

Install into a specific directory: append `| bash -s -- /path/to/project`.

Then restart Claude Code so the `SessionStart` hook runs.

### From inside Claude Code

Drop [`commands/claude-modules.md`](commands/claude-modules.md) into `~/.claude/commands/`
(once), then run `/claude-modules` in any project to install or update the harness.

### Manual

1. Copy `CLAUDE.md` to your repo root, and `agents/` + `commands/` + `skills/` into `.claude/`.
2. Merge `settings.json` and `settings.local.json` into your `.claude/` versions.
3. Open Claude Code and start building. (Full setup details are in the article above.)
---