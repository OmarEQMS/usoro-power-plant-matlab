/**
 * Site-wide abbreviation pass (see docs/ui.md, "Abbreviation policy"):
 * wraps every known abbreviation in prose with <abbr title="long name">,
 * skipping code and math (those are separate token types, never plain
 * text tokens). Also lints prose for all-caps tokens missing from the
 * glossary and records them in env.unknownAbbr for the renderer to report.
 */
import type MarkdownIt from 'markdown-it';
import { abbreviations, lintIgnore } from './abbreviations';
import { identifiers } from './identifiers';

type Token = ReturnType<MarkdownIt['parseInline']>[number];

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function escapeAttr(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');
}

const keys = Object.keys(abbreviations).sort((a, b) => b.length - a.length);
const wrapPattern = new RegExp(`(^|[^\\w-])(${keys.map(escapeRegExp).join('|')})(?![\\w-])`, 'g');
const capsPattern = /(?:^|[^\w-])([A-Z]{2,})(?![\w-])/g;

const idKeys = Object.keys(identifiers).sort((a, b) => b.length - a.length);
const idPattern = new RegExp(`(^|[^\\w])(${idKeys.map(escapeRegExp).join('|')})(?![\\w])`, 'gi');

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/** Wrap known model identifiers in already-HTML-escaped text. */
export function wrapIdentifiersInEscapedText(text: string): string {
  let out = '';
  let cursor = 0;
  idPattern.lastIndex = 0;
  for (let m = idPattern.exec(text); m; m = idPattern.exec(text)) {
    const word = m[2];
    const meaning = identifiers[word.toLowerCase()];
    if (!meaning) continue;
    const start = m.index + m[1].length;
    out += text.slice(cursor, start);
    out += `<abbr title="${escapeAttr(meaning)}">${word}</abbr>`;
    cursor = start + word.length;
  }
  return out + text.slice(cursor);
}

/** Wrap identifiers in the text nodes of an HTML fragment (Prism output),
 *  leaving tags and attributes untouched. */
export function wrapIdentifiersInHtml(html: string): string {
  return html
    .split(/(<[^>]+>)/g)
    .map((seg) => (seg.startsWith('<') ? seg : wrapIdentifiersInEscapedText(seg)))
    .join('');
}

export function abbrPlugin(md: MarkdownIt): void {
  // Inline code spans: wrap known MODEL IDENTIFIERS (kjtre, whp, cfld, …)
  // with <abbr> tooltips. Case-insensitive, so `KJTRE` (thesis style) and
  // `kjtre` (code style) both resolve. Fenced blocks are left to Prism.
  md.renderer.rules.code_inline = (tokens, idx) =>
    `<code>${wrapIdentifiersInEscapedText(escapeHtml(tokens[idx].content))}</code>`;
  md.core.ruler.push('abbr_wrap', (state) => {
    const unknown: Set<string> = state.env.unknownAbbr ?? new Set<string>();
    state.env.unknownAbbr = unknown;

    for (const blockToken of state.tokens) {
      if (blockToken.type !== 'inline' || !blockToken.children) continue;
      const rebuilt: Token[] = [];
      for (const child of blockToken.children) {
        if (child.type !== 'text') {
          rebuilt.push(child);
          continue;
        }
        const text = child.content;

        // lint: all-caps tokens not in the glossary
        capsPattern.lastIndex = 0;
        for (let m = capsPattern.exec(text); m; m = capsPattern.exec(text)) {
          const word = m[1];
          if (!(word in abbreviations) && !lintIgnore.has(word)) unknown.add(word);
        }

        // wrap known abbreviations
        wrapPattern.lastIndex = 0;
        let cursor = 0;
        let match = wrapPattern.exec(text);
        if (!match) {
          rebuilt.push(child);
          continue;
        }
        while (match) {
          const abbrStart = match.index + match[1].length;
          const word = match[2];
          if (abbrStart > cursor) {
            const t = new state.Token('text', '', 0);
            t.content = text.slice(cursor, abbrStart);
            rebuilt.push(t);
          }
          const html = new state.Token('html_inline', '', 0);
          html.content = `<abbr title="${escapeAttr(abbreviations[word])}">${word}</abbr>`;
          rebuilt.push(html);
          cursor = abbrStart + word.length;
          match = wrapPattern.exec(text);
        }
        if (cursor < text.length) {
          const t = new state.Token('text', '', 0);
          t.content = text.slice(cursor);
          rebuilt.push(t);
        }
      }
      blockToken.children = rebuilt;
    }
  });
}
