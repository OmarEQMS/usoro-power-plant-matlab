/** Left rail: the current section's page tree with active page highlight. */
import { Page, hrefFrom } from '../pipeline/manifest';

export function sidebar(page: Page): string {
  if (!page.section) return '';
  const items = page.section.pages
    .map((p) => {
      const active = p.id === page.id;
      return `<li class="nav-item">
        <a class="nav-link${active ? ' active' : ''}" href="${hrefFrom(page.id, p.id)}">${p.title}</a>
      </li>`;
    })
    .join('\n');

  return `<nav class="site-sidebar" aria-label="${page.section.title} pages">
  <div class="sidebar-heading">${page.section.title}</div>
  <ul class="nav flex-column">
${items}
  </ul>
</nav>`;
}
