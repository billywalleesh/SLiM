"""GBF headline indicator A.4 - one slide figure, four cumulative build stages.

Visual grammar borrowed from the two source figures:
  Hoban et al. 2023, Conservation Letters, fig. 1 - populations as circles of
      countable glyphs, one glyph worth a fixed number of individuals, and a
      per-population pass/fail verdict summed into an indicator value.
  Hoban et al. 2024, BioScience, figs. 1-3       - the Ne > 500 / Ne < 500
      circle pair and the traffic-light reading of the threshold.

Writes gbf_indicator_build1..4.png  (drop build 4 on the slide, or animate all
four in order).
"""
import sys, os
sys.path.insert(0, "/home/claude/deck")
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, FancyArrowPatch, FancyBboxPatch
from figstyle import S1, S2, S3, INK, INK2, MUTED, GRID, SURF, FAINT

OUT  = "/home/claude/gbf"
W, H = 12.9, 5.45            # inches; fits under a title on a 16:9 slide
ASP  = W / H                 # y-units are this much shorter than x-units

PASS, FAIL = S3, S2          # green / orange, from the deck palette
PER_DOT = 1000
RATIO   = 0.1
THRESH  = 500

R_POP = 3.45                 # population circle radius, x-units
pops = [("A", 12000,  5.7, 62.0),
        ("B",  6000, 14.3, 62.0),
        ("C",  3000, 22.9, 62.0),
        ("D",  1000, 31.5, 62.0)]


def circ(ax, cx, cy, r, **kw):
    """A true circle in a coordinate system whose y axis is compressed."""
    ax.add_patch(Ellipse((cx, cy), 2 * r, 2 * r * ASP, **kw))


def dots_in_circle(n, cx, cy, r):
    """Sunflower packing, lightly jittered, always inside r."""
    rng = np.random.default_rng(7)
    golden = np.pi * (3 - np.sqrt(5))
    out = []
    for i in range(n):
        rad = r * 0.70 * np.sqrt((i + 0.5) / max(n, 1))
        th  = i * golden
        out.append((cx + rad * np.cos(th) + rng.normal(0, r * 0.05),
                    cy + (rad * np.sin(th) + rng.normal(0, r * 0.05)) * ASP))
    return out


