#!/usr/bin/env bash
# Export the GitHub Actions history of the PROVES flight-software repo into the
# two raw CSVs that analyze-ci.py consumes.
#
#   tools/fetch-ci-data.sh            # refresh data/ci-runs.csv + data/ci-jobs.csv
#
# Needs `gh` authenticated against github.com. Re-running is cheap for the runs
# list and expensive for the jobs list (one API call per run), so per-run job
# payloads are cached under .cache/ci-jobs/ and only missing ones are fetched.
set -euo pipefail

REPO="Open-Source-Space-Foundation/proves-core-reference"
WORKFLOW=183589922 # .github/workflows/ci.yaml
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE="$ROOT/.cache/ci"
mkdir -p "$CACHE/runs" "$CACHE/jobs" "$ROOT/data"

total=$(gh api "repos/$REPO/actions/workflows/$WORKFLOW/runs?per_page=1" --jq '.total_count')
pages=$(((total + 99) / 100))
echo "workflow runs: $total ($pages pages)"

for p in $(seq 1 "$pages"); do
  gh api "repos/$REPO/actions/workflows/$WORKFLOW/runs?per_page=100&page=$p" \
    >"$CACHE/runs/p$p.json"
done

# The runs endpoint pages can overlap when new runs land mid-crawl, so dedupe.
jq -s -r '
  ["run_id","run_number","created_at","updated_at","run_started_at","duration_s",
   "event","status","conclusion","head_branch","actor","run_attempt"],
  ([.[].workflow_runs[]] | unique_by(.id) | sort_by(.created_at) | .[] |
   [.id, .run_number, .created_at, .updated_at, .run_started_at,
    ((.updated_at|fromdate) - ((.run_started_at // .created_at)|fromdate)),
    .event, .status, .conclusion, .head_branch, .actor.login, .run_attempt])
  | @csv' "$CACHE"/runs/p*.json >"$ROOT/data/ci-runs.csv"

jq -s -r '[.[].workflow_runs[]] | unique_by(.id) | .[].id' "$CACHE"/runs/p*.json \
  >"$CACHE/run-ids.txt"
echo "fetching per-run jobs (cached in $CACHE/jobs)…"
# -P 8 keeps this under the secondary rate limit while still finishing in ~10min
# on a cold cache; `test -s` makes re-runs incremental.
xargs -P 8 -I{} sh -c \
  "test -s '$CACHE/jobs/{}.json' || gh api 'repos/$REPO/actions/runs/{}/jobs?per_page=100' > '$CACHE/jobs/{}.json'" \
  <"$CACHE/run-ids.txt"

jq -s -r '
  ["run_id","job_id","job_name","status","conclusion","started_at","completed_at",
   "duration_s","runner_name","run_attempt"],
  (.[] | .jobs[] |
   [.run_id, .id, .name, .status, .conclusion, .started_at, .completed_at,
    (if .completed_at and .started_at
     then ((.completed_at|fromdate) - (.started_at|fromdate)) else null end),
    .runner_name, .run_attempt])
  | @csv' "$CACHE"/jobs/*.json >"$ROOT/data/ci-jobs.csv"

echo "wrote data/ci-runs.csv ($(($(wc -l <"$ROOT/data/ci-runs.csv") - 1)) runs)"
echo "wrote data/ci-jobs.csv ($(($(wc -l <"$ROOT/data/ci-jobs.csv") - 1)) jobs)"
