$failed = Get-ChildItem "D:\Projects\CWG\assets\sprites\cards" -Recurse -File -Filter "*.png" | Where-Object { $_.Length -lt 10000 }
$log = "D:\Projects\CWG\gen_log.txt"
$count = 0
foreach ($f in $failed) {
    $id = $f.BaseName
    $dir = $f.Directory.Name
    $side = if ($dir -eq "units_union") { "union" } else { "confederate" }
    $tint = if ($side -eq "union") { "blue+tint" } else { "red+tint" }
    $prompt = "19th+century+engraving+Harper+Weekly+cross-hatching+sepia+$id+$tint+card+art"
    $seed = Get-Random -Minimum 10000 -Maximum 99999
    $url = "https://image.pollinations.ai/prompt/$prompt?width=512&height=768&nologo=true&seed=$seed"
    
    $retries = 0
    while ($retries -lt 3) {
        curl.exe -s -o $f.FullName $url --max-time 120 2>$null
        $newSize = (Get-Item $f.FullName).Length
        if ($newSize -ge 10000) {
            $count++
            "$count $id OK $([math]::Round($newSize/1KB))KB" | Out-File $log -Append
            Write-Output "$count $id OK $([math]::Round($newSize/1KB))KB"
            break
        }
        $retries++
        Start-Sleep -Seconds 15
    }
    if ($retries -ge 3) {
        "$id FAILED after 3 retries" | Out-File $log -Append
        Write-Output "FAIL $id"
    }
    Start-Sleep -Seconds 12
}
"TOTAL OK: $count / $($failed.Count)" | Out-File $log -Append