def draw(stage, fname):
    fig, ax = plt.subplots(figsize=(W, H))
    ax.set_xlim(0, 100); ax.set_ylim(0, 100); ax.axis("off")

    def step_head(x, n, head, sub):
        circ(ax, x + 1.1, 95.0, 1.85, fc=INK, ec="none", zorder=4)
        ax.text(x + 1.1, 95.0, n, fontsize=13, fontweight="bold", color=SURF,
                ha="center", va="center", zorder=5)
        ax.text(x + 4.2, 95.0, head, fontsize=17, fontweight="bold",
                color=INK, ha="left", va="center")
        ax.text(x, 87.5, sub, fontsize=13, color=MUTED, ha="left", va="center")

    # ---- step 1: count the individuals ------------------------------------
    step_head(1.5, "1", "Count the individuals",
              "Census size, from surveys and reports — no DNA needed")

    for lab, nc, cx, cy in pops:
        r = R_POP
        circ(ax, cx, cy, r, fc=FAINT, ec=GRID, lw=1.4, zorder=1)
        for px, py in dots_in_circle(nc // PER_DOT, cx, cy, r):
            circ(ax, px, py, 0.40, fc=INK2, ec="none", zorder=2)
        ax.text(cx, cy - r * ASP - 5.0, lab, fontsize=13,
                fontweight="bold", color=INK, ha="center", va="center")
        ax.text(cx, cy - r * ASP - 11.0, f"$N_c$ = {nc:,}", fontsize=12.5,
                color=INK2, ha="center", va="center")

    ax.text(1.5, 33.0, f"one dot = {PER_DOT:,} individuals", fontsize=12,
            color=MUTED, ha="left", va="center", style="italic")

    # ---- step 2: convert to effective size ---------------------------------
    if stage >= 2:
        ax.add_patch(FancyArrowPatch((36.0, 62), (40.0, 62), mutation_scale=18,
                                     lw=2.0, color=MUTED, arrowstyle="-|>"))
        step_head(42.0, "2", "Convert to $N_e$",
                  "Not every individual reproduces")
        ax.add_patch(FancyBboxPatch((42.5, 50.0), 21.0, 22.0,
                                    boxstyle="round,pad=0.7,rounding_size=1.8",
                                    fc=FAINT, ec=GRID, lw=1.4, zorder=1))
        ax.text(53.0, 64.0, r"$N_e \approx N_c \times 0.1$", fontsize=24,
                fontweight="bold", color=S1, ha="center", va="center")
        ax.text(53.0, 55.5, "the default ratio applied\nwhen no genetic data exist",
                fontsize=12.5, color=INK2, ha="center", va="center",
                linespacing=1.4)
        ax.text(53.0, 45.5, "0.1\u20130.3 for most species;\n0.1 is the conservative default",
                fontsize=11, color=MUTED, ha="center", va="center",
                style="italic", linespacing=1.4)

    # ---- step 3: compare to 500 --------------------------------------------
    if stage >= 3:
        ax.add_patch(FancyArrowPatch((66.5, 62), (70.5, 62), mutation_scale=18,
                                     lw=2.0, color=MUTED, arrowstyle="-|>"))
        step_head(73.0, "3", "Compare to 500",
                  "The tipping point written into the indicator")

        x0, x1, xmax = 76.0, 93.0, 1400.0
        X = lambda v: x0 + (v / xmax) * (x1 - x0)
        ys = [72.0, 61.0, 50.0, 39.0]

        ax.plot([X(THRESH)] * 2, [33.5, 77.5], ls=(0, (5, 4)), lw=1.8,
                color=INK2, zorder=1)
        ax.text(X(THRESH), 79.0, "$N_e$ = 500", fontsize=13,
                fontweight="bold", color=INK2, ha="center", va="bottom")

        for (lab, nc, _, _), y in zip(pops, ys):
            ne  = nc * RATIO
            col = PASS if ne > THRESH else FAIL
            ax.plot([x0, X(ne)], [y, y], lw=3.6, color=col,
                    solid_capstyle="round", zorder=2)
            circ(ax, X(ne), y, 0.80, fc=col, ec=SURF, lw=1.3, zorder=3)
            ax.text(x0 - 1.6, y, lab, fontsize=13, fontweight="bold",
                    color=INK, ha="right", va="center")
            ax.text(99.5, y, f"{ne:,.0f}", fontsize=13,
                    fontweight="bold", color=col, ha="right", va="center")

    # ---- step 4: the indicator value ---------------------------------------
    if stage >= 4:
        n_ok = sum(1 for _, nc, _, _ in pops if nc * RATIO > THRESH)
        ax.add_patch(FancyBboxPatch((1.5, 8.0), 93.5, 12.0,
                                    boxstyle="round,pad=0.7,rounding_size=1.8",
                                    fc="#eef4fc", ec=S1, lw=1.6, zorder=1))
        ax.text(4.0, 17.0, "GBF headline indicator A.4", fontsize=13,
                fontweight="bold", color=S1, ha="left", va="center")
        ax.text(4.0, 11.0,
                f"the proportion of populations with $N_e$ > 500  →  "
                f"{n_ok} of {len(pops)}",
                fontsize=15, color=INK, ha="left", va="center")
        ax.text(93.0, 14.0, f"{n_ok / len(pops):.2f}", fontsize=36,
                fontweight="bold", color=S1, ha="right", va="center")

    ax.text(1.5, 3.0,
            "After Hoban et al. 2023, Conservation Letters 16:e12953, fig. 1; "
            "and Hoban et al. 2024, BioScience 74:269\u2013280, figs. 1\u20133.",
            fontsize=10, color=MUTED, ha="left", va="center")

    fig.subplots_adjust(left=0.004, right=0.996, top=0.996, bottom=0.004)
    fig.savefig(os.path.join(OUT, fname), dpi=260, facecolor=SURF)
    plt.close(fig)
    print("wrote", fname)


for k in (1, 2, 3, 4):
    draw(k, f"gbf_indicator_build{k}.png")
