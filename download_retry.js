const fs = require('fs');
const https = require('https');

const items = JSON.parse(fs.readFileSync('D:/Projects/CWG/missing_items.json', 'utf8'));
let done = 0;
let failed = 0;

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function download(item) {
    return new Promise((resolve) => {
        const url = `https://image.pollinations.ai/prompt/${encodeURIComponent(item.prompt)}?width=512&height=768&nologo=true&seed=${item.seed}`;
        const outPath = `D:/Projects/CWG/assets/sprites/cards/${item.dir}/${item.id}.jpg`;
        const file = fs.createWriteStream(outPath);
        
        https.get(url, { timeout: 120000 }, (res) => {
            if (res.statusCode === 429) {
                file.close();
                try { fs.unlinkSync(outPath); } catch(e) {}
                resolve(429);
                return;
            }
            if (res.statusCode >= 500) {
                file.close();
                try { fs.unlinkSync(outPath); } catch(e) {}
                resolve(res.statusCode);
                return;
            }
            if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
                file.close();
                const mod = res.headers.location.startsWith('https') ? https : require('http');
                mod.get(res.headers.location, { timeout: 120000 }, (res2) => {
                    res2.pipe(file);
                    file.on('finish', () => {
                        file.close();
                        const size = fs.statSync(outPath).size;
                        if (size < 1000) { fs.unlinkSync(outPath); resolve(0); return; }
                        console.log(`OK [${done+1}/${items.length}] ${item.id} (${(size/1024).toFixed(0)}KB)`);
                        resolve(200);
                    });
                }).on('error', () => { try { fs.unlinkSync(outPath); } catch(e) {} resolve(0); });
                return;
            }
            if (res.statusCode !== 200) {
                file.close();
                try { fs.unlinkSync(outPath); } catch(e) {}
                resolve(res.statusCode);
                return;
            }
            res.pipe(file);
            file.on('finish', () => {
                file.close();
                const size = fs.statSync(outPath).size;
                if (size < 1000) { fs.unlinkSync(outPath); resolve(0); return; }
                console.log(`OK [${done+1}/${items.length}] ${item.id} (${(size/1024).toFixed(0)}KB)`);
                resolve(200);
            });
        }).on('error', (e) => {
            file.close();
            try { fs.unlinkSync(outPath); } catch(ex) {}
            resolve(0);
        });
    });
}

async function run() {
    console.log(`Downloading ${items.length} images...`);
    for (let i = 0; i < items.length; i++) {
        let retries = 3;
        while (retries > 0) {
            const code = await download(items[i]);
            if (code === 200) { done++; break; }
            if (code === 429) {
                retries--;
                console.log(`RATE LIMIT ${items[i].id} — waiting 15s (retry ${3-retries}/3)`);
                await sleep(15000);
            } else {
                retries--;
                console.log(`FAIL ${items[i].id} HTTP ${code} — waiting 5s`);
                await sleep(5000);
            }
        }
        if (done + failed < i + 1) { failed++; console.log(`SKIP ${items[i].id} after 3 retries`); }
        if (i < items.length - 1) await sleep(2000);
    }
    console.log(`\nDone! ${done} ok, ${failed} failed out of ${items.length}`);
}

run();
