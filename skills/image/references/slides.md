# Presentation Slides

Professional slide visuals for decks and pitches.

## Design Principles

### One Slide = One Idea
Не комбинируй несвязные концепции. Аудитория запоминает 65% визуального vs 10% услышанного.

### Content Limits
- Max 5 пунктов на слайде
- 15-20 слов в блоке текста
- Заголовок + список ИЛИ абзац, не оба

### Typography
```
Заголовок: 44-54 pt, bold
Подзаголовок: 28-36 pt, medium
Текст: 18-24 pt, regular (min 18 для читаемости)

Шрифты: sans-serif основной (Inter, Helvetica, Roboto)
Serif только для акцента
```

### Contrast & Color
- 3-4 цвета max (основной + 2-3 акцента)
- Один нейтральный фон (white/black/gray)
- Контраст min 4.5:1
- Избегай pure white #fff на чёрном - используй #f5f5f5

### Whitespace
- Контент должен дышать
- Асимметричные макеты (2/3 + 1/3) динамичнее центрированных
- Если тесно - разбей на два слайда

### Visual Consistency
- Один стиль: фото ИЛИ иллюстрации ИЛИ минимал графика
- Смешивание = визуальный хаос
- High-res only, каждый образ усиливает идею

### Checklist
```
☐ Один слайд = одна идея
☐ Max 5 пунктов
☐ Заголовок 44-54pt, текст 18-24pt
☐ 3-4 цвета, высокий контраст
☐ Достаточно whitespace
☐ High-res визуалы, единый стиль
```

---

## Slide Types

### Hero Title (Dark)
```
Create dramatic title slide for [CONTEXT] presentation.

Background: Gradient from [DARK hex] to #0a0a0a.
Atmospheric: subtle mist at lower edge.

Typography:
"[MAIN TITLE]" in extra bold, white, extremely large, upper third
"[SUBTITLE]" in thin, muted, 5x smaller, below

Mood: Confident, premium
Format: 16:9
```

### Data Visualization
```
Create data slide for [CONTEXT] presentation.

Background: Dark gradient [hex] to [hex].

Hero number: "[METRIC]" in bold, [ACCENT], center
Trend: [up/down arrow] in [green/red]
Supporting: 3-4 smaller metrics below

Chart: [TYPE] showing [DATA]

Mood: Analytical, impactful
Format: 16:9
```

### Comparison (Light)
```
Create comparison slide for [CONTEXT].

Background: Off-white #fafafa to #f0efed.

Split layout:
Left: "[OPTION A]" with details
Right: "[OPTION B]" with details

Emphasis: Right side accent bar #3b82f6

Mood: Clear, objective
Format: 16:9
```

### Insight/Problem
```
Create insight slide for [CONTEXT].

Background: Clean off-white.

Focal: "[KEY MESSAGE]" in bold, centered
Supporting: "[CONTEXT]" smaller, below
Emphasis bar: [ACCENT] strip with data point

Mood: Clarity, focus
Format: 16:9
```

### Process/Timeline
```
Create process slide for [CONTEXT].

Flow: [HORIZONTAL/VERTICAL]
Stages: [1]→[2]→[3]→[4]
Each: icon + "[LABEL]" + description
Connectors: arrows in [ACCENT]

Format: 16:9
```

## Typography

**Hierarchy:**
- Hero: "Extremely large, dominating upper third"
- Primary: "Large, commanding"
- Secondary: "3-5x smaller than hero"
- Footer: "Minimal"

**Weight:** thin | regular | medium | bold | extra bold
**Position:** "upper third", "left aligned 10% margin", "centered"

## Color Systems

**Dark palette:**
- Near-black: #0a0a0a, #121212
- Deep tones: #0d3d2d, #1a2a3a
- Text: #ffffff, #e0e0e0

**Light palette:**
- Off-white: #fafafa, #f8f9fa
- Warm gray: #f5f5f4
- Text: #1a1a1a, #374151

**Data colors:**
- Positive: #22c55e
- Negative: #dc2626
- Highlight: #3b82f6

## Atmospheric Effects

