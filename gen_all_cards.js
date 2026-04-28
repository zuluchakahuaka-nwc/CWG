const https = require("https");
const fs = require("fs");
const path = require("path");

const base = "D:/Projects/CWG/assets/sprites/cards";
const db = [
  ...JSON.parse(fs.readFileSync("data/cards/units_union.json", "utf8")),
  ...JSON.parse(fs.readFileSync("data/cards/units_confederate.json", "utf8")),
  ...JSON.parse(fs.readFileSync("data/cards/commanders.json", "utf8")),
  ...JSON.parse(fs.readFileSync("data/cards/situations.json", "utf8")),
];

function getOutPath(card) {
  const side = card.side || card.target_side || "";
  let sub = "situations/";
  if (card.type === "commander") sub = "commanders/";
  else if (side === "union") sub = "units_union/";
  else if (side === "confederate") sub = "units_confederate/";
  return path.join(base, sub, card.id + ".png");
}

function exists(p) { return fs.existsSync(p) || fs.existsSync(p.replace(".png", ".jpg")); }

const missing = db.filter(c => !exists(getOutPath(c)));
console.log(`Missing: ${missing.length} / ${db.length}`);

function buildPrompt(card) {
  const name = card.name_en || card.id;
  const side = card.side || card.target_side || "";
  const type = card.type || "";
  const desc = card.description_en || card.flavor_en || "";

  if (type === "commander") {
    return `American Civil War portrait of ${name}, ${card.rank || "officer"}, historical engraving style, sepia tones, detailed pen and ink illustration, 1860s military uniform, dignified pose, crosshatch shading`;
  }
  if (type === "situation" || type === "event" || card.id.startsWith("EVENT_") || card.id.startsWith("SIT_")) {
    return `American Civil War scene: ${name}. ${desc}. Historical engraving style, sepia tones, detailed pen and ink illustration, 1860s era, dramatic composition, crosshatch shading`;
  }
  if (type === "ship") {
    return `American Civil War ${side === "union" ? "Union" : "Confederate"} warship ${name}, ${desc}, historical engraving style, sepia tones, detailed illustration of 1860s ironclad or steamship, naval scene, crosshatch`;
  }

  const typeMap = { infantry: "infantry regiment soldiers", cavalry: "cavalry soldiers on horses", artillery: "artillery battery firing cannons", special: "elite soldiers" };
  const typeDesc = typeMap[type] || "soldiers";
  const sideName = side === "union" ? "Union (blue)" : "Confederate (gray)";
  return `American Civil War ${sideName} ${typeDesc}, ${name}, ${desc}, historical engraving style illustration, sepia tones, 1860s military scene, detailed crosshatch`;
}

function download(url, outPath) {
  return new Promise((resolve, reject) => {
    const dir = path.dirname(outPath);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    https.get(url, { headers: { "User-Agent": "CWG/1.0" } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        download(res.headers.location, outPath).then(resolve).catch(reject);
        return;
      }
      if (res.statusCode !== 200) { res.resume(); reject(new Error("HTTP " + res.statusCode)); return; }
      const f = fs.createWriteStream(outPath);
      res.pipe(f);
      f.on("finish", () => { f.close(); resolve(); });
      f.on("error", reject);
    }).on("error", reject);
  });
}

const CONCURRENT = 1;
const DELAY_MS = 4000;
let idx = 0;
let done = 0;
let failed = 0;

async function worker() {
  while (idx < missing.length) {
    const i = idx++;
    const card = missing[i];
    const outPath = getOutPath(card);
    const prompt = buildPrompt(card);
    const seed = card.id.split("").reduce((a, c) => a + c.charCodeAt(0), 0) % 10000;
    const url = `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}?width=512&height=768&nologo=true&seed=${seed}&model=flux`;

    try {
      await download(url, outPath);
      done++;
      const pct = ((done + failed) / missing.length * 100).toFixed(0);
      console.log(`[${pct}%] ${card.id}: OK (${done}/${missing.length})`);
    } catch (e) {
      failed++;
      console.log(`[FAIL] ${card.id}: ${e.message}`);
      if (String(e.message).includes("429")) {
        console.log("Rate limited, waiting 30s...");
        await new Promise(r => setTimeout(r, 30000));
      }
    }
    if (idx < missing.length) await new Promise(r => setTimeout(r, DELAY_MS));
  }
}

(async () => {
  const workers = [];
  for (let w = 0; w < CONCURRENT; w++) workers.push(worker());
  await Promise.all(workers);
  console.log(`\nDONE. Generated: ${done}, Failed: ${failed}, Total missing was: ${missing.length}`);
})();
