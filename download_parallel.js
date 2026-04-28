const fs = require('fs');
const https = require('https');
const http = require('http');

const items = JSON.parse(fs.readFileSync('D:/Projects/CWG/missing_items.json', 'utf8'));
const PARALLEL = 2;
let idx = 0;
let done = 0;
let failed = 0;

function download(item) {
    return new Promise((resolve) => {
        const url = `https://image.pollinations.ai/prompt/${encodeURIComponent(item.prompt)}?width=512&height=768&nologo=true&seed=${item.seed}`;
        const outPath = `D:/Projects/CWG/assets/sprites/cards/${item.dir}/${item.id}.jpg`;
        const file = fs.createWriteStream(outPath);
        
        const request = (u) => {
            const mod = u.startsWith('https') ? https : http;
            mod.get(u, { timeout: 60000 }, (res) => {
                if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
                    file.close();
                    request(res.headers.location);
                    return;
                }
                if (res.statusCode !== 200) {
                    file.close();
                    fs.unlinkSync(outPath);
                    console.log(`FAIL ${item.id} HTTP ${res.statusCode}`);
                    resolve(false);
                    return;
                }
                res.pipe(file);
                file.on('finish', () => {
                    file.close();
                    const size = fs.statSync(outPath).size;
                    if (size < 1000) {
                        fs.unlinkSync(outPath);
                        console.log(`FAIL ${item.id} too small (${size}b)`);
                        resolve(false);
                    } else {
                        console.log(`OK [${done + 1}/${items.length}] ${item.id} (${(size/1024).toFixed(0)}KB)`);
                        resolve(true);
                    }
                });
            }).on('error', (e) => {
                file.close();
                try { fs.unlinkSync(outPath); } catch(ex) {}
                console.log(`ERR ${item.id}: ${e.message}`);
                resolve(false);
            }).on('timeout', () => {
                file.close();
                try { fs.unlinkSync(outPath); } catch(ex) {}
                console.log(`TIMEOUT ${item.id}`);
                resolve(false);
            });
        };
        request(url);
    });
}

async function run() {
    console.log(`Starting download of ${items.length} images, ${PARALLEL} parallel...`);
    
    while (idx < items.length) {
        const batch = [];
        for (let i = 0; i < PARALLEL && idx < items.length; i++) {
            batch.push(download(items[idx++]));
        }
        const results = await Promise.all(batch);
        results.forEach(r => { if (r) done++; else failed++; });
    }
    
    console.log(`\nDone! ${done} ok, ${failed} failed out of ${items.length}`);
}

run();
