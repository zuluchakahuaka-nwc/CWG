const fs = require('fs');

const sit = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/situations.json', 'utf8'));
const base = 'https://image.pollinations.ai/prompt/';
const style = '19th century engraving, Harpers Weekly, cross-hatching, sepia, historical print, vintage woodcut';

const cmds = [];
sit.forEach((card, i) => {
    const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, '');
    const desc = ((card.description_en || '').substring(0, 60)).replace(/[^a-zA-Z0-9 ]/g, '');
    const side = card.side || 'both';
    let tint = 'warm+brown+neutral+tinting';
    if (side === 'union') tint = 'blue+tint';
    if (side === 'confederate') tint = 'red+tint';
    const prompt = `${style}, ${name}, ${desc}, ${tint}, card game illustration, dramatic scene`;
    const url = `${base}${encodeURIComponent(prompt)}?width=512&height=768&nologo=true&seed=${5000 + i}`;
    const out = `D:\\Projects\\CWG\\assets\\sprites\\cards\\situations\\${card.id}.png`;
    cmds.push(`curl.exe -s -o "${out}" "${url}" --max-time 120`);
});

fs.writeFileSync('D:/Projects/CWG/gen_situations.bat', cmds.join('\r\n'));
console.log('Generated ' + cmds.length + ' situation card commands');
