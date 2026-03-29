# stop-check.ps1
# Runs at end of every agent turn (Stop hook).
# Reads stdin JSON, checks if task is incomplete, nudges Claude to continue.

$input_json = $input | ConvertFrom-Json -ErrorAction SilentlyContinue

# If stop_hook_active is true — Claude already tried to continue, don't loop
if ($input_json.stop_hook_active) {
    exit 0
}

# Check if any task file has in_progress status without a reality-checker section
# This catches cases where Claude stopped mid-pipeline
$task_files = Get-ChildItem -Path "tasks" -Filter "TASK-*.md" -ErrorAction SilentlyContinue
foreach ($file in $task_files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match "status: in_progress" -and $content -notmatch "## reality") {
        # Task is in progress but pipeline not complete — remind Claude
        Write-Output "Task $($file.Name) is in_progress but pipeline incomplete. Continue the pipeline."
        exit 1
    }
}

exit 0
