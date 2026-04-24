# prompts.md — Система промптов для генерации графики CWG

> Все промпты на английском (генераторы лучше понимают).
> NEGATIVE PROMPT — общий для всех, внизу файла.

---

## БАЗОВЫЙ СТИЛЬ (добавлять в каждый промпт)

```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, fine linework, sepia tones, historical print,
antique paper texture, vintage woodcut engraving
```

## ЦВЕТОВОЕ КОДИРОВАНИЕ (ОБЯЗАТЕЛЬНО)

**Союз (Union / Север) = СИНИЙ оттенок:**
```
sepia tones with subtle blue color tinting, blue color dominant throughout image, UNION BLUE theme
```

**Конфедерация (Confederate / Юг) = КРАСНЫЙ оттенок:**
```
sepia tones with subtle red color tinting, red color dominant throughout image, CONFEDERATE RED theme
```

**Универсальные / Обе стороны = нейтральный сепия:**
```
sepia tones, warm brown tinting, no dominant blue or red
```

---

## 1. ПЕХОТА (портретная ориентация 512x768)

### Шаблон
```
[BASE STYLE], [SIDE] [REGIMENT NAME] infantry regiment,
[ACTION/POSE], [DISTINGUISHING FEATURE],
Civil War soldiers in [FORMATION/SCENE],
[UNIFORM DETAILS], [WEATHER/LIGHTING],
dramatic composition, card illustration
```

### Примеры

**20th Maine (legendary, bayonet charge)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
20th Maine Volunteer Infantry Regiment bayonet charge downhill,
soldiers with fixed bayonets rushing forward, desperate melee,
Union blue uniforms with Maine state badge,
Little Round Top Gettysburg, rocky hillside, dusk light,
dramatic composition, card illustration, ultra detailed linework
```

**1st Texas (rare, Hood's Brigade)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
1st Texas Infantry Regiment in fierce combat at Antietam,
soldiers fighting in cornfield, intense musket fire,
Confederate gray uniforms with Texas star,
Antietam cornfield, smoke-filled battlefield, harsh sunlight,
dramatic composition, card illustration, ultra detailed linework
```

**69th New York "Fighting 69th" (rare, Irish Brigade)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
69th New York Infantry "Fighting 69th" Irish Brigade advancing,
soldiers with green flags and shamrock badges,
Union blue uniforms with green harp insignia,
open battlefield, morning mist, flags waving,
dramatic composition, card illustration, ultra detailed linework
```

**54th Massachusetts (rare, colored troops)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
54th Massachusetts Colored Regiment storming Fort Wagner,
soldiers scaling earthworks under heavy fire,
Union blue uniforms, diverse soldiers charging,
coastal fortress, night attack, cannon fire illumination,
dramatic composition, card illustration, ultra detailed linework
```

**Generic Union Infantry (common)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Union infantry regiment in line of battle,
soldiers loading Springfield rifled muskets,
standard Union blue uniforms with forage caps,
open field, camp scene, overcast sky,
dramatic composition, card illustration, ultra detailed linework
```

**Generic Confederate Infantry (common)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Confederate infantry regiment defending earthworks,
soldiers behind breastworks firing,
butternut and gray uniforms, slouch hats,
forested defensive position, afternoon light,
dramatic composition, card illustration, ultra detailed linework
```

---

## 2. КАВАЛЕРИЯ (512x768)

### Шаблон
```
[BASE STYLE], [REGIMENT] cavalry [ACTION],
mounted soldiers with [WEAPONS], [HORSE DETAILS],
[SCENE/TERRAIN], [UNIFORM],
dynamic action composition, card illustration
```

### Примеры

**Mosby's Rangers (legendary)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
43rd Virginia Cavalry Battalion Mosby's Rangers guerrilla raid,
mounted partisan rangers ambush Union supply wagon,
gray ghost horsemen emerging from forest at night,
Confederate butternut uniforms, pistol and saber,
dark forest road, moonlight, dramatic shadows,
dynamic action composition, card illustration
```

**1st Virginia Cavalry / Stuart (legendary)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
1st Virginia Cavalry Regiment dashing cavalry charge,
JEB Stuart's cavalry with plumed hats and sabers drawn,
Confederate cavalry in full gallop,
open Virginia countryside, dust clouds, golden sunset,
dynamic action composition, card illustration
```

**Custer's Brigade (rare)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
5th Michigan Cavalry Custer's Wolverine Brigade charging,
young general with flowing hair leading cavalry,
Union cavalry with drawn sabers in full charge,
battlefield at Gettysburg, summer heat,
dynamic action composition, card illustration
```

**Generic Cavalry (common)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Civil War cavalry patrol, mounted scouts on dusty road,
soldiers with carbines and revolvers,
horses at steady canter, picket duty,
countryside road, autumn trees, quiet atmosphere,
dramatic composition, card illustration
```

---

## 3. АРТИЛЛЕРИЯ (512x768)

### Шаблон
```
[BASE STYLE], [BATTERY NAME] artillery [SCENE],
cannons firing, [GUN TYPE], smoke and fire,
artillery crew in [ACTION], [BATTLEFIELD],
dramatic composition, card illustration
```

