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

1. Copy `CLAUDE.md` to your repo root, and `agents/` + `commands/` + `skills/` into `.claude/`.
2. Merge `settings.json` into your `.claude/settings.json`.
3. Open Claude Code and start building. (Full setup details are in the article above.)
---