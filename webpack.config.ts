import * as path from 'path';
import HtmlWebpackPlugin from 'html-webpack-plugin';
import MiniCssExtractPlugin from 'mini-css-extract-plugin';
import type { Configuration } from 'webpack';
import 'webpack-dev-server';
import { assertSourcesExist, getPages } from './ui/pipeline/manifest';
import { renderPage } from './ui/pipeline/render';
import { ContentWatchPlugin } from './ui/pipeline/watch-content-plugin';

export default (_env: unknown, argv: { mode?: string }): Configuration => {
  const prod = argv.mode === 'production';
  assertSourcesExist();
  const pages = getPages();

  return {
    mode: prod ? 'production' : 'development',
    entry: { runtime: './ui/runtime/index.ts' },
    output: {
      path: path.resolve(__dirname, 'dist'),
      filename: prod ? '[name].[contenthash].js' : '[name].js',
      publicPath: 'auto',
      clean: true,
    },
    resolve: { extensions: ['.ts', '.js'] },
    module: {
      rules: [
        {
          test: /\.ts$/,
          loader: 'ts-loader',
          options: { transpileOnly: true },
          exclude: /node_modules/,
        },
        {
          test: /\.scss$/,
          use: [
            MiniCssExtractPlugin.loader,
            'css-loader',
            {
              loader: 'sass-loader',
              options: {
                sassOptions: {
                  quietDeps: true,
                  // Bootstrap 5.3 still uses @import internally; silence the
                  // dart-sass deprecation until Bootstrap 6 moves to @use.
                  silenceDeprecations: ['import'],
                },
              },
            },
          ],
        },
        {
          test: /\.css$/,
          use: [MiniCssExtractPlugin.loader, 'css-loader'],
        },
        {
          test: /\.(woff2?|ttf|eot)$/,
          type: 'asset/resource',
          generator: { filename: 'assets/fonts/[name][ext]' },
        },
        {
          test: /\.(png|jpe?g|svg|gif)$/,
          type: 'asset/resource',
          generator: { filename: 'assets/img/[name][ext]' },
        },
      ],
    },
    plugins: [
      new MiniCssExtractPlugin({ filename: prod ? '[name].[contenthash].css' : '[name].css' }),
      ...pages.map(
        (page) =>
          new HtmlWebpackPlugin({
            filename: page.out,
            templateContent: () => renderPage(page),
            chunks: ['runtime'],
            cache: false,
            minify: false,
          }),
      ),
      new ContentWatchPlugin(path.resolve(__dirname, 'ui', 'content')),
    ],
    devServer: {
      port: 8080,
      open: false,
      hot: false,
      liveReload: true,
    },
    devtool: prod ? false : 'source-map',
    stats: 'minimal',
    // The single shared stylesheet is Bootstrap + KaTeX + Prism; its size
    // is inherent to a static doc site and cached after the first page.
    performance: { hints: false },
  };
};
