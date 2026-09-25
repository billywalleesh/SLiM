"""Four demes on solid climate backgrounds, coloured off the map's own scale.

Colours are extracted from the ERA5 field at each site and passed through the
same diverging ramp the maps use (#2166AC - #F7F7F7 - #B2182B, Lab space,
limits 0.28-14.19 degC, white at 7.24), so a square on this slide and a cell on
the map mean the same temperature.
"""
import sys, os
sys.path.insert(0, "/home/claude/deck")
import numpy as np, matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Rectangle
from matplotlib.colors import LinearSegmentedColormap
from figstyle import INK, INK2, MUTED, GRID, SURF

W, H = 12.9, 5.45
ASP  = W / H
LIMS, MIDP = (0.28, 14.19), 7.24

sites = [   # label, P, T 1940-70, hex 1940-70, T 1971-2025, hex 1971-2025
    ("Geneva",     "p0", 11.11, "#DC857F", 12.50, "#CB5A57"),
    ("Bern",       "p1", 11.54, "#D77872", 12.66, "#C95553"),
    ("Zurich",     "p2", 11.65, "#D5746F", 12.67, "#C85552"),
    ("St. Gallen", "p3", 10.39, "#E39A94", 11.61, "#D67670"),
]

fig, ax = plt.subplots(figsize=(W, H))
ax.set_xlim(0, 100); ax.set_ylim(0, 100); ax.axis("off")

XS = [17.0, 39.0, 61.0, 83.0]      # square centres
SQ, SY = 16.0, 63.0                # square width (x-units), centre y

for (lab, pid, t1, h1, t2, h2), cx in zip(sites, XS):
    ax.add_patch(FancyBboxPatch((cx - SQ / 2, SY - SQ * ASP / 2), SQ, SQ * ASP,
                                boxstyle="round,pad=0,rounding_size=1.4",
                                fc=h1, ec="white", lw=2.0, zorder=2))
    ax.text(cx, SY + 4.5, pid, fontsize=15, fontweight="bold", color=INK,
            ha="center", va="center", zorder=3)
    ax.text(cx, SY - 4.0, f"{t1:.1f} °C", fontsize=14, color=INK,
            ha="center", va="center", zorder=3)
    ax.text(cx, SY - SQ * ASP / 2 - 5.5, lab, fontsize=13.5, fontweight="bold",
            color=INK, ha="center", va="center")

    # the same site, 55 years later
    ax.add_patch(FancyBboxPatch((cx - 5.6, 22.0), 11.2, 7.0,
                                boxstyle="round,pad=0,rounding_size=0.8",
                                fc=h2, ec="white", lw=1.6, zorder=2))
    ax.text(cx, 25.5, f"{t2:.1f} °C", fontsize=12, color=INK,
            ha="center", va="center", zorder=3)
    ax.text(cx, 17.0, f"+{t2 - t1:.1f} °C", fontsize=12, fontweight="bold",
            color="#B2182B", ha="center", va="center")

ax.text(1.0, 25.5, "1971–2025", fontsize=11.5, color=INK2,
        ha="left", va="center", fontweight="bold")
ax.text(1.0, 88.0, "1940–1970", fontsize=11.5, color=INK2,
        ha="left", va="center", fontweight="bold")

# migration between neighbours; the matrix connects all six pairs
for a, b in zip(XS[:-1], XS[1:]):
    ax.add_patch(FancyArrowPatch((a + SQ / 2 + 1.2, SY), (b - SQ / 2 - 1.2, SY),
                                 arrowstyle="<|-|>", mutation_scale=13,
                                 lw=1.6, color=INK2, zorder=4))
ax.text(50, 93.0, "migration between all pairs, rate falling with distance",
        fontsize=12, color=MUTED, ha="center", va="center", style="italic")

# --- the map's colour bar, with the four sites ticked on it ------------------
cmap = LinearSegmentedColormap.from_list("rdbu", ["#2166AC", "#F7F7F7", "#B2182B"])
BX, BY, BW, BH = 18.0, 6.0, 64.0, 3.4
grad = np.linspace(0, 1, 512).reshape(1, -1)
ax.imshow(grad, extent=[BX, BX + BW, BY, BY + BH], aspect="auto", cmap=cmap,
          zorder=2)
ax.add_patch(Rectangle((BX, BY), BW, BH, fc="none", ec=GRID, lw=1.0, zorder=3))

def bar_x(t):
    f = (t - LIMS[0]) / (LIMS[1] - LIMS[0]) if t >= MIDP else \
        (t - LIMS[0]) / (LIMS[1] - LIMS[0])
    return BX + f * BW

for t, lab in ((LIMS[0], f"{LIMS[0]:.0f}"), (MIDP, f"{MIDP:.0f}"),
               (LIMS[1], f"{LIMS[1]:.0f}")):
    ax.text(bar_x(t), BY - 2.6, lab, fontsize=10.5, color=INK2,
            ha="center", va="center")
for (_, _, t1, _, t2, _) in sites:
    for t in (t1, t2):
        ax.plot([bar_x(t)] * 2, [BY, BY + BH], lw=1.2, color=INK, zorder=4)
ax.text(BX + BW + 2.0, BY + BH / 2, "°C", fontsize=11, color=INK2,
        ha="left", va="center")
ax.text(BX - 2.0, BY + BH / 2, "same scale\nas the maps", fontsize=10.5,
        color=MUTED, ha="right", va="center", style="italic", linespacing=1.3)
ax.text(BX + BW + 6.0, BY + BH / 2,
        "all eight values sit\nin this narrow band",
        fontsize=10.5, color=MUTED, ha="left", va="center",
        style="italic", linespacing=1.3)

fig.subplots_adjust(0.004, 0.004, 0.996, 0.996)
fig.savefig("/home/claude/newslides/demes_climate.png", dpi=260, facecolor=SURF)
print("ok")
