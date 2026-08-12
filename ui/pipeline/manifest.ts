/**
 * Derives the flat page list (with prev/next, source and output paths)
 * from ui/site.config.ts, and provides id -> relative-href resolution.
 */
import * as fs from 'fs';
import * as path from 'path';
import { PageDef, SectionDef, sections } from '../site.config';

export interface PageRef {
  id: string;
  title: string;
}

export interface Page {
  id: string;
  title: string;
  section: SectionDef | null;
  /** absolute path of the markdown source */
  src: string;
  /** output path relative to dist/, e.g. "basics/units.html" */
  out: string;
  prev: PageRef | null;
  next: PageRef | null;
}

const CONTENT_DIR = path.resolve(__dirname, '..', 'content');

function outPath(id: string): string {
  return `${id}.html`;
}

function toPage(def: PageDef, section: SectionDef | null): Page {
  return {
    id: def.id,
    title: def.title,
    section,
    src: path.join(CONTENT_DIR, `${def.id}.md`),
    out: outPath(def.id),
    prev: null,
    next: null,
  };
}

function buildPages(): Page[] {
  const pages: Page[] = [toPage({ id: 'index', title: 'Home' }, null)];
  for (const section of sections) {
    const sectionPages = section.pages.map((p) => toPage(p, section));
    sectionPages.forEach((p, i) => {
      p.prev = i > 0 ? sectionPages[i - 1] : null;
      p.next = i < sectionPages.length - 1 ? sectionPages[i + 1] : null;
    });
    pages.push(...sectionPages);
  }
  return pages;
}

const pages = buildPages();
const byId = new Map(pages.map((p) => [p.id, p]));

export function getPages(): Page[] {
  return pages;
}

export function getPage(id: string): Page {
  const page = byId.get(id);
  if (!page) {
    throw new Error(`unknown page id "${id}" — not listed in ui/site.config.ts`);
  }
  return page;
}

/** Relative href from one page to another (output files live in subfolders). */
export function hrefFrom(fromId: string, toId: string): string {
  const from = getPage(fromId);
  const to = getPage(toId);
  const rel = path.posix.relative(path.posix.dirname(from.out), to.out);
  return rel === '' ? path.posix.basename(to.out) : rel;
}

/** Build-time sanity check: every manifest page must have a source file. */
export function assertSourcesExist(): void {
  const missing = pages.filter((p) => !fs.existsSync(p.src));
  if (missing.length > 0) {
    throw new Error(
      `manifest pages without a markdown source:\n` +
        missing.map((p) => `  ${p.id} -> ${p.src}`).join('\n'),
    );
  }
}
