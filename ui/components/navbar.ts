/**
 * Top navigation: brand + one link per section, active state by section.
 * Below lg — where the sidebar is d-none — the collapse also carries the
 * current section's full page list (active page highlighted) plus jump
 * links to the other sections, so the toggler menu is a complete map.
 */
import { siteName, sections } from '../site.config';
import { Page, hrefFrom } from '../pipeline/manifest';

export function navbar(page: Page): string {
  const links = sections
    .map((section) => {
      const active = page.section?.id === section.id;
      const href = hrefFrom(page.id, section.pages[0].id);
      return `<li class="nav-item">
        <a class="nav-link${active ? ' active' : ''}"${active ? ' aria-current="page"' : ''} href="${href}">${section.title}</a>
      </li>`;
    })
    .join('\n');

  // Mobile-only page map for the current section + other-section jumps.
  let mobileNav = '';
  if (page.section) {
    const pageItems = page.section.pages
      .map((p) => {
        const active = p.id === page.id;
        return `<li class="nav-item">
          <a class="nav-link${active ? ' active' : ''}"${active ? ' aria-current="page"' : ''} href="${hrefFrom(page.id, p.id)}">${p.title}</a>
        </li>`;
      })
      .join('\n');
    const otherLinks = sections
      .filter((s) => s.id !== page.section!.id)
      .map(
        (s) => `<li class="nav-item">
          <a class="nav-link" href="${hrefFrom(page.id, s.pages[0].id)}">${s.title} &rarr;</a>
        </li>`,
      )
      .join('\n');
    mobileNav = `<div class="d-lg-none mobile-nav">
        <div class="mobile-nav-heading">${page.section.title}</div>
        <ul class="navbar-nav">
${pageItems}
        </ul>
        <hr class="mobile-nav-divider">
        <div class="mobile-nav-heading">Other sections</div>
        <ul class="navbar-nav">
${otherLinks}
        </ul>
      </div>`;
  }

  // With the mobile map present, the plain section links are desktop-only;
  // on the landing page (no section) they serve both widths as before.
  const desktopOnly = page.section ? ' d-none d-lg-flex' : '';

  return `<nav class="navbar navbar-expand-lg sticky-top site-navbar" data-bs-theme="dark">
  <div class="container-xxl">
    <a class="navbar-brand" href="${hrefFrom(page.id, 'index')}">${siteName}</a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#site-nav"
            aria-controls="site-nav" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="site-nav">
      <ul class="navbar-nav ms-auto${desktopOnly}">
${links}
      </ul>
${mobileNav}
    </div>
  </div>
</nav>`;
}
