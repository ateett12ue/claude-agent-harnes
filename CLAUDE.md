<!-- claude-modules:managed — keep this comment. settings.json's SessionStart hook uses it to back up this file and auto-restore it if `code-review-graph install` ever overwrites it. -->

# Project Operating Manual

How to work in this project: run at full capability, spend tokens only where
they buy correctness. This is the single source of truth — edit it here.

---

## 1. Operating principles — full capacity, low waste

- **Graph before grep.** This repo has a `code-review-graph` knowledge graph
  (§2). Use its MCP tools to explore, trace, and review *before* reaching for
  Grep/Glob/Read — they're faster, cheaper, and return structural context
  (callers, dependents, tests) that file scanning can't.
- **Keep the main context lean.** Delegate broad, file-dumping searches to
  sub-agents (§4) and synthesize their conclusions — don't pull whole files
  into the main thread to "look around." Read the *slice* you need, not the
  whole file (exception: a command may tell you to read a named file fully
  before planning — honor that).
- **Match the model to the task.** Cheap, parallel search/locate work →
  `sonnet`. Architecture, planning, tricky reasoning → `opus`. The agents and
  commands already pin sensible models; trust them.
- **Parallelize.** Independent reads, searches, and sub-agents go out in one
  batch, not one-at-a-time.
- **Stop when the question is answered.** Don't explore past a confident answer,
  re-derive facts already in context, or re-read files you've already read.
- **Think hard on the hard parts.** Use deeper reasoning for design trade-offs,
  ambiguous requirements, and root-cause analysis — not for mechanical edits.

---

<!-- code-review-graph MCP tools -->
## 2. Knowledge graph — `code-review-graph` (use FIRST)

**This project has a code knowledge graph. Use the `code-review-graph` MCP tools
BEFORE Grep/Glob/Read.** Always start a graph task with
`get_minimal_context(task="<what you're doing>")` at `detail_level="minimal"`;
escalate to `"standard"` only when minimal is insufficient. Target: finish any
explore/review/debug/refactor task in ≤5 graph calls. If the graph is missing or
stale, call `build_or_update_graph_tool` (the `SessionStart` hook also refreshes
it automatically — see the hooks in `settings.json`).

| Need | Tool |
|------|------|
| Orient on a task with minimal tokens | `get_minimal_context` |
| Find a function/class by name or concept | `semantic_search_nodes` |
| Trace callers / callees / imports / tests | `query_graph` (`callers_of`, `callees_of`, `imports_of`, `tests_for`) |
| High-level structure & modules | `get_architecture_overview`, `list_communities`, `get_community` |
| Review a change set (risk-scored) | `detect_changes` + `get_review_context` |
| Blast radius of a change | `get_impact_radius` |
| Which execution paths are affected | `get_affected_flows`, `list_flows`, `get_flow` |
| Plan renames / find dead code | `refactor_tool` → `apply_refactor_tool` |
| Overall metrics / complexity | `list_graph_stats`, `find_large_functions` |

Fall back to Grep/Glob/Read **only** when the graph genuinely doesn't cover the
need (e.g. non-code files, config, comments).
<!-- /code-review-graph MCP tools -->

---

## 3. The core workflow

A plan-then-implement loop. Each step is a slash command (§5).

```
Research ──> Plan ──> Implement ──> Validate ──> Handoff
                                         │
                         /debug (read-only) at any point
```

1. **`/research_codebase`** — understand the current state (parallel agents, no edits).
2. **`/create_plan`** — phased, interactive implementation plan.
3. **`/implement_plan`** — execute phase-by-phase with verification gates.
4. **`/validate_plan`** — confirm the implementation matches the plan.
5. **`/create_handoff`** — capture state so the next session can resume.

---

## 4. Agents (sub-agent workers — spawn in parallel)

Workers that search/read/report back. Commands spawn these; you can too. They
keep heavy exploration out of the main context.

| Agent | Use for |
|-------|---------|
| `codebase-locator` | *Where* code lives — files grouped by purpose (no analysis). |
| `codebase-analyzer` | *How* code works — data flow & logic with `file:line` refs. |
| `codebase-pattern-finder` | Existing patterns / similar implementations — returns real snippets. |
| `thoughts-locator` | Find docs in a `thoughts/` directory (tickets, plans, research). |
| `thoughts-analyzer` | Extract decisions/constraints from a specific `thoughts/` doc. |
| `web-search-researcher` | External research with cited sources. |

> The `thoughts-*` agents assume a `thoughts/` directory. In projects without
> one, use the `_nt` / `_generic` command variants (§5) and skip them.

---

## 5. Commands (slash workflows)

| Command | Does | Variants |
|---------|------|----------|
| `research_codebase` | Document the codebase as-is (parallel agents, no critique). | `_nt` (no `thoughts/`), `_generic` (portable + recommendations) |
| `create_plan` | Interactive phased plan with research. | `_nt`, `_generic` |
| `iterate_plan` | Revise an existing plan with fresh research. | `_nt` |
| `implement_plan` | Execute a plan phase-by-phase with auto + manual gates. | — |
| `validate_plan` | Verify implementation vs. plan; pass/fail report. | — |
| `debug` | Read-only investigation (logs, state, git history). | — |
| `create_worktree` | Git worktree + background implementation session. | — |
| `create_handoff` / `resume_handoff` | Persist / resume session state. | — |

**Variant guide:** *(none)* = uses a `thoughts/` directory · `_nt` = no
`thoughts/` · `_generic` = no project-specific tooling (most portable).

---

## 6. Skills (reference knowledge — invoke by name)

Skills shape *how* work gets done. The graph-powered four pair with §2.

**Graph-powered:** `Explore Codebase` · `Debug Issue` · `Review Changes` ·
`Refactor Safely` — each enforces the token rules in §2.

**UI / React:**
- `ui-design-brain` — production-grade UI: 60+ component patterns, 5 design presets.
- `vercel-react-best-practices` — 70 React/Next.js performance rules by impact.
- `vercel-react-view-transitions` — View Transition API (shared-element morphs, route slides, Suspense reveals, Next.js).
- `visual-qa-testing` — in-browser QA: screenshots, console errors, network audits.

---

## 7. Token-economy checklist

- [ ] Started graph work with `get_minimal_context` at `detail_level="minimal"`.
- [ ] Used the graph (§2) before Grep/Glob/Read.
- [ ] Delegated broad searches to sub-agents; kept the main context lean.
- [ ] Read only the needed slice (unless a command says read fully).
- [ ] Ran independent calls in parallel.
- [ ] Matched model to task; stopped once the answer was confident.
