# Four demes, four windows on one ramp

Each box keeps a gradient — so it still reads as *a climate*, not a single number — but each
box's gradient is a **different quarter of the same scale**. The gradient stops carrying
decoration and starts carrying position.

The ramp is the one your maps use: `#2166AC` → `#F7F7F7` → `#B2182B`.

## The gradient stops

| Box | Window | Stop 1 (0%) | Stop 2 (100%) | Reads as |
|---|---|---|---|---|
| **P1** | 0 – 25% | `#2166AC` | `#98ABD2` | deep blue → mid blue |
| **P2** | 25 – 50% | `#98ABD2` | `#F7F7F7` | mid blue → white |
| **P3** | 50 – 75% | `#F7F7F7` | `#E0908A` | white → medium red |
| **P4** | 75 – 100% | `#E0908A` | `#B2182B` | medium red → deep red |

Each box's second stop is the next box's first stop, so laid end to end the four boxes
reconstruct the full ramp exactly. That is what makes it read as stepwise rather than as four
arbitrary colours.

## Building it in PowerPoint

For each box: **Format Shape → Fill → Gradient fill**

1. **Type:** Linear. **Angle:** `0°` for left-to-right (use `270°` if you keep the
   top-to-bottom direction you have now).
2. Delete every gradient stop until **two** remain.
3. Stop 1 at position **0%**, colour from the table.
   Stop 2 at position **100%**, colour from the table.
4. **Transparency 0%, Brightness 0%** on both stops — PowerPoint sometimes adds brightness
   offsets to preset gradients and it will throw the colours off.
5. Outline: white, 2 pt. It separates the boxes from each other and from the slide.

**Text colour:** white on P1 and P4, black on P2 and P3. P2 and P3 are pale enough that white
text disappears.

## Layout: row, not grid

The comparison sheet shows both. The row wins, for one reason: in a 2 × 2 the four windows are
visible but the arrangement carries no order, so the viewer has to be *told* that it's one
scale cut into four. In a row, left to right, the arrangement says it.

Put a thin colour bar under the row with the four windows bracketed on it. That single strip
is what turns "four coloured boxes" into "one gradient, four demes" without a word of
explanation — and it ties the slide to your maps, which use the same ramp.

## One caution

This version is schematic: P1–P4 step evenly across the whole ramp. Your four real sites do
not — they span about 1.3 °C, all of it in the warm half. Both figures are legitimate, but
they say different things, so don't show them as if they were the same claim:

- **This one** says *the model has demes at different points on a climate gradient.* Label the
  boxes P1–P4 and say "schematic".
- **The real-values one** says *these are the four Swiss sites and this is how much they
  actually differ.* Label them Geneva, Bern, Zurich, St. Gallen with temperatures.

If you show both, show the schematic first to explain the design, then the real one, and say
the difference out loud.
