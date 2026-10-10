# De-Slop — killing the "AI look"

Load this whenever the brief is **a real photograph**: portrait, reportage, product-in-hand, UGC, casting shot, anything that must pass as an unretouched capture. Also load it when the user complains that a result "looks AI", "too glossy", "not like the reference".

Do NOT load it for illustration, 3D, poster graphics, stylized art — there the polish is the point.

*De-slop* is the name of this whole discipline: casting, capture, located imperfection, grading. The booster-word hygiene inside it is the same rule GPT Image 2.5 already carries as §Anti-Slop in [gpt-image.md](gpt-image.md) — that file owns the model syntax, this one owns the discipline.

The premise: both model families carry a strong prior toward an idealized image. Left alone they beautify — skin loses pores, faces gain symmetry, clothes lose creases, backgrounds gain saturation. Anything in the reference that differs from that ideal is quietly discarded unless you escalate it.

## 1. The default prior — where beautification starts

Check every axis before writing. If the brief or reference differs from the middle column, the deviation must be escalated (§2).

| Axis | What the model reaches for | What a real reference usually has |
|---|---|---|
| Eyes | large, round, wide-open, symmetric | narrow, hooded, monolid, one eye smaller |
| Face | V-line jaw, doll proportions, mirror symmetry | long or flat midface, visible asymmetry |
| Skin | poreless, glowing, even tone | pores, peach fuzz, redness zones, uneven tone |
| Body | idealized silhouette | flat, square, heavy, or simply ordinary |
| Clothing | tighter, newer, more skin | the exact coverage and wear of the reference |
| Hair | volumized, glossy, every strand placed | flatter, clumped, flyaways, dull ends |
| Stance | model pose, chin up | the awkward real stance from the reference |
| Casting | idol / influencer look | an ordinary person |
| Background | saturated, tidy, gradient | muted, cluttered, one named hex |
| Extras | adds earrings, props, signage, text | explicitly absent |

Counter-steer toward the reference, not toward plainness. If the subject genuinely is glamorous, describe that faithfully — only the capture rules in §4-§6 still apply.

## 2. Escalate every deviation in two places

A deviation stated once, in passing, loses to the prior. State it twice:

1. **In the descriptive slot**, geometrically and measurably — "narrow eyes with a low single lid crease, iris about 60% covered", not "unusual eyes".
2. **In `Constraints`** (GPT Image 2.5 fifth slot, see [gpt-image.md](gpt-image.md)) — one imperative line per axis, labeled: `EYES:`, `SKIN:`, `BODY:`, `HAIR:`, `MEDIUM:`.

This is the one place where naming the unwanted version is legitimate — the `Constraints` slot exists for "what must NOT change or appear". Everywhere else keep the positive framing from [golden-rules.md](golden-rules.md) §2.

Nano Banana has no constraints slot: fold the same lines into one short closing sentence of the prose prompt.

## 3. Boosters banned from positive slots

These words push the prior harder, they do not add fidelity: `4K`, `8K`, `ultra-detailed`, `hyper-detailed`, `ultra-realistic`, `photorealistic render`, `masterpiece`, `best quality`, `sharp focus`, `crisp`, `intricate detail`, `flawless`, `stunning`, `perfect`.

On GPT Image 2.5 they actively degrade the result ([gpt-image.md](gpt-image.md) §Anti-Slop). On Nano Banana they are mostly inert, but they crowd out the facts that would have worked.

## 4. A capture pipeline instead of adjectives

Do not ask for "realistic". Name the device and the path the file took — that is what carries the texture.

| Medium | What to state | Residue to ask for |
|---|---|---|
| Video frame grab | grabbed from handheld footage, not a photo | soft detail, mild compression blocking, slight motion smear |
| Film scan | 35mm colour negative, lab scan | visible grain, halation around highlights, soft blacks |
| Phone photo | phone camera, auto HDR off | smeared shadow noise, faint edge halo, slightly flat tone |
| Mirrorless / DSLR still | natural light, no flash, no retouch | fine sensor noise, natural falloff, unpolished skin |

State the medium as a fact of the image, never as a render style: "a real phone photo", not "photorealistic render in phone style".

## 5. Imperfections, and where they sit

An imperfection without a location gets ignored or sprayed everywhere. Name the place:

- skin — "pores across the nose and cheeks, redness at the nostril wings, one mole below the left jaw"
- hair — "two flyaways above the crown, ends clumped on the right shoulder"
- fabric — "creases at the elbow bend, collar sitting slightly askew on the left"
- environment — "scuffed baseboard behind the subject, uneven paint on the wall"
- optics — "one blown highlight on the forehead, slight motion blur on the near hand"

Calibrate to the reference, but never set the count to zero. See the micro-detail checklist in [prompt-framework.md](prompt-framework.md) §Cinematic Verbose for the same discipline applied to hero shots.

## 6. Sharpness and grading

- Ask for no added sharpening and low micro-contrast. Never write "sharp focus" or "crisp" (see §3).
- Grading: flat or natural, muted-to-moderate saturation, low contrast — unless the reference clearly shows otherwise.
- Ban the glow family in `Constraints`: HDR, bloom, high clarity, luminous or radiant skin, glossy hair highlights, perfectly even background.
- On GPT Image 2.5 stay at `quality: medium` for this kind of work. The table in [gpt-image.md](gpt-image.md) §Quality Settings sends portraits to `high` — that entry optimizes identity fidelity, which here fights the brief: `high` sharpens micro-texture until it reads as retouching. Step up to `high` only when matching a supplied face outranks the unretouched look, then re-run this section's checks on the result.

## 7. Self-check before sending

- Every axis in §1 that deviates appears both in a descriptive slot and in `Constraints`.
- No booster word from §3 survives in any positive slot.
- A capture pipeline from §4 is named, and the medium is stated as fact, not as style.
- At least three located imperfections from §5, each with a place.
- Sharpness and grading clauses present (§6).
- Anything the model likes to add but the brief does not contain — glasses, earrings, a second person, signage, captions — is listed as absent.
- Nothing in `Constraints` contradicts a positive slot (asking for grain while banning grain).

## 8. When the result still misses the reference

Treat every mismatch as a variable that was under-specified, not as a bad roll. Split the offending description into finer sub-facts, add or sharpen its `Constraints` line, and re-run the same prompt — one change per iteration, per [golden-rules.md](golden-rules.md) §3. Re-rolling an unchanged prompt returns the prior.

---

*Author: Serge Shima ([t.me/aimastersme](https://t.me/aimastersme) · [sergeshima.com](https://sergeshima.com) · [aimasters.me](https://aimasters.me)) · License: CC BY 4.0 — attribution required · Source: [smixs/visual-skills](https://github.com/smixs/visual-skills)*
