# PM Reference

## Full pipeline
```
BA → tz.md (architect estimation: XS/S/M/L/XL per REQ)
Decomposer → backlog.md index + tasks/TASK-NNN.md files
PM: dry-run → OQ check → stale locks → git checkpoint → lock files
HandoffValidator → [Architect: L/XL or new API/DB/schema] → Developer
[web UI] SmokeTester
Bash: lint bisect + test suite
CodeReviewer + SecurityAnalyst (parallel, diff-aware) [retry ≤3]
UnitTester + IntegrationTester (parallel) [business logic only] → TestReviewer [>5 tests]
Documentation → changelog-agent → RealityChecker
git commit → archive task file → unlock → progress.log → tz.md REQ ✅ → memory
[phase complete] git tag → retro (3 questions to user)
```

Lightweight routes:
```
docs only:    BA → documentation → reality-checker
audit only:   dependency-auditor → reality-checker
refactor:     refactoring → code-reviewer → reality-checker
spike:        rapid-prototyper → (CONFIRMED) → task in backlog
```

## Estimation → Pipeline mapping

| complexity | architect | developer model | unit tests | retry limit |
|-----------|-----------|----------------|------------|-------------|
| XS | skip | sonnet | no | 2 |
| S | skip | sonnet | no | 2 |
| M | optional | sonnet | per task | 3 |
| L | required | sonnet | yes | 3 |
| XL | required | opus | yes | 3 |

Architect always required: new endpoints, DB schema changes, cross-service deps, security-sensitive.

## OQ priority format
```
OQ-XXX [blocker:project] — blocks all, answer first
OQ-XXX [blocker:track]   — blocks specific track
OQ-XXX [blocker:task]    — blocks one task only
```
Show user ordered: project → track → task.

## Watchdog
Partial failure if: response <100 words without status code OR no section appended to task file.
Log to progress.log. Retry. Max 2 watchdog retries (separate from gate retries).

## Targeted re-delegation
On NEEDS_WORK: read "delegate to" section in reality-checker output.
Delegate only named agents. No full pipeline restart.
After fixes → reality-checker only.

## Lint bisect
```bash
git diff HEAD~1 --name-only | xargs -I{} sh -c '[lint_cmd] {} 2>&1 && echo OK:{} || echo FAIL:{}'
```
Pass developer only FAIL files + errors.

## Phase retro
After `git tag phase-N-complete` — ask user:
1. What went wrong? → known-issues.md
2. Recurring patterns? → patterns.md with [recurring] tag
3. Change next phase? → decisions.md

## Models

| tier | model | agents |
|------|-------|--------|
| opus | claude-opus-4-6 | pm, architect (L/XL tasks), developer (XL override) |
| sonnet | claude-sonnet-4-6 | developer, ba, decomposer, code-reviewer, security-analyst, integration-tester, smoke-tester, e2e-tester, accessibility-auditor, test-reviewer, refactoring, devops, dependency-auditor, reality-checker, rapid-prototyper, database-architect |
| haiku | claude-haiku-4-5 | handoff-validator, unit-tester, documentation, status |

PM can override model in agent instruction for non-standard tasks.

## Agent audit (every 10 tasks)
If agent consistently underperforms:
1. error patterns — what do failing tasks have in common?
2. instruction misunderstanding — wrong role/task?
3. output format — structural issues?
4. context loss — large tasks degrading?
5. tool misuse — wrong tools?

Fix: add example of WRONG behavior to description + specific rule to prompt body. Log in .claude/decisions/adr-*.md.

## Task file template
```markdown
# TASK-NNN: [name]

## spec
agent: developer|database-architect|devops|architect
track: [name]
complexity: XS|S|M|L|XL
priority: high|medium|low
depends_on: TASK-NNN | none
files: [list]
req: REQ-NNN

description:
[what + acceptance criteria]

## context
[relevant memory excerpts — paths not content]

---
```

## Backlog index format
```markdown
# Backlog

> created: [date] · project: [name] · progress: 0/N done

## Phase 1: [name]
- [ ] TASK-001 [S] feat/auth · track:auth · deps:none → tasks/TASK-001.md
- [x] TASK-002 [M] feat/users · track:users · deps:TASK-001 → tasks/archive/TASK-002.md

## Phase 2: [name]
...
```

## Persistent files

| file | purpose | writer |
|------|---------|--------|
| tz.md | reqs, AC, OQ | BA + agents |
| backlog.md | index of tasks (links only) | PM, decomposer |
| tasks/TASK-NNN.md | full task + handoff | PM + all agents |
| tasks/archive/ | completed tasks | PM |
| memory/stack.md | tech stack | PM, architect |
| memory/patterns.md | code patterns + [recurring] | PM, developer |
| memory/decisions.md | architectural decisions | PM, architect |
| memory/known-issues.md | issues, workarounds + [recurring] | PM, any agent |
| .claude/decisions/adr-*.md | detailed ADRs | architect |
| .claude/locks.json | locked files with timestamp | PM |
| .claude/progress.log | action log + watchdog events | PM |

## New agents in v0.7

| agent | model | when to run |
|-------|-------|-------------|
| ux-interviewer | sonnet | once per project, before ui-designer |
| ui-designer | sonnet | once per project, after ux-interviewer |
| changelog-agent | haiku | end of every task pipeline (before git commit) |
| estimator | sonnet | after decomposer, once per project/phase |
| onboarding | sonnet | once when adopting system on existing project |
| git-workflow | sonnet | replaces PM git steps when using branch workflow |
| env-manager | haiku | when adding env vars or before deploy |
| performance-profiler | sonnet | after implementation for perf-sensitive tasks |
| migration-validator | sonnet | before applying DB migrations to production |
| context-summarizer | haiku | when task file > 200 lines or CONTEXT_OVERFLOW |

## Design workflow
```
ux-interviewer → design-brief.md
ui-designer    → design-spec.md
[all frontend tasks] developer reads design-spec.md automatically
```

## Feature addition workflow
User: "I want to add X" → PM triggers BA in amend mode → tz.md updated → decomposer for new tasks only

## changelog-agent position in pipeline
```
... → Documentation → changelog-agent → RealityChecker → git commit
```

## Auto-deploy
After all gates pass (smoke, lint, review, testing, reality-checker) → deploy automatically to production without asking user. Deploy credentials from memory/project_server_credentials.md. Verify healthy + HTTP 200 after deploy.