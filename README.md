# Claude Code Multi-Agent Dev System

A drop-in system of 32 coordinated Claude agents that take your project from idea to committed code. You describe what to build — the PM agent orchestrates the rest.

---

## How it works

Run the `pm` agent. It selects the next task, runs the full pipeline automatically, and stops only when it needs your input.

**What PM does on its own:**
```
validate task → architect (if needed) → developer → smoke test (UI only)
→ code review + security (parallel) → tests → changelog → reality check → git commit
```

**When PM stops and asks you:**
- Found an unanswered question in `tz.md` that blocks development
- Architect needs a spike before designing the solution
- Linter fails 3 times in a row
- Reality checker returns a critical blocker

---

## Quick start

Copy the `.claude/` folder and other root files into your project directory and run `claude`.

**New project:**
```
ux-interviewer agent   → design brief
business-analyst agent → requirements (tz.md)
estimator agent        → timeline
decomposer agent       → tasks (backlog.md)
pm agent               → development (repeat per task)
```

**Existing project:**
```
onboarding agent   → reads codebase, populates memory/
pm agent           → development
```

**Add a feature to an existing project:**
```
Tell PM: "add X"   → PM runs business-analyst in amend mode automatically
```

Not sure where to start? Run `/start` for guided onboarding.

---

## Agents

### Run once per project (you invoke these)

| Agent | What it does |
|-------|-------------|
| `ux-interviewer` | Interviews you about design → `design-brief.md` |
| `ui-designer` | Builds a design system → `design-spec.md` with CSS tokens |
| `business-analyst` | Collects requirements → `tz.md` (also handles amend for new features) |
| `estimator` | Calculates timeline from task complexity → `timeline.md` |
| `decomposer` | Breaks requirements into tasks → `backlog.md` + `tasks/` |
| `onboarding` | Reads an existing codebase → populates `memory/` |

### Run automatically by PM (you don't think about these)

| Agent | When |
|-------|------|
| `handoff-validator` | Before every task |
| `architect` | For L/XL tasks or API/DB/schema changes |
| `developer` | Implementation |
| `smoke-tester` | After developer, UI changes only |
| `code-reviewer` | After developer, always |
| `security-analyst` | Parallel with code-reviewer, always |
| `unit-tester` | For tasks with business logic |
| `integration-tester` | Parallel with unit-tester |
| `test-reviewer` | If more than 5 tests were written |
| `changelog-agent` | After every task |
| `reality-checker` | Final gate before commit |
| `context-summarizer` | If task file exceeds 200 lines |

### Run manually when needed

| Agent | When to run |
|-------|------------|
| `rapid-prototyper` | Technical uncertainty before a task (spike) |
| `refactoring` | Once per phase or when you see code degradation |
| `dependency-auditor` | Before release or once per sprint |
| `migration-validator` | Before applying DB migrations to production |
| `performance-profiler` | For speed/optimization tasks |
| `accessibility-auditor` | Once per phase or before release |
| `e2e-tester` | Critical user flows only |
| `env-manager` | When adding new environment variables |
| `git-workflow` | If using feature branches instead of direct commits |
| `devops` | CI/CD, Docker, infrastructure |
| `database-architect` | DB schema design, parallel with architect |
| `status` | See what's currently happening in the project |

---

## Slash commands

### Project setup

| Command | What it does |
|---------|-------------|
| `/start` | Guided onboarding — detects project state and routes you to the right workflow |
| `/onboard` | Read existing codebase and populate `memory/` |
| `/ux` | UX discovery interview → `design-brief.md` |
| `/design` | Build design system from brief → `design-spec.md` |
| `/ba [feature]` | Collect requirements → `tz.md` (or amend for a new feature) |
| `/decompose` | Break requirements into tasks → `backlog.md` + `tasks/` |
| `/estimate` | Calculate timeline from backlog complexity → `timeline.md` |

### Development

