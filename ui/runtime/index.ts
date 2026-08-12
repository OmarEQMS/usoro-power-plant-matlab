/**
 * Browser runtime — deliberately tiny. All content is pre-rendered; this
 * bundle only provides interactivity (navbar collapse on mobile) and the
 * shared stylesheet imports (extracted to CSS by the build).
 */
import 'katex/dist/katex.min.css';
import 'prismjs/themes/prism.css';
import '../styles/main.scss';
import 'bootstrap/js/dist/collapse';
import 'bootstrap/js/dist/scrollspy';
import 'bootstrap/js/dist/modal';
import 'bootstrap/js/dist/tab';
