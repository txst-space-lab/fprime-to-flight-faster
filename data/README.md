# CI data for the poster

Everything here is derived from the GitHub Actions history of
[`Open-Source-Space-Foundation/proves-core-reference`](https://github.com/Open-Source-Space-Foundation/proves-core-reference),
workflow `.github/workflows/ci.yaml`. Window: **2025-08-24 → 2026-08-01**,
1,938 workflow runs and 7,091 jobs.

Regenerate with:

```sh
tools/fetch-ci-data.sh     # raw export (needs an authenticated `gh`)
python3 tools/analyze-ci.py  # derived CSVs + figures/*.svg
```

## Files

| File | Rows | What it is |
|---|---|---|
| `ci-runs.csv` | 1,938 | Raw export, one row per workflow run |
| `ci-jobs.csv` | 7,091 | Raw export, one row per job within a run |
| `ci-summary.csv` | 14 | Headline numbers for the poster's stat tiles, each with its definition |
| `ci-pipeline-stages.csv` | 6 | Median/p90 duration per stage, current pipeline — source for `fig-pipeline-stages.svg` |
| `ci-hil-monthly.csv` | 11 | HIL jobs passed/failed per month — source for `fig-hil-reliability.svg` |
| `ci-feedback-time.csv` | 317 | Per-run commit-to-verdict wall clock, current pipeline — source for `fig-feedback-time.svg` |

## Definitions and caveats — read before quoting a number

**"HIL job"** means any job whose name starts with `integration`. The job was
renamed and split over the year: a single `integration` job from 2025-10 until
`integration-uart` + `integration-radio` replaced it on **2026-05-19**. Timing
figures are scoped to after that split (called the *current pipeline* below),
because the pre-split job tested less and would understate today's coverage.
Rate figures use the whole window, since the question there is how reliability
changed.

**Rates exclude `cancelled` and `skipped`.** Those outcomes say nothing about
the code under test. `ci-summary.csv` counts 1,565 *decided* HIL jobs out of
1,935 total.

**`branches_blocked_then_fixed` (65) is a proxy, not a defect count.** It counts
PR branches where a HIL job failed and a later run on the same branch passed —
i.e. the gate held the merge until something changed. CI history cannot tell a
real regression from an infrastructure flake, and during bring-up many were
flakes. Quote it as "branches the gate blocked until they were fixed", not as
"defects caught".

**Pass rate is not flake rate.** A failing HIL job may mean the commit was bad,
the bench was bad, or the test was flaky. The monthly series shows all three
together. The honest claim is the trend: 31% in 2025-10 → 61% in 2026-07 while
monthly volume rose from 160 to 431 jobs.

**The final month is partial.** The export ends 2026-08-01, so the `2026-08`
row is one day (6 jobs, 100%). It is kept in `ci-hil-monthly.csv` for
completeness and excluded from the figure.

**Runner counts.** `hil_benches` (10) case-folds runner names and drops the
ephemeral `GitHub Actions NNNN` names, which would otherwise inflate the count
to 31. The named lab machines are `spacelab-ubuntu-macmini`,
`spacelab-ThinkPad-T420`, `spacelab-macmini`, `integration-test`, `T38Talon`,
`NCC-Michael`, `hal2000`, `mac-mini`, `BS_laptp[`, and `deathstar`.

**Wall clock vs critical path.** Two different timing numbers, both real:

- `critical_path_min` (13.4) — median `build` plus median `integration-radio`,
  the longest dependent chain. This is the pipeline's floor.
- `median_feedback_min` (17.7) — measured end-to-end run duration. Higher than
  the critical path because the two HIL jobs contend for the same bench and
  serialize.

Note that the poster outline's "~5 minutes" claim is **not supported** by this
data; the observed figure is ~18 minutes median, 39 minutes at p90.
