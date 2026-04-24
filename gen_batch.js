const fs = require('fs');

const u = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/units_union.json', 'utf8'));
const c = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/units_confederate.json', 'utf8'));
const cmd = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/commanders.json', 'utf8'));

const base = 'https://image.pollinations.ai/prompt/';
const stylePart = '19th+century+engraving+style,+Harper+Weekly+illustration,+cross-hatching,+linework,+historical+print,+vintage+woodcut';

const cmds = [];
const all = [...u, ...c, ...cmd];

all.forEach((card, i) => {
  const side = card.side;
  const tint = side === 'union' ? 'blue+color+tinting+blue+dominant' : 'red+color+tinting+red+dominant';
  const dir = side === 'union' ? 'units_union' : 'units_confederate';
  const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, '').replace(/ +/g, '+');
  const desc = ((card.description_en || '').substring(0, 80)).replace(/[^a-zA-Z0-9 ]/g, '').replace(/ +/g, '+');
  const type = card.type || 'commander';
  const url = base + encodeURIComponent(stylePart + ', ' + name + ' ' + desc + ', ' + tint + ', card game illustration').replace(/%20/g, '+') + '?width=512&height=768&nologo=true&seed=' + (2000 + i);
  const out = 'D:\\Projects\\CWG\\assets\\sprites\\cards\\' + dir + '\\' + card.id + '.png';
  cmds.push('curl.exe -s -o "' + out + '" "' + url + '" --max-time 180');
});

fs.writeFileSync('D:/Projects/CWG/gen_all.bat', cmds.join('\r\n'));
console.log('Generated ' + cmds.length + ' commands to gen_all.bat');
