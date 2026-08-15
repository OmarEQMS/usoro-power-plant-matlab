/**
 * Book build — assembles the full book into one paged-media HTML document
 * (dist-book/book.html), which pagedjs-cli turns into an A5 PDF
 * (`npm run book`). Reuses ui/pipeline's renderer unchanged; everything
 * book-specific (assembly, stylesheet, PDF) lives under book/.
 *
 * Structure: cover, preface + contents (roman folios), three parts from
 * ui/site.config.ts (chapters numbered 1..45, arabic folios restarting at
 * Part I), then back matter: source listings for every file Part III
 * cites, and glossary/identifier tables from the site's own data.
 */
import * as fs from 'fs';
import * as path from 'path';
import Prism from 'prismjs';
import { sections } from '../ui/site.config';
import { getPage } from '../ui/pipeline/manifest';
import { renderBody, TocEntry } from '../ui/pipeline/render';
import { resetEquationCounter } from '../ui/components/blocks';
import { wrapIdentifiersInHtml } from '../ui/pipeline/abbr-plugin';
import { abbreviations } from '../ui/pipeline/abbreviations';
import { identifiers } from '../ui/pipeline/identifiers';
import { wrapCodeBlocks } from './wrap-code';

const REPO_ROOT = path.resolve(__dirname, '..');
const OUT_DIR = path.join(REPO_ROOT, 'dist-book');

/** Consolas columns that truly fit the A5 measure at 8pt: 110mm inside
 *  the box padding / 1.55mm per char = 70 (verified on the PoC render;
 *  71 soft-wrapped). Overshooting sends lines to the CSS soft-wrap
 *  backstop, which breaks without the continuation marker. */
const CODE_COLS = 70;

/** listing chunk size: each chunk becomes its own seamless <pre> so
 *  Paged.js paginates between chunks instead of splitting one huge block */
const LISTING_CHUNK = 44;

const PART_NUMERALS = ['I', 'II', 'III', 'IV'];

/** One document, one anchor namespace: every page gets a unique anchor
 *  (`page-basics-steam-tables`) and its headings the matching prefix. */
const anchorOf = (id: string): string => `page-${id.replace(/\//g, '-')}`;

const included = new Set(sections.flatMap((s) => s.pages.map((p) => p.id)));

/** Cross-page links become internal anchors; the stylesheet appends
 *  "(p. N)" via target-counter. Links to pages outside the book render
 *  as plain text (href "#void", styled inert) instead of dead links. */
