#!/bin/bash
# Stop hook: Log session summary for audit trail
set +e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "handoffs" 2>/dev/null

RECENT_COMMITS=$(git log --oneline --since="8 hours ago" 2>/dev/null)
MODIFIED=$(git diff --name-only 2>/dev/null)
STAGED=$(git diff --staged --name-only 2>/dev/null)

# Only log if something happened
if [ -z "$RECENT_COMMITS" ] && [ -z "$MODIFIED" ] && [ -z "$STAGED" ]; then
    exit 0
fi

{
    echo "## Session End: $TIMESTAMP"
    if [ -n "$RECENT_COMMITS" ]; then
        echo "### Commits"
        echo "$RECENT_COMMITS"
    fi
    if [ -n "$STAGED" ] || [ -n "$MODIFIED" ]; then
        echo "### Uncommitted Changes"
        [ -n "$STAGED" ]   && echo "$STAGED"   | while read -r f; do echo "  [staged]   $f"; done
        [ -n "$MODIFIED" ] && echo "$MODIFIED" | while read -r f; do echo "  [unstaged] $f"; done
    fi
    echo "---"
    echo ""
} >> "handoffs/session-log.md" 2>/dev/null

exit 0
