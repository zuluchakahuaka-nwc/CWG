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

### [В ПРОЦЕССЕ] Графика — массовая генерация (170 карт)
- Метод: Pollinations.ai (бесплатный, через curl.exe)
- Цветовое кодирование: Union = синий, Confederate = красный
- Карта: перегенерена в стиле военной стратегии 1861-1865
- Рамки: frame_legendary.png сгенерена
- SVG-схема: map_schematic.svg (схема территорий)
- Скрипт генерации: gen_batch.js → gen_all.bat (170 команд)
- card_widget.gd: переписан — рисует карту через _draw():
  - Фон по стороне (синий/красный)
  - Рамка по редкости (серая/зелёная/синяя/золотая)
  - Портрет по центру
  - Статы: ATK(красный), DEF(синий), HP(зелёный), COST(жёлтый)
  - Полоска HP при ранении
  - Иконки типа (🔫🐎💣⚓🎯📜⭐)
  - ⚡ для карт с linked_events

### [ОЖИДАЕТ] Следующие шаги
- [ ] Дождаться генерации 170 карт (~2 часа)
- [ ] Генерация ситуационных карт (67 шт)
- [ ] Рамки: common/uncommon/rare (3 шт)
- [ ] Иконки ресурсов и типов (8 шт)
- [ ] Шрифты (исторический стиль)
- [ ] Звуки SFX (12 эффектов)
- [ ] Музыка (пользователь закинет)
- [ ] Тестовые скрипты
- [ ] Экспорт PC + Android
