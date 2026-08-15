/**
 * The markdown -> full HTML document pipeline (see docs/ui.md, "How
 * markdown becomes HTML"). Runs in Node during the webpack build; the
 * browser receives finished HTML.
 */
import * as fs from 'fs';
import * as path from 'path';
import matter from 'gray-matter';
import MarkdownIt from 'markdown-it';
import Prism from 'prismjs';
import { shell } from '../components/shell';
import { registerBlocks, resetEquationCounter } from '../components/blocks';
import { Page, getPage, hrefFrom } from './manifest';
import { mathPlugin } from './math-plugin';
import { abbrPlugin, wrapIdentifiersInHtml } from './abbr-plugin';

// Prism languages are loaded once, server-side.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const loadLanguages = require('prismjs/components/') as (langs: string[]) => void;
loadLanguages(['matlab', 'fortran', 'typescript', 'json']);

export interface TocEntry {
  level: 2 | 3;
  slug: string;
  text: string;
}

export interface RenderEnv {
  page: Page;
  toc: TocEntry[];
  unknownAbbr?: Set<string>;
  /** book build: map a validated cross-page link to an href (site default:
   *  relative href between output files) */
  resolveLink?: (toId: string, anchor?: string) => string;
  /** book build: heading ids get `<prefix>--` so 45 chapters can share one
   *  document without anchor collisions */
  idPrefix?: string;
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

const md = new MarkdownIt({
  html: true,
  linkify: false,
  typographer: false,
  highlight: (code, lang) => {
    if (lang && Prism.languages[lang]) {
      const html = wrapIdentifiersInHtml(Prism.highlight(code, Prism.languages[lang], lang));
      return `<pre class="language-${lang}"><code class="language-${lang}">${html}</code></pre>`;
    }
    return `<pre class="language-none"><code>${wrapIdentifiersInHtml(escapeHtml(code))}</code></pre>`;
  },
});

md.use(mathPlugin);
md.use(abbrPlugin);
registerBlocks(md);

// Bootstrap-style responsive tables.
md.renderer.rules.table_open = () =>
  '<div class="table-responsive"><table class="table table-sm table-striped">\n';
md.renderer.rules.table_close = () => '</table></div>\n';

// Heading ids + in-page TOC collection (h2/h3).
md.core.ruler.push('heading_anchors', (state) => {
  const env = state.env as RenderEnv;
  if (!env.toc) return;
  const tokens = state.tokens;
  for (let i = 0; i < tokens.length - 1; i += 1) {
    const open = tokens[i];
    if (open.type !== 'heading_open' || (open.tag !== 'h2' && open.tag !== 'h3')) continue;
    const inline = tokens[i + 1];
    if (inline.type !== 'inline') continue;
    const text = inline.children
      ?.filter((t) => t.type === 'text' || t.type === 'code_inline')
      .map((t) => t.content)
      .join('') ?? '';
    const slug = slugify(text);
    const id = env.idPrefix ? `${env.idPrefix}--${slug}` : slug;
    open.attrSet('id', id);
    env.toc.push({ level: open.tag === 'h2' ? 2 : 3, slug: id, text });
  }
});

// @page-id cross-links, resolved and validated against the manifest.
const defaultLinkOpen =
  md.renderer.rules.link_open ??
  ((tokens, idx, options, _env, self) => self.renderToken(tokens, idx, options));
md.renderer.rules.link_open = (tokens, idx, options, env, self) => {
  const href = tokens[idx].attrGet('href');
  if (href && href.startsWith('@')) {
    const [id, anchor] = href.slice(1).split('#');
    const page = getPage(id); // throws on unknown id -> build failure
    const renderEnv = env as RenderEnv;
    if (renderEnv.resolveLink) {
      tokens[idx].attrSet('href', renderEnv.resolveLink(page.id, anchor));
    } else {
      const rel = hrefFrom(renderEnv.page.id, page.id);
      tokens[idx].attrSet('href', anchor ? `${rel}#${anchor}` : rel);
    }
  }
  return defaultLinkOpen(tokens, idx, options, env, self);
};

const REPO_ROOT = path.resolve(__dirname, '..', '..');

/** Source-code modal: pages with `sourceFile:` front-matter (a path or a
 *  YAML list of paths) get an icon next to their h1 that opens the
 *  file(s)' current contents — tabbed when there is more than one file.
 *  Files are read from the repository AT BUILD TIME (the one sanctioned
 *  exception to the ui/ isolation rule) so listings can never go stale —
 *  and a renamed source file fails the build here instead of lying. */
function sourceModalParts(sourceFiles: string[]): { button: string; modal: string } {
  const panes = sourceFiles.map((file, i) => {
    const abs = path.join(REPO_ROOT, file);
    const code = fs.readFileSync(abs, 'utf8'); // throws on rename -> build fails
    const highlighted = wrapIdentifiersInHtml(
      Prism.highlight(code, Prism.languages.matlab, 'matlab'),
    );
    const base = path.posix.basename(file.replace(/\\/g, '/'));
    return { file, i, base, highlighted };
  });

  const label = sourceFiles.join(', ');
  const button = `<button type="button" class="source-btn" data-bs-toggle="modal"
    data-bs-target="#source-modal" title="View source: ${label}"
    aria-label="View the full source of ${label}">
    <svg width="20" height="20" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">
      <path d="M5.854 4.854a.5.5 0 1 0-.708-.708l-3.5 3.5a.5.5 0 0 0 0 .708l3.5 3.5a.5.5 0 0 0 .708-.708L2.707 8l3.147-3.146zm4.292 0a.5.5 0 0 1 .708-.708l3.5 3.5a.5.5 0 0 1 0 .708l-3.5 3.5a.5.5 0 0 1-.708-.708L13.293 8l-3.147-3.146z"/>
    </svg>
  </button>`;

  // Same tabbed layout regardless of file count — a single file simply
  // renders as a one-tab bar, keeping the modal's look consistent.
  const tabs = panes
    .map(
      (p) => `<li class="nav-item" role="presentation">
        <button class="nav-link${p.i === 0 ? ' active' : ''}" data-bs-toggle="tab"
          data-bs-target="#src-pane-${p.i}" type="button" role="tab"
          aria-controls="src-pane-${p.i}" aria-selected="${p.i === 0}"
          title="${p.file}">${p.base}</button>
      </li>`,
    )
    .join('\n');
  const header = `<ul class="nav nav-tabs source-tabs" id="source-modal-title" role="tablist">
${tabs}
  </ul>`;
  const body = `<div class="tab-content">
${panes
  .map(
    (p) => `<div class="tab-pane${p.i === 0 ? ' show active' : ''}" id="src-pane-${p.i}"
      role="tabpanel" tabindex="0">
      <pre class="language-matlab source-listing"><code class="language-matlab">${p.highlighted}</code></pre>
    </div>`,
  )
  .join('\n')}
</div>`;

  const modal = `<div class="modal fade" id="source-modal" tabindex="-1"
    aria-labelledby="source-modal-title" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header">
        ${header}
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body p-0">
        ${body}
      </div>
    </div>
  </div>
</div>`;
  return { button, modal };
}

/** Invariant: every option defaults to the site's behavior. renderPage
 *  passes none, and the site build must stay byte-identical to a
 *  renderer without these hooks (verification recipe: docs/ui.md,
 *  checklist item 4). Extend the book only with new optional hooks that
 *  keep that property. */
export interface RenderBodyOptions {
  /** book build: override cross-page link hrefs (default: relative site href) */
  resolveLink?: (toId: string, anchor?: string) => string;
  /** book build: unique-id prefix for headings (default: none) */
  idPrefix?: string;
  /** include the view-source modal button + markup (site default: true;
   *  the book renders listings its own way) */
  sourceModal?: boolean;
  /** restart equation numbering (site: per page; the book resets once and
   *  numbers continuously — no prose references numbers, so this is safe) */
  resetEquations?: boolean;
}

export interface RenderedBody {
  body: string;
  toc: TocEntry[];
  description?: string;
  /** `sourceFile:` front-matter paths, repo-relative (empty when absent) */
  sourceFiles: string[];
}

export function renderBody(page: Page, opts: RenderBodyOptions = {}): RenderedBody {
  const raw = fs.readFileSync(page.src, 'utf8');
  const { data, content } = matter(raw);
  const env: RenderEnv = {
    page,
    toc: [],
    resolveLink: opts.resolveLink,
    idPrefix: opts.idPrefix,
  };
  if (opts.resetEquations !== false) resetEquationCounter();
  let body = md.render(content, env);

  const sourceFiles: string[] = Array.isArray(data.sourceFile)
    ? data.sourceFile.filter((f: unknown): f is string => typeof f === 'string')
    : typeof data.sourceFile === 'string'
      ? [data.sourceFile]
      : [];
  if (sourceFiles.length > 0 && opts.sourceModal !== false) {
    const { button, modal } = sourceModalParts(sourceFiles);
    body = body.replace('</h1>', `${button}</h1>`) + modal;
  }

  if (env.unknownAbbr && env.unknownAbbr.size > 0) {
    const list = [...env.unknownAbbr].sort().join(', ');
    console.warn(
      `[abbr-lint] ${page.id}: all-caps tokens missing from the glossary: ${list}` +
        ` (add to ui/pipeline/abbreviations.ts or to lintIgnore)`,
    );
  }

  return {
    body,
    toc: env.toc,
    description: typeof data.description === 'string' ? data.description : undefined,
    sourceFiles,
  };
}

export function renderPage(page: Page): string {
  const { body, toc, description } = renderBody(page);
  return shell({ page, description, body, toc });
}
