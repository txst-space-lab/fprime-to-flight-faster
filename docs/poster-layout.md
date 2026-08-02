# Poster Layout — F Prime to Flight Faster

Canvas: **36 in × 36 in square** (`docs/requirements.md` R1). **Three columns**
of 10.67 in with a 0.8 in gutter and 1.2 in side margins; 30.9 in of column
height under the title band.

This file is the content plan. `poster.typ` is what prints, and panels there are
named blocks composed into columns at the bottom of the file — the panel names
below (`p-problem`, `f-stages`, …) are those bindings.

`[NEEDED]` marks content that does not exist yet in the source outline.
Word budgets are enforceable: at poster type sizes, going over means shrinking
the font below the 24 pt floor.

The column geometry below replaced a four-column 48 in × 36 in layout mapped to
`Research Poster Template 202506.potx`. That template's box coordinates are no
longer what the poster is built to; see **What the square canvas cost** at the
end of this file for what came off in the reflow.

### Column assignment

| Column | Panels, top to bottom |
|---|---|
| 1 | The Problem (with terminology sidebar) · Per-Commit Pipeline · Build This Yourself |
| 2 | Results · Figure 1 · Figure 2 · Future Work |
| 3 | What Broke, and What Fixed It · What Made the Difference · Figure 3 · Acknowledgments |

Panels are justified to a common bottom edge: each column is a fixed-height
block and leftover space is split evenly between its panels. A column whose
content exceeds that height spills onto a second page, which is what makes
`pdfinfo poster.pdf | grep Pages` a real fit check.

---

## TITLE BAND — full width, 3.3 in tall

**Title** (68 pt)

> F Prime to Flight Faster: Hardware-in-the-Loop Continuous Integration for Accelerated CubeSat Development

**Authors** (28 pt)

> Nate Gay¹, Saidi Adams¹, Michael Pham²

**Affiliations** (24 pt)

> ¹Texas State University Space Lab · ²Open Source Space Foundation · nategay@txstate.edu

---

## COLUMN 1 — the problem and the mechanism

### `p-problem` — The Problem  ·  10.0 in  ·  ~120 words

**Header:** Integration Is Where Small-Sat Teams Slow Down

Three short paragraphs, no bullets:

1. Small satellite flight software teams iterate fast in development and then
   stall at integration, because software must be validated against real
   hardware that is itself changing.
2. Bench testing is manual, intermittent, and happens late — defects are found
   days after the commit that caused them, when the context is gone.
3. **Our claim:** hardware-in-the-loop testing can be a per-commit pre-merge
   gate, not a milestone. In the PROVES program, every commit ran on a real
   engineering satellite before it could merge.

> Define on first use — the audience arrives cold: **F´ (F Prime)**,
> **HIL (hardware-in-the-loop)**, **GDS (Ground Data System)**,
> **PROVES**, **SWD (Serial Wire Debug)**.

### `p-pipeline` — Per-Commit Pipeline  ·  10.8 in  ·  ~110 words + numbered flow

**Header:** Per-Commit Pipeline
**Subheader:** Commit → real satellite → merge gate, in ~18 minutes

Numbered steps, one line each — this is the only description of the hardware
path on the poster, so keep the vocabulary consistent with the captions:

1. Commit opens a PR on GitHub.
2. Cloud runners lint and run unit tests — no hardware needed.
3. Build machine compiles F´ flight software (separate from the test host);
   static gates fail here rather than on the bench.
4. Programmable power supply cycles the engineering satellite.
5. SWD/GDB flashes the microcontroller — no dependency on working flight code.
6. SD card is reformatted to clear residual state.
7. F´ GDS comes up; integration tests run over UART **and** radio.
8. The board is power-cycled and re-tested through a YAMCS ground segment.
9. Result gates the merge. Red means no merge.

> Steps 2 and 3 are the cheap tier and step 8 is the second ground system —
> both were absent from the submitted abstract and both are load-bearing for the
> "what made the difference" argument in `p-difference`.

**Verified each run:** commanding · telemetry · eventing · IMU · thermal ·
antenna deployment · RTC · filesystem · power management · hardware watchdog

---

## COLUMN 2 — the evidence

### `p-results` — Results  ·  7.4 in  ·  numbers, not prose

**Header:** Results
**Subheader:** Two sites, eighteen months, every commit

Set these as a grid of large figures — the number in display type, the label
small beneath. This panel should be readable from across the room and is the
single most important block on the poster.

