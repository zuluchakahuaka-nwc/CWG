const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

const CARDS_DIR = 'D:/Projects/CWG';
const REGEN = JSON.parse(fs.readFileSync(path.join(CARDS_DIR, 'regen_list.json'), 'utf8'));
const MAX_CONCURRENT = 5;
const MAX_RETRIES = 3;
const TIMEOUT_MS = 180000;

const cardData = {
  ...Object.fromEntries(JSON.parse(fs.readFileSync(path.join(CARDS_DIR, 'data/cards/units_union.json'), 'utf8')).map(c => [c.id, c])),
  ...Object.fromEntries(JSON.parse(fs.readFileSync(path.join(CARDS_DIR, 'data/cards/units_confederate.json'), 'utf8')).map(c => [c.id, c])),
  ...Object.fromEntries(JSON.parse(fs.readFileSync(path.join(CARDS_DIR, 'data/cards/commanders.json'), 'utf8')).map(c => [c.id, c])),
  ...Object.fromEntities || {},
};
const sitData = Object.fromEntries(JSON.parse(fs.readFileSync(path.join(CARDS_DIR, 'data/cards/situations.json'), 'utf8')).map(c => [c.id, c]));

function buildPrompt(entry) {
  const cd = cardData[entry.id] || sitData[entry.id];
  const name = cd ? (cd.name_en || cd.id) : entry.id;
  const side = cd ? cd.side : 'both';
  const sideColor = side === 'union' ? 'blue+color+tinting+blue+dominant' : side === 'confederate' ? 'red+color+tinting+red+dominant' : 'sepia+tone';
  const desc = cd ? (cd.description_en || '') : '';
  
  if (entry.type.includes('situation') || entry.id.startsWith('EVENT_') || entry.id.startsWith('SIT_')) {
    return `19th+century+engraving+style+cross-hatching+historical+print+vintage+woodcut+${encodeURIComponent(name)}+${encodeURIComponent(desc.slice(0, 80))}+sepia+tones+card+game+illustration`;
  }
  return `19th+century+engraving+style+Harper+Weekly+illustration+cross-hatching+linework+historical+print+vintage+woodcut+${encodeURIComponent(name)}+${encodeURIComponent(desc.slice(0, 80))}+${sideColor}+card+game+illustration`;
}

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith('https') ? https : http;
    const req = mod.get(url, { timeout: TIMEOUT_MS }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return download(res.headers.location, dest).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        res.resume();
        return reject(new Error('HTTP ' + res.statusCode));
      }
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => {
        const buf = Buffer.concat(chunks);
        if (buf.length < 100) return reject(new Error('Too small: ' + buf.length));
        const h = buf.toString('hex', 0, 4).toUpperCase();
        if (h.startsWith('7B22')) return reject(new Error('Got JSON error'));
        fs.writeFileSync(dest, buf);
        resolve(buf.length);
      });
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Timeout')); });
  });
}

async function generateOne(entry, retry = 0) {
  const prompt = buildPrompt(entry);
  const seed = 5000 + Math.floor(Math.random() * 9000);
  const url = `https://image.pollinations.ai/prompt/${prompt}?width=512&height=768&nologo=true&seed=${seed}`;
  const dest = path.join(entry.dir, entry.id + '.jpg');
  
  try {
    const size = await download(url, dest);
    console.log(`  OK: ${entry.id} (${(size/1024).toFixed(1)}KB)`);
    return true;
  } catch (e) {
    if (fs.existsSync(dest)) fs.unlinkSync(dest);
    if (retry < MAX_RETRIES) {
      console.log(`  RETRY ${retry+1}: ${entry.id} (${e.message})`);
      await new Promise(r => setTimeout(r, 2000));
      return generateOne(entry, retry + 1);
    }
    console.log(`  FAIL: ${entry.id} (${e.message})`);
    return false;
  }
}

async function runBatch(items, label) {
  console.log(`\n--- ${label}: ${items.length} images ---`);
  let ok = 0, fail = 0;
  for (let i = 0; i < items.length; i += MAX_CONCURRENT) {
    const batch = items.slice(i, i + MAX_CONCURRENT);
    const results = await Promise.all(batch.map(item => generateOne(item)));
    ok += results.filter(r => r).length;
    fail += results.filter(r => !r).length;
    process.stdout.write(`  Progress: ${Math.min(i + MAX_CONCURRENT, items.length)}/${items.length}\n`);
  }
  console.log(`  ${label}: ${ok} ok, ${fail} failed`);
  return { ok, fail };
}

async function main() {
  const items = REGEN.filter(e => !e.id.startsWith('frame_'));
  console.log(`Regenerating ${items.length} images...`);
  
  const byType = {};
  items.forEach(i => { byType[i.type] = byType[i.type] || []; byType[i.type].push(i); });
  
  let totalOk = 0, totalFail = 0;
  for (const [type, list] of Object.entries(byType)) {
    const r = await runBatch(list, type);
    totalOk += r.ok;
    totalFail += r.fail;
  }
  
  console.log(`\n=== DONE: ${totalOk} ok, ${totalFail} failed out of ${items.length} ===`);
}

main().catch(console.error);
