# Poster Layout — F Prime to Flight Faster

Mapped to `Research Poster Template 202506.potx`, **Poster A** layout.
Canvas: **48 in × 36 in landscape**. Four columns.

Panel coordinates below are inches from the top-left of the poster and match the
template's existing text boxes and picture placeholders — drop content in, don't
move the boxes.

`[NEEDED]` marks content that does not exist yet in the source outline.
Word budgets are enforceable: at poster type sizes, going over means shrinking
the font below readable-at-4-feet.

---

## TITLE BAND — `y 1.0–4.6`, full width

**Title** (`Title 23`, y1.0 h1.9)

> F Prime to Flight Faster: Hardware-in-the-Loop Continuous Integration for Accelerated CubeSat Development

**Authors** (`Text Placeholder 58`, y2.8 h1.0)

> Nate Gay¹, Saidi Adams¹, Michael Pham²

**Affiliations** (`Text Placeholder 59`, y3.9 h0.7)

> ¹Texas State University Space Lab · ²Open Source Space Foundation · nategay@txstate.edu

---

## COLUMN 1 — `x 1.5, w 10.0`

### Panel 1A — The Problem  ·  `y 6.5, h 15.0`  ·  ~120 words

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

### Panel 1B — How It Works  ·  `y 22.0, h 13.0`  ·  ~110 words + numbered flow

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
> "what made the difference" argument in Panel 4A.

**Verified each run:** commanding · telemetry · eventing · IMU · thermal ·
antenna deployment · RTC · filesystem · power management · hardware watchdog

---

## COLUMN 2 — `x 12.5, w 11.0`

### Panel 2A — Results  ·  `y 6.5, h 11.2`  ·  numbers, not prose

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

## COLUMN 3 — `x 24.5, w 11.0`

### Panel 3A — Failure Modes & Fixes  ·  `y 6.5, h 11.2`  ·  table

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

## FIGURE ZONE — center, `x 12.5–35.5, y 18.4–35.0`

The template supplies six picture placeholders with paired caption boxes.
Captions are sentence-case, one line, and state the *finding*, not the subject
("Flake rate fell after X" beats "Graph of test results").

| Slot | Placeholder | Figure | Status |
|---|---|---|---|
| 1 | `idx 17` — y18.4 x12.5 w7.0 | Checks in GitHub PR view | placed as Figure 1, in the figure zone |
| 2 | `idx 23` — y18.4 x24.5 w7.0 | Current CI cube on standoffs | have (`images/ci-cube.jpeg`?) |
| 3 | `idx 13` — y23.3 x16.4 w7.0 | — | dropped |
| 4 | `idx 19` — y23.3 x24.5 w7.0 | Pass/fail rate over time | `[NEEDED — export from CI]` |
| 5 | `idx 15` — y28.1 x12.5 w11.0 | Before/after: assembled cube → skeleton cube | optional |
| 6 | `idx 21` — y28.2 x24.5 w11.0 | Early bench setup, first integration bench | optional |

> The system architecture diagram was dropped; the numbered steps in the
> Per-Commit Pipeline panel carry the hardware path instead, and the GitHub
> checks screenshot takes the top-left figure slot.
>
> Slots 5 and 6 are the first things to cut if space gets tight. The "at my
> house" photo is charming but only earns a slot if it makes a point about how
> low the barrier to entry is — which is actually a good point, if you frame the
> caption that way.

---

## COLUMN 4 — `x 36.5, w 10.0`

### Panel 4A — What Worked  ·  `y 6.5, h 13.5`  ·  ~100 words

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

### Panel 4B — Next  ·  `y 20.6, h 4.5`  ·  ~60 words

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
> as the mitigation for the cross-site row in Panel 3A.

### Panel 4C — Build This Yourself  ·  `y 25.7, h 4.5`

**Header:** Everything Here Is Open Source

The poster's actual call to action — give it real estate and a **large QR code**.

- PROVES Kit hardware: `[URL NEEDED]`
- Flight software + CI workflows: `[URL NEEDED]`
- F´ (NASA JPL): github.com/nasa/fprime
- Bench setup instructions: `[NEEDED — listed as future work; if not ready,
  point the QR at the repo README instead]`

Acknowledgments + funding line, one line, small type.

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
