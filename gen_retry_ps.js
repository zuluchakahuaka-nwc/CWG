const fs = require('fs');

const u = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/units_union.json', 'utf8'));
const c = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/units_confederate.json', 'utf8'));
const cmd = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/commanders.json', 'utf8'));

const style = "19th century steel engraving style, Harper's Weekly illustration, detailed cross-hatching, fine linework, sepia tones, historical print, vintage woodcut engraving";

function getPrompt(card) {
    const tint = card.side === 'union'
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
const tasks = [];

all.forEach((card, i) => {
    const dir = getDir(card);
    const path = `D:\\Projects\\CWG\\assets\\sprites\\cards\\${dir}\\${card.id}.png`;
    try {
        const stat = fs.statSync(path);
        if (stat.size >= 10240) return;
    } catch (e) {}
    tasks.push({ id: card.id, prompt: getPrompt(card), path, seed: 2000 + i });
});

const psLines = [
    '$ErrorActionPreference = "Continue"',
    `$total = ${tasks.length}`,
    '$done = 0',
    '$ok = 0',
    '$fail = 0',
    ''
];

tasks.forEach((t, idx) => {
    const url = `https://image.pollinations.ai/prompt/${encodeURIComponent(t.prompt)}?width=512&height=768&nologo=true&seed=${t.seed}`;
    psLines.push(`$done++`);
    psLines.push(`Write-Host "[${idx + 1}/${tasks.length}] ${t.id}"`);
    psLines.push(`try {`);
    psLines.push(`  Invoke-WebRequest -Uri "${url}" -OutFile "${t.path}" -TimeoutSec 180 -UseBasicParsing`);
    psLines.push(`  $sz = (Get-Item "${t.path}").Length`);
    psLines.push(`  if ($sz -ge 10240) { $ok++; Write-Host "  OK ($([math]::Round($sz/1KB))KB)" }`);
    psLines.push(`  else { $fail++; Write-Host "  FAIL ($([math]::Round($sz/1KB))KB)" }`);
    psLines.push(`} catch { $fail++; Write-Host "  ERROR: $_" }`);
    psLines.push(`Start-Sleep -Seconds 12`);
    psLines.push('');
});

psLines.push(`Write-Host ""`);
psLines.push(`Write-Host "COMPLETE: $ok OK, $fail failed out of $total"`);

fs.writeFileSync('D:/Projects/CWG/gen_retry.ps1', psLines.join('\r\n'));
console.log(`Generated gen_retry.ps1 with ${tasks.length} tasks`);
