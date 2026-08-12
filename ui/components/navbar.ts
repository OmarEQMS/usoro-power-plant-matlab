/** Top navigation: brand + one link per section, active state by section. */
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

  return `<nav class="navbar navbar-expand-lg sticky-top site-navbar" data-bs-theme="dark">
  <div class="container-xxl">
    <a class="navbar-brand" href="${hrefFrom(page.id, 'index')}">${siteName}</a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#site-nav"
            aria-controls="site-nav" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="site-nav">
      <ul class="navbar-nav ms-auto">
${links}
      </ul>
    </div>
  </div>
</nav>`;
}
