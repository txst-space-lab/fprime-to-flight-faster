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

**Status: met.** `poster.typ` is `36in × 36in` with 1.2 in side margins, 0.7 in
top and bottom, and three 10.67 in columns separated by a 0.8 in gutter.

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

**Status: met.** Every explicit `size:` in `poster.typ` is 24 pt or larger and
the document default is 24 pt. The generated charts are audited too: they are a
7 in canvas rendered at a 10.67 in column, a 1.52× scale, and
`tools/analyze-ci.py` holds a 16 pt minimum so the smallest tick label prints at
24.4 pt. That audit is why the charts may not be rendered narrower than a full
column — at the old two-thirds-column size their labels printed at about 15 pt.

One consequence worth stating plainly: **a screenshot of a user interface cannot
meet this requirement.** The GitHub checks screenshot carries type at roughly
10 pt at column width, and enlarging it far enough to fix that leaves no room
for the rest of the poster. It is off the sheet (see `docs/poster-layout.md`);
if it ever goes back on, it goes on as a violation of R2 that you are choosing
knowingly, not as an oversight.

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

## R1 + R2 together

These two pull against each other, and the tension is permanent, not a one-time
migration cost. At a fixed 24 pt floor the sheet area *is* the word budget:
36 × 36 holds about three quarters of what 48 × 36 held. Squaring the canvas cost
two figures and two ranked list items; `docs/poster-layout.md` records exactly
what and why.

The practical rule that falls out of it: **nothing gets added to this poster
without something else coming off.** The tightest column has under an inch of
slack. When content has to shrink, shrink figures — type has nowhere to go.
