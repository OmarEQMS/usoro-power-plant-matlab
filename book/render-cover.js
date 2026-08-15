/**
 * Renders book/cover-wrap.html to dist-book/cover-wrap.pdf at the exact
 * Lulu wrap size (12.497in x 8.52in with bleed, 234-page spine). Uses puppeteer directly
 * instead of pagedjs-cli because Paged.js snaps the page box to whole CSS
 * pixels, which shaves ~0.2mm off the sheet.
 */
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');
const { PDFDocument } = require('pdf-lib');

// Lulu total document size (trim + bleed), in points.
const WIDTH_PT = 12.497 * 72; // 899.784
const HEIGHT_PT = 8.52 * 72; // 613.44

(async () => {
  const src = path.resolve(__dirname, 'cover-wrap.html');
  const out = path.resolve(__dirname, '..', 'dist-book', 'cover-wrap.pdf');

  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  await page.goto('file:///' + src.replace(/\\/g, '/'), { waitUntil: 'networkidle0' });
  await page.pdf({
    path: out,
    width: '12.502in',
    height: '8.52in',
    printBackground: true,
    margin: { top: 0, right: 0, bottom: 0, left: 0 },
    pageRanges: '1',
  });
  await browser.close();

  // Chromium rounds the page box to whole points (900 x 613), 0.16mm shy
  // of Lulu's spec; stretch the page to the exact size (<0.08% scale).
  const doc = await PDFDocument.load(fs.readFileSync(out));
  const sheet = doc.getPage(0);
  const { width, height } = sheet.getSize();
  sheet.scale(WIDTH_PT / width, HEIGHT_PT / height);
  fs.writeFileSync(out, await doc.save());
  console.log('Saved ' + out);
})();
