/** Right rail: in-page table of contents from the rendered h2/h3 headings. */
import type { TocEntry } from '../pipeline/render';

export function toc(entries: TocEntry[]): string {
  if (entries.length < 2) return '';
  const items = entries
    .map(
      (e) =>
        `<li class="toc-item toc-level-${e.level}"><a class="nav-link" href="#${e.slug}">${e.text}</a></li>`,
    )
    .join('\n');
  return `<nav class="site-toc" aria-label="On this page">
  <div class="toc-heading">On this page</div>
  <ul class="nav flex-column">
${items}
  </ul>
</nav>`;
}
