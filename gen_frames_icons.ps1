$ErrorActionPreference = "Continue"
$base = "https://image.pollinations.ai/prompt/"
$style = "19th century engraved ornamental card frame border, Civil War era American design, transparent center for illustration, card game frame"

$frames = @(
    @{ Name = "frame_common"; Prompt = "$style, simple gray frame with thin decorative lines, minimal ornament"; Seed = 5001 },
    @{ Name = "frame_uncommon"; Prompt = "$style, elegant green frame with leaf scrollwork, moderate decoration"; Seed = 5002 },
    @{ Name = "frame_rare"; Prompt = "$style, rich blue frame with military motifs cannon and flag, elaborate decoration"; Seed = 5003 },
    @{ Name = "frame_legendary"; Prompt = "$style, ornate gold frame with eagle and laurel wreath, maximum decoration"; Seed = 5004 }
)

$iconStyle = "19th century engraving style icon, Civil War era, simple icon design, white on dark background"
$icons = @(
    @{ Name = "icon_manpower"; Prompt = "$iconStyle, soldier silhouette in kepi hat"; Seed = 5101 },
    @{ Name = "icon_money"; Prompt = "$iconStyle, gold coins and treasury notes"; Seed = 5102 },
    @{ Name = "icon_supply"; Prompt = "$iconStyle, supply wagon and crates"; Seed = 5103 },
    @{ Name = "icon_morale"; Prompt = "$iconStyle, regimental flag with eagle"; Seed = 5104 },
    @{ Name = "icon_infantry"; Prompt = "$iconStyle, infantryman with rifle and bayonet"; Seed = 5105 },
    @{ Name = "icon_cavalry"; Prompt = "$iconStyle, cavalryman on horse with saber"; Seed = 5106 },
    @{ Name = "icon_artillery"; Prompt = "$iconStyle, cannon with limber"; Seed = 5107 },
    @{ Name = "icon_ship"; Prompt = "$iconStyle, ironclad ship on water"; Seed = 5108 }
)

$ok = 0; $fail = 0

foreach ($f in $frames) {
    $url = "$base$([System.Uri]::EscapeDataString($f.Prompt))?width=512&height=768&nologo=true&seed=$($f.Seed)"
    $out = "D:\Projects\CWG\assets\sprites\ui\frames\$($f.Name).png"
    Write-Host "[FRAME] $($f.Name)"
    try {
        Invoke-WebRequest -Uri $url -OutFile $out -TimeoutSec 180 -UseBasicParsing
        $sz = (Get-Item $out).Length
        if ($sz -ge 10240) { $ok++; Write-Host "  OK ($([math]::Round($sz/1KB))KB)" }
        else { $fail++; Write-Host "  FAIL ($([math]::Round($sz/1KB))KB)" }
    } catch { $fail++; Write-Host "  ERROR: $_" }
    Start-Sleep -Seconds 12
}

foreach ($i in $icons) {
    $url = "$base$([System.Uri]::EscapeDataString($i.Prompt))?width=256&height=256&nologo=true&seed=$($i.Seed)"
    $out = "D:\Projects\CWG\assets\sprites\ui\icons\$($i.Name).png"
    Write-Host "[ICON] $($i.Name)"
    try {
        Invoke-WebRequest -Uri $url -OutFile $out -TimeoutSec 180 -UseBasicParsing
        $sz = (Get-Item $out).Length
        if ($sz -ge 10240) { $ok++; Write-Host "  OK ($([math]::Round($sz/1KB))KB)" }
        else { $fail++; Write-Host "  FAIL ($([math]::Round($sz/1KB))KB)" }
    } catch { $fail++; Write-Host "  ERROR: $_" }
    Start-Sleep -Seconds 12
}

Write-Host "COMPLETE: $ok OK, $fail failed"
