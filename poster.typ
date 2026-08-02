// F Prime to Flight Faster: 45in x 45in research poster
//
// Build:  typst compile poster.typ poster.pdf
// Watch:  typst watch poster.typ
//
// Layout follows docs/poster-layout.md; the hard print constraints (square
// canvas, 24pt type floor, one page) are in docs/requirements.md. Content
// marked TODO is tracked in docs/notes-source-material.md under "Open items to
// resolve before printing".
//
// The panels below are defined as named blocks and then composed into three
// columns at the bottom of the file. Moving a panel between columns is a
// one-line change there; nothing in a panel depends on which column it lands in.

// ---------------------------------------------------------------- constants

#let maroon = rgb("#501214") // Texas State primary
#let gold = rgb("#907040")
#let ink = rgb("#1a1a1a")
#let muted = rgb("#5c5c5c")
#let rule = rgb("#d4d4d4")
#let wash = rgb("#f4f1ee")

// Font stacks list fallbacks so the poster still compiles outside the Nix
// shell, but the pinned fonts are what the print-ready PDF should use.
#let sans = ("Inter", "Source Sans 3", "Helvetica", "Liberation Sans")
#let mono = ("JetBrains Mono", "DejaVu Sans Mono")

// The sheet prints at 45in but is composed at 36in: every length and type size
// in this file is a 36in-sheet value, and the whole composition is scaled once
// at the bottom of the file. Scaling instead of reflowing keeps the column
// geometry that was tuned to fit and lifts the type floor with the paper —
// 24pt composed prints at 30pt. To change the print size, change `print-size`
// alone; nothing else in this file is in printed units.
#let design-size = 36in
#let print-size = 45in
#let print-scale = print-size / design-size
#let design-margin = (x: 1.2in, y: 0.7in)

#set page(
  width: print-size,
  height: print-size,
  // Margins live on the scaled block below so they scale with everything else.
  margin: 0pt,
  fill: white,
)

// 24pt is the floor, not a starting point — see docs/requirements.md R2. Body
// copy sits on it, so anything that needs to shrink has to be a figure. These
// are composed sizes; on paper they print `print-scale` larger.
#set text(font: sans, size: 24pt, fill: ink, lang: "en")
#set par(justify: false, leading: 0.62em, spacing: 1.0em)

#show heading: set text(fill: maroon)

// ---------------------------------------------------------------- components

// A titled content panel. Everything on the poster lives in one of these.
#let panel(title, subtitle: none, accent: maroon, body) = block(
  width: 100%,
  breakable: false,
  {
    block(
      width: 100%,
      inset: (bottom: 7pt),
      stroke: (bottom: 4pt + accent),
      text(size: 38pt, weight: 700, fill: accent, title),
    )
    if subtitle != none {
      block(
        width: 100%,
        inset: (top: 8pt),
        text(size: 26pt, style: "italic", fill: muted, subtitle),
      )
    }
    block(width: 100%, inset: (top: 12pt), body)
  },
)

// One big number plus its label.
#let stat(value, label) = block(
  width: 100%,
  inset: (y: 6pt),
  {
    // Extra leading on this one paragraph: the label sits 8pt further off the
    // number than the poster's default line spacing would put it.
    set par(leading: 0.62em + 8pt)
    text(size: 58pt, weight: 800, fill: maroon, value)
    linebreak()
    text(size: 24pt, fill: muted, label)
  },
)

// A photograph or screenshot, framed, with a finding-first caption. The GitHub
// checks screenshot uses it; the CI cube photograph in images/ is the other
// candidate if a panel ever has room for it.
#let fig(path, caption, height: none) = block(
  width: 100%,
  {
    block(
      width: 100%,
      height: if height == none { auto } else { height },
      clip: true,
      stroke: 2pt + rule,
      // A fixed height crops to fill; without one the image scales to the
      // column, which is what a screenshot needs so no UI text is cut off.
      if height == none {
        image(path, width: 100%)
      } else {
        image(path, width: 100%, height: 100%, fit: "cover")
      },
    )
    block(inset: (top: 8pt), text(size: 24pt, fill: muted, caption))
  },
)

// A generated chart from tools/analyze-ci.py. Unlike `fig`, these get no frame
// and no fixed height: the SVGs are transparent, carry their own titles, and
// share one 7:4.8 canvas, so scaling to the column width lines every chart up
// on a common baseline.
//
// The chart's own type must clear the 24pt floor once scaled. At one full
// column (10.67in) a 7in-wide canvas scales 1.52x, so the 16pt matplotlib
// minimum in tools/analyze-ci.py lands at 24.4pt. Do NOT render these narrower
// than a column without re-checking that. Regenerate before printing:
//   python3 tools/analyze-ci.py
#let chart(path, caption) = block(
  width: 100%,
  {
    image(path, width: 100%)
    block(inset: (top: 8pt), text(size: 24pt, fill: muted, caption))
  },
)

