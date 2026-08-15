/**
 * Build-time hard-wrap for code blocks. The A5 measure fits ~72 Consolas
 * columns; longer lines are broken at sensible points and continuations
 * marked with a gray arrow. Runs over Prism's HTML output, so widths are
 * counted in *visible* columns: tags are zero-width, entities one column.
 * book.css keeps `white-space: pre-wrap` as the safety net — a miscount
 * here degrades to a browser soft-wrap, never an overflow.
 */

const CONT_HTML = '<span class="code-cont">  ↪ </span>';
const CONT_WIDTH = 4; // visible columns the marker occupies

/** tag (attribute-quote aware) | HTML entity | one character */
const SEG_RE = /<(?:[^>"]|"[^"]*")+>|&[a-zA-Z][a-zA-Z0-9]*;|&#x?[0-9a-fA-F]+;|[\s\S]/g;

interface Seg {
  html: string;
  width: 0 | 1;
  isSpace: boolean;
}

function tokenize(line: string): Seg[] {
  const segs: Seg[] = [];
  for (const m of line.match(SEG_RE) ?? []) {
    const isTag = m.length > 1 && m.startsWith('<');
    segs.push({ html: m, width: isTag ? 0 : 1, isSpace: m === ' ' || m === '\t' });
  }
  return segs;
}

const visibleWidth = (segs: Seg[]): number => segs.reduce((n, s) => n + s.width, 0);

const join = (segs: Seg[]): string => segs.map((s) => s.html).join('');

export function wrapLine(line: string, max: number): string {
  const segs = tokenize(line);
  if (visibleWidth(segs) <= max) return line;

  // A trailing `% comment` is the usual culprit. Locate it once.
  let commentSeg = -1;
  let commentCol = 0;
  let col = 0;
  for (let i = 0; i < segs.length; i += 1) {
    if (segs[i].html.startsWith('<span class="token comment')) {
      commentSeg = i;
      commentCol = col;
      break;
    }
    col += segs[i].width;
  }

  // Small overflow with an aligned comment: absorb it from the alignment
  // spaces (keeping >= 2) so near-identical lines in a block don't get
  // inconsistent treatment — one wrapped, its neighbor inline.
  if (commentSeg > 0) {
    const overflow = visibleWidth(segs) - max;
    let run = 0;
    while (run < commentSeg && segs[commentSeg - 1 - run].isSpace) run += 1;
    if (run - overflow >= 2) {
      segs.splice(commentSeg - overflow, overflow);
      return join(segs);
    }
  }

  // Otherwise, if the code before the comment fits, move the whole
  // comment to the continuation line.
  let breakSeg = commentSeg > 0 && commentCol <= max ? commentSeg : -1;

  if (breakSeg < 0) {
    // greedy: break after the last space that still fits
    let lastSpace = -1;
    let i = 0;
    for (col = 0; i < segs.length && col < max; i += 1) {
      if (segs[i].isSpace) lastSpace = i;
      col += segs[i].width;
    }
    breakSeg = lastSpace > 0 ? lastSpace + 1 : i;
  }

  let head = segs.slice(0, breakSeg);
  let rest = segs.slice(breakSeg);
  while (head.length > 0 && head[head.length - 1].isSpace) head.pop();

  if (visibleWidth(head) === 0) {
    // degenerate (e.g. space-only prefix): hard break at the measure
    let i = 0;
    for (col = 0; i < segs.length && col < max; i += 1) col += segs[i].width;
    head = segs.slice(0, i);
    rest = segs.slice(i);
  }

  return `${join(head)}\n${CONT_HTML}${wrapLine(join(rest), max - CONT_WIDTH)}`;
}

/** Wrap every Prism code block in a rendered HTML fragment. */
export function wrapCodeBlocks(html: string, max: number): string {
  return html.replace(
    /(<pre class="language-[^"]*"><code[^>]*>)([\s\S]*?)(<\/code><\/pre>)/g,
    (_m, open: string, code: string, close: string) =>
      open +
      code
        .split('\n')
        .map((l) => wrapLine(l, max))
        .join('\n') +
      close,
  );
}
