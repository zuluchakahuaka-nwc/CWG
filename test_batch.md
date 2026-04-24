# test_batch.md — Тестовая партия графики (3 карты + фон карты)

> Копируй промпт целиком в генератор. Результат → в указанную папку.
> Размер: 512x768 для карт, 1920x1080 для фона карты.

---

## КАРТА 1: 20-й Мэнский (Союз, легендарная, пехота)

**Файл:** `assets/sprites/cards/units_union/u_inf_20me.png`

```
PROMPT:
19th century steel engraving style, Harper's Weekly illustration, detailed cross-hatching, fine linework, sepia tones, historical print, antique paper texture, monochrome with subtle blue tinting, American Civil War era 1861-1865, vintage woodcut engraving, 20th Maine Volunteer Infantry Regiment bayonet charge downhill at Little Round Top, Union soldiers with fixed bayonets rushing forward in desperate counterattack, rocky hillside with boulders, soldiers in blue uniforms with forage caps, afternoon light at Gettysburg, dramatic action composition, detailed faces showing determination, card game illustration, centered subject

NEGATIVE:
photograph, 3D render, anime, cartoon, modern, colorful, low quality, blurry, distorted, deformed, bad anatomy, watermark, signature, text, logo, modern clothing, realistic photo, digital art, CGI, low resolution, oversaturated, neon colors
```

---

## КАРТА 2: 1-й Вирджинский кавалерийский / Стюарт (КША, легендарная, кавалерия)

**Файл:** `assets/sprites/cards/units_confederate/c_cav_01va.png`

```
PROMPT:
19th century steel engraving style, Harper's Weekly illustration, detailed cross-hatching, fine linework, sepia tones, historical print, antique paper texture, monochrome with subtle gray tinting, American Civil War era 1861-1865, vintage woodcut engraving, 1st Virginia Cavalry Regiment dashing cavalry charge led by JEB Stuart, Confederate cavalry with plumed hats and sabers drawn, horses at full gallop, gray uniforms with yellow trim, Virginia countryside with split-rail fences, dust clouds rising, golden sunset behind, dramatic action composition, cavalry in motion, card game illustration, centered subject

NEGATIVE:
photograph, 3D render, anime, cartoon, modern, colorful, low quality, blurry, distorted, deformed, bad anatomy, watermark, signature, text, logo, modern clothing, realistic photo, digital art, CGI, low resolution, oversaturated, neon colors
```

---

## КАРТА 3: USS Monitor (Союз, легендарная, флот)

**Файл:** `assets/sprites/cards/units_union/u_ship_monitor.png`

```
PROMPT:
19th century steel engraving style, Harper's Weekly illustration, detailed cross-hatching, fine linework, sepia tones, historical print, antique paper texture, monochrome with subtle blue tinting, American Civil War era 1861-1865, vintage woodcut engraving, USS Monitor ironclad warship with rotating gun turret, revolutionary low-freeboard iron hull design, two 11-inch Dahlgren guns visible in turret, calm Hampton Roads waters, maritime engraving style, ship centered in frame, detailed iron plating texture, card game illustration, centered subject

NEGATIVE:
photograph, 3D render, anime, cartoon, modern, colorful, low quality, blurry, distorted, deformed, bad anatomy, watermark, signature, text, logo, modern clothing, realistic photo, digital art, CGI, low resolution, oversaturated, neon colors
```

---

## ФОН КАРТЫ: Восточное побережье США (1920x1080)

**Файл:** `assets/sprites/map/territories/map_background.png`

```
PROMPT:
19th century engraved map of Eastern United States, Civil War era 1861-1865, Harper's Weekly atlas style, detailed engraved map showing states from Pennsylvania to Georgia, Mississippi River visible, Appalachian Mountains, Atlantic coastline, state borders clearly marked, vintage parchment paper background, sepia tones, cartographic engraving with decorative border, place names in period typography, rivers and railroads marked, historical map illustration, wide format panoramic composition, no text overlay, clean cartographic style

NEGATIVE:
photograph, modern, colorful, satellite imagery, 3D terrain, low quality, blurry, watermark, text labels covering art, modern borders, neon colors
```

---

## РАМКА ЛЕГЕНДАРНАЯ (тест рамки)

**Файл:** `assets/sprites/ui/frames/frame_legendary.png`

```
PROMPT:
card frame border only, 19th century engraved ornamental border, ornate gold decorative frame with American eagle at top and laurel wreath at bottom, Civil War era military medal design, empty transparent center, elaborate corner scrollwork, stars and stripes motifs, card game rarity frame, PNG style with no background in center, gold and cream color scheme

NEGATIVE:
photograph, modern, colorful, low quality, blurry, text, filled center, illustration inside frame, watermark
```

---

## ПРОВЕРКА ПОСЛЕ ГЕНЕРАЦИИ

После генерации каждого изображения проверь:

1. **Стиль единообразен?** — все 3 карты выглядят как из одной серии?
2. **Линии гравюры видны?** — cross-hatching должен быть чётким
3. **Сепия?** — не слишком цветные, не чёрно-белые, а тёплый коричневатый тон
4. **Центральный объект?** — чётко виден в центре, не обрезан
5. **512x768?** — верный размер, вертикальная ориентация

Если что-то не так — поправь промпт:
- Слишком цветное → добавь `monochrome with subtle sepia tinting`
- Слишком размытое → добавь `ultra detailed, sharp lines, crisp`
- Объект обрезан → добавь `full subject visible, centered, complete figure`
- Слишком современное → добавь `strictly 19th century, no modern elements`

---

## МАСШТАБИРОВАНИЕ ПОСЛЕ ТЕСТА

Если 3 карты + рамка + фон прошли проверку → копируй методику из prompts.md
для всех 237 карт. Шаблон промпта менять не нужно — только имена и описания.