- "Subtle gradient haze"
- "White mist at ground level"
- "Soft vignette darkening edges"
- "Noise texture for premium feel"

---

## Layout Systems

Универсальные правила вёрстки. Работают с любым визуальным стилем.

---

### Bento Grid

Модульная система из блоков разного размера.

**Core Rules:**
- Родительский контейнер с явными границами модулей
- Иерархия: важный контент → крупные блоки, второстепенный → мелкие
- Max 9 блоков (иначе перегруз)
- Единообразные gaps (16px стандарт)
- Связанный контент группируется в одном блоке

**Размеры:** широкие/плоские (hero) | узкие/высокие (списки) | квадратные (иконки)

**Сетки:**
```
3-block:           6-block:             9-block:
┌───────┬───┐     ┌───┬───┬───┐       ┌─────┬───┬───┐
│ HERO  │SEC│     │ S │ S │ S │       │HERO │MED│ S │
├───────┴───┤     ├───┴───┼───┤       ├──┬──┴───┼───┤
│  FOOTER   │     │ CHART │LST│       │S │ MED  │ S │
└───────────┘     └───────┴───┘       └──┴──────┴───┘
```

**Prompt:**
```
Layout: bento grid, [N] blocks
Hero block: [MAIN], Medium: [SECONDARY], Small: [ICONS]
Gaps: uniform spacing
```

---

### Asymmetric Grid

Динамичные композиции с визуальным балансом.

**Rules:**
- Начинай с базовой сетки, потом ломай осознанно
- Балансируй вес: крупный элемент слева = несколько мелких справа
- Rule of Thirds для естественного баланса
- Ключевые элементы выделяй размером и положением

**Применять:** креативные презентации, портфолио, fashion, стартапы
**НЕ применять:** банки, госпорталы, B2B с большими данными, пожилая аудитория

**Prompt:**
```
Layout: asymmetric composition
Left: [LARGE - 60%], Right: [2-3 SMALLER stacked]
Balance: visual weight distributed
Rule of thirds positioning
```

---

### Negative Space

Пространство как инструмент фокусировки.

**Rules:**
- Структурирует, а не создаёт пустоту ради красоты
- Управляет вниманием, фокусирует на главном
- Gestalt: элементы с пространством = отдельные, близко = связанные

**Применять:** премиальные бренды, минималистичные презентации, hero-секции
**НЕ применять:** новостные порталы, дашборды, мобильные версии

**Prompt:**
```
Layout: generous whitespace
Focal point: [ELEMENT] with breathing room
Empty space: intentional, guides eye to [CTA]
```

---

### Split Screen

Двухколоночная композиция.

**Пропорции:**
- 50/50 - равноценные элементы
- 60/40 - акцент на одной стороне
- 70/30 - явный герой + поддержка

**Prompt:**
```
Layout: split-screen [RATIO]
Left: [CONTENT], Right: [CONTENT]
Divider: [sharp / gradient / none]
```

---

### Brutalist

Сырая эстетика, огромные шрифты, яркие цвета.

**Rules:**
- Сохраняй чёткую навигацию и иерархию
- Читабельность > экспрессия
- Применяй селективно: яркие цвета ИЛИ огромные шрифты

**Применять:** портфолио художников, fashion, стартапы
**НЕ применять:** e-commerce, корпораты, образование, финтех

**Prompt:**
```
Style: brutalist design
Typography: massive, raw
Colors: high contrast, bold
Hierarchy: clear despite unconventional styling
```

---

## Futuristic / SaaS Style

Apple Keynote minimalism + glassmorphism + 3D objects.

### Visual Language
```
Style: Apple Keynote + SaaS + glassmorphism
Mood: premium, immersive, clean, breathable
Lighting: volumetric, ray-traced reflections, ambient occlusion
Base: deep void black OR pure ceramic white
Accents: aurora gradients (neon purple, electric blue, coral, cyan)
```

### Glassmorphism Cards
```
Material: frosted glass with blur
Edges: delicate white borders
Shadow: soft, diffused
Spacing: generous internal whitespace
```

