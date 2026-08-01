# F Prime to Flight Faster

Poster source for **"F Prime to Flight Faster: Hardware-in-the-Loop Continuous
Integration for Accelerated CubeSat Development"** — Nate Gay, Saidi Adams,
Michael Pham.

Built with [Typst](https://typst.app). Output is a single 48 in × 36 in
landscape PDF sized for the Texas State research poster template.

## Prerequisites

- [Nix](https://nixos.org/download)
- [direnv](https://direnv.net)

Everything else — Typst, `qrencode`, image tools, and the pinned fonts — comes
from `flake.nix`. Nothing needs to be installed system-wide.

## Quick start

```sh
direnv allow                         # one time; brings the toolchain in
typst watch poster.typ               # live preview while editing
typst compile poster.typ poster.pdf  # build
```

Without direnv:

```sh
nix develop           # same shell, entered manually
nix build             # -> result/poster.pdf
```

## Layout

```
poster.typ  the poster — single source of truth for what gets printed
figures/    generated SVG charts, plus _proof.typ for previewing them
images/     photographs used as figures
docs/       prose: abstract, layout plan, source material. Not printed.
data/       CI export and the derived CSVs behind every number on the poster
tools/      fetch + analysis scripts that produce data/ and figures/
```

| File | What it is |
|---|---|
| `poster.typ` | The poster. Single source of truth for what gets printed. |
| `images/ci-cube.jpeg` | Figure 2 — the skeleton CI cube on standoffs. |
| `images/screenshot-github-checks.png` | Figure 1 — the GitHub merge-gate checks view. Derived from `images/screenshot-github-failing-checks.png` (bottom row faded to imply the list continues). |
| `docs/requirements.md` | Hard print requirements — canvas size, minimum font size, and how to verify them. Read before changing layout. |
| `docs/poster-layout.md` | Layout plan — panel-by-panel content map with word budgets, derived from the `.potx` template's actual box coordinates. |
| `docs/abstract.md` | The submitted abstract, on its own, for pasting into submission forms and program listings. |
| `docs/notes-source-material.md` | Submitted and declined abstracts, corrections to them, and the list of open items to resolve before printing. |
| `docs/proves-ci-changes-code-review.md` | Review of the flight-software repo's CI/test history — where the poster's failure modes, mitigations, and pipeline description are sourced from. |
| `docs/original-outline.md` | Original brain-dump outline. Kept for reference. |
| `data/README.md` | What each CSV is and how the headline numbers are defined. |
| `flake.nix` / `.envrc` | Reproducible toolchain (Typst, tinymist, typstyle, image tools, pinned fonts). |

The Texas State PowerPoint template (`Research Poster Template 202506.potx`)
that the layout is matched to is not checked in; `docs/poster-layout.md` records
its box coordinates.

## Editing the poster

`poster.typ` is organized as a four-column grid matching the template:
10 in / 11 in / 11 in / 10 in, with a 1 in gutter. Row 1 is text panels; row 2
puts the figure zone across the two center columns.

Everything on the poster is built from a few helpers defined at the top of the
file:

- `panel(title, subtitle: ..., accent: ...)[body]` — a titled section
- `stat(value, label)` — one large number with its caption
- `step(n)[text]` — a numbered pipeline step
- `fig(path, caption, height: ...)` — a real figure
- `shot(path, caption, height: ...)` — a screenshot, scaled to fit rather than cropped
- `todo[note]` — inline red marker for unresolved content

Placeholders are deliberately loud. An unanswered number should be impossible
to miss in a draft, and impossible to send to the printer by accident.

### Before printing

Search for `#todo[` in `poster.typ` — it should return nothing. The open items
are tracked in `docs/notes-source-material.md`; the one that matters most:

1. **The defect-catch count is still soft.** The gate blocked 65 pull-request
   branches, but CI history cannot separate a real regression from a bench
   flake, so the poster cites that as a floor rather than a defect count.

Then generate the QR code and swap it in:

```sh
qrencode -o qr.svg -t SVG -m 0 "https://github.com/<org>/<repo>"
```

Replace the dashed `QR` placeholder block in the "Build This Yourself" panel
with `image("qr.svg", width: 3.2in)`.

### Checking it fits

Typst will silently spill onto a second page if a column overflows — on a
poster that means content quietly vanishes off the printed sheet. Always
confirm the output is exactly one page:

```sh
typst compile poster.typ poster.pdf && pdfinfo poster.pdf | grep Pages
```

If it is two pages, shrink figure heights before shrinking type. Body text
below ~22 pt stops being readable at four feet.

## Fonts

`flake.nix` pins Inter, Source Sans 3, Source Serif 4, and JetBrains Mono and
exports `TYPST_FONT_PATHS`, so the poster renders identically on every machine.
The font stacks in `poster.typ` include fallbacks so it still compiles outside
the Nix shell — but a fallback font reflows the layout, so the print-ready PDF
must be built from inside `nix develop`. Verify with `typst fonts`.

## Print

- Final size 48 in × 36 in, landscape, no bleed
- Export at full scale; do not let the print shop "fit to page"
- Check the maroon (`#501214`) reproduces acceptably in CMYK before a full run
