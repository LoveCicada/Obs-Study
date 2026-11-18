const fs = require('fs');
const path = require('path');
const dir = 'e:/code/obs/obs-AI/docs-analysis';
const dataDir = path.join(dir, 'qa-data');
const marker = '/*__QA_DATA__*/';

const parts = [1,2,3,4,5].map(i => fs.readFileSync(path.join(dataDir, `qa-part${i}.js`), 'utf8').trim()).join('\n');
const tpl = fs.readFileSync(path.join(dataDir, 'template.html'), 'utf8');
if (!tpl.includes(marker)) throw new Error('marker not found');

const html = tpl.replace(marker, parts);
const out = path.join(dir, 'obs-500-qa.html');
fs.writeFileSync(out, html, 'utf8');

const qCount = (html.match(/\{"q":/g) || []).length;
const scripts = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)].map(m => m[1]);
scripts.forEach((s, i) => { new Function(s); });
console.log('OUTPUT=' + out);
console.log('BYTES=' + Buffer.byteLength(html, 'utf8'));
console.log('QA_COUNT=' + qCount);
console.log('INLINE_SCRIPTS_PARSED=' + scripts.length);
