"""What can be observed, against what has to be simulated - on a log time axis.

GEN_YEARS is an assumption, stated on the figure: change it and every number
moves with it.
"""
import sys; sys.path.insert(0, "/home/claude/deck")
import numpy as np, matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
from figstyle import S1, S2, INK, INK2, MUTED, GRID, SURF, FAINT

W, H = 12.9, 5.45
GEN_YEARS = 50            # European beech, order of magnitude
RECORD    = 2025 - 1940   # years of ERA5
GENS_RUN  = 4055

rows = [
    ("A genetic study",  "one sample, one moment",
     0.6,                         "0 generation transitions",   INK),
    ("The climate record", "ERA5, 1940–2025",
     RECORD,                      f"{RECORD / GEN_YEARS:.1f} generations", INK),
    ("One simulation run", "SLiM, burn-in plus the record",
     GENS_RUN * GEN_YEARS,        f"{GENS_RUN:,} generations",  S1),
]

fig, ax = plt.subplots(figsize=(W, H))
ax.set_xscale("log")
ax.set_xlim(0.5, 1.2e6)
ax.set_ylim(-0.25, 3.55)
ax.spines[["top", "right", "left"]].set_visible(False)
ax.spines["bottom"].set_color(GRID)
ax.set_yticks([])
ax.set_xticks([1, 10, 100, 1000, 10000, 100000, 1000000])
ax.set_xticklabels(["1 yr", "10", "100", "1,000", "10,000", "100,000",
                    "1 million"], fontsize=11.5, color=INK2)
ax.tick_params(length=0, pad=8)
ax.grid(axis="x", color=GRID, lw=0.9)
ax.set_axisbelow(True)

ax.axvline(GEN_YEARS, color=S2, lw=1.6, ls=(0, (5, 4)), zorder=3)
ax.text(GEN_YEARS * 1.15, 3.38, f"one beech generation ≈ {GEN_YEARS} years",
        fontsize=11.5, color=S2, ha="left", va="center", fontweight="bold")

for i, (head, sub, span, gens, col) in enumerate(rows):
    y = 2.55 - i * 1.10
    ax.barh(y, span - 0.5, left=0.5, height=0.40, color=col,
            alpha=1.0 if col is S1 else 0.82, zorder=4)
    ax.text(0.62, y + 0.58, head, fontsize=13.5, fontweight="bold", color=col,
            ha="left", va="bottom")
    ax.text(0.62, y + 0.30, sub, fontsize=11.5, color=INK2,
            ha="left", va="bottom")
    ax.text(max(span, 1.2) * 1.6, y, gens, fontsize=12.5, fontweight="bold",
            color=col, ha="left", va="center")

ax.set_xlabel("Time the method actually covers", fontsize=12.5, color=INK2,
              labelpad=10)

fig.text(0.012, 0.035,
         "Simulation does not replace field data. The record is what makes the "
         "simulation realistic — it lets a process too slow to watch be "
         "run to its end.",
         fontsize=12.5, color=INK, ha="left", style="italic")
fig.subplots_adjust(left=0.012, right=0.995, top=0.94, bottom=0.22)
fig.savefig("/home/claude/newslides/timescales.png", dpi=260, facecolor=SURF)
print("ok")