| Command | What it does |
|---------|-------------|
| `/status` | Current project state: progress, active tasks, blockers |
| `/next-task` | Top 3 tasks ready to run with explanation |
| `/new-task` | Create a task file and add it to backlog |
| `/fix [TASK-XXX]` | Quick-run a task without dry-run |
| `/spike [hypothesis]` | Technical spike to validate a hypothesis before committing |
| `/refactor [area]` | Reduce technical debt without changing behavior |
| `/db [schema]` | DB schema design, migrations, query optimization |
| `/devops [task]` | CI/CD, Docker, infrastructure, environment config |
| `/git-workflow [branch]` | Feature branch + PR workflow instead of direct commits |
| `/env` | Sync `.env.example`, validate env vars across environments |

### Quality & testing

| Command | What it does |
|---------|-------------|
| `/dep-audit` | Scan dependencies for CVEs and outdated packages |
| `/validate-migration [file]` | Validate DB migration for production safety |
| `/perf [area]` | Profile bundle size, Lighthouse, N+1 queries, response times |
| `/a11y` | WCAG 2.2 AA audit — keyboard, screen reader, contrast |
| `/e2e [flow]` | Playwright E2E tests for critical user flows |

### Incidents & maintenance

| Command | What it does |
|---------|-------------|
| `/hotfix [description]` | Emergency fix bypassing normal pipeline |
| `/bug-report [description]` | Structured bug report, or `analyze [path]` to scan a file |
| `/scope-check` | Detect scope creep vs original tz.md requirements |
| `/tech-debt scan\|add\|prioritize\|report` | Manage technical debt register |

---

## File structure

```
.claude/
├── agents/          ← agent prompts
├── commands/        ← slash command definitions
├── hooks/           ← automation hooks (session start, blockers, pre-compact)
├── decisions/       ← ADR files (written by architect)
├── pm-ref.md        ← pipeline reference for PM
├── tz-template.md   ← requirements template
├── statusline.sh    ← status bar script
└── settings.json    ← permissions and hooks config

memory/              ← project knowledge (stack, patterns, decisions, known issues)
tasks/               ← task files (spec + full pipeline handoff in one file)
tasks/archive/       ← completed tasks
handoffs/            ← agent audit log, session log, hotfix records
locks.json           ← files locked during active tasks (managed by PM)
progress.log         ← action log and watchdog events
backlog.md           ← task index (links only)
tz.md                ← active requirements: open REQs, open OQs, constraints
tz-archive.md        ← completed REQs (PM archives after task close, agents never read)
design-brief.md      ← design brief (created by ux-interviewer)
design-spec.md       ← design system (created by ui-designer)
timeline.md          ← timeline (created by estimator)
CLAUDE.md            ← rules for all agents
```

> `memory/` and `locks.json` live outside `.claude/` intentionally — Claude Code prompts for confirmation when writing to `.claude/`, which interferes with autonomous agent operation.

---

## Session hooks

The system includes hooks that run automatically:

| Hook | Event | What it does |
|------|-------|-------------|
| `session-start.sh` | Session start | Shows branch, recent commits, open tasks, blockers |
| `detect-gaps.sh` | Session start | Detects missing tz.md, empty backlog, BLOCKED tasks |
| `check-blockers.ps1` | After each agent | Blocks PM if new open questions appear in tz.md |
| `stop-check.ps1` | Session end | Nudges continuation if pipeline is incomplete |
| `pre-compact.sh` | Before context compaction | Dumps in-progress task state so it survives summarization |
| `validate-commit.sh` | Before Bash | Blocks `--no-verify`, prevents committing `.env` files |
| `validate-push.sh` | Before Bash | Blocks force push |
| `log-agent.sh` | Agent invocation | Writes audit log to `handoffs/agent-audit.log` |
| `session-stop.sh` | Session end | Logs session summary to `handoffs/session-log.md` |

---

## Anthropic docs
- [Claude Code Agents](https://docs.anthropic.com/en/docs/claude-code/agents)
- [Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Memory](https://docs.anthropic.com/en/docs/claude-code/memory)
