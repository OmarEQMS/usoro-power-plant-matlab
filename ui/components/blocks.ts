/**
 * Content building blocks — the `:::` containers available to authors
 * (see docs/ui.md, "Content building blocks"). Milestone-1 renderings are
 * deliberately simple Bootstrap; milestone 2 refines them.
 *
 *   ::: why [optional title]        motivation callout
 *   ::: caution [optional title]    honesty note / model limitation
 *   ::: definition [term]           term/symbol callout
 *   ::: equation [caption]          numbered display equation w/ caption
 *   ::: metrics [title]             key-figures block (markdown table/list inside)
 *   ::: code-map [title]            symbol -> code -> file mapping table
 */
import type MarkdownIt from 'markdown-it';
import containerPlugin from 'markdown-it-container';

// markdown-it-container's bundled types target an older markdown-it API
// surface; the runtime is compatible with v14.
const container = containerPlugin as unknown as Parameters<MarkdownIt['use']>[0];

interface CalloutDef {
  defaultTitle: string;
  icon: string;
}

const callouts: Record<string, CalloutDef> = {
  why: { defaultTitle: 'Why', icon: '&#x2753;' },
  caution: { defaultTitle: 'Caution', icon: '&#x26A0;&#xFE0F;' },
  definition: { defaultTitle: 'Definition', icon: '&#x1F4D8;' },
};

let equationCounter = 0;

export function resetEquationCounter(): void {
  equationCounter = 0;
}

export function registerBlocks(md: MarkdownIt): void {
  for (const [name, def] of Object.entries(callouts)) {
    md.use(container, name, {
      render(tokens: { info: string; nesting: number }[], idx: number): string {
        const token = tokens[idx];
        if (token.nesting === 1) {
          const title = token.info.trim().slice(name.length).trim() || def.defaultTitle;
          return `<div class="callout callout-${name}">
<div class="callout-heading"><span class="callout-icon" aria-hidden="true">${def.icon}</span> ${title}</div>\n`;
        }
        return '</div>\n';
      },
    });
  }

  md.use(container, 'equation', {
    render(tokens: { info: string; nesting: number }[], idx: number): string {
      const token = tokens[idx];
      if (token.nesting === 1) {
        equationCounter += 1;
        const caption = token.info.trim().slice('equation'.length).trim();
        return `<figure class="eq-block" id="eq-${equationCounter}">
<figcaption><span class="eq-number">Eq. ${equationCounter}</span>${caption ? ` — ${caption}` : ''}</figcaption>\n`;
      }
      return '</figure>\n';
    },
  });

  for (const name of ['metrics', 'code-map']) {
    md.use(container, name, {
      render(tokens: { info: string; nesting: number }[], idx: number): string {
        const token = tokens[idx];
        if (token.nesting === 1) {
          const title = token.info.trim().slice(name.length).trim();
          return `<div class="block-${name}">${title ? `<div class="block-heading">${title}</div>` : ''}\n`;
        }
        return '</div>\n';
      },
    });
  }

  // ::: compare — two fenced code blocks inside render side by side
  // (thesis FORTRAN vs model MATLAB); stacks on narrow screens.
  md.use(container, 'compare', {
    render(tokens: { info: string; nesting: number }[], idx: number): string {
      const token = tokens[idx];
      if (token.nesting === 1) {
        const title = token.info.trim().slice('compare'.length).trim();
        return `<div class="block-compare">${title ? `<div class="block-heading">${title}</div>` : ''}<div class="compare-grid">\n`;
      }
      return '</div></div>\n';
    },
  });

  // ::: figure <caption> — image (or SVG) with a caption
  md.use(container, 'figure', {
    render(tokens: { info: string; nesting: number }[], idx: number): string {
      const token = tokens[idx];
      if (token.nesting === 1) {
        const caption = token.info.trim().slice('figure'.length).trim();
        return `<figure class="content-figure">
${caption ? `<figcaption>${caption}</figcaption>` : ''}\n`;
      }
      return '</figure>\n';
    },
  });
}
