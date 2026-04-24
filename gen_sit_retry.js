const fs = require('fs');
const sit = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/situations.json', 'utf8'));
const base = 'https://image.pollinations.ai/prompt/';
const style = '19th century steel engraving style, Harper\'s Weekly illustration, detailed cross-hatching, fine linework, sepia tones, historical print, vintage woodcut engraving';

const lines = [];
sit.forEach((card, i) => {
    const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const desc = ((card.description_en || '').substring(0, 100)).replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    let tint = 'sepia tones, warm brown tinting';
    if (card.side === 'union') tint = 'sepia tones with subtle blue color tinting, blue color dominant';
    else if (card.side === 'confederate') tint = 'sepia tones with subtle red color tinting, red color dominant';
    const prompt = `${style}, ${name}, ${desc}, dramatic historical scene, ${tint}, card game illustration`;
    const url = `${base}${encodeURIComponent(prompt)}?width=512&height=768&nologo=true&seed=${4000 + i}`;
    const out = `D:\\Projects\\CWG\\assets\\sprites\\cards\\situations\\${card.id}.png`;
    lines.push(`echo [${i + 1}/${sit.length}] ${card.id}`);
    lines.push(`curl.exe -s -o "${out}" "${url}" --max-time 180`);
    lines.push('timeout /t 15 /nobreak >nul');
});

fs.writeFileSync('D:/Projects/CWG/gen_situations_retry.bat', lines.join('\r\n'));
console.log(`Generated ${lines.length / 3} situation download commands`);
