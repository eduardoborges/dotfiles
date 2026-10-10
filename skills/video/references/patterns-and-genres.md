# Montage patterns and genre modules

## Contents

1. Montage patterns (6 ready structures)
2. Genre modules (7 archetypes)
3. Multi-clip story structure
4. Choosing the story arc (read first when the shape of the story is not yet decided)

---

## 1. Montage patterns

These are pre-built structures that solve common scene types. Pick one, fill with your specifics.

### Pattern 1. Escalation

Use for tension builds, reveals, dramatic emphasis.

```text
wide -> medium -> close-up -> macro -> reaction close-up -> impact
```

### Pattern 2. Anxiety

Use for psychological pressure, internal conflict, impending bad news.

```text
face -> object -> hand -> face -> object closer -> sound cue -> sudden stillness
```

### Pattern 3. Discovery

Use for revealing a hidden element, exploration, search.

```text
POV -> empty space -> searching hand -> hidden object -> rack focus -> emotional reaction
```

### Pattern 4. Catastrophe

Use for comedic or dramatic disaster. Tiny object failures play bigger than explosions.

```text
anticipation -> object instability -> reaction -> object falling -> impact -> silence -> emotional collapse
```

### Pattern 5. Commercial product drama

Use for ads with a hero product.

```text
lifestyle setup -> product reveal -> macro texture -> human reaction -> use moment -> hero product shot
```

### Pattern 6. Music video loop

Use for rhythmic repetition, transformation, performance.

```text
gesture A -> cut -> gesture A from new angle -> cut -> transformation -> repeat gesture A -> release
```

---

## 2. Genre modules

Each genre has a distinct visual grammar. Match style and rhythm to the genre.

### Domestic tragedy

Ordinary objects treated with extreme seriousness. Tiny event as cosmic disaster.

- Style. Cold night interior. Mundane location. Dramatic close-ups. Slow push-ins. Macro inserts. Sudden silence.
- Tone. Tragicomic. Absurd sincerity.
- Pace. Slow build, longer reaction shots.
- Example. A man discovering his fridge is empty, played like a Greek tragedy.

### Music video

Rhythm. Repetition. Visual motif. Transformation.

- Style. Repeated gestures. Match cuts. Performance fragments. Visual loops. Color-coded sections. Aggressive lens changes.
- Tone. Emotional intensity. Sensory overload with readable structure.
- Pace. Fast, beat-driven.

### Commercial

Clarity. Product logic. Sensory detail.

- Style. Clean lighting. Intentional macro. Clear product visibility. Controlled movement. Readable final hero shot.
- Tone. Desire. Transformation. Benefit shown through action.
- Pace. Medium, building to hero shot.

### Psychological drama

Pressure. Stillness. Negative space.

- Style. Locked frames. Long close-ups. Reflections. Obstructed framing. Quiet sound design.
- Tone. Internal conflict. Hidden tension. Emotional compression.
- Pace. Slow, sustained.

### Action

Spatial clarity above all else.

- Style. Establishing geography. Clear direction of movement. Impact inserts. Wide shots between close-ups. Strong eyeline continuity.
- Tone. Urgency. Force. Readable chaos.
- Pace. Fast but geometrically clear.

### Race / speed

Authentic velocity. Faceless detail-as-emotion. Cold combative palette.

- Style. Low bumper-height. Asphalt streaking in frame. Foreground reference objects passing. Hard light on metal/rubber/sweat. Beat-locked cutting that collapses toward the launch.
- Tone. Threat, not glamour. Force transmission over shiny bodywork.
- Pace. Silence-then-bang. Held ritual, exploding launch, dense contest, one held aftermath.
- For the full grammar (schools, start-line ritual, 5 shot families, drift adaptation, anti-fake guard) load `race-and-speed.md`; for turning it into still panels load `animatic-keyframes.md`.

### Fashion

Symmetric framing. Controlled palette. Repeated silhouettes.

- Style. Slow motion micro-beats. Macro fabric detail. Confident stillness. Rim light.
- Tone. Assured. Sensual.
- Pace. Slow, intentional.

### UGC / Social

Authentic. Vertical. Quick.

- Style. Handheld. Natural light. 9:16. Vertical compositions. Direct-to-camera gestures. Quick beats.
- Tone. Immediate. Casual. Urgent relevance.
- Pace. Rapid, thumbnail-readable.

---

## 3. Multi-clip story structure

AI video generators have no memory between generations. Longer videos live in multiple clips stitched in the edit.

### Default splits

- 10s. 2 clips x 5s
- 15s. 3 clips x 5s
- 30s. 6 clips x 5s
- 45s. 9 clips x 5s
- 60s. 12 clips x 5s

Exception. Seedance multi-shot can pack 2-3 shots into a single 5-10s clip.

### What every clip must repeat

Every clip is self-contained. The model has no memory. Repeat this block in every clip.

- Character identity (face, hair, clothing, distinguishing marks)
- Clothing items, exactly named
- Location description
- Visual style (palette, grade, reference)
- Camera language (dominant grammar of the whole piece)
- Lighting logic (dominant source and direction)
- Continuity rules (what must remain constant)
- Color palette with specific colors

