# Building the real-data / simulated-data cycle in PowerPoint

The figure you sent is four things stacked: a **yin-yang**, two **label circles**, a **ring of
arcs with arrowheads**, and **six text blocks** around the outside. None of it needs an
illustration program — the yin-yang comes out of Merge Shapes in about two minutes once you
know the trick.

`cycle_target.png` in this folder is what you're aiming at.

> **Units.** All numbers below are centimetres, for a 33.87 × 19.05 cm slide (the standard
> 16:9, which is what your deck uses). If your PowerPoint shows inches, divide by 2.54.
> Type every number into **Format Shape → Size & Properties → Size / Position** rather than
> dragging. Dragging is how figures end up almost aligned.

> **Delete the footer placeholder on this slide.** The figure needs the full height, and that
> placeholder is showing `Footer (Edit via "Insert > Header and Footer")` anyway.

---

## 1. The yin-yang — no Merge Shapes needed

Forget merging. The shape is just **five ovals stacked in order**, each one painting over the
last. Nothing is cut, nothing is destroyed, and every piece stays clickable afterwards.

`yinyang_parts.pptx` in this folder has it built — slide 1 is the finished shape, slide 2 is
the same five pieces exploded in build order. Copy slide 1's shapes straight into your deck if
you like; the steps below are for building it from scratch.

Everything is concentric on a centre at **(16.93, 10.40)**.

| # | Shape | Size | Position (left, top) | Fill | Outline |
|---|---|---|---|---|---|
| 1 | Oval | 10 × 10 | 11.93, 5.40 | light blue `#E7F0FB` | black 2.25 pt |
| 2 | **Pie** | 10 × 10 | 11.93, 5.40 | light grey `#F0EFEC` | none |
| 3 | Oval | 5 × 5 | 14.43, 5.40 | light grey `#F0EFEC` | none |
| 4 | Oval | 5 × 5 | 14.43, 10.40 | light blue `#E7F0FB` | none |
| 5 | Oval | 10 × 10 | 11.93, 5.40 | **no fill** | black 2.25 pt |

1. **Shape 1** is the whole circle — this is the *simulated data* half.
2. **Shape 2** is the **Pie** (Insert → Shapes → Basic Shapes, the pac-man one). Give it the
   same size and position as shape 1, then drag its two yellow handles so it covers exactly the
   **right half**. You can see when it's clean — the straight edge runs dead vertical through
   the centre. This is the *real data* half.
3. **Shape 3**, a half-size grey oval sitting on the upper half, pushes grey across into the
   left side.
4. **Shape 4**, a half-size blue oval on the lower half, carves blue back into the right side.
   That one move is what turns two halves into the S.
5. **Shape 5** is an empty circle with only an outline, on top of everything, so the rim is a
   single unbroken stroke rather than two arcs meeting at a seam.

Order matters only in the sense that each shape must sit **on top of** the one before. If you
draw them in the order above, they already do.

> **Why not Merge Shapes?** Because Subtract and Intersect depend on *which shape you clicked
> first*, they can't be undone once you've moved on, and a single wrong click gives you a
> crescent instead of a tadpole. Stacking has none of those failure modes — if a layer looks
> wrong, change its fill or nudge it, and everything else is untouched.

### If you still want the merge route

It does work, and the two things that break it are both selection-order problems:

- **Subtract removes the *later* selection from the *first*.** Click the big merged shape
  first, then the small circle. Reversed, you get "small circle minus tadpole" — a thin
  crescent. That is the commonest symptom.
- **Never rubber-band or Ctrl+A the shapes.** Marquee selection gives PowerPoint no defined
  order, so Subtract and Intersect pick a base arbitrarily. Click each shape individually,
  in order, with Ctrl held.
- **Check you're on Subtract, not Combine.** *Combine* is exclusive-or: it deletes the overlap
  and keeps both leftovers, so the small circle's far half survives as a stray blob. The five
  buttons read Union · Combine · Fragment · Intersect · Subtract, left to right.
- Duplicate every shape before merging it. Merges are one-way.

## 2. The two label circles

