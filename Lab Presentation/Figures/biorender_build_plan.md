# Build plan — "What sequencing sees vs what simulation sees"

A BioRender build guide. Work top to bottom; the order is chosen to avoid rework.

---

## The idea in one sentence

**Draw the genealogy once. Show it twice — greyed out with a single node restored, then fully lit.**

Both bands are the *same population*, the same tree, the same geometry. Only the lighting changes. That is what makes the point land: sequencing doesn't show you a different, smaller thing — it shows you one node of a structure that was always there.

---

## Before you open BioRender

**Check your licence first.** BioRender has **no vector export at any tier**. Free accounts get PNG/JPEG at 72/150/300 DPI. Premium adds PDF, 600 DPI, and transparent background. Find out whether UZH has an institutional licence before you invest hours — it determines your export ceiling.

**Set the canvas before you draw anything.** Resizing later rescales elements unpredictably. For a 16:9 slide use **1920 × 1080 px**. If it might also go on a poster, build at **2400 × 1350 px** and scale down — never up.

**Palette** — matches your deck exactly:

| Role | Hex |
|---|---|
| Simulation blue | `#2a78d6` |
| Sampled / alarm orange | `#eb6834` |
| Ink (text, real-data band) | `#0b0b0b` |
| Secondary text | `#52514e` |
| Ghost grey (the invisible genealogy) | `#dedcd7` |
| Muted grey (captions) | `#8a8880` |

Font: **Arial** throughout. It matches the UZH template, and BioRender has it.

---

## Phase 1 — the skeleton (~10 min)

1. New illustration, canvas set as above.
2. Drop a horizontal **arrow** across the bottom, spanning about 70% of the width. Label the left end `past`, the right end `today`. Colour `#52514e`.
3. Add six small tick marks on the arrow, evenly spaced. These are your generation columns — everything else aligns to them. Use **Align → Distribute horizontally** rather than eyeballing.
4. Add two text boxes on the left margin:
   - `What sequencing gives you`
   - `What simulation gives you`
   Arial Bold, ~28 pt at 1920 px wide. Colour the first `#0b0b0b`, the second `#2a78d6`.
5. **Lock the arrow and the tick marks** (right-click → Lock). You'll thank yourself later.

---

## Phase 2 — build the atom (~15 min)

The whole figure is one repeated unit. Build it once, properly.

6. Search the BioRender icon library for your organism. For beech try **`tree`**, **`deciduous tree`**, **`plant`**. Pick a simple silhouette — detail disappears at this size.
7. Scale it small: about 40 px tall at 1920 px canvas. Set fill to `#2a78d6`.
8. Beside it, build a **genome strip**: draw one small rounded rectangle (~8 × 18 px), duplicate it 13 times, distribute horizontally with a 3 px gap. Colour them all `#cfcdc7`, then recolour four at random to `#eb6834` — those are the variants.
9. **Group the tree and its strip** (Ctrl/Cmd+G). This is your atom. Name the group `individual` in the layers panel.

> If the tree icon plus a genome strip feels too busy at this size, drop the strip from the repeated individuals and use it only once, blown up, next to the sampled individual in Band A. That is the version I'd try first — see step 17.

---

## Phase 3 — build Band B first (~35 min)

**Build the simulation band first, even though it appears second in the figure.** You will copy it upward to make Band A. Doing it the other way round doubles the work.

10. Place five copies of the atom in a vertical column at the first tick mark. Select all five → **Align left**, **Distribute vertically**.
11. **Group that column.** Name it `generation`.
12. Duplicate the group five times, one per tick mark. Select all six → **Distribute horizontally**. You now have a 6 × 5 lattice.
13. Draw the inheritance lines. From each individual in one column, draw **two thin lines** to two individuals in the next column. Weight 1 px, colour `#2a78d6`, opacity **30%**.
    - Don't be systematic about which pairs — a slightly irregular web reads as a real pedigree. A tidy grid reads as a diagram of nothing.
    - Draw the lines on their own layer, then **send to back** so they sit behind the individuals.