### 3D Visual Anchors
```
Purpose: abstract 3D artifacts as focal points
Materials: polished metal, iridescent acrylic, transparent glass, soft silicone
Shapes: capsules, spheres, shields, Möbius strips, fluid waves
Quality: looks like expensive collectibles
```

### Composition by Type

**Cover:** huge 3D glass object center + bold title + aurora background
**Content:** bento grid + 3D icons in small cards + text in large cards  
**Data:** split-screen (text left, glowing 3D chart right)

### Charts Style
```
3D donut charts, glowing
Capsule-shaped progress bars
Floating numbers with neon glow
Style: looks like glowing neon toys
```

### Example Prompt
```
Create a futuristic SaaS slide for product presentation.

Style: Apple Keynote + glassmorphism.
Mood: premium, immersive, clean.
Background: void black with aurora gradient (purple → cyan).

Layout: bento grid, 6 blocks.
Cards: frosted glass, blur, white edges, soft shadows.
Hero block: floating iridescent sphere.
Data blocks: glowing 3D donut chart, neon metrics.

Typography: clean sans-serif, high contrast white.
Format: 16:9
```

---

## Именованные стили колоды

Готовые связки «фон + акцент + типографика + обработка изображений». Палитры выше дают цвета по отдельности, именованный стиль — собранное решение: выбрал один, применил ко всей колоде, не смешивал. Один акцент на колоду, не два.

### Тёмный кинематографичный — дефолт, когда тема не считывается

- **Фон:** глубокий графит или тёмно-синий #121212 → #0a0a0a к краям, едва заметное зерно.
- **Акцент:** электрик #3b82f6 **или** тёплое золото #d4a24a. Один из двух, не оба.
- **Второй тон:** айвори #f5f1e8 для текста.
- **Типографика:** плотный современный гротеск в заголовках, крупные номера слайдов.
- **Изображения:** кадрированный герой с градиентной маской, вписан в слайд, а не вставлен прямоугольником.
- **Для чего:** стратегия, премиальный бренд, редакционные разборы, выступления руководителей.

### Тёмный спортивный

- **Фон:** почти чёрный #0a0a0a со световым градиентом сверху, лёгкая виньетка.
- **Акцент:** красный #ef4444; данные и выноски — циан #22d3ee.
- **Типографика:** жирный узкий гротеск, допустим наклон; крупные цифры в духе номеров на форме.
- **Изображения:** контрастная съёмка движения, пересвеченный стадионный свет как свечение, портреты кадрированы плотно.
- **Для чего:** спортивные итоги, разборы матчей, киберспорт, любая тема со счётом и таблицами.

### Тёмный аналитический

- **Фон:** графит с едва читаемой картографической или координатной сеткой.
- **Акцент:** янтарь #f59e0b; маршруты, связи и подписи данных — циан #06b6d4.
- **Типографика:** спокойный редакционный гротеск плюс моноширинный для числовых подписей.
- **Изображения:** карты во весь слайд под тёмной заливкой, спутниковые снимки, линии связей.
- **Для чего:** аналитика новостей, логистика и цепочки поставок, разборы рынков, брифинги.

### Тёмный редакционный

- **Фон:** почти чёрный, плоский, без градиентов.
- **Акцент:** тёплое золото #d4a24a **или** коралл #f87171 — один.
- **Типографика:** антиква в заголовках, тихий гротеск в тексте. Ощущение длинного журнального материала.
- **Изображения:** один герой на слайд, красиво кадрирован, минимум наложений — фотография работает сама.
- **Для чего:** журналистика, документальные темы, сторителлинг бренда.

### Тёмный люкс

- **Фон:** чистый чёрный, идеально плоский.
- **Акцент:** сусальное золото #c9a961, буквально в нескольких местах.
- **Второй тон:** приглушённый айвори #f5f1e8.
- **Типографика:** контрастная антиква в заголовках, широкий трекинг, чистый гротеск в тексте.
- **Изображения:** минимум. Ч/Б или дуотон, один объект на слайд.
- **Для чего:** люкс, часы и ювелирка, приватный банкинг, инвестиционные истории.

### Светлый минимальный

