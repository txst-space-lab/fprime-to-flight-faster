# Poster Requirements

Hard constraints the printed poster must satisfy. These are not preferences —
a violation means the poster is rejected or unreadable on the floor. Layout
choices live in `docs/poster-layout.md`; this file is only the rules that
layout has to obey.

---

## R1 — Canvas size: 36 in × 36 in

The poster must be **36 inches wide by 36 inches tall** — square.

- Set in `poster.typ` via `#set page(width: 36in, height: 36in, ...)`.
- Export at full scale. Never let the print shop "fit to page"; a rescale
  breaks every other requirement on this page at once.
- No bleed.

**Status: not met.** `poster.typ` is currently `48in × 36in` landscape, matching
the four-column Texas State template recorded in `docs/poster-layout.md`.
Squaring the canvas removes 12 in of width, so the four-column grid
(10 / 11 / 11 / 10 with 1 in gutters) does not survive as-is — see *Consequences*
below.

## R2 — Minimum font size: 24 pt

**No text may render below 24 pt.** That includes figure captions, table
headers, footnotes, references, URLs, and any type baked into an image or SVG.

- Body text is 26 pt; 24 pt is the floor used for captions, table cells, and
  the terminology block.
- Text inside `figures/*.svg` and `images/*` counts. A chart axis label that
  ends up under 24 pt after the figure is scaled down is a violation even
  though nothing in `poster.typ` says "24pt".
- Scaling a figure with `height:` scales its embedded type. Shrinking a figure
  to make content fit can silently push its labels under the floor.

**Status: met in `poster.typ`.** Every explicit `size:` is 24 pt or larger and
the document default is 26 pt. Embedded type in figures has not been audited
against this floor.

## R3 — One page

Typst spills silently onto a second page when a column overflows, and on a
poster that means content vanishes off the printed sheet.

```sh
typst compile poster.typ poster.pdf && pdfinfo poster.pdf | grep Pages
```

Must report `Pages: 1`. When it does not, shrink figure heights first — R2
means type is not available as slack.

## R4 — No unresolved placeholders

`grep -n '#todo\[' poster.typ` must return nothing before the file goes to the
printer. Open items are tracked in `docs/notes-source-material.md`.

## R5 — Build from the pinned toolchain

The print-ready PDF must be built inside `nix develop` (or with direnv active).
Fallback fonts reflow the layout, which can break R2 and R3 without any source
change. Verify with `typst fonts`.

---

## Verification

| Requirement | Check |
|---|---|
| R1 size | `pdfinfo poster.pdf \| grep "Page size"` → 2592 × 2592 pts |
| R2 min font | `grep -n "size: [0-9]*pt" poster.typ` → no value under 24; plus a visual pass over every figure |
| R3 one page | `pdfinfo poster.pdf \| grep Pages` → 1 |
| R4 placeholders | `grep -n '#todo\[' poster.typ` → no output |
| R5 fonts | built inside `nix develop`; `typst fonts` lists Inter and JetBrains Mono |

`pdfinfo` reports page size in PostScript points at 72 pt/in, so 36 in = 2592 pt
on both axes.

---

## Consequences of R1 + R2 together

The two hard requirements pull against each other, and the resolution is a
content decision, not a formatting one:

- 36 × 36 is 25% less area than 48 × 36. At a fixed 24 pt floor, that area is
  the word budget — roughly a quarter of the current content has to go, or the
  figures shrink to absorb it (which then risks R2 inside the figures).
- Four columns at 24 pt+ do not fit in 36 in of width. A square poster wants
  **three columns** (about 10.5 in each with 1 in gutters and 1.5 in margins),
  or two wide columns with a full-width figure band.
- The title band and the figure zone both currently assume 48 in of width; both
  need re-flowing, and `docs/poster-layout.md` needs to be re-derived rather
  than patched.