14. Add the right-hand label, Arial Bold ~22 pt, colour `#2a78d6`:
    ```
    every individual,
    every generation,
    the whole genealogy
    ```
15. **Select the entire band — lattice, lines, label — and group it.** Name it `BAND B`.

---

## Phase 4 — make Band A from Band B (~15 min)

This is the trick that makes the figure work.

16. Duplicate the `BAND B` group. Move the copy up into the top band. Rename it `BAND A`.
17. With the copy selected, restyle it as invisible history:
    - Set every individual to `#dedcd7`.
    - Set the lines to `#dedcd7`, **dashed**, opacity 55%.
    - Delete the right-hand label.
18. Now **restore exactly one node**: the middle individual in the last (rightmost) column.
    - Recolour it `#0b0b0b`.
    - Add a thin ring around it — a circle outline, no fill, `#0b0b0b`, 2 px.
19. Beside that one individual, place the **big genome strip** (the one from step 8, scaled up 3–4×). Caption it underneath, Arial ~14 pt, `#52514e`:
    ```
    the one genome you actually read
    ```
20. To its right, Arial Bold ~22 pt, `#0b0b0b`:
    ```
    one individual,
    one moment
    ```
21. Add the quiet callout into the empty grey middle of Band A, Arial ~16 pt, colour `#8a8880`, with a thin leader line pointing into the ghost lattice:
    ```
    the genealogy exists —
    you just cannot see it
    ```

---

## Phase 5 — the sampling moment (optional, ~10 min)

Only if the figure still feels too abstract.

22. Search the icon library for **`microcentrifuge tube`**, **`pipette`**, or **`DNA sequencer`**. Place one small icon above the sampled individual with a short downward arrow.
23. Label it `you sample here`, Arial ~14 pt, `#52514e`.

Keep this tiny. It's a footnote, not a second subject.

---

## Phase 6 — polish and export (~20 min)

24. **Alignment sweep.** Select each band in turn and check the columns line up with the locked tick marks. Nudge with arrow keys, never by dragging.
25. **Whitespace check.** The gap between the two bands should be larger than any gap within a band — that's what makes them read as two things being compared rather than one crowded picture.
26. **Squint test.** Zoom out to 25%. You should still see: a grey band, a blue band, one dark dot. If the dark dot isn't the first thing you notice, make it bigger or make everything else lighter.
27. **Type audit.** Every label should be one of exactly three sizes — band titles, callouts, captions. If you have four, merge two.
28. Export: **PNG, 300 DPI**, transparent background if your licence allows it (it drops onto the UZH white template cleanly either way).
29. Export a second copy at **150 DPI** for quick iteration in the deck — the 300 DPI file is slow to move around in PowerPoint.

---

## What to check before you commit to it

- **Does it work without the labels?** Cover them. The picture should still say "lots vs one." If it doesn't, the greyness contrast isn't strong enough.
- **Is the ghost lattice too visible?** It should be *just* readable — present enough to prove the history exists, faint enough that the one dark node dominates. If in doubt, lighten it.
- **Are the lines a distraction?** If the web looks like noise, cut to one line per individual instead of two.

---

## Two variants worth trying if the first version disappoints

**Variant A — collapse Band A.** Instead of a ghost lattice, show Band A as *only* the single individual on an otherwise empty band. Starker, less informative. Try it if the ghost version reads as cluttered.

**Variant B — add a third band.** `What a time series gives you`: the same lattice with one node lit per column — i.e. repeated sampling still misses almost everything. This makes the argument stronger but adds a third thing to explain. Only worth it if the figure has to stand alone in a paper.

---

## Reference

The blueprint PNG in this folder shows the intended composition with the build steps keyed 1–4. It's a target, not a template — the proportions are right, the icons are placeholders for BioRender's.
