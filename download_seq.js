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
        
        https.get(url, { timeout: 90000 }, (res) => {
            if (res.statusCode === 429) {
                file.close();
                try { fs.unlinkSync(outPath); } catch(e) {}
                console.log(`RATE LIMITED ${item.id} - will retry`);
                resolve(false);
                return;
            }
            if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
                file.close();
                const mod = res.headers.location.startsWith('https') ? https : require('http');
                mod.get(res.headers.location, { timeout: 90000 }, (res2) => {
                    res2.pipe(file);
                    file.on('finish', () => {
                        file.close();
                        const size = fs.statSync(outPath).size;
                        if (size < 1000) { fs.unlinkSync(outPath); resolve(false); return; }
                        console.log(`OK [${done+1}/${items.length}] ${item.id} (${(size/1024).toFixed(0)}KB)`);
                        resolve(true);
                    });
                });
                return;
            }
            if (res.statusCode !== 200) {
                file.close();
                try { fs.unlinkSync(outPath); } catch(e) {}
                console.log(`FAIL ${item.id} HTTP ${res.statusCode}`);
                resolve(false);
                return;
            }
            res.pipe(file);
            file.on('finish', () => {
                file.close();
                const size = fs.statSync(outPath).size;
                if (size < 1000) { fs.unlinkSync(outPath); console.log(`FAIL ${item.id} too small`); resolve(false); return; }
                console.log(`OK [${done+1}/${items.length}] ${item.id} (${(size/1024).toFixed(0)}KB)`);
                resolve(true);
            });
        }).on('error', (e) => {
            file.close();
            try { fs.unlinkSync(outPath); } catch(ex) {}
            console.log(`ERR ${item.id}: ${e.message}`);
            resolve(false);
        });
    });
}

async function run() {
    console.log(`Downloading ${items.length} images sequentially with 3s delay...`);
    for (let i = 0; i < items.length; i++) {
        const ok = await download(items[i]);
        if (ok) done++; else failed++;
        if (i < items.length - 1) await sleep(3000);
    }
    console.log(`\nDone! ${done} ok, ${failed} failed out of ${items.length}`);
}

run();
