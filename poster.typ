// F Prime to Flight Faster: 48in x 36in research poster
//
// Build:  typst compile poster.typ poster.pdf
// Watch:  typst watch poster.typ
//
// Layout follows docs/poster-layout.md. Content marked TODO is tracked in
// docs/notes-source-material.md under "Open items to resolve before printing".

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

#set page(
  width: 48in,
  height: 36in,
  margin: (x: 1.5in, y: 1.2in),
  fill: white,
)

#set text(font: sans, size: 26pt, fill: ink, lang: "en")
#set par(justify: false, leading: 0.62em, spacing: 1.1em)

#show heading: set text(fill: maroon)

// ---------------------------------------------------------------- components

// A titled content panel. Everything on the poster lives in one of these.
#let panel(title, subtitle: none, accent: maroon, body) = block(
  width: 100%,
  breakable: false,
  {
    block(
      width: 100%,
      inset: (bottom: 8pt),
      stroke: (bottom: 4pt + accent),
      text(size: 44pt, weight: 700, fill: accent, title),
    )
    if subtitle != none {
      block(
        width: 100%,
        inset: (top: 10pt),
        text(size: 28pt, style: "italic", fill: muted, subtitle),
      )
    }
    block(width: 100%, inset: (top: 14pt), body)
  },
)

// One big number plus its label.
#let stat(value, label) = block(
  width: 100%,
  inset: (y: 10pt),
  {
    text(size: 76pt, weight: 800, fill: maroon, value)
    linebreak()
    text(size: 24pt, fill: muted, label)
  },
)

// Numbered pipeline step.
#let step(n, body) = grid(
  columns: (auto, 1fr),
  column-gutter: 14pt,
  block(
    width: 46pt,
    height: 46pt,
    radius: 23pt,
    fill: maroon,
    align(center + horizon, text(size: 24pt, weight: 700, fill: white, str(n))),
  ),
  block(inset: (top: 6pt), body),
)

// A real figure with a finding-first caption.
#let fig(path, caption, height: 8in) = block(
  width: 100%,
  {
    block(
      width: 100%,
      height: height,
      clip: true,
      stroke: 2pt + rule,
      image(path, width: 100%, height: 100%, fit: "cover"),
    )
    block(inset: (top: 8pt), text(size: 24pt, fill: muted, caption))
  },
)

// A screenshot. Unlike `fig`, this scales to fit the full column width instead
// of cropping, so no UI text is cut off and the image reads at arm's length.
#let shot(path, caption) = block(
  width: 100%,
  {
    block(
      width: 100%,
      clip: true,
      stroke: 2pt + rule,
      image(path, width: 100%),
    )
    block(inset: (top: 8pt), text(size: 24pt, fill: muted, caption))
  },
)

// A generated chart from tools/analyze-ci.py. Unlike `fig`, these get no frame
// and no fixed height: the SVGs are transparent, carry their own titles, and are
// all exported at one 7:5.6 canvas, so scaling to the column width lines every
// chart in a row up on a common baseline. Regenerate before printing:
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

#block(
  width: 100%,
  inset: (bottom: 28pt),
  stroke: (bottom: 6pt + maroon),
  grid(
  columns: (1fr, auto),
  column-gutter: 1in,
  align: (left + horizon, right + top),
  {
    text(size: 96pt, weight: 800, fill: maroon)[
      F Prime to Flight Faster
    ]
    linebreak()
    block(
      inset: (top: 12pt),
      text(size: 48pt, weight: 500, fill: ink)[
        Hardware-in-the-Loop Continuous Integration for Accelerated CubeSat Development
      ],
    )
    block(
      inset: (top: 22pt),
      text(size: 32pt, weight: 600)[
        Nate Gay#super[1], Saidi Adams#super[1], Michael Pham#super[2]
      ],
    )
    block(
      inset: (top: 8pt),
      text(size: 26pt, fill: muted)[
        #super[1]Texas State University Space Lab
        #h(18pt) · #h(18pt)
        #super[2]Open Source Space Foundation
        #h(18pt) · #h(18pt)
        nategay\@txstate.edu
      ],
    )
  },

  // The dark wordmark reads directly on the white page; the -light variant is
  // the white-on-transparent one and needs a maroon plate behind it.
  image("images/txst-logo-dark.svg", width: 9in),
  ),
)

#v(30pt)

// ---------------------------------------------------------------- body grid
//
// Four columns matching the template: 10in / 11in / 11in / 10in.
// Row 1 is text; row 2 puts the figure zone across the two center columns.