### Примеры

**Washington Artillery (legendary)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Washington Artillery of New Orleans firing vollies,
ornate brass cannons with LA state seal,
elite crew in immaculate uniforms,
battlefield at First Manassas, smoke billowing, fire from cannons,
dramatic composition, card illustration, ultra detailed
```

**Stuart's Horse Artillery / Pelham (legendary)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Stuart's Horse Artillery John Pelham single gun holding flank,
galloping horse artillery limber, fast deployment,
Confederate artillerymen in cavalry gear,
Fredericksburg hillside, cannon fire, distant infantry,
dramatic composition, card illustration
```

**Generic Artillery (common)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Civil War artillery battery in action,
12-pounder Napoleon cannons firing, crew serving guns,
artillerymen with sponges and ramrods,
battlefield position, smoke-filled sky,
dramatic composition, card illustration
```

---

## 4. ФЛОТ / КОРАБЛИ (512x768)

### Шаблон
```
[BASE STYLE], [SHIP NAME] [SHIP TYPE],
[NAVAL SCENE], [WEATHER/WATER],
[DETAIL: ironclad/steam/sail], maritime engraving,
dramatic composition, card illustration
```

### Примеры

**USS Monitor (legendary)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
USS Monitor ironclad warship with rotating turret,
low-freeboard iron hull with circular turret,
calm Hampton Roads waters, revolutionary warship design,
maritime engraving, dramatic composition, card illustration
```

**CSS Virginia / Merrimack (legendary)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
CSS Virginia Confederate ironclad ram ship,
sloping casemate iron armor, ram bow,
Hampton Roads battle, smoke and fire, ship charging,
maritime engraving, dramatic composition, card illustration
```

**H.L. Hunley (legendary)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
H.L. Hunley Confederate submarine underwater attack,
small hand-cranked submarine approaching ship,
dark Charleston harbor waters, torch signals on shore,
maritime engraving, dramatic composition, card illustration
```

**CSS Alabama (legendary)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
CSS Alabama Confederate raider ship at sea,
sailing ship with auxiliary steam, Confederate naval ensign,
open ocean, dramatic seas, ship under full sail,
maritime engraving, dramatic composition, card illustration
```

**Generic River Ironclad (common)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
City-class river ironclad gunboat on Mississippi,
flat-bottomed armored boat with casemate guns,
western river waters, trees on banks, smokestacks,
maritime engraving, dramatic composition, card illustration
```

---

## 5. КОМАНДУЮЩИЕ (портрет 512x768)

### Шаблон
```
[BASE STYLE], portrait of [NAME], [RANK], [SIDE],
[UNIFORM DETAILS], [DISTINGUISHING FEATURE],
[SETTING], [POSE],
formal portrait, card illustration
```

### Примеры

**Robert E. Lee**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
portrait of General Robert E. Lee, Confederate commander,
gray uniform with three stars on collar, dignified bearing,
white beard and hair, noble expression,
standing in Confederate command tent with maps,
formal portrait, card illustration
```

**Ulysses S. Grant**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
portrait of General Ulysses S. Grant, Union commander,
dark blue uniform with lieutenant general stars, calm determined face,
short beard, cigar in hand, squinting eyes,
standing by field tent with battle plans,
formal portrait, card illustration
```

**Stonewall Jackson**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
portrait of General Stonewall Jackson, Confederate lieutenant general,
gray uniform with Virginia Military Institute bearing,
dark beard, intense piercing eyes, pointing forward,
on horseback at First Manassas battlefield,
formal portrait, card illustration
```

**Abraham Lincoln**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
portrait of President Abraham Lincoln, tall gaunt figure,
black suit and stovepipe hat, melancholy wise expression,
full beard, deep-set eyes, standing in White House,
formal portrait, card illustration
```

**William T. Sherman**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
portrait of General William Tecumseh Sherman, Union major general,
blue uniform, red-haired beard, fierce determined eyes,
standing before burning Atlanta, gaunt resolute face,
formal portrait, card illustration
```

**J.E.B. Stuart**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
portrait of General JEB Stuart, Confederate cavalry commander,
gray cavalry uniform with plumed hat, golden curls,
dashing smile, cavalry boots and gauntlets,
on horseback with cavalry escort behind,
formal portrait, card illustration
```

**Nathan Bedford Forrest**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
portrait of General Nathan Bedford Forrest, Confederate lieutenant general,
rough uniform without insignia, fierce intimidating stare,
mounted on horseback with drawn saber, self-made warrior,
frontier intensity, battle-scarred face,
formal portrait, card illustration
```

---

## 6. СПЕЦПОДРАЗДЕЛЕНИЯ (512x768)

**Berdan's Sharpshooters (rare)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
1st US Sharpshooters Berdan's in green uniforms,
marksman aiming Sharps rifle from prone position,
green uniform with hunting horn badge, scoped target,
open field with treeline background, stillness before shot,
dramatic composition, card illustration
```

