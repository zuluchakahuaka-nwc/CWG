<!-- README for GitHub -->

[English](#civil-war-blue--gray) | [Русский](#-описание-1) | [中文](#-说明-1)

> **This README is intended for GitHub publication.**

# Civil War: Blue & Gray

![Status](https://img.shields.io/badge/status-83%25%20complete-orange)
![Engine](https://img.shields.io/badge/engine-Godot%204.x-478CBF)
![Language](https://img.shields.io/badge/language-GDScript-478CBF)
![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Android-lightgrey)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

**Гражданская война: Синие и Серые** — a turn-based card strategy game set during the American Civil War (1861–1865). Command Union or Confederate forces through historically accurate battles with over 146 unique unit cards, 24 commanders, and 67+ situational event cards.

---

## Features

- **146+ historically accurate unit cards** — Union and Confederate infantry, cavalry, artillery, navy, and special forces
- **24 commanders** — Each with unique abilities that shape your strategy
- **67+ situation cards** — Historical events like Pickett's Charge, Monitor vs Virginia, Emancipation Proclamation, and more
- **Morale system** — Ranges from -20 to +20; affects combat outcomes and unit behavior
- **Territory map** — 38 distinct regions to capture and hold across the war theater
- **AI opponent** — Single-player against a strategic AI
- **Phonograph music player** — Period-appropriate soundtrack
- **Full localization** — Russian and English
- **Data-driven design** — All cards, maps, and events stored in JSON files for easy modding

## Tech Stack

| Layer | Technology |
|---|---|
| Engine | Godot 4.x |
| Language | GDScript |
| Data Format | JSON |
| Art | 2D digital / card art |
| Resolution | 1920×1080 (PC), adaptive (Android) |

## Installation

### Prerequisites

- [Godot 4.x](https://godotengine.org/) editor

### Build from Source

```bash
git clone https://github.com/your-org/civil-war-blue-gray.git
cd civil-war-blue-gray

# Open the project in Godot 4.x editor
# File -> Open Project -> select the project folder
```

### Export

1. Open the project in Godot 4.x
2. Go to **Project → Export**
3. Select your target platform (Windows Desktop, Linux/X11, macOS, Android)
4. Configure export templates if not already installed
5. Click **Export Project**

## Project Structure

```
├── scenes/
│   ├── main_menu/           # Main menu and navigation
│   ├── battle/              # Battle screen and card play
│   ├── map/                 # Territory map view
│   └── phonograph/          # Music player
├── scripts/
│   ├── card_system/         # Card logic, deck management
│   ├── combat/              # Combat resolution engine
│   ├── ai/                  # AI opponent logic
│   ├── morale/              # Morale system
│   └── commanders/          # Commander abilities
├── data/
│   ├── units/               # Unit card definitions (JSON)
│   ├── commanders/          # Commander data (JSON)
│   ├── situations/          # Situation card data (JSON)
│   └── map/                 # Territory and region data (JSON)
├── assets/
│   ├── cards/               # Card artwork
│   ├── maps/                # Map graphics
│   ├── music/               # Soundtrack files
│   └── ui/                  # UI elements
├── localization/
│   ├── en.json              # English strings
│   └── ru.json              # Russian strings
└── project.godot            # Godot project configuration
```

## Game Mechanics

### Units
Each unit card represents a historical regiment, battery, or vessel with stats for attack, defense, and special capabilities. Units are organized by branch: infantry, cavalry, artillery, navy, and elite/special forces.

### Commanders
24 historical commanders from both sides, each granting unique bonuses and tactical options. Commander selection shapes your entire approach to the campaign.

### Situation Cards
Event cards drawn during play trigger historical events — some beneficial, some devastating. From daring cavalry raids to political turning points, these cards ensure no two games play out the same way.

### Morale
A persistent morale score (-20 to +20) influenced by victories, defeats, events, and commander actions. Low morale weakens units; high morale grants combat bonuses.

### Territory Map
38 regions spanning the Eastern and Western theaters. Capture and hold territory to win the war. Each region provides strategic resources and advantages.

## Platforms

| Platform | Status |
|---|---|
| Windows | Supported |
| Linux | Supported |
| macOS | Supported |
| Android | Adaptive layout, in progress |

## Current Status

The game is approximately **83% complete**. Core mechanics are functional. Remaining work includes additional art assets, AI refinement, balance tuning, and Android optimization.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🇷🇺 Описание

**Civil War: Blue & Gray (Гражданская война: Синие и Серые)** — пошаговая карточная стратегическая игра, действие которой происходит в период Гражданской войны в США (1861–1865). Командуйте войсками Союза или Конфедерации в исторически достоверных сражениях с более чем 146 уникальными карточками юнитов, 24 командующими и 67+ ситуационными картами.

### Возможности

- **146+ исторически достоверных карточек юнитов** — пехота, кавалерия, артиллерия, флот и спецподразделения Союза и Конфедерации
- **24 командующих** — Каждый обладает уникальными способностями, формирующими вашу стратегию
- **67+ ситуационных карт** — Исторические события: Чардж Пикетта, Монитор против Вирджинии, Прокламация об освобождении и другие
- **Система морали** — Диапазон от -20 до +20; влияет на исход боёв и поведение юнитов
- **Карта территорий** — 38 отдельных регионов для захвата и удержания
- **AI-противник** — Одиночная игра против стратегического ИИ
- **Патефон** — Музыкальный проигрыватель с атмосферным саундтреком
- **Полная локализация** — Русский и английский языки
- **Данные на основе JSON** — Все карты, карты и события хранятся в JSON для удобного моддинга

### Технологический стек

| Слой | Технология |
|---|---|
| Движок | Godot 4.x |
| Язык | GDScript |
| Формат данных | JSON |
| Графика | 2D цифровой арт / карточные иллюстрации |
| Разрешение | 1920×1080 (ПК), адаптивное (Android) |

### Установка

```bash
git clone https://github.com/your-org/civil-war-blue-gray.git
cd civil-war-blue-gray
# Откройте проект в редакторе Godot 4.x
```

### Структура проекта

```
├── scenes/          # Сцены: меню, бой, карта, патефон
├── scripts/         # Скрипты: карты, бой, ИИ, мораль, командующие
├── data/            # JSON-данные: юниты, командующие, ситуации, карта
├── assets/          # Ресурсы: иллюстрации карт, графика карты, музыка, UI
├── localization/    # Локализация: en.json, ru.json
└── project.godot    # Конфигурация проекта Godot
```

### Текущий статус

Игра завершена примерно на **83%**. Основные механики работают. Оставшаяся работа включает дополнительные графические ресурсы, доработку ИИ, балансировку и оптимизацию для Android.

---

## 🇨🇳 说明

**Civil War: Blue & Gray（南北战争：蓝与灰）** — 以美国南北战争（1861–1865）为背景的回合制卡牌策略游戏。指挥联邦军或邦联军，在历史性战役中运用146+张独特单位卡牌、24位指挥官和67+张情境事件卡。

### 游戏特色

- **146+张历史还原单位卡牌** — 联邦和邦联的步兵、骑兵、炮兵、海军和特种部队
- **24位指挥官** — 每位拥有塑造策略走向的独特能力
- **67+张情境卡牌** — 历史事件如皮克特冲锋、莫尼特号对阵弗吉尼亚号、解放奴隶宣言等
- **士气系统** — 范围从-20到+20，影响战斗结果和单位行为
- **领土地图** — 38个可攻占和防守的独特区域
- **AI对手** — 单人对战策略AI
- **留声机播放器** — 时代风格的配乐
- **完整本地化** — 俄语和英语
- **数据驱动设计** — 所有卡牌、地图和事件以JSON格式存储，便于模组修改

### 技术栈

| 层级 | 技术 |
|---|---|
| 引擎 | Godot 4.x |
| 语言 | GDScript |
| 数据格式 | JSON |
| 美术 | 2D数字/卡牌艺术 |
| 分辨率 | 1920×1080（PC），自适应（Android） |

### 安装

```bash
git clone https://github.com/your-org/civil-war-blue-gray.git
cd civil-war-blue-gray
# 在Godot 4.x编辑器中打开项目
```

### 项目结构

```
├── scenes/          # 场景：菜单、战斗、地图、留声机
├── scripts/         # 脚本：卡牌、战斗、AI、士气、指挥官
├── data/            # JSON数据：单位、指挥官、情境、地图
├── assets/          # 资源：卡牌插画、地图图形、音乐、UI
├── localization/    # 本地化：en.json, ru.json
└── project.godot    # Godot项目配置
```

### 当前状态

游戏已完成约**83%**。核心机制可正常运行。剩余工作包括额外美术资源、AI优化、平衡调整和Android适配。
