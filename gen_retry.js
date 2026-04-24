const fs = require('fs');

const u = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/units_union.json', 'utf8'));
const c = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/units_confederate.json', 'utf8'));
const cmd = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/commanders.json', 'utf8'));

const base = 'https://image.pollinations.ai/prompt/';
const style = '19th century steel engraving style, Harper\'s Weekly illustration, detailed cross-hatching, fine linework, sepia tones, historical print, vintage woodcut engraving';

function getPrompt(card) {
    const side = card.side;
    const tint = side === 'union'
        ? 'sepia tones with subtle blue color tinting, blue color dominant'
        : 'sepia tones with subtle red color tinting, red color dominant';
    const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const desc = ((card.description_en || '').substring(0, 100)).replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const type = card.type || 'commander';

    let typeScene = '';
    if (type === 'infantry') typeScene = 'infantry regiment in battle, soldiers with rifles';
    else if (type === 'cavalry') typeScene = 'cavalry charge, mounted soldiers with sabers';
    else if (type === 'artillery') typeScene = 'artillery battery firing cannons, smoke and fire';
    else if (type === 'ship') typeScene = 'warship at sea, maritime engraving';
    else if (type === 'special') typeScene = 'elite soldiers in action, special operations';
    else if (type === 'commander') typeScene = 'formal military portrait, commander in uniform, dignified pose';

    return `${style}, ${name}, ${desc}, ${typeScene}, ${tint}, card game illustration, dramatic composition`;
}

function getDir(card) {
    if (card.id.startsWith('cmd_')) return 'commanders';
    return card.side === 'union' ? 'units_union' : 'units_confederate';
}

const all = [...u, ...c, ...cmd];
const failed = [];

all.forEach((card, i) => {
    const dir = getDir(card);
    const path = `D:\\Projects\\CWG\\assets\\sprites\\cards\\${dir}\\${card.id}.png`;
    try {
        const stat = fs.statSync(path);
        if (stat.size < 10240) {
            failed.push({ card, path, seed: 2000 + i });
        }
    } catch (e) {
        failed.push({ card, path, seed: 2000 + i });
    }
});

console.log(`Found ${failed.length} failed images out of ${all.length} total`);

const lines = [];
failed.forEach((item, idx) => {
    const prompt = getPrompt(item.card);
    const url = `${base}${encodeURIComponent(prompt)}?width=512&height=768&nologo=true&seed=${item.seed}`;
    lines.push(`echo [${idx + 1}/${failed.length}] ${item.card.id}`);
    lines.push(`curl.exe -s -o "${item.path}" "${url}" --max-time 180`);
    lines.push('timeout /t 15 /nobreak >nul');
});

fs.writeFileSync('D:/Projects/CWG/gen_retry.bat', lines.join('\r\n'));
console.log(`Written gen_retry.bat with ${failed.length} entries`);
