# Context: Claude Modules — Every File Explained

A complete, file-by-file reference for this repository. This repo is a **library of reusable Claude Code building blocks** — agents, slash commands, skills, and configuration — that you drop into a project's `.claude/` directory to get structured planning → research → implement → validate → handoff workflows.

This document has two parts:

1. **[Part 1 — Every File, One by One](#part-1--every-file-one-by-one)** — what each file is and does.
2. **[Part 2 — The Flow: How Claude Reads These Files](#part-2--the-flow-how-claude-reads-these-files)** — the order and triggers by which Claude Code actually loads each file at runtime.

---

## Repository Map

```
Claude Modules/
├── CLAUDE.md              # Project instructions for Claude Code (auto-loaded)
├── GEMINI.md              # Same instructions, for Gemini
├── QODER.md               # Same instructions, for Qodo
├── README.md              # Human-facing overview of the whole repo
├── context.md             # ← THIS FILE
├── settings.json          # Shared permission allowlist + hooks
├── settings.local.json    # Machine-local permissions (not shared)
│
├── agents/                # 6 sub-agents (workers spawned by commands)
│   ├── codebase-locator.md
│   ├── codebase-analyzer.md
│   ├── codebase-pattern-finder.md
│   ├── thoughts-locator.md
│   ├── thoughts-analyzer.md
│   └── web-search-researcher.md
│
├── commands/              # 14 slash commands (multi-step workflows)
│   ├── create_plan.md            create_plan_nt.md      create_plan_generic.md
│   ├── iterate_plan.md           iterate_plan_nt.md
│   ├── research_codebase.md      research_codebase_nt.md  research_codebase_generic.md
│   ├── implement_plan.md
│   ├── validate_plan.md
│   ├── create_worktree.md
│   ├── debug.md
│   ├── create_handoff.md
│   └── resume_handoff.md
│
└── skills/                # 8 skills (reference knowledge, loaded on demand)
    ├── debug-issue.md
    ├── explore-codebase.md
    ├── review-changes.md
    ├── refactor-safely.md
    ├── ui-skills.md
    ├── ui-best-practice.md
    ├── react-view-trnx.md
    └── visual-qa-testing.md
```

**Three concepts, three roles:**

| Type | Role | When it loads |
|------|------|---------------|
| **Command** | Orchestrator — a multi-step workflow script | When you type `/command_name` |
| **Agent** | Worker — searches/reads/reports back in an isolated context | When a command (or Claude) spawns it via the Task tool |
| **Skill** | Reference guide — knowledge that shapes how Claude writes code | When the skill's `description` matches the task and Claude invokes it |

---

# Part 1 — Every File, One by One

## Root configuration & instruction files

### `CLAUDE.md`
The **project instructions** Claude Code reads automatically at the start of every session in this repo. Two things live here:
- **Line 1: `@AGENTS.md`** — an *import directive*. Claude Code inlines the contents of `AGENTS.md` at this spot. ⚠️ **`AGENTS.md` does not currently exist in this repo**, so this import resolves to nothing — a dangling reference worth knowing about.
- **The rest:** instructions telling Claude to **always use the `code-review-graph` MCP tools before falling back to Grep/Glob/Read**. It lists when to use the graph (exploring code, impact analysis, code review, finding relationships, architecture) and a table of key tools (`detect_changes`, `get_review_context`, `get_impact_radius`, `get_affected_flows`, `query_graph`, `semantic_search_nodes`, `get_architecture_overview`, `refactor_tool`).

### `GEMINI.md`
The **same MCP-graph instructions as `CLAUDE.md`**, but for Google's Gemini tooling. It omits the `@AGENTS.md` import line — otherwise the body is identical.

### `QODER.md`
The **same MCP-graph instructions again**, for the Qodo (Qoder) AI tool. Byte-for-byte identical to `GEMINI.md`. The three files exist so each AI assistant reads native project instructions in its own conventional filename.

### `README.md`
The **human-facing front door**. Explains the repo's purpose, the `Research → Plan → Implement → Validate → Handoff` workflow, how commands spawn agents, how skills differ from agents, and gives reference tables for every agent, command, and skill. Ends with a 4-step **Setup** guide for dropping these modules into another project's `.claude/`. This is documentation *for people*; Claude doesn't auto-load it.

### `settings.json`
The **shared, checked-in Claude Code settings**. Two sections:
- **`permissions.allow`** — an allowlist of Bash commands that run without a permission prompt (e.g. `pnpm lint *`, `git commit -m ' *`, vite dev-server start/stop, `sips` image inspection).
- **`hooks`** — automation the *harness* runs (not the model):
  - **`PostToolUse`** (matches `Edit|Write|Bash`): after any edit/write/bash, runs `code-review-graph update --skip-flows` to keep the knowledge graph current.
  - **`SessionStart`**: runs `code-review-graph status` to report graph state when a session begins.

  Note both hook commands hard-code a `--repo` path pointing at a *different* project (`Truth.fun UI/truth-fun`) — a sign this file was copied from another project and the paths need adjusting when reused (the README's setup step 2 calls this out).

### `settings.local.json`
The **machine-local settings — not meant to be shared**. A much larger `permissions.allow` list capturing project-specific commands the user accumulated while working: `code-review-graph` MCP tool allowlists, dozens of `curl` calls against `localhost:3000/3001` and Solana RPC endpoints, `npm`/`pnpm`/`tsx`/`anchor`/`solana` commands, `python3` JSON-parsing one-liners, etc. It also grants `additionalDirectories` access to `/private/tmp`. This is essentially a personal cache of "don't ask me again" approvals and would differ on every machine.

---

## `agents/` — the 6 worker sub-agents

Each agent file is a Markdown doc with **YAML frontmatter** (`name`, `description`, `tools`, `model`, sometimes `color`) followed by a **system prompt** body. The frontmatter registers the sub-agent; the body becomes its instructions when spawned. All six run on the `sonnet` model and are **read-only documentarians** — a recurring theme is "describe what exists, never critique or suggest improvements."

The agents split into two families: **codebase-** agents (search the actual source) and **thoughts-** agents (search a `thoughts/` docs directory), plus one **web** agent.

### `agents/codebase-locator.md`
**Finds WHERE code lives.** Tools: `Grep, Glob, LS`. Given a feature or topic, it locates files and returns them **grouped by purpose** — implementation, tests, config, type definitions, docs, entry points — with full paths and per-directory file counts. **It does not read file contents or analyze logic.** Think "map of the territory." Strongly worded guardrails forbid it from critiquing structure or suggesting reorganization. This is the `thoughts-locator`'s codebase twin.

### `agents/codebase-analyzer.md`
**Explains HOW code works.** Tools: `Read, Grep, Glob, LS`. It reads the files, traces data flow from entry points through transformations to storage, and documents the implementation with **precise `file:line` references** — entry points, core logic, state management, key patterns, configuration, error handling. Output is structured technical documentation. It explicitly will *not* find bugs, judge quality, or suggest refactors. This is the deepest "read and understand" agent.

### `agents/codebase-pattern-finder.md`
**Finds similar implementations to copy from.** Tools: `Grep, Glob, Read, LS`. Like the locator, but it *reads* and returns **actual code snippets** as templates — e.g. "here's how pagination is done in two places," with the working code, key aspects, and matching test patterns. Used when you want to model new work on existing conventions. Returns concrete examples, not just locations.

### `agents/thoughts-locator.md`
**The `thoughts/` directory equivalent of codebase-locator.** Tools: `Grep, Glob, LS`. Searches a project's `thoughts/` docs tree (research, plans, tickets, PRs, notes) and returns documents grouped by type. A key behavior: it knows about a read-only `thoughts/searchable/` mirror and **rewrites those paths back to the real editable paths** (strips only `searchable/`, preserves the rest). Does not deeply read content — just categorizes.

### `agents/thoughts-analyzer.md`
**Extracts high-value insights from a specific thought document.** Tools: `Read, Grep, Glob, LS`. Where the thoughts-locator finds docs, this one reads one deeply and **filters aggressively** — pulling out firm decisions, trade-offs, constraints, technical specs, and gotchas while discarding exploratory rambling and superseded ideas. Includes a worked "before/after" example of distilling a rambling rate-limiting note into crisp decisions. Acts as a curator, not a summarizer.

### `agents/web-search-researcher.md`
**Researches the web.** Tools: `WebSearch, WebFetch, TodoWrite, Read, Grep, Glob, LS` (color: yellow). The only agent that reaches outside the repo. It plans strategic searches, fetches the most promising pages, and synthesizes findings **with direct quotes, citations, and source links**, noting currency and conflicting sources. Used when a command needs external/up-to-date info (and only when the user explicitly asks for web research).

---

## `commands/` — the 14 slash-command workflows

Each command file has frontmatter (`description`, and for the heavyweight ones `model: opus`) plus a body that is the **step-by-step playbook** Claude follows when you invoke `/command_name`. Commands are the orchestrators: they read context, spawn the agents above in parallel, synthesize results, and (often) write a document.

### The "variants" idea
Several commands ship in **three flavors** distinguished by suffix:

| Suffix | Meaning | Difference |
|--------|---------|-----------|
| *(none)* | **Full** | Integrates a `thoughts/` docs directory; uses `thoughts-locator`/`thoughts-analyzer`; runs `humanlayer thoughts sync` |
| `_nt` | **No-Thoughts** | Same workflow but **skips the thoughts agents and sync** — for projects with no `thoughts/` dir |
| `_generic` | **Generic** | **No project-specific tooling at all** — most portable, fewest assumptions |

### Planning commands

#### `commands/create_plan.md` *(model: opus)*
The flagship. **Builds a phased implementation plan interactively.** The workflow: (1) read every mentioned file *fully* in the main context — no partial reads, no sub-agents yet; (2) spawn `codebase-locator` + `codebase-analyzer` (+ `thoughts-locator`) in parallel to gather context; (3) read all files they surface; (4) present an *informed* understanding and ask only the questions code can't answer; (5) iterate on design options; (6) agree on phase structure; (7) write the plan to `thoughts/shared/plans/YYYY-MM-DD-ENG-XXXX-description.md` using a detailed template; (8) `humanlayer thoughts sync`. Heavy emphasis on **skepticism, verifying corrections against code, separating Automated vs Manual success criteria, and no open questions in the final plan.**

#### `commands/create_plan_nt.md` *(model: opus)*
**Create-plan, No-Thoughts variant.** Identical interactive planning workflow, but drops the `thoughts-locator`/`thoughts-analyzer` steps and the thoughts sync. For codebases that don't keep a `thoughts/` directory.

#### `commands/create_plan_generic.md` *(model: opus)*
**Create-plan, Generic variant.** Same planning loop with no `thoughts/` integration and no project-specific tooling (no `humanlayer`, no Linear). The most portable planner — drop it in any repo.

#### `commands/iterate_plan.md` *(model: opus)*
**Updates an existing plan from feedback.** Parses a plan path + requested changes, then spawns **fresh** codebase (and thoughts) research to verify the requested change against current reality before editing the plan — so iterations stay grounded, not just accepted blindly. Full variant (uses thoughts agents).

#### `commands/iterate_plan_nt.md` *(model: opus)*
**Iterate-plan, No-Thoughts variant.** Same plan-revision workflow using only codebase agents, no `thoughts/` directory.

### Research commands

#### `commands/research_codebase.md` *(model: opus)*
**Documents the codebase as-is to answer a question.** Opens with a hard rule echoed throughout: **document what IS, never evaluate or recommend.** Workflow: read mentioned files fully → decompose the question → spawn `codebase-locator`/`analyzer`/`pattern-finder` and `thoughts-locator`/`analyzer` in parallel → wait for all → synthesize with `file:line` refs → gather metadata (`hack/spec_metadata.sh`) → write a structured research doc to `thoughts/shared/research/` with YAML frontmatter → add GitHub permalinks if pushed → `humanlayer thoughts sync` → handle follow-ups by appending. Full variant (includes `thoughts/`).

#### `commands/research_codebase_nt.md` *(model: opus)*
**Research, No-Thoughts variant.** Same documentation-only research, codebase agents only, no `thoughts/` directory or sync.

#### `commands/research_codebase_generic.md` *(model: opus)*
**Research, Generic variant.** Per the README, the most full-featured *standalone* research command — produces a structured research document with findings, code references, architecture insights, GitHub permalinks, and follow-up support, without assuming any project-specific tooling.

### Execution commands

#### `commands/implement_plan.md`
**Executes an approved plan phase-by-phase.** Reads the plan completely (honoring existing `- [x]` checkmarks to resume), implements one phase, runs that phase's **Automated Verification** (`make check test`), checks off items in the plan file with Edit, then **pauses and asks the human to run the Manual Verification steps** before moving to the next phase. Stresses adapting to reality when code has diverged from the plan, and stopping to surface mismatches rather than forcing the plan.

#### `commands/validate_plan.md`
**Verifies an implementation matches its plan.** Locates the plan, gathers evidence from `git log`/`git diff` and `make check test`, spawns parallel tasks to compare planned vs actual (DB, code, tests), then emits a **Validation Report** grouped by phase — implementation status, automated results, "matches / deviations / potential issues," and the manual testing still required. Read/analyze only; pairs with `/implement_plan` → `/commit` → `/validate_plan` → `/describe_pr`.

#### `commands/create_worktree.md`
**Sets up a git worktree and launches a background implementation session.** Reads `hack/create_worktree.sh`, creates a worktree on the Linear branch, confirms details with the user, then runs `humanlayer launch --model opus -w <worktree>` with a prompt that chains `/implement_plan` → commit → open PR → comment the PR link on the Linear ticket. The shortest command file — heavily `humanlayer`/Linear-specific.

#### `commands/debug.md`
**Investigates issues during manual testing — read-only, no file edits.** Designed to "bootstrap a debugging session without burning the primary window's context." Knows where logs, the SQLite daemon DB, and service processes live, then spawns parallel tasks to (1) scan recent logs for errors, (2) query DB state, (3) check git/file state, and produces a **Debug Report**: what's wrong, evidence, root cause, next steps. Like the research commands, it's `humanlayer`-flavored (paths under `~/.humanlayer/`).

### Session-continuity commands

#### `commands/create_handoff.md`
**Writes a handoff document so another session can pick up the work.** Generates metadata (`scripts/spec_metadata.sh`), then writes a concise-but-thorough doc to `thoughts/shared/handoffs/ENG-XXXX/<timestamp>_..._description.md` with YAML frontmatter and fixed sections: **Task(s), Critical References, Recent changes, Learnings, Artifacts, Action Items & Next Steps, Other Notes.** Prefers `file:line` references over big code blocks. Syncs, then tells the user the exact `/resume_handoff <path>` command to continue.

#### `commands/resume_handoff.md`
**The other half of the handoff loop.** Accepts a handoff file path *or* a ticket number (`ENG-XXXX` → finds the most recent file in `thoughts/shared/handoffs/ENG-XXXX/`). Reads the handoff and its linked plan/research docs fully, spawns research tasks to **verify the handoff's claims against current state** (changes still present? learnings still valid?), presents a reconciled analysis, builds a TodoWrite task list, and resumes work. Includes scenarios for clean continuation, diverged codebase, incomplete work, and stale handoffs.

---

## `skills/` — the 8 reference skills

Skills are different from commands and agents. A skill file has frontmatter (`name`, `description`, sometimes `license`) and a body. **Claude always sees the `description`** (it's listed in the available-skills menu) and uses it to decide *when the skill is relevant*; the **body loads only when the skill is invoked.** Skills don't *do* work — they inject knowledge that shapes how Claude writes or reviews code.

The eight split into two groups: **four graph-powered workflow skills** (thin wrappers over the `code-review-graph` MCP) and **four front-end / UI skills**.

### Graph-powered skills (use the `code-review-graph` MCP)

All four end with the same **Token Efficiency Rules**: always start with `get_minimal_context(task=…)`, use `detail_level="minimal"`, and aim to finish in ≤5 tool calls / ≤800 output tokens.

#### `skills/debug-issue.md`
**A graph-driven debugging recipe.** Steps: `semantic_search_nodes` to find related code → `query_graph` (`callers_of`/`callees_of`) to trace call chains → `get_flow` for execution paths → `detect_changes` to see if a recent change caused it → `get_impact_radius` to see what else is affected. Tip: recent changes are the most common culprit.

#### `skills/explore-codebase.md`
**A graph-driven exploration recipe.** Starts broad (`list_graph_stats`, `get_architecture_overview`, `list_communities`/`get_community`) and narrows (`semantic_search_nodes`, `query_graph` relationships, `list_flows`/`get_flow`). Tips include `children_of` to list a file's members and `find_large_functions` for complexity hotspots.

#### `skills/review-changes.md`
**A graph-driven, risk-scored code review.** `detect_changes` → `get_affected_flows` → `query_graph pattern="tests_for"` on each high-risk function → `get_impact_radius` for blast radius → suggest tests for untested changes. Output is grouped by risk level (high/medium/low) with a final merge recommendation.

#### `skills/refactor-safely.md`
**A graph-driven safe-refactor recipe.** `refactor_tool mode="suggest"` for ideas, `mode="dead_code"` to find unreferenced code, `mode="rename"` to *preview* every affected location, `apply_refactor_tool` to apply, then `detect_changes` to verify. Safety checks: always preview before applying, check impact radius and affected flows first.

### Front-end / UI skills

#### `skills/ui-skills.md` *(frontmatter name: `ui-design-brain`)*
**Production-grade UI generation.** A curated knowledge base of 60+ component patterns (sourced from component.gallery) plus a design philosophy ("restraint over decoration," 8px grid, one strong accent, accessibility non-negotiable, no generic AI aesthetics). Gives a 4-step workflow (identify components → apply best practices → choose one of five style presets: Modern SaaS / Apple-Minimal / Enterprise / Creative / Data Dashboard → generate React + Tailwind code), a 15-component quick-reference table, and an anti-patterns list. References a fuller `components.md` (the 60+ reference). Use before writing any UI.

#### `skills/ui-best-practice.md` *(frontmatter name: `vercel-react-best-practices`)*
**React/Next.js performance optimization — Vercel's 70 rules across 8 categories**, prioritized by impact: Eliminating Waterfalls and Bundle Size (CRITICAL) → Server-Side (HIGH) → Client-Side Data Fetching (MED-HIGH) → Re-render, Rendering (MED) → JavaScript (LOW-MED) → Advanced (LOW). Each rule has a short slug (e.g. `async-parallel`, `bundle-barrel-imports`, `rerender-derived-state`); the skill is the index, and full per-rule files live under `rules/` with a compiled `AGENTS.md`. Apply when writing/reviewing/refactoring React or Next.js.

#### `skills/react-view-trnx.md` *(frontmatter name: `vercel-react-view-transitions`)*
**React View Transition API guide.** Teaches animating between UI states with the browser-native `document.startViewTransition` via React's `<ViewTransition>` — declare *what* with the component, trigger *when* with `startTransition`/`useDeferredValue`/`Suspense`, control *how* with CSS classes. Covers five patterns in priority order (shared element → Suspense reveal → list identity → state change → route change), directional `nav-forward`/`nav-back` slides, transition types, the critical placement rule, multi-VT interaction, `default="none"` discipline, and Next.js integration. Points to `references/` files (`implementation.md`, `patterns.md`, `css-recipes.md`, `nextjs.md`). Use for any route/state-change animation without third-party libs.

#### `skills/visual-qa-testing.md`
**In-browser visual QA after UI changes.** Uses a built-in browser MCP (`cursor-ide-browser`) to: ensure the dev server is up → `browser_navigate` to the page → `browser_take_screenshot` (review layout) → `browser_console_messages` (catch JS errors / hydration mismatches) → `browser_network_requests` (catch 4xx/5xx, CORS) → optionally interact (`browser_click`/`browser_fill`/`browser_hover`) and re-screenshot → report. Tips: snapshot before clicking for element refs; `browser_resize` for responsive checks.

---

# Part 2 — The Flow: How Claude Reads These Files

There are two distinct "reading orders" to understand. The first is **automatic loading by the Claude Code harness** (happens every session, no matter what). The second is **on-demand loading** of commands, agents, and skills (happens only when triggered).

## Stage 0 — Harness startup (before any user message)

These are read by the *runtime*, not pulled into the model's reasoning context as documents:

1. **`settings.json` → then `settings.local.json`** are loaded to build the permission allowlist and register hooks. Local settings layer on top of shared ones.
2. The **`SessionStart` hook** fires → runs `code-review-graph status …`, printing graph state into the session.

## Stage 1 — Project instructions injected into context (session start)

3. **`CLAUDE.md`** is automatically read and injected into the model's context as authoritative project instructions.
4. Because `CLAUDE.md`'s first line is **`@AGENTS.md`**, Claude Code tries to **resolve that import and inline `AGENTS.md`** at that position. *(In this repo `AGENTS.md` is missing, so nothing is inlined — see note in Part 1.)*
5. The result: from message one, Claude knows the **"use the code-review-graph MCP before Grep/Glob/Read"** rule. `GEMINI.md` and `QODER.md` are *not* read by Claude Code — they're for other tools, each read by *their* harness the same way.

> **Not auto-read:** `README.md`, `context.md`, and everything under `agents/`, `commands/`, `skills/` are **not** loaded at startup. Skills are the partial exception — see Stage 2.

## Stage 2 — Skill descriptions become visible (but bodies stay closed)

6. Claude Code surfaces each **skill's frontmatter `description`** in an available-skills list. Claude can *see that the skills exist and what they're for*, but the **body of a skill file is not read until the skill is invoked.** This is why `description` fields are written as precise "use this when…" triggers.

## Stage 3 — On-demand: invoking a command

When the user types a slash command, e.g. `/create_plan`:

7. **The matching `commands/<name>.md` is read in full** and its body becomes the workflow Claude executes. Frontmatter `model: opus` (on the planning/research/iterate commands) can switch the model for that command.
8. The command body then dictates a **deliberate internal reading order**. Using `/create_plan` as the canonical example:
   - **(a) Read mentioned files first, fully, in the main context** — tickets, research docs, JSON. The command is emphatic: *no partial reads, and do not spawn sub-agents before reading these yourself.*
   - **(b) Spawn agents in parallel** (Stage 4) to gather context.
   - **(c) Read every file the agents surfaced**, fully.
   - **(d) Synthesize**, ask only the questions code can't answer, iterate on design, then **write the output document** and sync.

   Other commands impose their own order but follow the same shape (read context → fan out → synthesize → write). `research_codebase.md` even labels the ordering "critical": read files → wait for all agents → gather metadata → write doc, never with placeholders.

## Stage 4 — On-demand: spawning agents

9. When a command spawns a sub-agent via the Task tool, **that `agents/<name>.md` is read** and its body becomes the sub-agent's system prompt. The sub-agent runs in its **own isolated context** with only its allowed tools (e.g. `codebase-locator` gets `Grep, Glob, LS`).
10. **Agents run in parallel** and each **reports a structured result back to the command.** The agent's file reads happen inside the agent's context — they don't bloat the main conversation. The orchestrating command waits for *all* agents, then reads the specific files they pointed to.

A typical fan-out for `/create_plan` or `/research_codebase`:

```
command (main context)
   ├─▶ codebase-locator        → "here's WHERE the code is"
   ├─▶ codebase-analyzer       → "here's HOW it works (file:line)"
   ├─▶ codebase-pattern-finder → "here are similar code snippets"
   ├─▶ thoughts-locator        → "here are related docs"  (full variant only)
   └─▶ thoughts-analyzer       → "here are the key decisions" (full variant only)
        … all run concurrently, then the command synthesizes …
```

## Stage 5 — On-demand: invoking a skill

11. When Claude (or the user) invokes a skill, **the full `skills/<name>.md` body is read** into context and shapes the work — e.g. `ui-skills` + `ui-best-practice` guide *how* UI code gets written, then `visual-qa-testing` verifies it in-browser. The graph skills (`debug-issue`, `explore-codebase`, `review-changes`, `refactor-safely`) inject their MCP-tool recipes the same way.
12. Some skills reference **further files loaded only if needed** — e.g. `ui-skills` → `components.md`, `ui-best-practice` → `rules/*.md` + `AGENTS.md`, `react-view-trnx` → `references/*.md`. These are progressive-disclosure: Claude reads them when the task demands the detail.

## Stage 6 — Continuous: hooks during the session

13. After **every** `Edit`, `Write`, or `Bash` tool call, the **`PostToolUse` hook** fires and runs `code-review-graph update …`, keeping the knowledge graph (that `CLAUDE.md` told Claude to rely on) fresh. This closes the loop: edits update the graph → the graph informs the next exploration.

## The end-to-end product workflow

Stitched together, the commands form the lifecycle the README advertises — each step reading the artifact the previous step wrote:

```
/research_codebase ─▶ writes thoughts/shared/research/…md
        │                         │ (read by)
        ▼                         ▼
/create_plan ──────▶ writes thoughts/shared/plans/…md
        │                         │ (read by)
        ▼                         ▼
/implement_plan ───▶ edits code, checks off [x] in the plan
        │                         │ (read by)
        ▼                         ▼
/validate_plan ────▶ writes a Validation Report (reads git + plan)
        │
        ▼
/create_handoff ──▶ writes thoughts/shared/handoffs/…md
        │                         │ (read by)
        ▼                         ▼
/resume_handoff ◀── reads the handoff to continue in a new session
```

`/debug` and `/create_worktree` sit beside this loop: `/debug` investigates problems read-only at any point, and `/create_worktree` launches `/implement_plan` in a background worktree session.

---

## Quick reference: reading order at a glance

| When | What gets read | Into whose context |
|------|----------------|--------------------|
| Harness boot | `settings.json`, `settings.local.json` | Runtime (permissions/hooks) |
| Session start | `CLAUDE.md` (+ tries `@AGENTS.md`) | Main model context |
| Session start | Skill **descriptions** only | Main model context |
| `/command` typed | `commands/<name>.md` (full body) | Main model context |
| Command step | User-mentioned files (full) | Main model context |
| Command fan-out | `agents/<name>.md` + the files it greps/reads | Isolated sub-agent context |
| Skill invoked | `skills/<name>.md` (+ optional `references/`, `rules/`, `components.md`) | Main model context |
| After every edit | (hook runs `code-review-graph update`) | Runtime side effect |
| Never auto-read | `README.md`, `context.md`, `GEMINI.md`, `QODER.md` | — |
```