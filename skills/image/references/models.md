# Model Selection — Nano Banana vs GPT Image 2.5

Skill пишет промпты под две семьи моделей. Они мыслят по-разному — выбор модели меняет структуру промпта.

## TL;DR

| Задача | Модель |
|--------|--------|
| Реальное место/объект (с грунтингом) | **Nano Banana** (NB2/NBP) |
| Сложная сцена с физикой/композицией | **Nano Banana Pro** |
| Длинные горизонтальные/вертикальные форматы (1:8, 8:1, 4:1) | **Nano Banana** (только NB поддерживает экстрим) |
| Дешёвая массовая генерация | **Nano Banana 2 Lite** или **GPT Image 2.5 Flare** (`quality: low`) |
| Фотореализм с тонкой типографикой/UI | **GPT Image 2.5** |
| Точное editing с preservation (try-on, swap, weather) | **GPT Image 2.5** (в editing у него лучшая identity-preservation) |
| Маленький плотный текст в кадре | **GPT Image 2.5** (`quality: high`) |
| Брендовая полиграфия / постеры с EXACT TEXT | **GPT Image 2.5** |
| Сториборды, комиксы (последовательность) | **Nano Banana** (extreme ratios + thinking) |
| Storyboard с фокусом на типографике | **GPT Image 2.5** |
| Style transfer без упоминаемых референс-картинок | **GPT Image 2.5** (concrete visual targets) |
| Рендер из 14+ референсов | **Nano Banana Pro** (до 14) или **GPT Image 2.5** (до 16) |

> Внутри GPT Image 2.5 две модели: **Flare** (`gpt-image-2.5-flare`) — быстрый default, качество выше GPT Image 2 при ~50% меньшей латентности; **Sunburst** (`gpt-image-2.5-sunburst`) — базовая, для precision-edits и кампейн-качества. Промпт-правила одинаковые. GPT Image 2 — migration-only.

## Когда что выигрывает

### Nano Banana выигрывает в
- **Image grounding.** NB2 ищет реальные изображения в интернете перед генерацией — точная архитектура конкретного храма, моста, площади; конкретные виды животных, растений. GPT Image 2.5 этого не делает.
- **Экстремальные пропорции.** 1:8, 8:1, 1:4, 4:1 — баннеры, скроллы, комикс-стрипы. У GPT Image 2.5 max 3:1.
- **«Thinking» режим.** Сложные инфографики со spatial logic.
- **Цена/скорость.** NB2 = $0.04/img.

### GPT Image 2.5 выигрывает в
- **Identity preservation в edit.** Меняешь одежду / погоду / фон — лицо, поза, геометрия не плывут. Двухколоночная логика (change / preserve) работает как контракт.
- **Тонкий текст в кадре.** Маленькие подписи, легенды, footnotes, multi-font layouts. На `quality: high` рендерит чётче.
- **UI-моки и продуктовые скриншоты.** Иерархия, реальные интерфейс-элементы, читаемые лейблы.
- **Структурированный 5-slot промпт.** Чёткое разделение Scene/Subject/Details/Use case/Constraints даёт предсказуемость.
- **`quality` рычаг.** low/medium/high/xhigh/max — осознанный trade-off скорости и точности (шкала новая, пятиступенчатая; medium = default).
- **4K-выход.** До 3840×2160 / 2160×3840 из коробки.

### Где обе модели одинаково хороши
- Photorealistic портреты.
- Product shots на нейтральном фоне.
- Минималистичные постеры.
- Editorial-фотография.

## Различия в синтаксисе промпта

| Аспект | Nano Banana | GPT Image 2.5 |
|--------|-------------|-------------|
| Стиль промпта | Натуральный язык, 1-2 параграфа | 5-slot с лейблами секций |
| Камера/линза | **Не указывать** числа (50mm, f/2.8) — NB игнорит | Можно «50mm feel», но как high-level look |
| «Stunning/epic/masterpiece» | Игнорит, не вредит | **Anti-slop**: вредит, делает результат хуже |
| Text in image | `"..."` в кавычках, font + position | `"..."` или ALL CAPS + «no extra words / no duplicate text» |
| Negative framing | Использовать позитив | Использовать позитив + явный preserve list |
| Сложные сцены | JSON для 5+ элементов | 5-slot template со секциями |
| Edit | «Keep X same, change Y» | «Change: X / Preserve: Y / Constraints: Z» — повторять preserve каждую итерацию |
| Множественные референсы | До 14, индексировать | До 16, индексировать с ролью («Image 1: base», «Image 2: jacket reference») |

## Стоимость (ориентир)

| Модель | Цена | Заметки |
|--------|------|---------|
| Nano Banana 2 Lite | ~$0.034/img | Только 1K, ~4 сек. Черновики и массовые батчи |
| Nano Banana 2 (Flash) | ~$0.04/img | Default для большинства задач |
| Nano Banana Pro | ~$0.15/img | Сложные сцены, до 14 рефов |
| GPT Image 2.5 (`low`) | ~$0.01/img (1K) | Latency-sensitive, превью, массовые батчи |
| GPT Image 2.5 (`medium`) | ~$0.024/img (1K) | Default для GPT Image |
| GPT Image 2.5 (`high`) | ~$0.09/img (1K) | Маленький текст, brand-sensitive, photorealism |
| GPT Image 2.5 (`xhigh`) | ~$0.16/img (1K) | Тонкие текстуры, print-ready |
| GPT Image 2.5 (`max`) | ~$0.36/img (1K) | Максимальная fidelity, только по конкретной нужде |

Цены Flare и Sunburst одинаковые (провайдерский ориентир на 1K; 2K/4K дороже). Каждый тир дешевле одноимённого тира GPT Image 2.

> Скилл сам не запускает генерацию — выдаёт промпт. Модель/quality указываем рядом с промптом как мета.

---

*Author: Serge Shima ([t.me/aimastersme](https://t.me/aimastersme) · [sergeshima.com](https://sergeshima.com) · [aimasters.me](https://aimasters.me)) · License: CC BY 4.0 — attribution required · Source: [smixs/visual-skills](https://github.com/smixs/visual-skills)*
