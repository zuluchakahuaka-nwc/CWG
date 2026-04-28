const fs = require('fs');

const u = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/units_union.json', 'utf8'));
const c = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/units_confederate.json', 'utf8'));
const cmd = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/commanders.json', 'utf8'));
const sit = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/situations.json', 'utf8'));

const base = 'https://image.pollinations.ai/prompt/';
const style = '19th century engraving, Harpers Weekly illustration, cross-hatching, sepia, historical print, vintage woodcut';
const cmdStyle = "19th century steel engraving style, Harper's Weekly illustration, detailed cross-hatching, fine linework, sepia tones, historical print, vintage woodcut engraving";

function getExisting(dir) {
    const full = 'D:/Projects/CWG/assets/sprites/cards/' + dir;
    try { return new Set(fs.readdirSync(full)); } catch(e) { return new Set(); }
}

function hasImage(dir, id) {
    const ext = getExisting(dir);
    return ext.has(id + '.jpg') || ext.has(id + '.png');
}

const items = [];

u.forEach(card => {
    if (!hasImage('units_union', card.id)) {
        const tint = 'blue color tinting, blue dominant';
        const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
        const desc = ((card.description_en || '').substring(0, 80)).replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
        items.push({ id: card.id, dir: 'units_union', prompt: `${style}, ${name}, ${desc}, ${tint}, card game illustration`, seed: 10000 + items.length });
    }
});

c.forEach(card => {
    if (!hasImage('units_confederate', card.id)) {
        const tint = 'red color tinting, red dominant';
        const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
        const desc = ((card.description_en || '').substring(0, 80)).replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
        items.push({ id: card.id, dir: 'units_confederate', prompt: `${style}, ${name}, ${desc}, ${tint}, card game illustration`, seed: 20000 + items.length });
    }
});

cmd.forEach(card => {
    const dir = card.side === 'union' ? 'units_union' : 'units_confederate';
    if (!hasImage(dir, card.id)) {
        const tint = card.side === 'union' ? 'sepia with blue tinting, blue dominant' : 'sepia with red tinting, red dominant';
        const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
        const rank = (card.rank || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
        items.push({ id: card.id, dir, prompt: `${cmdStyle}, portrait of ${name}, ${rank}, formal military portrait, commander in uniform, ${tint}, card game illustration`, seed: 30000 + items.length });
    }
});

sit.forEach(card => {
    if (!hasImage('situations', card.id)) {
        const side = card.side || 'both';
        let tint = 'warm brown neutral tinting';
        if (side === 'union') tint = 'blue tint';
        if (side === 'confederate') tint = 'red tint';
        const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
        const desc = ((card.description_en || '').substring(0, 60)).replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
        items.push({ id: card.id, dir: 'situations', prompt: `${style}, ${name}, ${desc}, ${tint}, card game illustration, dramatic scene`, seed: 40000 + items.length });
    }
});

fs.writeFileSync('D:/Projects/CWG/missing_items.json', JSON.stringify(items, null, 2));
console.log(`Total missing: ${items.length}`);
