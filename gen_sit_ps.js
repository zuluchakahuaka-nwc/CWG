const fs = require('fs');
const sit = JSON.parse(fs.readFileSync('D:/Projects/CWG/data/cards/situations.json', 'utf8'));

const style = "19th century steel engraving style, Harper's Weekly illustration, detailed cross-hatching, fine linework, sepia tones, historical print, vintage woodcut engraving";

const tasks = [];
sit.forEach((card, i) => {
    const path = `D:\\Projects\\CWG\\assets\\sprites\\cards\\situations\\${card.id}.png`;
    try {
        const stat = fs.statSync(path);
        if (stat.size >= 10240) return;
    } catch (e) {}
    const name = (card.name_en || '').replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    const desc = ((card.description_en || '').substring(0, 100)).replace(/[^a-zA-Z0-9 ]/g, ' ').trim();
    let tint = 'sepia tones, warm brown tinting';
    if (card.side === 'union') tint = 'sepia tones with subtle blue color tinting, blue color dominant';
    else if (card.side === 'confederate') tint = 'sepia tones with subtle red color tinting, red color dominant';
    const prompt = `${style}, ${name}, ${desc}, dramatic historical scene, ${tint}, card game illustration`;
    tasks.push({ id: card.id, prompt, path, seed: 4000 + i });
});

const psLines = [
    '$ErrorActionPreference = "Continue"',
    `$total = ${tasks.length}`,
    '$done = 0; $ok = 0; $fail = 0',
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

psLines.push(`Write-Host "COMPLETE: $ok OK, $fail failed out of $total"`);
fs.writeFileSync('D:/Projects/CWG/gen_situations.ps1', psLines.join('\r\n'));
console.log(`Generated gen_situations.ps1 with ${tasks.length} tasks`);