#let todo(body) = text(fill: rgb("#b00020"), weight: 600, [[TODO: #body]])

// ---------------------------------------------------------------- title band

#let title-band = block(
  width: 100%,
  inset: (bottom: 20pt),
  stroke: (bottom: 6pt + maroon),
  grid(
    columns: (1fr, auto),
    column-gutter: 0.6in,
    align: (left + horizon, right + horizon),
    {
      text(size: 68pt, weight: 800, fill: maroon)[
        F Prime to Flight Faster
      ]
      linebreak()
      block(
        inset: (top: 10pt),
        text(size: 36pt, weight: 500, fill: ink)[
          Hardware-in-the-Loop Continuous Integration for Accelerated CubeSat
          Development
        ],
      )
      block(
        inset: (top: 16pt),
        text(size: 28pt, weight: 600)[
          Nate Gay#super[1], Saidi Adams#super[1], Michael Pham#super[2]
        ],
      )
      block(
        inset: (top: 6pt),
        text(size: 24pt, fill: muted)[
          #super[1]Texas State University
          #h(14pt) · #h(14pt)
          #super[2]Open Source Space Foundation
        ],
      )
    },

    // The dark wordmark reads directly on the white page; the -light variant is
    // the white-on-transparent one and needs a maroon plate behind it.
    image("images/txst-logo-dark.svg", width: 5in),
  ),
)

// ---------------------------------------------------------------- panels

#let p-problem = panel(
  "The Problem",
  subtitle: "Integration is where flight software teams slow down",
)[
  Flight software teams iterate quickly in development and then
  slow down at integration, because the software must be validated against real
  hardware that is itself still changing.

  Bench testing is manual, intermittent, and happens late. Defects surface days
  after the commit that caused them, once the context is gone and the change has
  been built on.

  #v(8pt)

  #block(
    width: 100%,
    inset: 18pt,
    fill: wash,
    stroke: (left: 8pt + gold),
  )[
    *Our claim:* Automated testing on real satellite hardware, run on every
    commit, verifies correctness before merge and lets reviewers judge pending
    changes on design rather than on whether the code works, increasing team
    throughput.
  ]

  #v(8pt)

  // Glossary: boxed and labeled so it reads as a reference sidebar rather than
  // more body copy. One term per line, alphabetical, so a reader can scan for
  // the acronym they don't know instead of reading a paragraph to find it.
  #block(
    width: 100%,
    inset: (x: 18pt, top: 24pt, bottom: 18pt),
    stroke: 3pt + maroon,
  )[
    // Label sits on the rule, knocked out with a white plate behind it.
    #place(
      top + left,
      dy: -36pt,
      dx: -6pt,
      block(
        fill: white,
        inset: (x: 8pt),
        text(size: 24pt, weight: 700, fill: maroon, tracking: 2pt)[TERMINOLOGY],
      ),
    )
    #set par(spacing: 0.7em)
    #set text(size: 24pt, fill: muted)
    #for (term, defn) in (
      ([Commit], [one saved change to the software.]),
      ([Continuous Integration (CI)], [builds and tests every change.]),
      ([F Prime (F´)], [NASA JPL's open-source flight software framework.]),
      ([GNU debugger (GDB)], [loads and runs code on the satellite.]),
      ([Hardware-in-the-Loop (HIL)], [tests that run on satellite hardware.]),
      ([Job], [a single automated check in CI.]),
      ([PROVES], [an open-source CubeSat kit and program.]),
      (
        [Pull request (PR)],
        [a proposed change to the software.],
      ),
      (
        [Serial Wire Debug (SWD)],
        [a direct path to program the satellite.],
      ),
    ) {
      block[#text(weight: 700, fill: ink, term): #defn]
    }
  ]
]

#let p-challenge = panel(
  "Our Challenge",
  subtitle: "The hardware moved while the software was being written",
)[
  Over one year the PROVES Kit went through three major and four minor board
  revisions, plus two revisions of the solar face boards. Every one of them
  changed something the flight software depended on: pin assignments, device
  enumeration, power sequencing, which peripherals were even present.

  #v(8pt)

  #grid(
    columns: (1fr, 1fr, 1fr, 1fr),
    column-gutter: 16pt,
    // Labels stay short enough to sit on one line at a quarter of a column;
    // "over one year" is already established in the paragraph above.
    // 9 = three major + four minor mainboard revisions + two solar face
    // revisions, the same nine the paragraph above enumerates.
    stat("9", "board revisions"),
    stat("23", "contributors"),
    stat("1,917", "commits"),
    stat("212", "pull requests"),
  )

  #v(8pt)

  A team this size, at this rate, cannot re-qualify a satellite by hand every
  time either side changes. Hardware testing must be automated.

  #v(12pt)

  // The scope of what has to be re-qualified on every one of those commits;
  // "Results" counts these ten as a stat.
  #block(
    width: 100%,
    inset: 18pt,
    fill: wash,
    stroke: (left: 8pt + gold),
  )[
    *Verified every run:* commanding · telemetry · eventing · IMU · thermal
    management · antenna deployment · real-time clock · filesystem · power
    management · hardware watchdog
  ]
]