| Shape | Size | Position | Text |
|---|---|---|---|
| Upper eye | 3.8 × 3.8 | 15.03, 6.00 | **Real data** |
| Lower eye | 3.8 × 3.8 | 15.03, 11.00 | **Simulated data** |

Fill **white**, **no outline**. Type the text straight into the shape. Arial Bold 18 pt —
black for *Real data*, **`#2A78D6`** for *Simulated data*, so the blue ties to the blue half.

These sit exactly where the yin-yang's eyes would go, which is why the composition works.

---

## 3. The ring of arrows

Build **one** arc, format it, then duplicate and rotate. Rotating a concentric shape keeps it
on the ring, so all six land perfectly without any measuring.

8. **Insert → Shapes → Lines → Arc.** Draw one roughly, then set
   **Size 11.6 × 11.6, Position 11.13, 4.60.** The bounding box is the full circle the arc is
   cut from, so it is now concentric with everything else.
9. Drag the two **yellow handles** so the arc spans about 50° — roughly one-sixth of the
   circle with a small gap. Exact isn't important; identical is, and duplicating handles that.
10. Format it: **Line → Solid, black, 2.5 pt**; **End Arrow type** = filled triangle,
    **End Arrow size** = the largest.
11. Check the arrowhead is on the **clockwise** end. If it's on the wrong end, swap to
    *Begin Arrow type* instead.
12. **Ctrl+D** five times. Set each copy's rotation to **60, 120, 180, 240, 300** in
    **Format Shape → Size → Rotation**. Six evenly spaced arrows, no alignment work.

---

## 4. The six stations

All six text boxes are **10 × 1.8 cm**. Each holds two lines: a bold headline and a lighter
sub-line.

| # | Clock | Position (left, top) | Align | Headline / sub-line |
|---|---|---|---|---|
| 1 | 12 | 11.93, 2.50 | centre | **Sample the population** / a few individuals, once |
| 2 | 2 | 23.00, 6.00 | left | **Sequence them** / allele frequencies, one time point |
| 3 | 4 | 23.00, 13.00 | left | **Estimate Ne** / a number with nothing to check it |
| 4 | 6 | 11.93, 16.50 | centre | **Build the same demography** / census, migration, climate record |
| 5 | 8 | 0.90, 13.00 | right | **Run it forward** / every individual, every generation |
| 6 | 10 | 0.90, 6.00 | right | **Score the estimator** / against the genealogy you recorded |

Type: Arial Bold 14 pt for headlines, Arial 12 pt `#52514E` for sub-lines.

**Colour carries the argument.** Stations 1 and 2 black — that's the field world.
Station 3 in **`#EB6834`** — it's the dead end, the number you cannot check. Stations 4, 5, 6
in **`#2A78D6`** — the simulated world that supplies what was missing. Someone who only looks
at the colours still gets the point.

Finally, a caption text box across the bottom, Arial Italic 12 pt `#8A8880`:

> Field data sets the assumptions. Simulation says what the field data could not have told you.

That's your Act 2 line from the deck, so the figure closes the loop you already opened.

---

## 5. Icons, if you want them

The Pulendran figure leans hard on silhouettes. Yours doesn't need many — two or three,
placed just inside the ring near their station:

- **Insert → Icons** (built into Microsoft 365) and search `tree`, `dna`, `laptop`, `chart`.
- Insert, then **Graphics Format → Graphics Fill** to recolour. Grey `#52514E` on the real
  side, blue `#2A78D6` on the simulated side.
- Keep them small, ~1.2 cm. If an icon needs a caption to be understood, cut it.

---

## 6. Finish

13. Select everything → **Group** (Ctrl+G), so a stray click can't nudge one arc out of line.
14. If you want to animate: appear the yin-yang first, then stations 1–3 together, then 4–6,
    then the caption. Four clicks, matching the story order.
15. To reuse it elsewhere: right-click the group → **Save as Picture → PNG**.

---

## Two things that will bite you

**Merge Shapes is destructive.** Once merged you cannot recover the parts. Duplicate before
every merge until you're happy — step 2 exists for exactly this reason.

**Selection order decides the result.** *Subtract* removes the later selection from the first.
If you get the inverse of what you wanted, you clicked them in the wrong order — undo and
reselect rather than trying to fix it downstream.
