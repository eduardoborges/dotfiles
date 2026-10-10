# GPT Image 2.5 — Specific Rules

Актуальное поколение OpenAI (сентябрь 2026). Две модели, единый API и единые правила промптинга:

| Модель | Model ID | Роль |
|--------|----------|------|
| **GPT Image 2.5 Flare** | `gpt-image-2.5-flare` | Default. Малая модель, оптимизирована на скорость; качество выше GPT Image 2 при ~50% меньшей латентности |
| **GPT Image 2.5 Sunburst** | `gpt-image-2.5-sunburst` | Базовая модель, оптимизирована на качество: precision-edits, identity preservation, кампейн-креатив, продуктовая съёмка |

Выбор: рутинная генерация и высокие объёмы → Flare; сложные многошаговые edits, критичное сохранение лиц/продуктов/лейблов → Sunburst. Рабочий паттерн: черновики на Flare, финальные деливераблы прогонять на Sunburst только там, где Flare не дотянул. GPT Image 2 и старше — migration-only, в новых промптах не использовать.

## Структура промпта — 5 slots

GPT Image 2.5 сильнее всего реагирует на разделение по секциям. Для сложных запросов пиши лейблами, не сплошным текстом (офф. дока: «organize the prompt as scene, subject, details, and constraints, using labeled sections»). Формат при этом свободный — короткий промпт, параграф, JSON-подобная структура или теги работают одинаково; выбирай тот, который проще читать и обновлять.

```
Scene: location, time of day, background, environment
Subject: primary focus — who or what is central
Important Details: materials, textures, lighting, camera angle, mood, composition
Use Case: editorial, product mockup, UI, poster, infographic
Constraints: what must NOT change/appear (no watermarks, preserve face, no extra text)
```

> «The fifth slot is where most mediocre prompts fail silently.» Без явных constraints модель дрейфует.

### Минимальный пример

```
Scene: small Lisbon florist storefront at blue hour, wet cobblestones
Subject: woman in navy apron locking the front door, half-turned to camera
Important Details: warm interior glow spilling onto pavement, 50mm feel,
  soft contact shadows, brushed brass door handle, "Florista" hand-painted sign
Use Case: editorial photography
Constraints: no extra signage, no people in background, no text other than the sign
```

## Anti-Slop Rules

GPT Image 2.5 особенно чувствителен к качеству формулировок. Vague praise = деградация результата.

| ❌ Не пиши | ✅ Пиши |
|-----------|---------|
| stunning, incredible, epic, gorgeous, masterpiece | overcast daylight, brushed aluminum, chipped paint, 50mm feel |
| «minimalist brutalist luxury photoreal» (стиль-теги) | «cream background, heavy black sans-serif, asymmetrical type block, one hero object, generous negative space» |
| «как в Apple-рекламе» | конкретные визуальные факты |
| мудовый язык, в котором тонут функциональные требования | прямое заявление: «image must contain a transit kiosk» |

## Quality Settings — пятиступенчатая шкала

`quality`: `low` · `medium` · `high` · `xhigh` · `max` (+ `auto`). Это **новая шкала**, не переименование трёх старых уровней GPT Image 2 — не переноси настройки один-в-один.

| Setting | Когда |
|---------|-------|
| `low` | High-volume, превью, exploratory, latency-sensitive, draft |
| `medium` | **Default starting point** |
| `high` | Маленький/плотный текст, infographics, портреты, identity-sensitive edits, brand assets |
| `xhigh` | Тонкие текстуры, насыщенные детальные сцены, print-ready ассеты |
| `max` | Максимальная fidelity модели — только если `xhigh` не закрыл конкретное требование |

Методика офф. доки: стартуй с `medium`; не хватает — шаг вверх; хватает — проверь шаг вниз ради latency. `xhigh`/`max` только когда они закрывают конкретное невыполненное требование в рамках latency-бюджета. Меняй один параметр за раз: сначала quality, потом переписывание промпта.

## Размеры

