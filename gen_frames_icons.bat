@echo off
echo Generating frames and UI icons...

echo [1/4] Common frame
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\frames\frame_common.png" "https://image.pollinations.ai/prompt/19th%20century%20engraved%20ornamental%20card%20frame%20border%2C%20simple%20gray%20frame%20with%20thin%20decorative%20lines%2C%20Civil%20War%20era%20American%20design%2C%20minimal%20ornament%2C%20transparent%20center%20for%20illustration%2C%20card%20game%20frame?width=512&height=768&nologo=true&seed=5001" --max-time 180
timeout /t 15 /nobreak >nul

echo [2/4] Uncommon frame
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\frames\frame_uncommon.png" "https://image.pollinations.ai/prompt/19th%20century%20engraved%20ornamental%20card%20frame%20border%2C%20elegant%20green%20frame%20with%20leaf%20scrollwork%2C%20Civil%20War%20era%20American%20design%2C%20moderate%20decoration%2C%20transparent%20center%20for%20illustration%2C%20card%20game%20frame?width=512&height=768&nologo=true&seed=5002" --max-time 180
timeout /t 15 /nobreak >nul

echo [3/4] Rare frame
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\frames\frame_rare.png" "https://image.pollinations.ai/prompt/19th%20century%20engraved%20ornamental%20card%20frame%20border%2C%20rich%20blue%20frame%20with%20military%20motifs%20cannon%20and%20flag%2C%20Civil%20War%20era%20American%20design%2C%20elaborate%20decoration%2C%20transparent%20center%20for%20illustration%2C%20card%20game%20frame?width=512&height=768&nologo=true&seed=5003" --max-time 180
timeout /t 15 /nobreak >nul

echo [4/4] Legendary frame (already OK, skipping if >50KB)
for %%F in ("D:\Projects\CWG\assets\sprites\ui\frames\frame_legendary.png") do if %%~zF LSS 50000 (
    curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\frames\frame_legendary.png" "https://image.pollinations.ai/prompt/19th%20century%20engraved%20ornamental%20card%20frame%20border%2C%20ornate%20gold%20frame%20with%20eagle%20and%20laurel%20wreath%2C%20Civil%20War%20era%20American%20design%2C%20maximum%20decoration%2C%20transparent%20center%20for%20illustration%2C%20card%20game%20frame?width=512&height=768&nologo=true&seed=5004" --max-time 180
)

echo.
echo Now generating UI icons (256x256)...

echo [1/8] Manpower icon
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\icons\icon_manpower.png" "https://image.pollinations.ai/prompt/19th%20century%20engraving%20style%20icon%2C%20Civil%20War%20soldier%20silhouette%20in%20kepi%20hat%2C%20simple%20icon%20design%2C%20white%20on%20dark%20background?width=256&height=256&nologo=true&seed=5101" --max-time 180
timeout /t 15 /nobreak >nul

echo [2/8] Money icon
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\icons\icon_money.png" "https://image.pollinations.ai/prompt/19th%20century%20engraving%20style%20icon%2C%20Civil%20War%20era%20gold%20coins%20and%20treasury%20notes%2C%20simple%20icon%20design%2C%20white%20on%20dark%20background?width=256&height=256&nologo=true&seed=5102" --max-time 180
timeout /t 15 /nobreak >nul

echo [3/8] Supply icon
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\icons\icon_supply.png" "https://image.pollinations.ai/prompt/19th%20century%20engraving%20style%20icon%2C%20Civil%20War%20supply%20wagon%20and%20crates%2C%20simple%20icon%20design%2C%20white%20on%20dark%20background?width=256&height=256&nologo=true&seed=5103" --max-time 180
timeout /t 15 /nobreak >nul

echo [4/8] Morale icon
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\icons\icon_morale.png" "https://image.pollinations.ai/prompt/19th%20century%20engraving%20style%20icon%2C%20Civil%20War%20regimental%20flag%20with%20eagle%2C%20simple%20icon%20design%2C%20white%20on%20dark%20background?width=256&height=256&nologo=true&seed=5104" --max-time 180
timeout /t 15 /nobreak >nul

echo [5/8] Infantry icon
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\icons\icon_infantry.png" "https://image.pollinations.ai/prompt/19th%20century%20engraving%20style%20icon%2C%20Civil%20War%20infantryman%20with%20rifle%20and%20bayonet%2C%20simple%20icon%20design%2C%20white%20on%20dark%20background?width=256&height=256&nologo=true&seed=5105" --max-time 180
timeout /t 15 /nobreak >nul

echo [6/8] Cavalry icon
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\icons\icon_cavalry.png" "https://image.pollinations.ai/prompt/19th%20century%20engraving%20style%20icon%2C%20Civil%20War%20cavalryman%20on%20horse%20with%20saber%2C%20simple%20icon%20design%2C%20white%20on%20dark%20background?width=256&height=256&nologo=true&seed=5106" --max-time 180
timeout /t 15 /nobreak >nul

echo [7/8] Artillery icon
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\icons\icon_artillery.png" "https://image.pollinations.ai/prompt/19th%20century%20engraving%20style%20icon%2C%20Civil%20War%20cannon%20with%20limber%2C%20simple%20icon%20design%2C%20white%20on%20dark%20background?width=256&height=256&nologo=true&seed=5107" --max-time 180
timeout /t 15 /nobreak >nul

echo [8/8] Ship icon
curl.exe -s -o "D:\Projects\CWG\assets\sprites\ui\icons\icon_ship.png" "https://image.pollinations.ai/prompt/19th%20century%20engraving%20style%20icon%2C%20Civil%20War%20ironclad%20ship%20on%20water%2C%20simple%20icon%20design%2C%20white%20on%20dark%20background?width=256&height=256&nologo=true&seed=5108" --max-time 180

echo Done!
