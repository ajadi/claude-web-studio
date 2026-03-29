#!/usr/bin/env bash
# check-blockers.sh
# Runs after every Agent tool call.
# Checks tz.md for new open questions (OQ).
# If new ones found — blocks PM (exit 2) and shows them to user.

TZ_FILE="tz.md"
STATE_FILE=".claude/.oq-state"

# If tz.md does not exist — init state and continue
if [ ! -f "$TZ_FILE" ]; then
    echo "0" > "$STATE_FILE"
    exit 0
fi

# Count current open questions
CURRENT=$(grep -c "⏳ open" "$TZ_FILE" 2>/dev/null || echo "0")

# Read previous state
# If file doesn't exist — first run of hook in this session.
# Initialize to current count (don't block on pre-existing OQs).
PREVIOUS=$CURRENT
if [ -f "$STATE_FILE" ]; then
    STATE_CONTENT=$(cat "$STATE_FILE" 2>/dev/null | tr -d '[:space:]')
    if [[ "$STATE_CONTENT" =~ ^[0-9]+$ ]]; then
        PREVIOUS=$STATE_CONTENT
    fi
fi

# Save current state
echo "$CURRENT" > "$STATE_FILE"

# No new OQs — continue
if [ "$CURRENT" -le "$PREVIOUS" ]; then
    exit 0
fi

# New OQs detected — block PM
DIFF=$((CURRENT - PREVIOUS))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⛔  DEVELOPMENT BLOCKED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Agent added $DIFF new open question(s) to tz.md."
echo "Your answer is required before continuing."
echo ""
echo "Open questions:"
echo ""

grep -n "⏳ open" "$TZ_FILE" | while IFS=: read -r lineno line; do
    echo "  Line $lineno: $line"
done

echo ""
echo "How to continue:"
echo "  1. Answer the questions above"
echo "  2. Update tz.md (replace ⏳ open with ✅ closed)"
echo "  3. Run the pm agent again"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 2