- Max edge: ≤3840px
- Обе стороны: кратны 16
- Aspect ratio: max 3:1 (long:short)
- Total pixels: 655 360 – 8 294 400
- `size: auto` или кастомный `WIDTHxHEIGHT`

**Ходовые (из офф. доки):**
- Portrait 1024×1536 · Landscape 1536×1024 · Square 1024×1024
- 2K: 2048×2048, 2048×1152
- 4K: 3840×2160 (landscape), 2160×3840 (portrait)

**`background`:** `auto` | `opaque` | `transparent` (для transparent — PNG или WebP, проверяй реальный alpha-канал, не «нарисованный» фон).

> Экстрим вроде 1:8 / 8:1 GPT Image 2.5 НЕ умеет (лимит 3:1) — иди в Nano Banana.

## Text in Image

- Литеральный текст в `"..."` или ALL CAPS.
- Укажи, **сколько раз** текст должен появиться («render the tagline exactly once»).
- Шрифт, размер, цвет, позиция — явно.
- Сложные слова и бренды: спеллинг по буквам.
- Защита от мусора: «**no extra text, no duplicate text, no watermarks**».
- Для нечитаемого мелкого текста: «**100 percent readable and physically believable**».
- Маленький/плотный/multi-font → `quality: high` минимум; print-ready плотная типографика → `xhigh`.

## Editing — двухколоночная логика

Endpoint: `images.edit` (OpenAI API) или `openai/gpt-image-2.5-flare/edit` · `openai/gpt-image-2.5-sunburst/edit` (fal/wavespeed-провайдеры). Для edit-heavy пайплайнов приоритет Sunburst.

```
Change: [single concrete change]
Preserve: face, identity, pose, lighting, framing, background, geometry, text, layout
Constraints: no extra objects, no redesign, no drift
```

**Правила edit:**
- **Один edit за итерацию.** Не пытайся менять всё разом.
- **Preserve list повторять каждую итерацию.** «Same style as before» несёт контекст, но при drift — restate critical constraints.
- **Surgical edits:** явно перечисли что НЕ трогать (saturation, contrast, layout, arrows, labels, camera angle).
- Input fidelity всегда high — отдельного параметра нет.
- Опционально: маска для точечных edits (см. editing with a mask в офф. доке).

### Edit-паттерны

**Virtual try-on:** «Change garments only. Preserve exact face, body shape, pose, hair, expression, background, camera angle. Match lighting/shadows so outfit looks naturally worn.»

**Object removal:** «Remove [X]. Do not change anything else.»

**Lighting/weather swap:** «Change ONLY environmental conditions: lighting direction/quality, shadows, atmosphere, precipitation. Preserve identity, geometry, camera angle, object placement.»

**Interior swap:** «Swap [furniture]. Preserve camera angle, lighting, shadows, surrounding context. Photorealistic contact shadows.»

**Translate in place:** «Translate the text in the infographic to [lang]. Do not change any other aspect of the image.» — потом проверь перевод и слова, оставшиеся на исходном языке.

**Sketch-to-render:** «Turn this drawing into a photorealistic image. Preserve the exact layout, proportions, and perspective. Choose realistic materials and lighting consistent with the sketch intent. Do not add new elements or text.»

## Multi-Image — до 16 рефов

Индексируй с **ролью**, не только номером (subject / style / clothing / background):
```
Image 1: base scene
Image 2: jacket reference (apply only the jacket fabric/cut to subject in Image 1)
Image 3: lighting reference (apply golden-hour quality from Image 3)
```

## Style Transfer

Не пиши абстрактно («minimalist», «editorial»). Назови конкретные визуальные свойства референса: палитра, edge treatment, силуэт, обработка теней, plane логика. Референсу — явную роль: «use the palette and texture from the input image».

## World Knowledge

GPT Image 2.5 умеет домысливать контекст: «Bethel, NY, August 1969» → выведет Woodstock-эстетику. Используй: дай исторический/культурный анкер, не расписывай каждую деталь — но проверяй одежду, стейджинг и окружение на историческую точность.

