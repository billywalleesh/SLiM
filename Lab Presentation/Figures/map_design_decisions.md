# Migration map — decisions, not steps

Each section is one choice. Pick an option, make the edit, re-run. Work top to bottom: the early decisions remove work from the later ones.

```
Rscript scripts/R/13_map_4pop_migration.R
```

---

## Decision 0 — What is this map actually for?

Answer this first; it decides half of what follows.

| | What the map must do | What it can drop |
|---|---|---|
| **A. Orientation** | "Four sites, spread west to east across the Plateau" | rates, arrowheads, numbers |
| **B. Connectivity** | "Who exchanges migrants with whom, and how much" | geographic realism |

**For a talk, choose A.** The audience needs to know where the demes are and that they're connected. The actual rate is one sentence you say out loud, not six labels they'll squint at. Choose B only if a *difference* between links is part of your argument — and for `weak` and `strong` there is no difference, because every link is identical by design.

The rest of this assumes A unless noted.

---

## Decision 1 — Numbers on the map, or not

This is the cause of the mess.

| Option | Result | Edit |
|---|---|---|
| **None** (recommended) | Clean map. Rate goes in the caption: *"All demes exchange migrants at 0.67% per generation."* | Delete the whole `geom_label(...)` block |
| Width only | Structure visible, no clutter. Needs a legend to be readable | Keep `scale_linewidth`, change `guide = "none"` to `guide = "legend"` |
| Numbers only | Precise but busy | Keep `geom_label`, set `scale_linewidth(range = c(1, 1))` |

**Never keep both.** Width plus numbers is the same information twice, and it's why the current version looks cluttered.

---

## Decision 2 — Which links to draw

Four demes means six links, and six links crossing a small country is inherently untidy.

| Option | Lines | Looks |
|---|---|---|
| All six pairs | 6 | Honest, busy, unavoidable crossings |
| **West–east chain only** (recommended) | 3 | Clean. Add caption: *"all pairs exchange; nearest neighbours shown"* |
| No links, dots only | 0 | Cleanest. Connectivity stated in words |

For the chain, insert after `edges` is built:

```r
edges <- edges |> filter((i == 1 & j == 2) | (i == 2 & j == 3) | (i == 3 & j == 4))
```

> Be careful with this one. If your point is that *every* deme exchanges with every other — which is what makes per-deme Ne report the metapopulation — then drawing only three links undercuts your own argument. In that case take all six and thin them right down.

---

## Decision 3 — Straight or curved

| Option | Edit | When |
|---|---|---|
| Straight | `curvature = 0` | Chain layout, or few links |
| **Gentle, consistent** (recommended) | `curvature = 0.12` | All six links — the consistent bow stops them overlapping |
| Pronounced | `curvature = 0.3` | Only if you like the look; it distorts apparent distance |

Whatever you pick, keep it the same for every link. Mixed curvatures read as chaos.

---

## Decision 4 — Arrowheads

Your migration matrices are symmetric — the rate from Geneva to Bern equals Bern to Geneva. So arrowheads carry no information.

| Option | Edit |
|---|---|
| **None** (recommended) | Delete the `arrow = arrow(...)` argument entirely |
| Both ends | Leave as is |

Removing them also removes the little clumps where six arrowheads converge on one dot, which is most of the untidiness at Geneva and St. Gallen.

---

## Decision 5 — Line weight and colour

With arrowheads and numbers gone, the lines can be much lighter.

```r
scale_linewidth(range = c(0.6, 0.6), guide = "none")   # uniform, thin
```

and in `geom_curve`, set `colour = "#c9c7c1", alpha = 1`. Lines should sit *underneath* the map's importance, not compete with the dots. If you can read the line weight before you read the city names, they're too heavy.

---

## Decision 6 — Basemap

| Option | Edit | Effect |
|---|---|---|
| Switzerland + grey neighbours | as written | Context, more visual noise |
| **Switzerland alone** (recommended) | Comment out the `geom_sf(data = nb, ...)` line and the four `annotate("text", ...)` country names | Much calmer; the shape is recognisable without them |
| Outline only | Also set `fill = NA` on the `ch` layer | Lightest possible |

Also delete the `FRANCE / GERMANY / ITALY / AUSTRIA` labels if you keep neighbours — they're the first thing to go.

**Outline quality.** If the border looks chunky, you're on the 1:50m data. Install the high-resolution set once:

```r
install.packages("rnaturalearthhires",
                 repos = "https://ropensci.r-universe.dev", type = "source")
```

then set `MAP_SCALE <- "large"` at the top. For a country this size it's a visible improvement.

---

## Decision 7 — City labels

Manual nudges are in the block near the top (`loc$dx`, `loc$dy`, metres). Geneva currently sits outside the border — raise its `dy`.

Easier alternative:

```r
install.packages("ggrepel")
library(ggrepel)
# replace the geom_text(...) call with:
geom_text_repel(data = loc, aes(X, Y, label = label),
                size = 6.2, fontface = "bold", colour = INK,
                point.padding = 0.6, min.segment.length = Inf, seed = 1)
```

`seed = 1` keeps positions identical between runs, so the figure doesn't shuffle every time you re-render.

---

## Decision 8 — Furniture

Delete unless it earns its place:

- **Scale bar** — keep. It's the one thing that makes it a map rather than a diagram.
- **Caption** — keep, and put the migration rate in it.
- **North arrow** — skip. North is up; everyone knows.
- **Graticule** — already off via `datum = NA`. Leave it off.

---

## If you decide you *do* need the numbers

Don't put them on the map. Put them beside it.

A 4 × 4 matrix as small coloured tiles reads better than six scattered labels, and it shows the structure of the treatment at a glance — including the fact that `weak` and `strong` are completely uniform, which is hard to see on a map and obvious in a grid.

```r
library(tidyr)
m <- as.data.frame(as.table(mig))
names(m) <- c("from", "to", "rate")
m$from <- loc$label[as.integer(m$from)]
m$to   <- loc$label[as.integer(m$to)]

ggplot(m, aes(to, from, fill = rate)) +
  geom_tile(colour = "white", linewidth = 1.6) +
  geom_text(aes(label = ifelse(rate == 0, "", sprintf("%.2f%%", rate * 100))),
            size = 4.2, colour = "white", fontface = "bold") +
  scale_fill_gradient(low = "#cde2fb", high = "#2a78d6", guide = "none") +
  coord_equal() + labs(x = NULL, y = NULL) + theme_minimal(base_size = 13)
```

Map for *where*, grid for *how much*. Two clean panels beat one crowded one.

---

## My default, if you want one

Switzerland alone, no neighbours · all six links, uniform thin grey, gentle curve, no arrowheads · no numbers on the map · four coloured dots with repelled labels · scale bar · rate in the caption.

That's roughly ten minutes of edits from the script as delivered, and it will look like a figure rather than a diagram of a figure.
