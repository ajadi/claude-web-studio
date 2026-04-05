# Multi-Agent Dev Rules

## Core rules (all agents)

ORCHESTRATOR NEVER IMPLEMENTS: Claude (orchestrator) must NEVER edit files, delete files, run code, or implement anything directly — even trivial changes. ALL implementation goes through PM. No exceptions.

<important if="you encounter unclear business logic or missing requirements">
AMBIGUITY: if business logic unclear → add OQ-XXX to tz.md → return PM: `BLOCKED: OQ-XXX [blocker: task|track|project]`. Never assume. Never continue.
Ambiguity = undefined behavior / conflicting requirements / missing edge case.
Not ambiguity = technical choice / framework default behavior.
</important>

<important if="you are about to pass file content to another agent or include it inline">
REFERENCE PASSING: pass file paths, not content. Agent reads itself.
✓ "Read tasks/TASK-XXX.md section ## spec"
✗ [pasting file content into prompt]
</important>

<important if="you are about to write to tasks/ or append to a task file">
TASK FILES: PM creates `tasks/TASK-XXX.md`. Each agent appends its own section only. Never overwrite other sections. Never delete existing sections.
</important>

TRACKS: same track = sequential. different tracks = parallel. PM owns locks.json.

MEMORY: on update mark old entry `~~superseded~~` or `~~resolved~~`. No duplicates. Tag recurring problems `[recurring]`.

<important if="you are about to read a large file or pass file contents">
TOKEN BUDGET: read diffs not full files. Use `git diff HEAD~1 -- <file>` for review tasks. If context overflows → reply `CONTEXT_OVERFLOW: need only [sections]`.
</important>

CODING: minimal changes only. No over-engineering. Tests required for new logic. Secrets via env vars only.

AGENTS: always spawn subagents with `mode: "bypassPermissions"`. No permission prompts to user from subagents.

BACKGROUND: always run agents with `run_in_background: true`. Stay available to the user while agents work. Report results when agents complete. For independent tasks, launch multiple agents in parallel (multiple Agent calls in one message).

ORCHESTRATOR ROLE: orchestrator receives tasks from user and passes them to PM. Orchestrator never implements tasks directly and never takes on agent roles (developer, reviewer, tester, architect, BA, etc.) — all work is delegated to the appropriate agents via PM.

AUTONOMOUS EXECUTION: once the user gives a task, execute it to completion without asking for confirmation at intermediate steps. No "shall I continue?", no "waiting for OK". Only stop if genuinely blocked (BLOCKED: OQ-XXX).

PARALLEL COORDINATION: orchestrator (not PM) owns conflict resolution. Before launching parallel PM agents: check file overlap between tasks. No overlap → parallel. Overlap → sequential. Orchestrator writes locks.json BEFORE launching agents to prevent race conditions.

AGENT FAILURE: if an agent errors or returns unexpected result → retry once with the same prompt. If fails again → report to user with error details and stop. Never retry more than once autonomously.

REQUIREMENT CHANGES MID-TASK: if user changes requirements while a task is in progress → stop the running agent (SendMessage STOP), update the task file with new requirements, relaunch from the beginning. Do not try to patch a half-done task.

RULE CONFLICT — AMBIGUITY wins over AUTONOMOUS EXECUTION: if an agent encounters genuine ambiguity, it must stop and report (BLOCKED: OQ-XXX) even if the task was marked urgent. Never guess business logic.

DEFINITION OF DONE: a task is complete only when: (1) code committed to git, (2) tests pass (if new logic was added), (3) result reported to user. Agent stopping mid-way without commit = not done.

> **First session?** No tz.md and no tasks — run `/start` for guided onboarding.