Yes, every single clip. Yes, even if it feels repetitive. That repetition is the only thing keeping the output consistent.

### Timecoded internal beats

Inside each 5-second prompt, use timecodes.

```text
0.0-0.8. [action / camera / light]
0.8-1.6. [action / camera / light]
1.6-2.5. [action / camera / light]
2.5-3.7. [action / camera / light]
3.7-5.0. [action / camera / light]
```

Density by genre.

- Emotional drama. 3-4 beats per 5s. Longer reactions.
- Standard narrative. 4-7 beats per 5s.
- Fast montage / music video. 6-9 beats per 5s.

Use timecoded structure for Seedance and Veo. Kling prefers flowing prose.

### Continuity across clips

When moving from clip N to clip N+1, the first beat of the new clip should match the final beat of the previous clip. Character in same pose. Same light. Same color temperature. This is what makes them cut together cleanly in the editor.

Example. Clip 1 ends on him reaching into the fridge. Clip 2 opens on his hand inside the fridge at the same height and light.

---

## 4. Choosing the story arc

The montage patterns in §1 shape *how* a sequence cuts. This section decides *what shape the story has* before any of that. Pick the arc first, then the pattern, then the beat map from `dramaturgy.md` §10.

Five arcs cover almost everything short-form asks for. Each entry names what it is for and — more usefully — what it breaks on. Forcing the wrong arc is the most common reason a spot feels busy but empty.

### Arc 1. Causal chain

- **Shape.** Ordinary state → the thing that disrupts it → consequence → consequence → resolution.
- **Use when.** There is an external goal and each beat is caused by the previous one. Quests, journeys, a task pursued to its end, partner-and-partner stories.
- **Signals in the brief.** Someone is looking for / going to / delivering / rescuing. A destination or objective is stated outright.
- **Does not fit.** A single moment with no progression. A story that lives on a reveal rather than on cause and effect. A contemplative scene with nothing being pursued.

### Arc 2. Turn without conflict (kishotenketsu)

- **Shape.** Setup → widening → an unrelated element turns the meaning → the two halves reconcile.
- **Use when.** Nothing opposes the hero and nothing needs to. The power is in a recontextualization: a discovery, a memory, an object that turns out to mean something else.
- **Signals in the brief.** "It turns out that", a found object, a photograph, a revelation about the past, two strangers who share something. No antagonist anywhere.
- **Does not fit.** Fights, competition, anything with an opponent to defeat. Goal-driven quests. Problem-then-solution advertising.
- **Note.** The turn is the Crack in `dramaturgy.md` §10 — it is not optional here either, it is simply not a conflict.

### Arc 3. One peak moment

- **Shape.** Just enough context → the peak → the residue it leaves.
- **Use when.** The piece captures a single significant instant and lets the audience supply everything around it. Vows, the winning second, the last note, a goodbye.
- **Signals in the brief.** No "and then". No obstacle. A ceremony, a culmination, a farewell.
- **Does not fit.** Any story with sequential progression, a battle with an outcome, a search, a problem being solved.
- **Note.** This is the one arc where the beat map in `dramaturgy.md` §10 collapses: Crack and Impact land on the same beat, and Aftermath carries most of the running time. Do not manufacture a fake obstacle to fill the middle.

### Arc 4. Conflict beat sheet

- **Shape.** Opening image → the thing that starts it → midpoint reversal → lowest point → climax → closing image.
- **Use when.** Two forces are in direct opposition and the outcome is in doubt. Fights, chases, survival, an obstacle that can genuinely win.
- **Signals in the brief.** Versus, against, escape, defeat, physical danger, a clock running down.
- **Does not fit.** Quiet discoveries, non-conflict narratives, a simple linear sequence with no reversal to pay off.
- **Pairs with.** §1 Pattern 1 (Escalation) and Pattern 4 (Catastrophe).

### Arc 5. Hook and open end

- **Shape.** Hook → a self-contained fragment of story → a question left standing, or a call to act.
- **Use when.** The piece is episode one, a teaser, or a campaign unit that is meant to continue. Resolution is deliberately withheld.
- **Signals in the brief.** Series, part one, teaser, "to be continued", a mystery introduced, a product reveal held back.
- **Does not fit.** A self-contained story. Anything where the client expects closure inside this one film.
- **Pairs with.** §1 Pattern 5 (Commercial product drama) when the open end is the call to action.

### Fast selection

- Someone fights, races, or escapes → **Arc 4**.
- Someone searches for or pursues a stated goal → **Arc 1**.
- Something is discovered and the meaning shifts, with no opponent → **Arc 2**.
- One ceremony or culmination, nothing before or after → **Arc 3**.
- It is episode one or the ending is withheld on purpose → **Arc 5**.

If two arcs look equally plausible, the brief is not decided yet — ask which one the client is buying before writing shots. Running two arcs at once produces a film that changes its mind in the middle.

---

*Author: Serge Shima ([t.me/aimastersme](https://t.me/aimastersme) · [sergeshima.com](https://sergeshima.com) · [aimasters.me](https://aimasters.me)) · License: CC BY 4.0 — attribution required · Source: [smixs/visual-skills](https://github.com/smixs/visual-skills)*
