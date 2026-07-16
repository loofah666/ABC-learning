// Tick IMAGES_CHECKLIST.md rows whose filename is present in images/.
// Untouched rows remain "[ ]", so removing a JPG later doesn't un-tick — this is
// intentional (checklist tracks intent, images/ tracks realized state).
// Usage:  node scripts/sync_checklist.js

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const imgDir = path.join(root, 'images');
const checklistPath = path.join(root, 'IMAGES_CHECKLIST.md');

const slugs = new Set(
  fs.readdirSync(imgDir)
    .filter(f => /\.jpg$/i.test(f))
    .map(f => f.replace(/\.jpg$/i, ''))
);

const md = fs.readFileSync(checklistPath, 'utf8');
let hits = 0;
const out = md.replace(/^- \[ \] `([a-z0-9_]+)\.jpg`/gm, (m, slug) => {
  if (slugs.has(slug)) { hits++; return '- [x] `' + slug + '.jpg`'; }
  return m;
});

if (out !== md) fs.writeFileSync(checklistPath, out, 'utf8');
console.log('ticked', hits, 'new entries (' + slugs.size + ' images total)');