function resolveLink(toId: string, anchor?: string): string {
  if (!included.has(toId)) return '#void';
  return anchor ? `#${anchorOf(toId)}--${anchor}` : `#${anchorOf(toId)}`;
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

interface Chapter {
  id: string;
  number: number;
  title: string;
  body: string;
  toc: TocEntry[];
  sourceFiles: string[];
}

interface Part {
  numeral: string;
  title: string;
  anchor: string;
  chapters: Chapter[];
}

function renderParts(): Part[] {
  resetEquationCounter(); // once: equation numbers run through the book
  let number = 0;
  return sections.map((section, i) => ({
    numeral: PART_NUMERALS[i],
    title: section.title,
    anchor: `part-${section.id}`,
    chapters: section.pages.map((def) => {
      const page = getPage(def.id);
      number += 1;
      const { body, toc, sourceFiles } = renderBody(page, {
        resolveLink,
        idPrefix: anchorOf(def.id),
        sourceModal: false,
        resetEquations: false,
      });
      return {
        id: def.id,
        number,
        title: page.title,
        body: wrapCodeBlocks(body, CODE_COLS),
        toc,
        sourceFiles,
      };
    }),
  }));
}

function coverHtml(): string {
  // Line-art steam cycle — the loop the book teaches: drum over the
  // fired furnace (risers/downcomers), steam line through the
  // superheater coil to the turbine, generator on the shaft, exhaust to
  // the condenser, condensate back through the feed pump to the drum.
  const schematic = `<svg viewBox="0 0 240 150" fill="none" stroke="currentColor" stroke-width="1" aria-hidden="true">
  <rect x="20" y="18" width="52" height="22" rx="11"/>
  <line x1="27" y1="31" x2="65" y2="31" stroke-width="0.5" stroke-dasharray="3 2.5" opacity="0.65"/>
  <rect x="24" y="62" width="44" height="52" stroke-width="0.9"/>
  <path d="M36 110 q4 -5 0 -10 q-4 -5 0 -10 M46 112 q5 -6 0 -12 q-5 -6 0 -12 M56 110 q4 -5 0 -10 q-4 -5 0 -10" stroke-width="0.7" opacity="0.8"/>
  <line x1="32" y1="40" x2="32" y2="62" stroke-width="0.8"/>
  <line x1="60" y1="40" x2="60" y2="62" stroke-width="0.8"/>
  <path d="M72 29 H96 a4 4 0 0 1 8 0 a4 4 0 0 1 8 0 a4 4 0 0 1 8 0 H132 V50 H146" stroke-width="0.8"/>
  <path d="M146 36 L184 24 L184 76 L146 64 Z"/>
  <line x1="184" y1="50" x2="199" y2="50" stroke-width="0.8"/>
  <circle cx="212" cy="50" r="13"/>
  <path d="M204 50 q4 -6 8 0 q4 6 8 0" stroke-width="0.8"/>
  <line x1="165" y1="76" x2="165" y2="88" stroke-width="0.8"/>
  <rect x="142" y="88" width="46" height="26" stroke-width="0.9"/>
  <path d="M147 101 L153 95 L159 107 L165 95 L171 107 L177 95 L183 101" stroke-width="0.6" opacity="0.8"/>
  <path d="M165 114 V128 H105" stroke-width="0.8"/>
  <circle cx="98" cy="128" r="7" stroke-width="0.8"/>
  <path d="M101 124 L93 128 L101 132 Z" stroke-width="0.7"/>
  <path d="M91 128 H14 V29 H20" stroke-width="0.8"/>
</svg>`;

  return `<section class="cover">
  <div class="cover-frame">
    <div class="cover-kicker">A guided tour in three parts</div>
    <h1 class="cover-title">The Usoro<br>Power Plant</h1>
    <div class="cover-subtitle">Physics, plant and code of a 47-state<br>drum boiler&ndash;turbine model</div>
    <div class="cover-art">${schematic}</div>
    <div class="cover-footer">Compiled from the project documentation &middot; MMXXVI</div>
  </div>
</section>`;
}

function prefaceHtml(): string {
  return `<section class="preface" id="preface">
<h1>Preface</h1>
<p>This book teaches one specific thing, thoroughly: the 47th-order
dynamic model of a 600&nbsp;MW drum boiler&ndash;turbine power plant from
P.&nbsp;B.&nbsp;Usoro's 1977 MIT thesis, and the MATLAB implementation
that accompanies it. By the end you should be able to open any model file
and recognize every equation in it &mdash; where it comes from, what it
assumes, and why it is written the way it is.</p>
<p>The three parts are ordered. <em>Basic Knowledge</em> builds the
mathematics and physics toolkit: units, balances, steam properties, flow
networks, machines, feedback control and numerical integration.
<em>Power Plant</em> walks the unit component by component, furnace to
generator. <em>Code</em> goes file by file through
<code>src/+model</code>, ending with three full equation-to-code
walkthroughs. Later chapters rely only on earlier ones, and
cross-references carry page numbers, so the book reads front to back but
supports jumping in anywhere.</p>
<p>The model is 47th order: 23 states describe the physical plant and 24
describe its analog control system. It runs in English engineering units
throughout &mdash; the opening chapter explains exactly what that means
and why it matters more than it sounds.</p>
<p>Abbreviations are spelled out at first use in each chapter, and the
glossary at the back collects them all, together with a table of the
model's variable names. The complete source of every file discussed in
Part III appears in Appendix&nbsp;A.</p>
<blockquote>P.&nbsp;B.&nbsp;Usoro, <em>Modeling and Simulation of a Drum
Boiler-Turbine Power Plant Under Emergency State Control</em>, M.S.
thesis, MIT Department of Mechanical Engineering, May 1977.</blockquote>
<p>The book is compiled from the project's living documentation site: it
describes the model as currently implemented, and collects the model's
correction history in the changelog chapter that closes
Part&nbsp;II.</p>
</section>`;
}

interface BackMatterEntry {
  letter: string;
  title: string;
  anchor: string;
  html: string;
}

function tocHtml(parts: Part[], backMatter: BackMatterEntry[]): string {
  const rows: string[] = [];
  for (const part of parts) {
    rows.push(
      `    <li class="toc-part"><a href="#${part.anchor}">Part ${part.numeral} &mdash; ${part.title}</a></li>`,
    );
    for (const ch of part.chapters) {
      rows.push(
        `    <li class="toc-chapter"><a href="#${anchorOf(ch.id)}"><span class="toc-num">${ch.number}</span>${ch.title}</a></li>`,
      );
      // TocEntry.text keeps only plain-text tokens, so headings with math
      // or code lose fragments ("Mass, force and $g_c$" -> "Mass, force
      // and") — take the fully rendered h2 from the body instead.
      const h2html = new Map<string, string>();
      for (const m of ch.body.matchAll(/<h2 id="([^"]+)">([\s\S]*?)<\/h2>/g)) {
        h2html.set(m[1], m[2]);
      }
      for (const t of ch.toc.filter((t) => t.level === 2)) {
        rows.push(
          `    <li class="toc-sub"><a href="#${t.slug}">${h2html.get(t.slug) ?? t.text}</a></li>`,
        );
      }
    }
  }
  rows.push(`    <li class="toc-part">Back matter</li>`);
  for (const bm of backMatter) {
    rows.push(
      `    <li class="toc-chapter"><a href="#${bm.anchor}"><span class="toc-num">${bm.letter}</span>${bm.title}</a></li>`,
    );
  }
  return `<nav class="book-toc">
  <h1>Contents</h1>
  <ol>
${rows.join('\n')}
  </ol>
</nav>`;
}

