#!/bin/bash
# SessionStart hook: Detect project state and surface actionable gaps
set +e

# --- Fresh project detection ---
HAS_TZ=false
HAS_TASKS=false
HAS_MEMORY=false

[ -f "tz.md" ] && HAS_TZ=true
[ "$(ls tasks/TASK-*.md 2>/dev/null | wc -l)" -gt 0 ] && HAS_TASKS=true
if [ -f "memory/stack.md" ]; then
    STACK_LINES=$(wc -l < "memory/stack.md" 2>/dev/null | tr -d ' ')
    [ "$STACK_LINES" -gt 3 ] && HAS_MEMORY=true
fi

if [ "$HAS_TZ" = false ] && [ "$HAS_TASKS" = false ]; then
    echo ""
    echo "🚀 NEW PROJECT: No tz.md and no tasks found."
    echo "   Run /start to begin guided onboarding."
    echo ""
    exit 0
fi

# --- Detect gaps ---
GAPS_FOUND=false

# tz.md exists but no tasks decomposed
if [ "$HAS_TZ" = true ] && [ "$HAS_TASKS" = false ]; then
    echo "⚠️  GAP: tz.md found but backlog is empty."
    echo "    Suggested: run decomposer agent to generate tasks."
    GAPS_FOUND=true
fi

# Tasks exist but memory not populated
if [ "$HAS_TASKS" = true ] && [ "$HAS_MEMORY" = false ]; then
    echo "⚠️  GAP: Tasks exist but memory/stack.md is sparse."
    echo "    Suggested: run onboarding agent to populate memory/."
    GAPS_FOUND=true
fi

# BLOCKED tasks
if [ -d "tasks" ]; then
    BLOCKED=$(grep -rl 'BLOCKED:' tasks/TASK-*.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$BLOCKED" -gt 0 ]; then
        echo "⚠️  BLOCKED tasks: ${BLOCKED} — check tz.md for open OQ."
        GAPS_FOUND=true
    fi
fi

# progress.log watchdog entries
if [ -f "progress.log" ]; then
    WATCHDOG=$(grep -c '\[WATCHDOG\]' progress.log 2>/dev/null || echo 0)
    if [ "$WATCHDOG" -gt 0 ]; then
        echo "⚠️  Watchdog events in progress.log: ${WATCHDOG} — review before continuing."
        GAPS_FOUND=true
    fi
fi

if [ "$GAPS_FOUND" = false ]; then
    echo "✓ No gaps detected."
fi

exit 0
