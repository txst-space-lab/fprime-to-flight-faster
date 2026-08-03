# Poster Requirements

Hard constraints the printed poster must satisfy. These are not preferences —
a violation means the poster is rejected or unreadable on the floor. Layout
choices live in `docs/poster-layout.md`; this file is only the rules that
layout has to obey.

---

## R1 — Canvas size: 45 in × 45 in

The poster must be **45 inches wide by 45 inches tall** — square.

- Set in `poster.typ` via the `print-size` constant. The layout is composed at
  a 36 in `design-size` and scaled onto the sheet in one place at the bottom of
  the file, so every length and type size in the source is a 36 in value and
  prints 1.25× larger. Change `print-size` alone to change the sheet.
- Export at full scale. Never let the print shop "fit to page"; a rescale
  breaks every other requirement on this page at once.
- No bleed.

**Status: met.** `poster.typ` renders a 3240 × 3240 pt page. In composed units
that is 36 in × 36 in with 1.2 in side margins, 0.7 in top and bottom, and three
10.67 in columns separated by a 0.8 in gutter — on paper, 1.5 in / 0.875 in
margins and three 13.33 in columns on a 1 in gutter.

## R2 — Minimum font size: 24 pt

**No text may render below 24 pt.** That includes figure captions, table
headers, footnotes, references, URLs, and any type baked into an image or SVG.

Sizes below are **composed** sizes — the numbers in `poster.typ`. The 1.25×
print scale (R1) lifts every one of them, so the composed 24 pt floor prints at
30 pt. Keep auditing against the composed floor anyway: it is the number in the
source, and it holds the poster readable if the sheet ever shrinks back.

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
10 pt composed (12.5 pt printed) at column width, and enlarging it far enough to fix that leaves no room
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

## R6 — Texas State branding colors

**Every color that carries meaning must come from the Texas State brand
palette**: <https://brand.txst.edu/visual-identity/colors.html>. This is a
university-branded poster shown under university letterhead, so off-brand hues
are a rejection risk, not a taste question.

Two files define color and both must draw from the same guide, with the brand
name in a comment next to each value:

- `poster.typ` — Primary (Maroon, Dark Gold) and Web-Exclusive (Sandstone).
- `tools/analyze-ci.py` — Primary (Maroon) for figure titles, Tertiary
  (Spring Lake Blue, Wild Rice Green, Eat 'Em Up Peach, Green Hills) for the
  marks.

Exempt: neutrals that are structure rather than meaning — ink, muted grey, grid
and axis hairlines, white — and the `#todo[]` marker, which never reaches print
(R4).

Two constraints ride along with the palette and outrank hue preference:

- **Contrast.** Any brand color used for a data mark or for text must stay
  legible at 4 ft on white. Tints meant as background fills — River Jump, for
  one — sit near 1.2:1 and disappear as bars or lines no matter how well they
  fit the brand.
- **Categorical separation.** Series colors in one chart must be tellable apart
  under normal vision *and* red-green CVD. The brand palette is small enough
  that this rules out some otherwise valid pairs.

**Status: met.** Every hue in `poster.typ` and `tools/analyze-ci.py` is a brand
color, grouped under the guide's own section names with the URL beside them.
One known compromise: green does double duty — hardware jobs in figure 1,
passed jobs in figure 2 — which is unambiguous only because no single figure
plots both encodings.

---

## Verification

| Requirement | Check |
|---|---|
| R1 size | `pdfinfo poster.pdf \| grep "Page size"` → 3240 × 3240 pts |
| R2 min font | `grep -n "size: [0-9]*pt" poster.typ` → no value under 24; plus a visual pass over every figure |
| R3 one page | `pdfinfo poster.pdf \| grep Pages` → 1 |
| R4 placeholders | `grep -n '#todo\[' poster.typ` → no output |
| R5 fonts | built inside `nix develop`; `typst fonts` lists Inter and JetBrains Mono |
| R6 brand colors | `grep -niE '#[0-9a-f]{6}' poster.typ tools/analyze-ci.py` → every hit is a brand color or a listed neutral |

`pdfinfo` reports page size in PostScript points at 72 pt/in, so 45 in = 3240 pt
on both axes. A page reporting 2592 pt is the old 36 in sheet — `print-size` in
`poster.typ` was changed or lost.

---

## R1 + R2 together

These two pull against each other, and the tension is permanent, not a one-time
migration cost. At a fixed 24 pt floor the sheet area *is* the word budget:
36 × 36 holds about three quarters of what 48 × 36 held. Squaring the canvas cost
two figures and two ranked list items; `docs/poster-layout.md` records exactly
what and why.

Going to 45 × 45 did **not** buy that content back. The sheet grew and the
composition was scaled with it, so the word budget is unchanged and everything
simply prints larger and more legibly at a distance. Spending the extra area on
content instead would mean re-laying out at 45 in composed units — a different,
larger job than this change, and one that has to re-audit R2 from scratch.

The practical rule that falls out of it: **nothing gets added to this poster
without something else coming off.** The tightest column has under an inch of
composed slack. When content has to shrink, shrink figures — type has nowhere
to go.
