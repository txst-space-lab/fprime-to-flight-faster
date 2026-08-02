# F Prime to Flight Faster

Poster source for **"F Prime to Flight Faster: Hardware-in-the-Loop Continuous
Integration for Accelerated CubeSat Development"** — Nate Gay, Saidi Adams,
Michael Pham.

Built with [Typst](https://typst.app). Output is a single 36 in × 36 in square
PDF. The print constraints it has to satisfy — canvas size, a 24 pt type floor,
one page — are in `docs/requirements.md`.

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
images/     logos, QR code, and photographs (not all are on the poster)
docs/       prose: abstract, layout plan, source material. Not printed.
data/       CI export and the derived CSVs behind every number on the poster
tools/      fetch + analysis scripts that produce data/ and figures/
site/       the GitHub Pages project page — abstract, links, authors, poster
```

| File | What it is |
|---|---|
| `poster.typ` | The poster. Single source of truth for what gets printed. |
| `images/ci-cube.jpeg` | The skeleton CI cube on standoffs. Not on the square poster — kept for slides and for the day the poster has room again. |
| `images/screenshot-github-checks.svg` | The GitHub merge-gate checks view. Also not on the square poster: its UI type renders around 10 pt at column width, under the 24 pt floor. |
| `docs/requirements.md` | Hard print requirements — canvas size, minimum font size, and how to verify them. Read before changing layout. |
| `docs/poster-layout.md` | Layout plan — panel-by-panel content map with word budgets, the column assignment, and a record of what came off the sheet when it went square. |
| `docs/abstract.md` | The submitted abstract, on its own, for pasting into submission forms and program listings. |
| `docs/notes-source-material.md` | Submitted and declined abstracts, corrections to them, and the list of open items to resolve before printing. |
| `docs/proves-ci-changes-code-review.md` | Review of the flight-software repo's CI/test history — where the poster's failure modes, mitigations, and pipeline description are sourced from. |
| `docs/original-outline.md` | Original brain-dump outline. Kept for reference. |
| `data/README.md` | What each CSV is and how the headline numbers are defined. |
| `flake.nix` / `.envrc` | Reproducible toolchain (Typst, tinymist, typstyle, image tools, pinned fonts). |

The poster was originally laid out on the Texas State PowerPoint template
(`Research Poster Template 202506.potx`, 48 in × 36 in, four columns). It is no
longer built to that template's geometry — see `docs/poster-layout.md`.

## Editing the poster

`poster.typ` is three equal 10.67 in columns with a 0.8 in gutter. Each panel is
a named block (`p-problem`, `f-stages`, …) and the columns are composed from
those names at the bottom of the file, so moving a panel between columns is a
one-line change. Panels are justified to a common bottom edge: a column is a
fixed-height block and leftover space is split evenly between its panels.

Every vertical space on the page is written down. Typst's default block spacing
would add about a third of an inch at each seam — over an inch per column, more
than the tightest column has to spare — so the title band and the columns are
composed with `stack`, which adds only what it is told to.

Everything on the poster is built from a few helpers defined at the top of the
file:

- `panel(title, subtitle: ..., accent: ...)[body]` — a titled section
- `stat(value, label)` — one large number with its caption
- `step(n)[text]` — a numbered pipeline step
- `fig(path, caption, height: ...)` — a photograph or screenshot, framed. With a
  `height:` it crops to fill; without one it scales to the column, which is what
  a screenshot needs. Nothing uses it at the moment — see `images/` above
- `chart(path, caption)` — a generated SVG chart, unframed
- `todo[note]` — inline red marker for unresolved content

Placeholders are deliberately loud. An unanswered number should be impossible
to miss in a draft, and impossible to send to the printer by accident.

### Before printing

Search for `#todo[` in `poster.typ` — it should return nothing. The open items
are tracked in `docs/notes-source-material.md`; the one that matters most:

1. **The defect-catch count is still soft.** The gate blocked 65 pull-request
   branches, but CI history cannot separate a real regression from a bench
   flake, so the poster cites that as a floor rather than a defect count.

The QR code in the "Build This Yourself" panel is real, not a placeholder. It
points at the project page (see [The web page](#the-web-page) below), which
carries all three of the panel's links plus the poster PDF — one code to scan
rather than three URLs to retype off a wall. Regenerate it if that URL changes:

```sh
qrencode -o images/qr-poster-site.svg -t SVG -m 0 -l M \
  "https://txst-space-lab.github.io/fprime-to-flight-faster/"
```

Verify what it actually encodes before printing — a QR nobody can scan is worse
than no QR:

```sh
rsvg-convert -w 600 images/qr-poster-site.svg -o /tmp/qr.png
# qrencode -m 0 omits the quiet zone; poster.typ supplies it as white inset,
# so add one here or the decoder will not find the code
magick /tmp/qr.png -bordercolor white -border 40 /tmp/qr-bordered.png
nix shell nixpkgs#zbar --command zbarimg -q /tmp/qr-bordered.png
# -> QR-Code:https://txst-space-lab.github.io/fprime-to-flight-faster/
```

### Checking it fits

Typst will silently spill onto a second page if a column overflows — on a
poster that means content quietly vanishes off the printed sheet. Always
confirm the output is exactly one page:

```sh
typst compile poster.typ poster.pdf && pdfinfo poster.pdf | grep Pages
```

Each column is a fixed-height block, so a column that overruns pushes its
excess onto page 2 rather than silently overlapping — a one-page result is a
real fit check, not just an absence of complaints.

If it is two pages, shrink figures. Type may not go below 24 pt
(`docs/requirements.md` R2), so figures are the only slack there is — and a
chart rendered narrower than a full column takes its own labels under the floor,
so shrink by re-exporting from `tools/analyze-ci.py`, not by scaling down in
`poster.typ`.

## Fonts

`flake.nix` pins Inter, Source Sans 3, Source Serif 4, and JetBrains Mono and
exports `TYPST_FONT_PATHS`, so the poster renders identically on every machine.
The font stacks in `poster.typ` include fallbacks so it still compiles outside
the Nix shell — but a fallback font reflows the layout, so the print-ready PDF
must be built from inside `nix develop`. Verify with `typst fonts`.

## The web page

`site/` is a static project page published to GitHub Pages at
**https://txst-space-lab.github.io/fprime-to-flight-faster/** — the abstract,
links to the lab, the PROVES Kit, and the flight-software repo, the authors,
and the poster with a PDF download.

`.github/workflows/pages.yml` builds it on every push to `main`:
`nix build` produces the PDF, `pdftoppm` renders the on-page preview, and both
land in `site/` before it is uploaded. Neither is committed — the published
poster is always the one `poster.typ` currently produces, and cannot drift from
the source.

Enable it once under **Settings → Pages → Source → GitHub Actions**. Pull
requests build the site but do not deploy.

To preview locally:

```sh
typst compile poster.typ poster.pdf
pdftoppm -png -r 44 -singlefile poster.pdf site/poster
cp poster.pdf site/poster.pdf
python3 -m http.server -d site 8000   # -> http://localhost:8000
```

Two things in `site/index.html` are still placeholders: the headshots in
`site/headshots/` are generated initial avatars, and Saidi Adams and Michael
Pham have no contact line. Replace the images and fill in the `.contact`
paragraphs when you have them.

## Print

- Final size 36 in × 36 in, square, no bleed
- Export at full scale; do not let the print shop "fit to page"
- Check the maroon (`#501214`) reproduces acceptably in CMYK before a full run
