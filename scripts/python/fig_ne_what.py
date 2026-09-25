"""What Ne is, in one line of reasoning: a count, a smaller effective count,
and a rate at which diversity is lost."""
import sys; sys.path.insert(0, "/home/claude/deck")
import numpy as np, matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, FancyArrowPatch, FancyBboxPatch
from figstyle import S1, S2, INK, INK2, MUTED, GRID, SURF, FAINT

W, H = 12.9, 5.0
ASP  = W / H
rng  = np.random.default_rng(3)

def circ(ax, cx, cy, r, **kw):
    ax.add_patch(Ellipse((cx, cy), 2*r, 2*r*ASP, **kw))

def cluster(cx, cy, r, n):
    g = np.pi * (3 - np.sqrt(5))
    out = []
    for i in range(n):
        rad = r * 0.78 * np.sqrt((i + 0.5) / n); th = i * g
        out.append((cx + rad*np.cos(th) + rng.normal(0, r*0.035),
                    cy + (rad*np.sin(th) + rng.normal(0, r*0.035)) * ASP))
    return out

fig, ax = plt.subplots(figsize=(W, H))
ax.set_xlim(0, 100); ax.set_ylim(0, 100); ax.axis("off")

N, NE_FRAC = 40, 0.25
pts = cluster(15.0, 63.0, 10.0, N)
eff = set(rng.choice(N, int(N * NE_FRAC), replace=False))

def head(x, n, title, sub, col=INK):
    circ(ax, x + 1.5, 93.0, 1.9, fc=INK, ec="none", zorder=4)
    ax.text(x + 1.5, 93.0, n, fontsize=12.5, fontweight="bold", color=SURF,
            ha="center", va="center", zorder=5)
    ax.text(x + 4.4, 93.0, title, fontsize=16, fontweight="bold", color=col,
            ha="left", va="center")
    ax.text(x, 84.5, sub, fontsize=12.5, color=MUTED, ha="left", va="center")

# ---- 1 the headcount --------------------------------------------------------
head(1.5, "1", "Count them", "census size, $N_c$")
circ(ax, 15.0, 63.0, 10.0, fc=FAINT, ec=GRID, lw=1.5, zorder=1)
for p in pts:
    circ(ax, p[0], p[1], 0.62, fc=INK2, ec="none", zorder=2)
ax.text(15.0, 31.0, "$N_c$ = 40", fontsize=15, fontweight="bold", color=INK,
        ha="center", va="center")

# ---- 2 the effective count --------------------------------------------------
ax.add_patch(FancyArrowPatch((27.0, 63), (32.0, 63), arrowstyle="-|>",
                             mutation_scale=18, lw=2.0, color=MUTED))
head(35.5, "2", "Not all of them breed", "effective size, $N_e$")
circ(ax, 49.0, 63.0, 10.0, fc=FAINT, ec=GRID, lw=1.5, zorder=1)
for i, p in enumerate(pts):
    x, y = p[0] + 34.0, p[1]
    if i in eff:
        circ(ax, x, y, 0.80, fc=S1, ec="none", zorder=3)
    else:
        circ(ax, x, y, 0.62, fc="#d8d6d1", ec="none", zorder=2)
ax.text(49.0, 31.0, "$N_e$ = 10", fontsize=15, fontweight="bold", color=S1,
        ha="center", va="center")
ax.text(49.0, 24.5, "with no DNA data, taken as $N_c \\times 0.1$",
        fontsize=11.5, color=MUTED, ha="center", va="center", style="italic")

# ---- 3 the consequence ------------------------------------------------------
ax.add_patch(FancyArrowPatch((61.0, 63), (66.0, 63), arrowstyle="-|>",
                             mutation_scale=18, lw=2.0, color=MUTED))
head(69.5, "3", "Diversity drains away", "at a rate set by $N_e$")

bx, by, bw, bh = 70.5, 44.0, 27.0, 33.0
ax.add_patch(FancyBboxPatch((bx, by), bw, bh,
                            boxstyle="round,pad=0,rounding_size=1.2",
                            fc=SURF, ec=GRID, lw=1.3, zorder=1))
t = np.linspace(0, 100, 200)
for ne, col, lab in ((10, S2, "$N_e$ = 10"), (100, INK2, "100"), (1000, S1, "1,000")):
    y = (1 - 1 / (2 * ne)) ** t
    ax.plot(bx + 2.0 + t / 100 * (bw - 4.0), by + 3.0 + y * (bh - 8.0),
            lw=2.4, color=col, zorder=3)
    ax.text(bx + bw - 1.8, by + 3.0 + ((1 - 1/(2*ne))**100) * (bh - 8.0) + 1.4,
            lab, fontsize=11, fontweight="bold", color=col, ha="right",
            va="bottom", zorder=4)
ax.text(bx + bw / 2, by - 3.2, "100 generations", fontsize=11.5, color=INK2,
        ha="center", va="center")
ax.text(bx - 1.2, by + bh / 2, "heterozygosity", fontsize=11.5, color=INK2,
        ha="center", va="center", rotation=90)

ax.text(50, 12.0, r"each generation, drift removes $1/(2N_e)$ of the diversity that is left",
        fontsize=14, color=INK, ha="center", va="center")
ax.text(50, 4.5, "so $N_e$ is not a headcount — it is a statement about how "
                 "fast genetic diversity disappears",
        fontsize=12.5, color=MUTED, ha="center", va="center", style="italic")

fig.subplots_adjust(0.004, 0.004, 0.996, 0.996)
fig.savefig("/home/claude/ne2/fig_ne_what.png", dpi=260, facecolor=SURF)
print("ok")
