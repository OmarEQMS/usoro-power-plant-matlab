/** Previous/next footer links, from the manifest order within a section. */
import { Page, hrefFrom } from '../pipeline/manifest';

export function pager(page: Page): string {
  if (!page.prev && !page.next) return '';
  const prev = page.prev
    ? `<a class="pager-link pager-prev" href="${hrefFrom(page.id, page.prev.id)}">
        <span class="pager-label">&larr; Previous</span>
        <span class="pager-title">${page.prev.title}</span>
      </a>`
    : '<span></span>';
  const next = page.next
    ? `<a class="pager-link pager-next" href="${hrefFrom(page.id, page.next.id)}">
        <span class="pager-label">Next &rarr;</span>
        <span class="pager-title">${page.next.title}</span>
      </a>`
    : '<span></span>';
  return `<div class="pager d-flex justify-content-between">
${prev}
${next}
</div>`;
}
