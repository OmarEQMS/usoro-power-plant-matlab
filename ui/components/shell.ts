/**
 * Page skeleton: <head>, navbar, three-column body (sidebar / content /
 * TOC), pager and footer. html-webpack-plugin injects the css/js tags.
 */
import { siteName } from '../site.config';
import { Page } from '../pipeline/manifest';
import type { TocEntry } from '../pipeline/render';
import { navbar } from './navbar';
import { sidebar } from './sidebar';
import { pager } from './pager';
import { toc } from './toc';

export interface ShellInput {
  page: Page;
  description?: string;
  body: string;
  toc: TocEntry[];
}

export function shell(input: ShellInput): string {
  const { page } = input;
  const title = page.id === 'index' ? siteName : `${page.title} · ${siteName}`;
  const desc = input.description
    ? `\n  <meta name="description" content="${input.description.replace(/"/g, '&quot;')}">`
    : '';
  const sidebarHtml = sidebar(page);
  const tocHtml = toc(input.toc);

  const spyAttrs = tocHtml
    ? ' data-bs-spy="scroll" data-bs-target=".site-toc" data-bs-smooth-scroll="true" tabindex="0"'
    : '';

  return `<!doctype html>
<html lang="en" data-bs-theme="light">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">${desc}
  <title>${title}</title>
</head>
<body${spyAttrs}>
${navbar(page)}
<div class="container-xxl site-layout">
  <div class="row">
    <aside class="col-lg-3 col-xl-2 d-none d-lg-block layout-sidebar">
${sidebarHtml}
    </aside>
    <main class="col-lg-9 ${tocHtml ? 'col-xl-8' : 'col-xl-10'} layout-content">
      <article class="content">
${input.body}
      </article>
${pager(page)}
    </main>
    ${tocHtml ? `<aside class="col-xl-2 d-none d-xl-block layout-toc">\n${tocHtml}\n    </aside>` : ''}
  </div>
</div>
<footer class="site-footer">
  <div class="container-xxl">
    Companion learning site for the MATLAB implementation of P. B. Usoro,
    <em>Modeling and Simulation of a Drum Boiler-Turbine Power Plant Under
    Emergency State Control</em>, M.S. thesis, MIT, 1977.
  </div>
</footer>
</body>
</html>`;
}