function partHtml(part: Part, isFirst: boolean): string {
  return `<section class="part${isFirst ? ' part--first' : ''}" id="${part.anchor}">
  <div class="part-number">Part ${part.numeral}</div>
  <h1 class="part-title">${part.title}</h1>
  <div class="part-rule"></div>
</section>`;
}

function chapterHtml(ch: Chapter): string {
  // the carrier feeds the verso running head (string-set needs in-flow text)
  return `<section class="chapter" id="${anchorOf(ch.id)}">
<span class="string-carrier">The Usoro Power Plant</span>
<div class="chapter-kicker">Chapter ${ch.number}</div>
${ch.body}
</section>`;
}

/** Full highlighted listing of one source file, chunked into seamless
 *  <pre> blocks so pagination happens between chunks. Safe because src
 *  has no block comments — per-chunk Prism output equals whole-file. */
function listingHtml(file: string): string {
  const code = fs.readFileSync(path.join(REPO_ROOT, file), 'utf8').replace(/\s+$/, '');
  const lines = code.split('\n');
  const chunks: string[] = [];
  for (let i = 0; i < lines.length; i += LISTING_CHUNK) {
    const chunk = lines.slice(i, i + LISTING_CHUNK).join('\n');
    const highlighted = wrapIdentifiersInHtml(
      Prism.highlight(chunk, Prism.languages.matlab, 'matlab'),
    );
    chunks.push(
      `<pre class="language-matlab listing"><code class="language-matlab">${highlighted}</code></pre>`,
    );
  }
  const base = path.posix.basename(file.replace(/\\/g, '/'));
  return `<h2 class="listing-name">${base}</h2>
<div class="listing-path">${file}</div>
<div class="listing-file">
${chunks.join('\n')}
</div>`;
}

