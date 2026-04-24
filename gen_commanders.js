const fs = require('fs');
const cmd = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/commanders.json', 'utf8'));
const base = 'https://image.pollinations.ai/prompt/';
const style = '19th century steel engraving style, Harper\'s Weekly illustration, detailed cross-hatching, fine linework, sepia tones, historical print, vintage woodcut engraving';

const lines = [];
cmd.forEach((card, i) => {
    const tint = card.side === 'union'
        ? 'sepia tones with subtle blue color tinting, blue color dominant'
        : 'sepia tones with subtle red color tinting, red color dominant';
    const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const rank = (card.rank || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const desc = ((card.description_en || '').substring(0, 80)).replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const prompt = `${style}, portrait of ${name}, ${rank}, ${desc}, formal military portrait, commander in uniform, dignified pose, ${tint}, card game illustration`;
    const url = `${base}${encodeURIComponent(prompt)}?width=512&height=768&nologo=true&seed=${3000 + i}`;
    const dir = card.side === 'union' ? 'units_union' : 'units_confederate';
    const out = `D:\\Projects\\CWG\\assets\\sprites\\cards\\${dir}\\${card.id}.png`;
    lines.push(`echo [${i + 1}/${cmd.length}] ${card.id}`);
    lines.push(`curl.exe -s -o "${out}" "${url}" --max-time 180`);
    lines.push('timeout /t 15 /nobreak >nul');
});

fs.writeFileSync('D:/Projects/CWG/gen_commanders.bat', lines.join('\r\n'));
console.log(`Generated ${lines.length / 3} commander download commands`);