#let p-results = panel(
  "Results",
  // The commit count moved to "Our Challenge"; repeating it here read as a
  // second, different measurement.
  subtitle: "1,917 commits · Aug 2025 – July 2026.",
)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 16pt,
    row-gutter: 20pt,
    stat("132 h", "of hardware test runtime"),
    stat("18 min", "median commit to HIL verdict"),

    stat("10", "flight-critical subsystems per run"),
    stat("100%", "of merges hardware-validated"),
  )
]

#let p-broke = panel(
  "What Broke, and What Fixed It",
  subtitle: "Lessons other teams can reuse",
)[
  #table(
    columns: (1fr, 1fr, 1.15fr),
    inset: 10pt,
    align: left + top,
    stroke: (x, y) => (
      bottom: if y == 0 { 3pt + maroon } else { 1pt + rule },
    ),
    fill: (x, y) => if y == 0 { white } else if calc.odd(y) { wash } else {
      white
    },

    table.header(
      text(weight: 700)[Symptom],
      text(weight: 700)[Root cause],
      text(weight: 700)[Mitigation],
    ),

    [Board unreachable after a bad flash],
    [Reprogramming depended on the software under test],
    [Program satellite hardware over SWD with GDB],

    [Watchdog resets flash],
    [Hardware watchdog fired during long software loads],
    [Programmable power supply; sequence power with the load],

    [Passes locally, fails in CI],
    [Residual SD card state between runs],
    [Reformat the SD card before each run to remove leftover state],

    [Same test, different result per site],
    [Lab-to-lab hardware differences],
    [Tag each test with the hardware it needs; a runner executes only the tests it can support],

    [Intermittent, unreproducible failures],
    [Various],
    [Log and archive all telemetry to correlate failures after runs],
  )

  #v(16pt)

  #fig(
    "images/screenshot-github-checks.svg",
    "CI as a developer sees it: the integration jobs run on real hardware, and a failing check blocks the merge.",
  )
]

#let p-difference = panel("What Made the Difference")[
  #block(spacing: 18pt)[
    *1. Deterministic hardware state.* \
    Reformat storage, cycle power, flash over an independent path, address the
    board by USB ID. Most flakiness was state, not code.
  ]
  #block(spacing: 18pt)[
    *2. Self-hosted build runner.* \
    No cache on free cloud runners meant a full submodule re-clone every build.
    Self-hosted runner saved about 10 minutes per run.
  ]
  #block(spacing: 18pt)[
    *3. Skeleton cube on standoffs.* \
    Swapping a part went from disassembling a satellite to unscrewing 4
    standoffs. Maintainability of the rig _is_ pipeline uptime.
  ]
  #block(spacing: 18pt)[
    *4. Flight-like communications and ground software.* \
    Adding radio tests alongside existing UART tests caught a failure class.
  ]
  #block(spacing: 18pt)[
    *5. Not every test needs hardware.* \
    Attitude math, time handling, and frame parsing were pulled out of flight
    components and unit-tested in the cloud in seconds.
  ]
  #block(spacing: 18pt)[
    *6. Shift failures earlier in the pipeline.* \
    Encode known hardware failure modes as static checks. A config setting
    that broke test downlink now fails the build, not HIL.
  ]
]

#let p-future = panel("Future Work")[
  - *Flat bench layout* replacing the cube form factor, so parts swap without
    rebuilding a structure
  - *Backplane* instead of hand-built per-component wire harnesses
  - *Reproducible CI runner setup* via Nix, a bootable image, or Ansible
  - *Job timeouts and queueing* so one hung board cannot monopolize the single
    physical runner
  - *Continue addressing flaky tests* to build trust in the pipeline and keep
    results reliable
]