**Wilder's Lightning Brigade (legendary)**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Wilder's Lightning Brigade mounted infantry with Spencer repeaters,
soldiers on horseback firing rapidly from saddle,
Union uniforms with mounted infantry gear,
Hoover's Gap Tennessee, rapid fire action,
dramatic composition, card illustration
```

---

## 7. СИТУАЦИОННЫЕ КАРТЫ (512x768)

**Pickett's Charge**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Pickett's Charge at Gettysburg, Confederate brigade advancing across open field,
thousands of soldiers in line of battle marching toward stone wall,
artillery shells bursting, flags, smoke covering field,
Gettysburg Pennsylvania cemetery ridge, July afternoon,
dramatic composition, card illustration
```

**Emancipation Proclamation**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Emancipation Proclamation signing scene,
President Lincoln at desk with document,
cabinet members watching solemnly,
White House interior with gas lamps, January 1863,
dramatic composition, card illustration
```

**Lincoln Assassination**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
assassination of Abraham Lincoln at Ford's Theatre,
presidential box with dramatic scene,
theatre interior with audience below, April 14 1865,
dramatic composition, card illustration
```

**Blockade / Blockade Runner**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Confederate blockade runner ship slipping past Union fleet at night,
steamship at full speed through moonlit waters,
Union warships with searchlights in background,
coastal waters, dark sea, dramatic night scene,
maritime engraving, dramatic composition, card illustration
```

**Sherman's March to the Sea**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Sherman's March to the Sea through Georgia,
Union army columns burning plantation buildings,
soldiers destroying railroad tracks and infrastructure,
Georgia countryside in flames, smoke-filled sky,
dramatic composition, card illustration
```

**Espionage / Spy**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Civil War spy reading dispatches by candlelight,
figure in dark coat with secret documents,
shadowy room with maps on wall,
candle-lit interior, mysterious atmosphere,
dramatic composition, card illustration
```

**Naval Mines / Torpedoes**
```
19th century steel engraving style, Harper's Weekly illustration,
detailed cross-hatching, sepia tones, historical print,
Civil War naval mine explosion on river,
wooden mine floating near ironclad ship,
water erupting from torpedo detonation,
western river, danger atmosphere,
maritime engraving, dramatic composition, card illustration
```

---

## 8. РАМКИ КАРТ (отдельно, 512x768, прозрачный центр)

### Common (серая)
```
card frame border design, 19th century engraved ornamental border,
simple gray frame with thin decorative lines,
Civil War era American design, minimal,
transparent center for illustration, PNG with alpha
```

### Uncommon (зелёная)
```
card frame border design, 19th century engraved ornamental border,
elegant green frame with leaf scrollwork,
Civil War era American design, moderate decoration,
transparent center for illustration, PNG with alpha
```

### Rare (синяя)
```
card frame border design, 19th century engraved ornamental border,
rich blue frame with military motifs cannon and flag,
Civil War era American design, elaborate decoration,
transparent center for illustration, PNG with alpha
```

### Legendary (золотая)
```
card frame border design, 19th century engraved ornamental border,
ornate gold frame with eagle and laurel wreath,
Civil War era American design, maximum decoration,
transparent center for illustration, PNG with alpha
```

---

## 9. UI ИКОНКИ (256x256)

**Ресурсы:**
- Manpower: `Civil War soldier silhouette icon, 19th century engraving style, simple icon`
- Money: `Civil War era gold coins and treasury icon, 19th century engraving style`
- Supply: `Civil War supply wagon and crate icon, 19th century engraving style`
- Morale: `Civil War regimental flag icon, 19th century engraving style`

**Типы юнитов:**
- Infantry: `Civil War infantryman with rifle icon, engraving style`
- Cavalry: `Civil War cavalryman on horse icon, engraving style`
- Artillery: `Civil War cannon icon, engraving style`
- Ship: `Civil War ironclad ship icon, engraving style`

---

## ОБЩИЙ NEGATIVE PROMPT (добавлять ко всем)

```
photograph, 3D render, anime, cartoon, modern, colorful,
low quality, blurry, distorted, deformed, bad anatomy,
watermark, signature, text, logo, modern clothing,
realistic photo, digital art, CGI, low resolution,
oversaturated, neon colors, gradient background
```

---

## ПЛАН ГЕНЕРАЦИИ (порядок работы)

1. **День 1:** Протестировать стиль на 5-6 картах → настроить промпт
2. **День 2:** 4 рамки (common/uncommon/rare/legendary) + UI иконки (~20)
3. **День 3-4:** Командующие (24 портрета) — самые важные
4. **День 5-6:** Пехота Union (26) + Confederate (30)
5. **День 7:** Кавалерия (28) + Артиллерия (20)
6. **День 8:** Флот Union (13) + Confederate (16)
7. **День 9:** Спецподразделения (13)
8. **День 10:** Ситуационные карты (67) — можно батчить похожие
9. **День 11:** Карта территорий (фоновая карта США)
10. **День 12:** Пост-обработка: обрезка, наложение рамок, финальная сборка

Итого: ~237 карт + 4 рамки + 20 иконок + фон карты ≈ **260 изображений**
При 150 токенов/день на Leonardo → **~2 дня генерации**
