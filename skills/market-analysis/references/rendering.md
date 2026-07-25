# Rendering system — HTML + PDF deliverables

Shared by market-analysis and business-plan. Turns a report's markdown into ONE self-contained
HTML file and a print-quality PDF that survives page-by-page inspection. The bar: a document a
founder hands an investor without apologizing.

## Design system (consulting-grade, non-negotiable defaults)

- **Two type families**: serif display for the cover title and H1s (system stack:
  `"Iowan Old Style", "Palatino", Georgia, serif`), sans for body, tables, captions
  (`-apple-system, "Helvetica Neue", Inter, Arial, sans-serif`). Never one font for everything.
  System stacks — a self-contained file loads no webfonts.
- **Scale**: cover title ~32pt, H2 18–20pt, body 11pt, annotations 9–10pt, footnotes 7–8pt.
  Max 4 sizes per page. Body column `max-width: 66ch` — never edge-to-edge paragraphs.
- **Color**: ONE accent hue (default: deep navy `#1a2e4a`) + a gray ramp. Any further color
  must carry meaning. Confidence/risk chips use color **plus** a letter — `H`/`M`/`L` inside
  the chip — never color alone. Body text contrast ≥ 4.5:1.
- **Action titles**: every section heading asserts the finding as a sentence ("The bottom-up
  SOM supports a $X–Y ARR ceiling by year 3"), never a label ("Market Sizing"). Pull the
  sentence from the report's content; the exhibit below is the proof.
- **Exec summary is pyramid-first**: conclusion paragraph, then 3–5 supporting bullets.
- **Cover page**: report title, one-line subtitle that states the takeaway, product/org name,
  date, "prepared by" line. Nothing else. **Exception — single-page artifacts (the
  one-pager)**: no cover at all; the title block is the first element of the one and only
  page, and the deliverable fails verification if it spills to page 2 (cut content, never
  shrink type below 9pt).
- **Exhibits**: chart/table dominant with a short "what this means" annotation beside or
  directly under it. Sources footnote at point of use (`[S12]` linking to the source table in
  the appendix), not buried in endnotes. Every table: consistent units, right-aligned numbers,
  hairline row rules or ≤8% zebra tint — never heavy bands.
- **Charts are inline SVG** you author (bars for sizing ranges, a 2×2 positioning map dots +
  labels). No chart libraries, no external anything — the file must open offline, forever.

## Print CSS — the pagination rules that actually work

Chromium quirks are the difference between polished and embarrassing. Encode exactly this:

```css
@page {
  size: A4;
  margin: 20mm 18mm 24mm 18mm;
  @bottom-right { content: counter(page) " / " counter(pages); font-size: 8pt; color: #666; }
  @bottom-left  { content: "<Product> — <Report title>"; font-size: 8pt; color: #666; }
}
@page :first { @bottom-right { content: none } @bottom-left { content: none } } /* cover */

section.chapter { break-before: page; }
h1, h2, h3     { break-after: avoid; }          /* no orphan headings */
p              { orphans: 3; widows: 3; }        /* prose only — useless on tables */
figure, .exhibit, .card, svg { break-inside: avoid; }
tr             { break-inside: avoid; }          /* helps, but NOT reliable in Chromium — see below */
```

- `@page` margin boxes (`@bottom-right` etc. + `counter(page)`) are **Chromium 131+ only** —
  fine for this pipeline; do NOT expect them in WeasyPrint output unchanged (WeasyPrint has its
  own full margin-box support, so the same rules render there too — it's Firefox/Safari that
  lack them, irrelevant here).
- **Never reference external images inside margin boxes** — headless CLI silently drops them.
  Inline any such asset as a base64 `data:` URI (better: don't put images in margin boxes).
- **Tables**: real `<thead>`/`<tbody>` markup so Chromium repeats the header on every page.
  `break-inside: avoid` on `<tr>` is unreliable in Blink — for a table whose rows must not
  split (the assumptions table, competitor profiles), either keep rows short, or build the
  "table" from `div`s with `break-inside: avoid` per row. Check in the verify pass either way.
- **Never wrap a table you expect to paginate in a `break-inside: avoid` container**
  (`.exhibit`, `.card`, `figure`): if the whole table still fits on one fresh page, Chromium
  relocates the entire wrapper to the next page instead of splitting it — a big blank gap on
  the prior page, and the thead-repeat behavior silently never exercised (live-verified
  failure). Paginating tables get their own unwrapped container, with the title as a sibling
  heading outside the avoid box.
- Long content that can't shrink (wide matrices): rotate to a landscape section
  (`@page wide { size: A4 landscape } .wide { page: wide }`) rather than letting it clip.

The same HTML must read well on screen: wrap print rules in `@media print` where they'd hurt
scrolling (keep `break-*` unprefixed — they're inert on screen), give screen a centered
`max-width` page with subtle shadow. One file, both media.

## Toolchain ladder (macOS, no paid tools)

**1. Headless Chrome CLI — the default.** CSS controls everything; the CLI respects `@page`
size. Exact invocation:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --virtual-time-budget=10000 \
  --print-to-pdf="/absolute/path/deliverables/report.pdf" \
  "file:///absolute/path/deliverables/report.html"
```

`--no-pdf-header-footer` kills the ugly default URL/date cruft (it replaced the older
`--print-to-pdf-no-header`). `--virtual-time-budget` lets fonts/async settle. The CLI has NO
margin/paper flags — margins live in `@page`, which is why the CSS above owns them. If Chrome
isn't at that path, try `Chromium.app`, `chromium`, `google-chrome`.

On macOS this prints harmless `ERROR:...task_policy_set...invalid argument` lines to stderr on
every run. **Success is the PDF written non-empty on disk, not a quiet stderr** — do not fall
through to step 2 because of those lines (live-verified: the PDF is fine).

**2. WeasyPrint — when Chromium mis-breaks something you can't restructure.** Full paged-media
implementation, very predictable breaks, no JS execution. Install needs brew libs FIRST — a
bare pip install fails to import Pango:

```bash
brew install cairo pango gdk-pixbuf libffi
uvx --from weasyprint weasyprint report.html report.pdf   # or pip install weasyprint in a venv
```

**3. pandoc → weasyprint — draft preview ONLY, never the deliverable** (`pandoc report.md
--pdf-engine=weasyprint -o draft.pdf`): it renders the markdown, so it structurally cannot
produce the cover page, action titles, exhibits, or chips the design system requires. Never
install LaTeX/basictex for any of this.

Step 1 needs no install and Chrome is present on virtually every macOS box — verify it FIRST.
Ask before brew-installing anything (slow, mutates the user's system). If no PDF path is
available at all, ship the self-contained HTML, say plainly that the PDF step was blocked and
why, and do not call the deliverables phase complete.

## The verify loop — mandatory, not a suggestion

Render, then **Read the PDF back** (the Read tool renders PDF pages) and inspect EVERY page:

1. No table or figure cut mid-element; no heading stranded at a page bottom.
2. `<thead>` repeated on tables that span pages; no row split mid-text.
3. Nothing clipped at the right edge; wide exhibits went landscape, not truncated.
4. Page numbers and running footer present from page 2; cover clean.
5. Chips/charts legible in grayscale logic (letter in every chip, labels on every SVG mark).
6. Page count sane — a 40-page PDF from a 15-page report means a CSS break rule exploded.

Fix the CSS (or restructure the offending exhibit), re-render, re-read. Loop until clean, then
tell the user the PDF passed page-by-page inspection — and only then is the deliverable done.