#let p-build = panel(
  "Build This Yourself",
  accent: gold,
)[
  // No URLs in the body: the QR carries every link, so nobody has to retype a
  // repo path off a printed poster.
  Every piece of hardware and software described here is *open source.*

  *Scan QR code* for links to get started as well as a digital copy of
  this poster and author contact information.

  #v(20pt)
  // Points at the project page, which carries all the links plus the poster PDF
  // and contact details — one code to scan instead of several URLs to retype.
  // Regenerate with:
  //   qrencode -o images/qr-poster-site.svg -t SVG -m 0 -l M \
  //     "https://txst-space-lab.github.io/fprime-to-flight-faster/"
  // The white inset is the quiet zone scanners need (qrencode -m 0 omits it).
  #align(center, block(
    fill: white,
    inset: 0.24in,
    image("images/qr-poster-site.svg", width: 3.5in),
  ))
]

#let p-acknowledgments = block(
  width: 100%,
  inset: 18pt,
  fill: wash,
  stroke: (left: 8pt + gold),
)[
  *Acknowledgments.* Dr. Blagoy Rangelov, Evan Jellison, Ines
  Khouider, Texas State University Department of Physics, Cal Poly Pomona, Open
  Source Space Foundation, NASA Jet Propulsion Laboratory, and NASA CubeSat
  Launch Initiative.
]

// Figures. Captions lead with the finding, not the mechanics.
//
// The square sheet holds three charts plus the GitHub checks screenshot, which
// sits in "What Broke". The CI cube photograph is still in images/, unplaced;
// see docs/poster-layout.md.

#let f-stages = chart(
  "figures/fig-pipeline-stages.svg",
  "Figure 1. HIL time is 70% of the critical path.",
)

#let f-reliability = chart(
  "figures/fig-hil-reliability.svg",
  "Figure 2. Pass rate rose 31% → 61% while monthly volume tripled.",
)

#let f-feedback = chart(
  "figures/fig-feedback-time.svg",
  "Figure 3. 90% of commits get a HIL verdict within 39 minutes.",
)

// ---------------------------------------------------------------- body grid
//
// Three equal columns. At the 36in composed width with 1.2in margins and a
// 0.8in gutter that is 10.67in each — the narrowest column that still holds the
// failure-mode table's three sub-columns at 24pt. On the 45in sheet every one of
// these numbers prints `print-scale` larger; the proportions are what matter.
//
// Reading order is down each column, then across. Column 1 sets up the problem
// and the mechanism, column 2 carries the evidence, column 3 carries the
// takeaways.

// Column height is fixed so the three columns can be justified to a common
// bottom edge: panels are separated by a 0.45in minimum plus an equal share of
// whatever slack the column has left. Ragged column bottoms are the thing that
// most makes a poster look thrown together.
//
// This is also the overflow tripwire. If a column's content exceeds
// `column-height`, Typst pushes the excess onto a second page rather than
// silently overlapping — so `pdfinfo poster.pdf | grep Pages` reporting 1 is a
// real check that everything fits (docs/requirements.md R3).
// 36in composed sheet - 2x0.7in margin - 3.3in title band - 0.3in gap below it,
// less a hair so rounding cannot spill a blank second page.
#let column-height = 30.9in
#let column-gap = 0.45in

// Panels are composed with the built-in `stack` rather than by dropping them
// into the flow: flow layout would add its own block spacing at every seam —
// about a third of an inch each, enough to push a column onto page 2 — and
// suppressing that with a `set` rule would also flatten the spacing *inside*
// the panels. A stack adds exactly what it is told to.
#let column-of(..items) = block(
  width: 100%,
  height: column-height,
  stack(
    dir: ttb,
    ..items.pos().map(it => (it, column-gap, 1fr)).join().slice(0, -2), // trailing gap + spacer after the last panel
  ),
)

// Stacked for the same reason the columns are: the seam below the title band is
// 0.3in because it says 0.3in, not 0.3in plus whatever the flow adds.
#let sheet = stack(
  dir: ttb,
  title-band,
  0.3in,
  grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.8in,
    align: top,

    // Column 1 — the problem, the scale of it here, and what made the answer work.
    column-of(p-problem, p-challenge, p-difference),

    // Column 2 — the evidence: the numbers and all three charts.
    column-of(p-results, f-stages, f-reliability, f-feedback),

    // Column 3 — what the program learned, where it goes next, and how to reuse it.
    column-of(p-broke, p-future, p-build, p-acknowledgments),
  ),
)

// The one place the composed sheet meets the printed one. The block is the full
// design canvas including its margins; scaling it from the top-left corner of a
// zero-margin page maps it onto the sheet exactly, with no reflow — text sizes,
// rules, insets, and the SVGs all grow by the same factor.
#scale(
  x: print-scale * 100%,
  y: print-scale * 100%,
  origin: top + left,
  reflow: true,
  block(
    width: design-size,
    height: design-size,
    inset: design-margin,
    sheet,
  ),
)
