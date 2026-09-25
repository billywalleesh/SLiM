"""Why 500: where the curve has flattened, not where it breaks."""
import sys; sys.path.insert(0, "/home/claude/deck")
import numpy as np, matplotlib.pyplot as plt
from figstyle import S1, S2, S3, INK, INK2, MUTED, GRID, SURF, clean

GENS = 100
ne = np.logspace(1, 4, 600)
h  = (1 - 1 / (2 * ne)) ** GENS

fig, ax = plt.subplots(figsize=(12.9, 5.0))
ax.set_xscale("log")
ax.set_xlim(10, 10000); ax.set_ylim(0, 1.06)

ax.axvspan(10, 500, color="#fdf0ea", zorder=0)
ax.plot(ne, h, lw=3.2, color=INK, zorder=4)
ax.axvline(500, color=S2, lw=2.2, ls=(0, (6, 4)), zorder=5)

for v, col in ((50, S2), (100, S2), (500, S3), (1000, S3)):
    y = (1 - 1 / (2 * v)) ** GENS
    ax.plot([v], [y], "o", ms=9, color=col, mec="white", mew=1.8, zorder=6)
    ax.annotate(f"{y*100:.0f}%", (v, y), xytext=(0, 13),
                textcoords="offset points", fontsize=12.5, fontweight="bold",
                color=col, ha="center")

ax.text(500 * 0.92, 1.015, "$N_e$ = 500", fontsize=14, fontweight="bold",
        color=S2, ha="right", va="center")

ax.text(11.5, 0.80, "below the threshold\n\n"
                  "diversity drains faster than\nmutation can replace it, and\n"
                  "less and less variation is\nleft for selection to act on",
        fontsize=12.5, color=S2, ha="left", va="center", linespacing=1.45)
ax.text(1250, 0.40, "above the threshold\n\n"
                    "diversity is essentially held;\n"
                    "raising $N_e$ further buys little",
        fontsize=12.5, color=INK2, ha="left", va="center", linespacing=1.45)

ax.set_xlabel("Effective population size, $N_e$", fontsize=13.5, labelpad=9)
ax.set_ylabel(f"Heterozygosity kept\nafter {GENS} generations", fontsize=13.5,
              labelpad=9, linespacing=1.4)
ax.set_xticks([10, 100, 1000, 10000])
ax.set_xticklabels(["10", "100", "1,000", "10,000"], fontsize=12.5)
ax.set_yticks([0, 0.5, 1.0]); ax.set_yticklabels(["0", "50%", "100%"],
                                                 fontsize=12.5)
clean(ax)

fig.text(0.012, 0.055,
         "Loss runs at $1/(2N_e)$ per generation — smooth, with no break at 500. "
         "The threshold is set where variation lost to drift balances variation "
         "gained by mutation (Franklin 1980).",
         fontsize=11, color=MUTED, ha="left")
fig.subplots_adjust(left=0.105, right=0.995, top=0.94, bottom=0.235)
fig.savefig("/home/claude/ne2/fig_ne_500.png", dpi=260, facecolor=SURF)
print("ok")
