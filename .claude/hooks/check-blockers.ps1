# check-blockers.ps1
# Runs after every Agent tool call.
# Checks tz.md for new open questions (OQ).
# If new ones found — blocks PM (exit 2) and shows them to user.

$TzFile = "tz.md"
$StateFile = ".claude\.oq-state"

# If tz.md does not exist — init state and continue
if (-not (Test-Path $TzFile)) {
    "0" | Set-Content $StateFile
    exit 0
}

# Count current open questions
$Content = Get-Content $TzFile -Raw -ErrorAction SilentlyContinue
if (-not $Content) {
    "0" | Set-Content $StateFile
    exit 0
}

$CurrentMatches = [regex]::Matches($Content, "⏳ open")
$Current = $CurrentMatches.Count

# Read previous state
# If file doesn't exist — first run of hook in this session.
# Initialize to current count (don't block on pre-existing OQs).
$Previous = $Current  # safe default
if (Test-Path $StateFile) {
    $StateContent = (Get-Content $StateFile -Raw -ErrorAction SilentlyContinue).Trim()
    if ($StateContent -match '^\d+$') {
        $Previous = [int]$StateContent
    }
}

# Save current state
"$Current" | Set-Content $StateFile

# No new OQs — continue
if ($Current -le $Previous) {
    exit 0
}

# New OQs detected — block PM
$Diff = $Current - $Previous
$Lines = Get-Content $TzFile

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
Write-Host "⛔  DEVELOPMENT BLOCKED" -ForegroundColor Red
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
Write-Host ""
Write-Host "Agent added $Diff new open question(s) to tz.md." -ForegroundColor Yellow
Write-Host "Your answer is required before continuing." -ForegroundColor Yellow
Write-Host ""
Write-Host "Open questions:" -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -match "⏳ open") {
        Write-Host "  Line $($i+1): $($Lines[$i])" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "How to continue:" -ForegroundColor Green
Write-Host "  1. Answer the questions above"
Write-Host "  2. Update tz.md (replace ⏳ open with ✅ closed)"
Write-Host "  3. Run the pm agent again"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red

exit 2
