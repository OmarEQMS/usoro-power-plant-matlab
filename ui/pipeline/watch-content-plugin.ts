/**
 * Webpack does not know the markdown files are build inputs (they are
 * read inside html-webpack-plugin templateContent callbacks), so watch
 * mode would ignore edits to them. Registering the content directory as
 * a context dependency makes every .md save trigger a recompile — and
 * with it a re-render of the pages.
 */
import type { Compiler } from 'webpack';

export class ContentWatchPlugin {
  constructor(private readonly dir: string) {}

  apply(compiler: Compiler): void {
    compiler.hooks.afterCompile.tap('ContentWatchPlugin', (compilation) => {
      compilation.contextDependencies.add(this.dir);
    });
  }
}