function backMatterHtml(parts: Part[]): BackMatterEntry[] {
  const seen = new Set<string>();
  const files: string[] = [];
  for (const part of parts) {
    for (const ch of part.chapters) {
      for (const f of ch.sourceFiles) {
        if (!seen.has(f)) {
          seen.add(f);
          files.push(f);
        }
      }
    }
  }

  const listings = wrapCodeBlocks(files.map(listingHtml).join('\n'), CODE_COLS);
  const abbrRows = Object.keys(abbreviations)
    .sort((a, b) => a.localeCompare(b))
    .map(
      (k) => `<p class="g-entry"><strong>${escapeHtml(k)}</strong> &mdash; ${escapeHtml(abbreviations[k])}</p>`,
    )
    .join('\n');
  const identRows = Object.keys(identifiers)
    .sort((a, b) => a.localeCompare(b))
    .map(
      (k) => `<p class="g-entry"><code>${escapeHtml(k)}</code> &mdash; ${escapeHtml(identifiers[k])}</p>`,
    )
    .join('\n');

  return [
    {
      letter: 'A',
      title: 'Source listings',
      anchor: 'backmatter-listings',
      html: `<p>The complete MATLAB source of every file cited by Part III,
as of this printing. Long lines are wrapped at the arrow marker.</p>
${listings}`,
    },
    {
      letter: 'B',
      title: 'Glossary of abbreviations',
      anchor: 'backmatter-glossary',
      html: `<p>Every abbreviation used in this book. Within chapters, each
is also spelled out at its first use.</p>
<div class="gloss">
${abbrRows}
</div>`,
    },
    {
      letter: 'C',
      title: 'Model identifiers',
      anchor: 'backmatter-identifiers',
      html: `<p>The thesis variable names that appear in code excerpts and
listings, with their meanings.</p>
<div class="gloss">
${identRows}
</div>`,
    },
  ];
}

function backMatterSection(bm: BackMatterEntry): string {
  return `<section class="chapter backmatter" id="${bm.anchor}">
<span class="string-carrier">The Usoro Power Plant</span>
<div class="chapter-kicker">Appendix ${bm.letter}</div>
<h1>${bm.title}</h1>
${bm.html}
</section>`;
}

function bookHtml(parts: Part[], backMatter: BackMatterEntry[]): string {
  const bodyParts: string[] = [coverHtml(), prefaceHtml(), tocHtml(parts, backMatter)];
  parts.forEach((part, i) => {
    bodyParts.push(partHtml(part, i === 0));
    bodyParts.push(...part.chapters.map(chapterHtml));
  });
  bodyParts.push(...backMatter.map(backMatterSection));

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>The Usoro Power Plant</title>
<link rel="stylesheet" href="assets/katex.min.css">
<link rel="stylesheet" href="assets/prism.css">
<link rel="stylesheet" href="assets/book.css">
</head>
<body>
${bodyParts.join('\n')}
</body>
</html>`;
}

/** dist-book/ is self-contained: stylesheets and KaTeX fonts are copied
 *  in so any server root (pagedjs-cli's included) can resolve them. */
function copyAssets(): void {
  const assets = path.join(OUT_DIR, 'assets');
  fs.mkdirSync(assets, { recursive: true });
  const nm = path.join(REPO_ROOT, 'node_modules');
  fs.copyFileSync(path.join(nm, 'katex', 'dist', 'katex.min.css'), path.join(assets, 'katex.min.css'));
  fs.cpSync(path.join(nm, 'katex', 'dist', 'fonts'), path.join(assets, 'fonts'), { recursive: true });
  fs.copyFileSync(path.join(nm, 'prismjs', 'themes', 'prism.css'), path.join(assets, 'prism.css'));
  fs.copyFileSync(path.join(__dirname, 'book.css'), path.join(assets, 'book.css'));
}

function main(): void {
  const parts = renderParts();
  const backMatter = backMatterHtml(parts);
  fs.mkdirSync(OUT_DIR, { recursive: true });
  copyAssets();
  const out = path.join(OUT_DIR, 'book.html');
  fs.writeFileSync(out, bookHtml(parts, backMatter));
  const total = parts.reduce((n, p) => n + p.chapters.length, 0);
  console.log(
    `book: ${parts.length} parts, ${total} chapters, ${backMatter.length} appendices -> ${path.relative(REPO_ROOT, out)}`,
  );
}

main();
