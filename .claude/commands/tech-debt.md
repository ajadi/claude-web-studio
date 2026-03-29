---
description: Track, categorize, and prioritize technical debt. Subcommands: scan | add | prioritize | report
argument-hint: "[scan | add | prioritize | report]"
allowed-tools: Read, Glob, Grep, Write
---



Debt register lives at `docs/tech-debt-register.md`.

---

## Subcommands

### `scan` — Scan codebase for debt indicators

Search for:
- `TODO` comments — categorize by type
- `FIXME` comments — bugs disguised as debt
- `HACK` / `WORKAROUND` comments — shortcuts needing proper solutions
- `@deprecated` markers
- Files over 500 lines (potential god objects) — list top 5
- Functions over 50 lines (complexity) — list top 5

Categorize each finding:
- **Architecture** — wrong abstractions, coupling, missing patterns
- **Code Quality** — duplication, complexity, naming
- **Test** — missing tests, flaky tests, untested edge cases
- **Docs** — missing/outdated docs, undocumented APIs
- **Dependencies** — outdated packages, deprecated APIs
- **Performance** — known slow paths, unoptimized queries, memory issues
- **Security** — known vulnerabilities deferred

Update register. Report: N new items found, N already tracked.

---

### `add` — Add a debt entry manually

Ask user for:
1. Description
2. Category (from list above)
3. Affected files
4. Estimated fix effort (XS/S/M/L/XL)
5. Impact if left unfixed (Low/Medium/High/Critical)
6. Why it was accepted (deadline / prototype / missing info)

Append to register.

---

### `prioritize` — Re-prioritize the register

Read `docs/tech-debt-register.md`.

Score each item: `(impact × frequency) / fix_effort`
- impact: Low=1, Medium=2, High=3, Critical=4
- frequency: Rare=1, Sometimes=2, Often=3, Always=4
- fix_effort: XS=1, S=2, M=3, L=4, XL=5

Re-sort by score descending. Recommend top 3 for next sprint.
Ask user: "Update register with new priorities?"

---

### `report` — Summary of current debt

Read register. Output:

```
## Tech Debt Report — [Date]

Total items: N | Estimated effort: [sum of sizes]

By category:
  Architecture: N items
  Code Quality: N items
  Test: N items
  Docs: N items
  Dependencies: N items
  Performance: N items
  Security: N items

Top priority items:
  1. [TD-001] [description] — [category] — effort: M — impact: High
  2. ...

Items aging >3 sprints without action: N
  ⚠️ [TD-XXX] [description] — added [date] — needs decision: fix or consciously accept

Trend: [Growing / Stable / Shrinking] (vs last scan)
```

---

## Register format

`docs/tech-debt-register.md`:

```markdown
## Technical Debt Register
Last updated: [Date]
Total: N items | Est. total effort: [XS×N + S×N + ...]

| ID | Category | Description | Files | Effort | Impact | Priority | Added | Note |
|----|----------|-------------|-------|--------|--------|----------|-------|------|
| TD-001 | Code Quality | [desc] | src/foo.ts | S | Medium | 4.0 | 2026-01-15 | accepted: deadline |
```

## Rules
- Every entry must have a WHY it was accepted
- Items >3 sprints old without action: flag for conscious decision
- `scan` should run at least once per phase
- Tech debt is not inherently bad — tracking it is what matters
