const fs = require('fs');
const https = require('https');

const items = JSON.parse(fs.readFileSync('D:/Projects/CWG/missing_items.json', 'utf8'));
let done = 0;

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function download(item) {
    return new Promise((resolve) => {
        const url = `https://image.pollinations.ai/prompt/${encodeURIComponent(item.prompt)}?width=512&height=768&nologo=true&seed=${item.seed}`;
        const outPath = `D:/Projects/CWG/assets/sprites/cards/${item.dir}/${item.id}.jpg`;
        const file = fs.createWriteStream(outPath);
        
        https.get(url, { timeout: 120000 }, (res) => {
            if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
                file.close();
                const mod = res.headers.location.startsWith('https') ? https : require('http');
                mod.get(res.headers.location, { timeout: 120000 }, (res2) => {
                    res2.pipe(file);
                    file.on('finish', () => {
                        file.close();
                        const size = fs.statSync(outPath).size;
                        if (size < 1000) { try { fs.unlinkSync(outPath); } catch(e) {} resolve(false); return; }
                        console.log(`OK ${item.id} (${(size/1024).toFixed(0)}KB)`);
                        resolve(true);
                    });
                }).on('error', () => { try { fs.unlinkSync(outPath); } catch(e) {} resolve(false); });
                return;
            }
            if (res.statusCode !== 200) {
                file.close();
                try { fs.unlinkSync(outPath); } catch(e) {}
                resolve(false);
                return;
            }
            res.pipe(file);
            file.on('finish', () => {
                file.close();
                const size = fs.statSync(outPath).size;
                if (size < 1000) { try { fs.unlinkSync(outPath); } catch(e) {} resolve(false); return; }
                console.log(`OK ${item.id} (${(size/1024).toFixed(0)}KB)`);
                resolve(true);
            });
        }).on('error', () => {
            try { fs.unlinkSync(outPath); } catch(e) {}
            resolve(false);
        });
    });
}

async function run() {
    console.log(`Quick download ${items.length} images...`);
    for (const item of items) {
        await download(item);
        await sleep(1500);
    }
    console.log('Batch done');
}

run();