| Figure | Label |
|---|---|
| **1,935** | test jobs run on real hardware |
| **132 h** | of hardware test runtime |
| **18 min** | median commit → hardware verdict |
| **212** | pull requests gated on hardware |
| **10** | flight-critical subsystems exercised per run |
| **100%** | of merges to `main` hardware-validated |

Measured from 1,917 commits, Aug 2025 – Aug 2026. The abstract's "~5 minutes"
was an early estimate; the measured median is **18 minutes**, with 90% of
commits inside 39. Update the abstract wording if it is reused in the talk.

The gate blocked **65** pull-request branches until a later run passed. CI
history cannot separate a real regression from a bench flake, so cite that as a
*floor* on defects caught, not a defect count.

`[NEEDED]` Team recollection: how many of the 65 were genuine flight-software
defects? That is the number that converts the central claim into evidence.

---

## COLUMN 3 — what the program learned

### `p-broke` — What Broke, and What Fixed It  ·  10.2 in  ·  table

**Header:** What Broke, and What Fixed It
**Subheader:** The parts other teams will photograph

This is the highest-value content on the poster and was the thinnest section of
the original outline. Format as a three-column table — symptom is what another
team will recognize in their own lab, so lead with it.

| Symptom | Root cause | Mitigation |
|---|---|---|
| Board unreachable after a bad flash | Reprogramming depended on the software under test | Program over SWD/GDB — independent path to the MCU |
| Watchdog resets mid-load | Hardware watchdog fired during long software loads | Programmable power supply; sequence power with the load |
| Passes locally, fails in CI | Residual SD card state between runs | Reformat the SD card before **and** after every run — a crashed run leaves it dirty |
| Same test, different result per site | Lab-to-lab hardware differences (e.g. RTC battery backup) | Tag each test with the hardware it needs; a runner executes only the tests it can support |
| Intermittent, unreproducible failures | Radio is half-duplex — the satellite cannot hear a command while it is transmitting | Retry with jittered exponential backoff; log all telemetry to correlate failures afterward |
| CI silently offline | A machine was physically unplugged; no one could reach the lab | `[NEEDED]` Physical access control / remote power / liveness alert |

> The last row is the only one still open. Label it "open" honestly on the
> poster or drop it — do not print a `[NEEDED]`.
>
> The half-duplex root cause is the strongest row on the poster: the failure is
> *physics*, not a bug, and the fix (backoff with jitter, so retries stop
> colliding with the same downlink burst) is directly reusable by any team
> testing over a radio. Lead with it if the table has to be cut for space.
>
> Two rows deliberately left off for space, both worth having in your pocket for
> questions: identifying the board by USB vendor/product ID after a board
> revision invalidated the device name, and killing leaked ground-software
> processes that held the serial port between runs.

---

## FIGURES — three, one per chart, 8.5 in each

