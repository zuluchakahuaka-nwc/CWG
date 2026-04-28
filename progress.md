# progress.md — Лог выполнения CWG

> Каждая запись = завершённый этап. Для возобновления — смотри последний пункт.

---

## [2026-04-24] Скелет проекта — ГОТОВ

### [ГОТОВО] Godot 4.x проект
- project.godot (4.2, 1920x1080, gl_compatibility, PC+Android)
- 30+ директорий, Autoload: Localization, GameManager, CardDatabase

### [ГОТОВО] Данные (JSON)

| Файл | Количество |
|------|-----------|
| units_union.json | 70 карт |
| units_confederate.json | 76 карт |
| commanders.json | 24 (12+12) |
| situations.json | 67 (13 морских + 28 сухопутных + 26 универсальных) |
| territories.json | 38 территорий |
| connections.json | 84 связи (70 land + 4 river + 10 sea) |
| battles.json | 25 сражений |
| tracks.json | 30 треков патефона (плейсхолдер) |
| translations.csv | 394 записи локализации |
| civil_war.json | Единая кампания (Апрель 1861 → Май 1865) |

### [ГОТОВО] Кампания
- Одна кампания `civil_war.json` — ВСЕГДА старт с апреля 1861 (Форт-Самтер)
- Таймлайн событий по ходам: auto_trigger + available_events
- Асимметричный баланс: Union (индустрия, флот) vs Confederate (генералы, оборона, рейды)
- Условия победы: 4 для каждой стороны
- Механика блокады: автоматически с 5-го хода
- Таймлайн гибели командующих: Джексон (ход 10), Стюарт (ход 14), Хилл (ход 45)

### [ГОТОВО] Баланс (проверен)
- Union: ATK avg 3.54, DEF avg 3.03, HP avg 4.01, COST avg 3.00 — 70 карт
- Confederate: ATK avg 3.58, DEF avg 2.67, HP avg 3.86, COST avg 2.91 — 76 карт
- Асимметрия через ресурсы: Union +money/территорию, Confederate +supply/территорию
- Confederate компенсирует меньшую DEF лучшими командующими и бонусом обороны дома

### [ГОТОВО] Скрипты (22 GDScript)
- Core: game_manager, turn_manager, morale_system, resource_manager, localization, auto_turn
- Cards: card_database, card_instance, deck, hand, card_effect
- Map: territory, map_controller, path_finder
- Combat: battle_resolver, unit_matcher, event_trigger
- AI: ai_controller, ai_strategy, auto_turn_executor
- UI: card_widget, hand_display, morale_bar, resource_panel, turn_info, phonograph_player

### [ГОТОВО] Сцены (6)
- main_menu, scenario_select, game_map, battle_screen, phonograph, settings

### [ГОТОВО] .gitignore

---

### [ГОТОВО] Графика — все 237 карт полностью
- Метод: Pollinations.ai (бесплатный, через curl.exe / Node.js)
- Цветовое кодирование: Union = синий, Confederate = красный
- units_union: 82 файла (70 юнитов + 12 командующих)
- units_confederate: 88 файлов (76 юнитов + 12 командующих)
- situations: 67 файлов (все ситуационные карты)
- Карта: перегенерена в стиле военной стратегии 1861-1865
- Рамки: frame_legendary.png сгенерена
- SVG-схема: map_schematic.svg (схема территорий)
- card_widget.gd: рисует карту через _draw():
  - Фон по стороне (синий/красный)
  - Рамка по редкости (серая/зелёная/синяя/золотая)
  - Портрет по центру
  - Статы: ATK(красный), DEF(синий), HP(зелёный), COST(жёлтый)
  - Полоска HP при ранении
  - Иконки типа
  - ⚡ для карт с linked_events

### [ГОТОВО] Иконки ресурсов и типов (8 шт)
- icon_manpower.png, icon_money.png, icon_supply.png, icon_morale.png
- icon_infantry.png, icon_cavalry.png, icon_artillery.png, icon_ship.png
- Метод: Pollinations.ai, 128x128, стиль гравюры

### [ГОТОВО] Спрайты карты
- map_background.png (170KB, фоновая карта)
- map_schematic.svg (схема территорий)
- game_map.tscn обновлён — TextureRect вместо ColorRect
- Территории рисуются программно через PanelContainer (map_controller.gd)

### [ГОТОВО] Шрифты (исторический стиль)
- PlayfairDisplay (Regular + Bold) — заголовки карт
- CrimsonText (Regular + Bold + Italic) — описания
- Cinzel (Regular + Bold) — титры
- SpectralSC (Regular) — подписи
- FontLoader autoload добавлен в project.godot
- card_widget.gd обновлён — использует FontLoader

### [ГОТОВО] Звуки SFX (12 эффектов)
- card_play.wav, card_draw.wav, battle_start.wav, battle_hit.wav
- battle_destroy.wav, march.wav, morale_up.wav, morale_down.wav
- victory.wav, defeat.wav, button_click.wav, phonograph_needle.wav

### [ГОТОВО] Музыка патефона (MP3, 18 треков)
- folk/: 8 треков (Dixieland, Bonnie Blue, Yellow Rose, Camptown, Oh Susanna, Southern Winds, Old Folks, Cumberland Gap)
- valces/: 10 треков (Home Sweet, Lorena, Aura Lea, Tenting, Just Before, All Quiet, Vacant Chair, When Johnny, Battle Hymn, Marching Georgia)
- Формат: MP3 (не OGG)

### [ГОТОВО] Тестовые скрипты (4 файла)
- test_card_database.gd — 12 тестов (загрузка JSON, поля карт, связи территорий)
- test_battle_resolver.gd — 11 тестов (бой, модификаторы, типы, захват)
- test_morale_system.gd — 18 тестов (шкала, статусы, бонусы, каскады)
- test_turn_manager.gd — 14 тестов (ходы, фазы, месяцы, ресурсы, сериализация)
- test_runner.tscn — сцена-раннер всех тестов
- Всего: 55 тестов

### [ОЖИДАЕТ] Следующие шаги
- [ ] Исправить ошибки воспроизведения музыки MP3 в игре
- [ ] Анимации UI
- [ ] Балансировка (плейтестинг)
- [ ] Экспорт PC (Windows/Linux/macOS)
- [ ] ~~Экспорт Android (.apk)~~ (отложено)
- [ ] ~~Адаптация UI под мобильные экраны~~ (отложено)