## Iteration Strategy

- Стартуй с **чистого** базового промпта.
- Один change за раунд. «Make lighting warmer», «remove extra tree», «restore original background».
- При drift — перечисли invariants заново.
- Для длинных промптов — labeled sections, не одна простыня.
- Character consistency в серии: создай character reference одним прогоном, дальше переиспользуй картинку как input и **повторяй defining details персонажа в каждом промпте**.

## Check the Result (чек-лист офф. доки)

- Текст точен и читаем? Лейблы и связи на диаграммах корректны?
- Identity, форма продукта, лейблы, детали референсов не уплыли?
- Edit изменил только запрошенное?
- Если нужна прозрачность — в файле реальный alpha-канал, а не закрашенный фон?

## Use-Case Templates

### Photoreal Editorial
```
Scene: [location, time, weather]
Subject: [who, action, framing]
Important Details: [lens feel, light source, surface wear, imperfections, real texture]
Use Case: editorial photograph, looks like a real photo
Constraints: no glamorization, no heavy retouching, no studio gloss
```

### Product Mockup (Clean Background)
```
Scene: plain white opaque background
Subject: [product] centered
Important Details: crisp silhouette, no halos/fringing, light contact shadow,
  preserve label legibility exactly, preserve geometry
Use Case: product mockup
Constraints: no restyling, only background removal + light polish
```

### UI Mockup
```
Scene: [device frame, e.g. iPhone 15 Pro]
Subject: [screen/app name] — describe AS IF IT EXISTS, not concept art
Important Details: layout, hierarchy, real interface elements, exact copy in quotes,
  typography behavior, spacing, state
Use Case: shipped product screenshot
Constraints: no sketch language, no placeholder text, no Lorem Ipsum
Quality: high (for small UI text)
```

### Marketing Creative with Text
```
Scene: [environment]
Subject: [hero element]
Important Details: [composition, palette, mood]
Use Case: ad creative for [audience]
Text: "EXACT HEADLINE" in [font style], [color], [position], exactly once
      "exact subhead" in [font style], [color], [position]
Constraints: no extra text, no duplicate text, no watermarks, no unrelated logos
Quality: high
```

### Infographic / Diagram
```
Title: "[TITLE]"
Content flow: [step 1] → [step 2] → [step 3]
Visual format: [layout type — flowchart, pyramid, isometric, etc.]
Use Case: educational infographic for [audience]
Constraints: readable labels at all sizes, clear hierarchy, no clutter,
  no decorative noise, ample whitespace
Quality: high
Size: 1536×1024
```

### Logo (transparent)
```
Subject: [brand] logo — [defining shapes], flat design, minimal strokes,
  no gradients unless essential, legible at small and large sizes
Use Case: reusable brand mark
Constraints: single centered logo, generous padding, clean alpha edges,
  no solid backdrop, no scenery, no checkerboard, no watermark
Background: transparent · Format: png
```

## Migration from GPT Image 2 / 1.5 / 1

- Промпты, референсы, размеры переносятся как есть — первый прогон делай без изменений и сравни.
- `quality` не мапится 1:1: шкала новая. Реши, что важнее — та же fidelity (старый `medium` ≈ новый `high`) или то же имя тира дешевле.
- `input_fidelity` (был в 1.5/1) убрать — high всегда.
- Стартовая точка: Sunburst для качества → если проходит, проверь Flare ради latency; либо сразу Flare, если GPT Image 2 уже устраивал.
- Смотри instruction following, identity/product preservation, точность текста, unwanted changes, transparency; повторяй запросы для оценки консистентности. Для editing-пайплайнов тестируй всю цепочку edits, не только шаги по отдельности.

---

*Author: Serge Shima ([t.me/aimastersme](https://t.me/aimastersme) · [sergeshima.com](https://sergeshima.com) · [aimasters.me](https://aimasters.me)) · License: CC BY 4.0 — attribution required · Source: [smixs/visual-skills](https://github.com/smixs/visual-skills)*