Captions are sentence-case and state the *finding*, not the subject ("Flake rate
fell after X" beats "Graph of test results").

| # | Binding | File | Finding |
|---|---|---|---|
| 1 | `f-stages` | `figures/fig-pipeline-stages.svg` | Satellite time is 70% of the critical path |
| 2 | `f-reliability` | `figures/fig-hil-reliability.svg` | Pass rate 31% → 61% as volume nearly tripled |
| 3 | `f-feedback` | `figures/fig-feedback-time.svg` | Median verdict in 18 min, 90% inside 39 |

All three come from `tools/analyze-ci.py` on one 7 × 4.8 in canvas. A column
scales them 1.52×, which is what makes the script's 16 pt minimum land at
24.4 pt on the sheet — **rendering a chart narrower than a full column breaks
the 24 pt floor**, so don't.

Two images are kept in `images/` but are not on the square poster (see below):
`screenshot-github-checks.svg`, the merge-gate checks view, and `ci-cube.jpeg`,
the skeleton cube on standoffs. The `fig()` helper in `poster.typ` is what puts
one back — with a `height:` to crop a photograph, without one for a screenshot.

> The system architecture diagram was dropped early; the numbered steps in the
> Per-Commit Pipeline panel carry the hardware path instead.

---

## PANELS SPREAD ACROSS THE COLUMNS

### `p-difference` — What Made the Difference  ·  column 3  ·  7.0 in

**Header:** What Made the Difference
**Subheader:** Ranked by impact

1. **Deterministic hardware state.** Reformat storage, cycle power, flash over
   an independent path, address the board by USB ID rather than a name a
   revision can invalidate. Most flakiness was state, not code.
2. **Separate build and integration machines.** Moving compilation off the bench
   host onto a dedicated build machine cut about 10 minutes from every pipeline
   run.
3. **Skeleton cube on standoffs.** Swapping a part went from disassembling a
   satellite to reaching in. Maintainability of the test rig *is* pipeline
   uptime.
4. **Flight-like transport and ground segment.** Adding radio alongside UART
   caught a class of failures UART never saw. Re-running the same board through
   production ground software caught another.
5. **Not everything needs the satellite.** Attitude math, time handling, and
   frame parsing were pulled out of flight components and unit-tested in the
   cloud in seconds — which is what keeps the fast tier fast.
6. **Push failures left.** Once a hardware failure mode is understood, encode it
   as a static check. A console setting that corrupted the downlink now fails
   the build, not the bench.

> **Only 1–4 are printed.** Items 5 and 6 came off in the reflow to 36 × 36;
> they are kept here because they are the two most likely to be asked about at
> the poster, and because they go straight back in if a panel elsewhere shrinks.

### `p-future` — Future Work  ·  column 2  ·  4.4 in  ·  ~60 words

**Header:** Future Work

- **Flat bench layout** replacing the cube form factor — parts swap without
  rebuilding a structure
- **Backplane** instead of hand-built wire harnesses per component
  (cf. OreSat's approach) `[Manuel — needs a full attribution for an
  outside reader, or drop the name]`
- **Reproducible runner setup** — Nix, bootable image, or Ansible, for both
  build and integration hosts
- **Remote power control** so a runner is never lost to a physical unplug
- **Job timeouts and queueing** so one hung board cannot monopolize the single
  physical runner

> "Capability-tagged tests" moved out of this list — it shipped, and now appears
> as the mitigation for the cross-site row in `p-broke`.

### `p-build` — Build This Yourself  ·  column 1  ·  5.9 in

**Header:** Everything Here Is Open Source

The poster's actual call to action — give it real estate and a **large QR code**.

- PROVES Kit hardware: `[URL NEEDED]`
- Flight software + CI workflows: `[URL NEEDED]`
- F´ (NASA JPL): github.com/nasa/fprime
- Bench setup instructions: `[NEEDED — listed as future work; if not ready,
  point the QR at the repo README instead]`

Acknowledgments + funding line, one line, small type.

---

## What the square canvas cost

36 × 36 is 25% less sheet than the 48 × 36 the poster was first laid out on, and
the 24 pt floor means the lost area has to come out of content rather than type.
Measured against the three-column budget, the old content ran about 17 column-
inches long. What came off, and why it was the cheapest thing to lose:

- **Figure: the GitHub checks screenshot** (`images/screenshot-github-checks.svg`).
  Its point — a red check blocks the merge — is already carried by step 9 of the
  pipeline panel and by the "100% of merges hardware-validated" stat. Its UI type
  also renders around 10 pt at column width, so it was the one figure that could
  not satisfy the 24 pt floor at any size that fit.
- **Figure: the CI cube photograph** (`images/ci-cube.jpeg`). The only casualty
  with no textual stand-in; "skeleton cube on standoffs" is now asserted in
  `p-difference` rather than shown. This is the first thing to put back if the
  poster ever grows.
- **Ranked items 5 and 6** of What Made the Difference, per the note above.

Two changes bought room without cutting anything:

- Charts were re-exported on a 7 × 4.8 canvas instead of 7 × 5.6, about an inch
  of column height each.
- Every vertical seam on the page is now explicit. Typst's default block spacing
  was adding roughly a third of an inch per seam — over an inch per column, more
  than the slack the tightest column has.

The tightest column has under an inch to spare. Anything added has to displace
something, and the fit check is `pdfinfo poster.pdf | grep Pages`.

---

## Notes on what changed

- **Abstract removed.** A five-paragraph abstract is unreadable on a poster;
  its content is redistributed into Problem, How It Works, and Results.
- **"This talk will highlight…" rewritten throughout.** Present-tense findings —
  the poster is the artifact, not a trailer for a talk.
- **Numbers pulled to the top.** They were buried in the third paragraph.
- **Duplicate "Hardware control" headings merged.** The old outline had the same
  subhead under both "What we learned" and "Future improvements."
- **Declined alternative abstract moved out** to `docs/notes-source-material.md` so
  the layout file has exactly one version of each claim.
