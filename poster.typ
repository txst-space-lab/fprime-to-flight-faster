// F Prime to Flight Faster — 48in x 36in research poster
//
// Build:  typst compile poster.typ poster.pdf
// Watch:  typst watch poster.typ
//
// Layout follows poster-layout.md. Content marked TODO is tracked in
// notes-source-material.md under "Open items to resolve before printing".

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
    text(size: 22pt, fill: muted, label)
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

// Placeholder for a figure that does not exist yet. Prints a visible box so a
// missing asset is obvious in every draft rather than silently absent.
#let fig-todo(caption, height: 8in) = block(
  width: 100%,
  {
    block(
      width: 100%,
      height: height,
      fill: wash,
      stroke: (paint: rule, thickness: 3pt, dash: "dashed"),
      align(
        center + horizon,
        text(size: 30pt, fill: muted, weight: 600, [FIGURE NEEDED \ #caption]),
      ),
    )
    block(inset: (top: 8pt), text(size: 20pt, fill: muted, caption))
  },
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
    block(inset: (top: 8pt), text(size: 20pt, fill: muted, caption))
  },
)

// A generated chart from tools/analyze-ci.py. Unlike `fig`, these get no frame
// and no fixed height: the SVGs are transparent, carry their own titles, and are
// all exported at one 7:5.6 canvas, so scaling to the column width lines every
// chart in a row up on a common baseline. Regenerate before printing —
//   python3 tools/analyze-ci.py
#let chart(path, caption) = block(
  width: 100%,
  {
    image(path, width: 100%)
    block(inset: (top: 8pt), text(size: 20pt, fill: muted, caption))
  },
)

#let todo(body) = text(fill: rgb("#b00020"), weight: 600, [[TODO: #body]])

// ---------------------------------------------------------------- title band

