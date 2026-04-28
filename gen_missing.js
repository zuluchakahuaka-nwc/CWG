const fs = require('fs');

const u = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/units_union.json', 'utf8'));
const c = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/units_confederate.json', 'utf8'));
const cmd = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/commanders.json', 'utf8'));
const sit = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/situations.json', 'utf8'));

const base = 'https://image.pollinations.ai/prompt/';

function getExisting(dir) {
    const full = 'D:/Projects/CWG/assets/sprites/cards/' + dir;
    try { return new Set(fs.readdirSync(full)); } catch(e) { return new Set(); }
}

function hasImage(dir, id) {
    const ext = getExisting(dir);
    return ext.has(id + '.jpg') || ext.has(id + '.png');
}

const style = '19th century engraving, Harpers Weekly illustration, cross-hatching, sepia, historical print, vintage woodcut';
const cmdStyle = "19th century steel engraving style, Harper's Weekly illustration, detailed cross-hatching, fine linework, sepia tones, historical print, vintage woodcut engraving";

const cmds = [];

function addUnit(card, dir, seed) {
    const tint = card.side === 'union'
        ? 'blue color tinting, blue dominant'
        : 'red color tinting, red dominant';
    const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const desc = ((card.description_en || '').substring(0, 80)).replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const prompt = `${style}, ${name}, ${desc}, ${tint}, card game illustration`;
    const url = `${base}${encodeURIComponent(prompt)}?width=512&height=768&nologo=true&seed=${seed}`;
    const out = `D:\\Projects\\CWG\\assets\\sprites\\cards\\${dir}\\${card.id}.jpg`;
    cmds.push(`echo [${cmds.length / 3 + 1}] ${card.id}`);
    cmds.push(`curl.exe -s -o "${out}" "${url}" --max-time 180`);
    cmds.push('timeout /t 12 /nobreak >nul');
}

function addCommander(card, seed) {
    const tint = card.side === 'union'
        ? 'sepia tones with subtle blue tinting, blue dominant'
        : 'sepia tones with subtle red tinting, red dominant';
    const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const rank = (card.rank || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const desc = ((card.description_en || '').substring(0, 80)).replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const prompt = `${cmdStyle}, portrait of ${name}, ${rank}, ${desc}, formal military portrait, commander in uniform, ${tint}, card game illustration`;
    const dir = card.side === 'union' ? 'units_union' : 'units_confederate';
    const url = `${base}${encodeURIComponent(prompt)}?width=512&height=768&nologo=true&seed=${seed}`;
    const out = `D:\\Projects\\CWG\\assets\\sprites\\cards\\${dir}\\${card.id}.jpg`;
    cmds.push(`echo [${cmds.length / 3 + 1}] ${card.id}`);
    cmds.push(`curl.exe -s -o "${out}" "${url}" --max-time 180`);
    cmds.push('timeout /t 12 /nobreak >nul');
}

function addSituation(card, seed) {
    const side = card.side || 'both';
    let tint = 'warm brown neutral tinting';
    if (side === 'union') tint = 'blue tint';
    if (side === 'confederate') tint = 'red tint';
    const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const desc = ((card.description_en || '').substring(0, 60)).replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const prompt = `${style}, ${name}, ${desc}, ${tint}, card game illustration, dramatic scene`;
    const url = `${base}${encodeURIComponent(prompt)}?width=512&height=768&nologo=true&seed=${seed}`;
    const out = `D:\\Projects\\CWG\\assets\\sprites\\cards\\situations\\${card.id}.jpg`;
    cmds.push(`echo [${cmds.length / 3 + 1}] ${card.id}`);
    cmds.push(`curl.exe -s -o "${out}" "${url}" --max-time 180`);
    cmds.push('timeout /t 12 /nobreak >nul');
}

let seed = 10000;

u.forEach(card => {
    const dir = 'units_union';
    if (!hasImage(dir, card.id)) {
        addUnit(card, dir, seed++);
    }
});

c.forEach(card => {
    const dir = 'units_confederate';
    if (!hasImage(dir, card.id)) {
        addUnit(card, dir, seed++);
    }
});

cmd.forEach(card => {
    const dir = card.side === 'union' ? 'units_union' : 'units_confederate';
    if (!hasImage(dir, card.id)) {
        addCommander(card, seed++);
    }
});

sit.forEach(card => {
    if (!hasImage('situations', card.id)) {
        addSituation(card, seed++);
    }
});

fs.writeFileSync('D:/Projects/CWG/gen_missing.bat', cmds.join('\r\n'));
console.log(`Generated ${cmds.length / 3} download commands to gen_missing.bat`);