- **Фон:** тёплый белый #fafaf8, много воздуха.
- **Акцент:** ровно один цвет под бренд или тему; только заголовки, разделители и одно выделение на слайд.
- **Второй тон:** серый #9ca3af для второстепенного текста.
- **Типографика:** антиква **или** геометрический гротеск — выбери одно направление и держи его. Крупный кегль, свободный интерлиньяж.
- **Изображения:** чистое кадрированное фото без наложений, с пропорциональными полями.
- **Для чего:** B2B и SaaS, дизайн-ориентированные бренды, доклады, конференц-кейноуты.

### Светлый коммерческий

- **Фон:** белый или плашки фирменного цвета во весь слайд.
- **Акцент:** насыщенный брендовый цвет (кобальт, алый, электрическая зелень) под сам продукт.
- **Типографика:** жирный гротеск, тяжёлые начертания, продуктовая подача.
- **Изображения:** продукт крупно, высокий ключ, чистые тени, цветные плашки за объектом; графики — прямо в брендовом цвете.
- **Для чего:** запуски потребительских товаров, ретейл, массовые кампании, питчи агентств.

### Стеклянный SaaS

Отдельного описания не требует — это раздел **Futuristic / SaaS Style** выше: аврора-градиенты, frosted-glass карточки, 3D-якоря. Стиль выбирают под AI, tech и креативные агентства.

### Как выбрать

- Спорт, новости, геополитика → тёмный спортивный или тёмный аналитический.
- Стратегия, бренд, документалистика → тёмный кинематографичный, редакционный или люкс.
- AI, SaaS, креативное агентство → стеклянный SaaS.
- B2B, экспертиза, дизайн-бренд → светлый минимальный.
- Потребительские товары и ретейл → светлый коммерческий.
- Тема не считывается → тёмный кинематографичный.

Выбранный стиль проговаривай пользователю до генерации — дешевле переспросить, чем перегенерировать колоду.

> **Гипотеза, не проверенный факт:** есть наблюдение, что GPT Image в тёмных стилях уводит слайды в недосвет. Если это подтвердится на твоей задаче — явно проси высокий контраст и проработанные света в главном объекте. По нашим источникам поведение не замерялось.

---

## Сборка колоды из шести слайдов

Когда нужен не один слайд, а обзорный борд (шесть тайлов 16:9 одной картинкой — паттерны в [multi-panel.md](multi-panel.md)), лэйауты подбираются не по вкусу, а под нарративную дугу.

- **Открывай и закрывай осознанно.** Первый слайд — Hero Title, последний — финальный: одна строка вывода, по желанию призыв и подпись. Финальный повторяет язык первого, но тише: та же палитра и типографика, спокойнее композиция. Не пересказывай на нём содержание колоды.
- **Не ставь два одинаковых типа подряд** и не бери один тип больше одного раза на шесть слайдов. Две одинаковые раскладки рядом читаются как ошибка вёрстки.
- **Чередуй плотность.** Текстовый слайд — следом визуально доминирующий. Четыре текстовых подряд убивают борд.
- **Тема с цифрами** → обязателен хотя бы один слайд, где герой — число или график (Data Visualization выше).
- **Тема про человека** → портретный слайд: портрет примерно на половину площади, рядом имя, роль и два-три факта мелким кеглем.
- **Тема спорная или сравнительная** → Comparison. Три сущности вместо двух — это уже не сравнение, а набор карточек.
- **Тема хронологическая** → Process/Timeline, 3-5 узлов. Восемь узлов на слайде не читаются.
- **Сильный тезис или голос клиента** → слайд-цитата: крупная строка, атрибуция под ней, тихий фон.
- **Акцент применяется одинаково** на всех шести: решил, что акцентом красятся заголовки и одна цифра — так на каждом слайде. Разное применение акцента разваливает колоду сильнее, чем разные лэйауты.

---

*Author: Serge Shima ([t.me/aimastersme](https://t.me/aimastersme) · [sergeshima.com](https://sergeshima.com) · [aimasters.me](https://aimasters.me)) · License: CC BY 4.0 — attribution required · Source: [smixs/visual-skills](https://github.com/smixs/visual-skills)*