#block(
  width: 100%,
  inset: (bottom: 28pt),
  stroke: (bottom: 6pt + maroon),
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
  panel("The Problem", subtitle: "Integration is where small-sat teams slow down")[
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

    #text(size: 22pt, fill: muted)[
      *F´ (F Prime)* — NASA JPL's open-source flight software framework.
      *HIL* — hardware-in-the-loop. *GDS* — F´ Ground Data System.
      *SWD* — Serial Wire Debug, a direct programming path to the
      microcontroller. *PROVES* — an open-source CubeSat kit and program.
    ]
  ],

  // ============================================================ COLUMN 2 / R1
  panel("Results", subtitle: "Two sites, every commit")[
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 20pt,
      stat("1,565", "test jobs run on real hardware"),
      stat("118 h", "of hardware test runtime"),
      stat("18 min", "median commit to hardware verdict"),
      stat("212", "pull requests gated on hardware"),
      stat("10", "flight-critical subsystems per run"),
      stat("100%", "of merges hardware-validated"),
    )

    #v(10pt)
    #text(size: 21pt, fill: muted)[
      Measured from 1,938 CI runs, Aug 2025 – Aug 2026. The gate blocked *65*
      pull-request branches until a later run passed. CI history cannot separate
      a real regression from a bench flake, so that figure is a floor on defects
      caught, not a defect count. #todo[team recollection: how many of the 65
      were genuine flight-software defects?]
    ]
  ],

  // ============================================================ COLUMN 3 / R1
  panel("What Broke, and What Fixed It", subtitle: "The lessons other teams can reuse")[
    #set text(size: 20pt)
    #table(
      columns: (1fr, 1fr, 1fr),
      inset: 12pt,
      align: left + top,
      stroke: (x, y) => (
        bottom: if y == 0 { 3pt + maroon } else { 1pt + rule },
      ),
      fill: (x, y) => if y == 0 { white } else if calc.odd(y) { wash } else { white },

      table.header(
        text(weight: 700, size: 22pt)[Symptom],
        text(weight: 700, size: 22pt)[Root cause],
        text(weight: 700, size: 22pt)[Mitigation],
      ),

      [Board unreachable after a bad flash],
      [Reprogramming depended on the software under test],
      [Program over SWD/GDB — an independent path to the MCU],

      [Watchdog resets mid-load],
      [Hardware watchdog fired during long software loads],
      [Programmable power supply; sequence power with the load],

      [Passes locally, fails in CI],
      [Residual SD card state between runs],
      [Reformat the SD card every run],

      [Same test, different result per site],
      [Lab-to-lab hardware differences (e.g. RTC battery backup)],
      [#todo[resolution?] Document a per-site hardware profile],

      [Intermittent, unreproducible failures],
      [Limited telemetry bandwidth, dropped packets],
      [#todo[retries? bandwidth budget? test redesign?]],

      [CI silently offline],
      [A machine was unplugged; no one could reach the lab],
      [#todo[remote power / liveness alert?]],
    )
  ],

  // ============================================================ COLUMN 4 / R1
  panel("What Made the Difference", subtitle: "Ranked by impact")[
    #block(spacing: 22pt)[
      *1. Deterministic hardware state.* \
      Reformat storage, cycle power, flash over an independent path. Most
      flakiness was state, not code.
    ]
    #block(spacing: 22pt)[
      *2. Separate build and integration machines.* \
      Build load stopped perturbing timing-sensitive hardware tests.
    ]
    #block(spacing: 22pt)[
      *3. Skeleton cube on standoffs.* \
      Swapping a part went from disassembling a satellite to reaching in.
      Maintainability of the rig _is_ pipeline uptime.
    ]
    #block(spacing: 22pt)[
      *4. Flight-like transport.* \
      Adding radio alongside UART caught a class of failures UART never saw.
    ]
  ],

  // ============================================================ COLUMN 1 / R2
  panel("Per-Commit Pipeline", subtitle: "Commit to merge gate in ~18 minutes")[
    #set text(size: 23pt)
    #block(spacing: 16pt, step(1)[Commit opens a pull request on GitHub.])
    #block(spacing: 16pt, step(2)[Self-hosted GitHub Actions runner picks up the job.])
    #block(spacing: 16pt, step(3)[Build machine compiles F´ flight software.])
    #block(spacing: 16pt, step(4)[Programmable power supply cycles the satellite.])
    #block(spacing: 16pt, step(5)[SWD/GDB flashes the microcontroller.])
    #block(spacing: 16pt, step(6)[SD card is reformatted to clear residual state.])
    #block(spacing: 16pt, step(7)[F´ GDS comes up; tests run over UART and radio.])
    #block(spacing: 16pt, step(8)[Result gates the merge. Red means no merge.])

    #v(14pt)
    #block(width: 100%, inset: 18pt, fill: wash)[
      #text(size: 21pt)[
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

      fig-todo(
        "Figure 1. Per-commit pipeline: GitHub to runner to build host to programmer and PSU to PROVES Kit to GDS to merge gate.",
        height: 7.5in,
      ),

      fig("IMG_7776.jpeg", "Figure 2. The skeleton CI cube on standoffs — parts swap without disassembling the satellite.", height: 7.5in),
    )

    #v(0.6in)

    // Bottom row: the three measured results, from 1,938 runs of the real
    // pipeline. All three share a canvas size so their titles align.
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 0.7in,

      chart(
        "figures/fig-pipeline-stages.svg",
        "Figure 3. Satellite time is 70% of the critical path — the gate costs hardware minutes, not build minutes.",
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
      #set text(size: 22pt)
      - *Flat bench layout* replacing the cube form factor, so parts swap
        without rebuilding a structure
      - *Backplane* instead of hand-built per-component wire harnesses
        #todo[full attribution for the OreSat / Manuel backplane work]
      - *Reproducible station setup* via Nix, a bootable image, or Ansible
      - *Capability-tagged tests* so a station runs only what its hardware
        supports
      - *Remote power control* so a station is never lost to a physical unplug
    ]

    v(1in)

    panel("Build This Yourself", accent: gold)[
      #grid(
        columns: (1fr, auto),
        column-gutter: 24pt,
        {
          set text(size: 23pt)
          [
            Every piece of hardware and software described here is open source.

            #v(10pt)
            *PROVES Kit hardware* #linebreak() #todo[URL]
            #v(6pt)
            *Flight software + CI* #linebreak() #todo[URL]
            #v(6pt)
            *F´* #linebreak() #text(font: mono, size: 20pt)[github.com/nasa/fprime]
          ]
        },
        // Generate with: qrencode -o qr.svg -t SVG -m 0 "<repo url>"
        // then swap this placeholder for: image("qr.svg", width: 3.2in)
        block(
          width: 3.2in,
          height: 3.2in,
          fill: wash,
          stroke: (paint: rule, thickness: 3pt, dash: "dashed"),
          align(center + horizon, text(size: 22pt, fill: muted)[QR]),
        ),
      )
    ]

    v(0.6in)

    block(width: 100%, inset: 16pt, fill: wash)[
      #text(size: 19pt, fill: muted)[
        *Acknowledgments.* #todo[funding line, collaborators, department and
        college names for the template affiliation block]
      ]
    ]
  },
)