#grid(
  columns: (10in, 11in, 11in, 10in),
  column-gutter: 1in,
  row-gutter: 1in,

  // ============================================================ COLUMN 1 / R1
  panel(
    "The Problem",
    subtitle: "Integration is where small-sat teams slow down",
  )[
    Small satellite flight software teams iterate quickly in development and
    then stall at integration, because the software must be validated against
    real hardware that is itself still changing.

    Bench testing is manual, intermittent, and happens late. Defects surface
    days after the commit that caused them, once the context is gone and the
    change has been built on.

    #v(10pt)

    #block(
      width: 100%,
      inset: 20pt,
      fill: wash,
      stroke: (left: 8pt + gold),
    )[
      *Our claim:* hardware-in-the-loop testing can be a per-commit merge gate,
      not a milestone. In the PROVES program, every commit ran on a real
      engineering satellite before it could merge.
    ]

    #v(10pt)

    // Glossary: boxed and labeled so it reads as a reference sidebar rather
    // than more body copy. One term per line so a reader can scan for the
    // acronym they don't know instead of reading a paragraph to find it.
    #block(
      width: 100%,
      inset: (x: 20pt, top: 26pt, bottom: 20pt),
      stroke: 3pt + maroon,
    )[
      // Label sits on the rule, knocked out with a white plate behind it.
      #place(
        top + left,
        dy: -38pt,
        dx: -6pt,
        block(
          fill: white,
          inset: (x: 8pt),
          text(size: 24pt, weight: 700, fill: maroon, tracking: 2pt)[TERMINOLOGY],
        ),
      )
      #set par(spacing: 0.75em)
      #set text(size: 24pt, fill: muted)
      #for (term, defn) in (
        ([F´ (F Prime)], [NASA JPL's open-source flight software framework.]),
        ([HIL], [hardware-in-the-loop.]),
        ([GDS], [F´ Ground Data System.]),
        ([SWD], [Serial Wire Debug, a direct programming path to the microcontroller.]),
        ([PROVES], [an open-source CubeSat kit and program.]),
      ) {
        block[#text(weight: 700, fill: ink, term): #defn]
      }
    ]
  ],

  // ============================================================ COLUMN 2 / R1
  panel("Results", subtitle: "Confidence with every commit")[
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 20pt,
      stat("1,935", "test jobs run on real hardware"),
      stat("132 h", "of hardware test runtime"),

      stat("18 min", "median commit to hardware verdict"),
      stat("212", "pull requests gated on hardware"),

      stat("10", "flight-critical subsystems per run"),
      stat("100%", "of merges hardware-validated"),
    )

    #v(10pt)
    #text(size: 24pt, fill: muted)[
      Measured from 1,917 commits, Aug 2025 – Aug 2026.
    ]
  ],

  // ============================================================ COLUMN 3 / R1
  panel(
    "What Broke, and What Fixed It",
    subtitle: "The lessons other teams can reuse",
  )[
    #set text(size: 24pt)
    #table(
      columns: (1fr, 1fr, 1fr),
      inset: 12pt,
      align: left + top,
      stroke: (x, y) => (
        bottom: if y == 0 { 3pt + maroon } else { 1pt + rule },
      ),
      fill: (x, y) => if y == 0 { white } else if calc.odd(y) { wash } else {
        white
      },

      table.header(
        text(weight: 700, size: 24pt)[Symptom],
        text(weight: 700, size: 24pt)[Root cause],
        text(weight: 700, size: 24pt)[Mitigation],
      ),

      [Board unreachable after a bad flash],
      [Reprogramming depended on the software under test],
      [Program over SWD/GDB, an independent path to the MCU],

      [Watchdog resets flash],
      [Hardware watchdog fired during long software loads],
      [Programmable power supply; sequence power with the load],

      [Passes locally, fails in CI],
      [Residual SD card state between runs],
      [Reformat the SD card before *and* after every run; a crashed run leaves it dirty],

      [Same test, different result per site],
      [Lab-to-lab hardware differences (e.g. RTC battery backup)],
      [Tag each test with the hardware it needs; a runner executes only the tests it can support],

      [Intermittent, unreproducible failures],
      [Various],
      [Log and archive all telemetry to correlate failures after runs],
    )
  ],

  // ============================================================ COLUMN 4 / R1
  panel("What Made the Difference", subtitle: "Ranked by impact")[
    #block(spacing: 22pt)[
      *1. Deterministic hardware state.* \
      Reformat storage, cycle power, flash over an independent path, address the
      board by USB ID. Most flakiness was state, not code.
    ]
    #block(spacing: 22pt)[
      *2. Separate build and integration machines.* \
      Moving compilation off the bench host onto a dedicated build machine cut
      about 10 minutes from every pipeline run.
    ]
    #block(spacing: 22pt)[
      *3. Skeleton cube on standoffs.* \
      Swapping a part went from disassembling a satellite to unscrewing 4 standoffs.
      Maintainability of the rig _is_ pipeline uptime.
    ]
    #block(spacing: 22pt)[
      *4. Flight-like comms and ground software.* \
      Adding radio tests alongside existing UART tests caught a new class of failures.
    ]
    #block(spacing: 22pt)[
      *5. Not every test needs hardware.* \
      Attitude math, time handling, and frame parsing were pulled out of flight
      components and unit-tested in the cloud in seconds.
    ]
    #block(spacing: 22pt)[
      *6. Push failures left.* \
      Once a hardware failure mode is understood, encode it as a static check. A
      console setting that corrupted the downlink now fails the build, not the
      bench.
    ]
  ],

  // ============================================================ COLUMN 1 / R2
  panel("Per-Commit Pipeline", subtitle: "Commit to merge gate in ~18 minutes")[
    #set text(size: 24pt)
    // Numbered from the list so steps can be inserted without renumbering by
    // hand.
    #for (i, s) in (
      [Commit opens a pull request on GitHub.],
      [Cloud runners lint and run unit tests; no hardware needed.],
      [Build machine compiles F´ flight software; static gates fail here, not on the bench.],
      [Programmable power supply cycles the satellite.],
      [SWD/GDB flashes the microcontroller.],
      [SD card is reformatted to clear residual state.],
      [F´ GDS comes up; tests run over UART and radio.],
      [The board is power-cycled and re-tested through a YAMCS ground segment.],
      [Result gates the merge. Red means no merge.],
    ).enumerate(start: 1) {
      block(spacing: 16pt, step(i, s))
    }

    #v(14pt)
    #block(width: 100%, inset: 18pt, fill: wash)[
      #text(size: 24pt)[
        *Verified every run:* commanding · telemetry · eventing · IMU ·
        thermal management · antenna deployment · real-time clock · filesystem ·
        power management · hardware watchdog
      ]
    ]
  ],

  // ================================================= FIGURE ZONE / R2 (2 cols)
  grid.cell(colspan: 2)[
    // Top row: the two "what it is" visuals, side by side at equal height.
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 1in,

      // 6.0in, not more: the three charts below size themselves from their SVG
      // aspect ratios, and anything taller here pushes the poster onto a second
      // page. Re-check `pdfinfo poster.pdf | grep Pages` after changing this.
      shot(
        "images/screenshot-github-checks.svg",
        "Figure 1. The gate as a developer sees it: integration-uart and integration-radio run on a real satellite, and a red check blocks the merge.",
      ),

      fig(
        "images/ci-cube.jpeg",
        "Figure 2. The skeleton CI cube on standoffs; parts swap without disassembling the satellite.",
        height: 4.7in,
      ),
    )

    #v(0.45in)

    // Bottom row: the three measured results, from 1,938 runs of the real
    // pipeline. All three share a canvas size so their titles align.
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 0.7in,

      chart(
        "figures/fig-pipeline-stages.svg",
        "Figure 3. Satellite time is 70% of the critical path; the gate costs hardware minutes, not build minutes.",
      ),

      chart(
        "figures/fig-hil-reliability.svg",
        "Figure 4. Pass rate rose 31% → 61% while monthly volume nearly tripled, as the state-reset fixes landed.",
      ),

      chart(
        "figures/fig-feedback-time.svg",
        "Figure 5. Half of all commits get a hardware verdict within 18 minutes; 90% within 39.",
      ),
    )
  ],

  // ============================================================ COLUMN 4 / R2
  {
    panel("Future Work")[
      #set text(size: 24pt)
      - *Flat bench layout* replacing the cube form factor, so parts swap
        without rebuilding a structure
      - *Backplane* instead of hand-built per-component wire harnesses
      - *Reproducible CI runner setup* via Nix, a bootable image, or Ansible
      - *Job timeouts and queueing* so one hung board cannot monopolize the
        single physical runner
      - *Continue addressing flaky tests* to build trust in the pipeline and
        keep results reliable
    ]

    v(0.7in)

    panel("Build This Yourself", accent: gold)[
      #grid(
        columns: (1fr, auto),
        column-gutter: 24pt,
        {
          set text(size: 24pt)
          [
            Every piece of hardware and software described here is open source.

            #v(10pt)
            *PROVES Kit hardware* #linebreak() #text(font: mono, size: 24pt)[proveskit.com]
            #v(6pt)
            *Flight software + CI* #linebreak() #text(font: mono, size: 24pt)[github.com/Open-Source-Space-Foundation/ #linebreak() proves-core-reference]
            #v(6pt)
            *F´* #linebreak() #text(font: mono, size: 24pt)[github.com/nasa/fprime]
          ]
        },
        // Regenerate with:
        //   qrencode -o images/qr-proves-core-reference.svg -t SVG -m 0 -l M \
        //     "https://github.com/Open-Source-Space-Foundation/proves-core-reference"
        // The white inset is the quiet zone scanners need (qrencode -m 0 omits it).
        block(
          fill: white,
          inset: 0.28in,
          image("images/qr-proves-core-reference.svg", width: 3.2in),
        ),
      )
    ]

    v(0.4in)

    block(width: 100%, inset: 16pt, fill: wash)[
      #text(size: 24pt, fill: muted)[
        *Acknowledgments.* #todo[funding line, collaborators, department and
          college names for the template affiliation block]
      ]
    ]
  },
)
