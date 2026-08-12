/**
 * Minimal markdown-it math plugin: $...$ inline, $$...$$ display block,
 * rendered to static HTML at build time with katex.renderToString (the
 * browser only loads katex.css). A bad expression throws and fails the
 * build — content errors must not ship.
 */
import type MarkdownIt from 'markdown-it';
import katex from 'katex';
import { macros } from './macros';

function renderKatex(tex: string, displayMode: boolean): string {
  return katex.renderToString(tex, {
    displayMode,
    macros,
    throwOnError: true,
    strict: 'warn',
  });
}

export function mathPlugin(md: MarkdownIt): void {
  // inline: $...$ — soft line breaks inside are allowed (prose is
  // hard-wrapped), and the scan is bounded to one paragraph by design.
  md.inline.ruler.after('escape', 'math_inline', (state, silent) => {
    const src = state.src;
    const start = state.pos;
    if (src[start] !== '$' || src[start + 1] === '$') return false;
    let end = start + 1;
    while (end < src.length && (src[end] !== '$' || src[end - 1] === '\\')) {
      end += 1;
    }
    if (end >= src.length || end === start + 1) return false;
    const content = src.slice(start + 1, end);
    if (/^\s/.test(content) || /\s$/.test(content)) return false;
    if (!silent) {
      const token = state.push('math_inline', 'span', 0);
      token.content = content;
    }
    state.pos = end + 1;
    return true;
  });

  // block: a line starting with $$, until a line ending with $$
  md.block.ruler.after('fence', 'math_block', (state, startLine, endLine, silent) => {
    const first = state.src
      .slice(state.bMarks[startLine] + state.tShift[startLine], state.eMarks[startLine])
      .trim();
    if (!first.startsWith('$$')) return false;
    if (silent) return true;

    let content: string;
    let nextLine = startLine + 1;
    if (first.length > 4 && first.endsWith('$$')) {
      content = first.slice(2, -2);
    } else {
      const lines: string[] = [first.slice(2)];
      let closed = false;
      for (; nextLine <= endLine; nextLine += 1) {
        const line = state.src
          .slice(state.bMarks[nextLine] + state.tShift[nextLine], state.eMarks[nextLine])
          .trim();
        if (line.endsWith('$$')) {
          lines.push(line.slice(0, -2));
          closed = true;
          nextLine += 1;
          break;
        }
        lines.push(line);
      }
      if (!closed) return false;
      content = lines.join('\n');
    }

    const token = state.push('math_block', 'div', 0);
    token.content = content.trim();
    token.map = [startLine, nextLine];
    state.line = nextLine;
    return true;
  });

  md.renderer.rules.math_inline = (tokens, idx) => renderKatex(tokens[idx].content, false);
  md.renderer.rules.math_block = (tokens, idx) =>
    `<div class="math-block">${renderKatex(tokens[idx].content, true)}</div>\n`;
}
