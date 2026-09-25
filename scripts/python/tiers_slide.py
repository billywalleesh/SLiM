"""Three ways to get a number for Ne - one slide, three cumulative builds.

Row 1  census x ratio      the GBF indicator: no genetic measurement at all
Row 2  genetic estimator   a model inverted on one sample; no reference to check
Row 3  simulation          the genealogy itself; the answer is known

Writes ne_tiers_build1..3.png
"""
import sys, os
sys.path.insert(0, "/home/claude/deck")
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, FancyBboxPatch, FancyArrowPatch
from figstyle import S1, S2, S3, INK, INK2, MUTED, GRID, SURF, FAINT

OUT  = "/home/claude/tiers"
W, H = 12.9, 5.45
ASP  = W / H
GHOST = "#dedcd7"

GEN_X = [14.2, 18.4, 22.6, 26.8, 31.0, 35.2]     # generation columns
OFF   = [-9.0, -3.0, 3.0, 9.0]                   # individuals within a column
BANDS = [75.0, 47.0, 19.0]                       # row centres

rng = np.random.default_rng(11)
PARENTS = {}                                      # fixed pedigree, drawn once
for gi in range(len(GEN_X) - 1):
    for k in range(len(OFF)):
        PARENTS[(gi, k)] = sorted(rng.choice(len(OFF), 2, replace=False))


def circ(ax, cx, cy, r, **kw):
    ax.add_patch(Ellipse((cx, cy), 2 * r, 2 * r * ASP, **kw))


def lattice(ax, cy, mode):
    """mode: 'ghost' (history invisible, one sample lit) or 'full'."""
    dot, line, lw, alpha = ((GHOST, GHOST, 0.7, 0.9) if mode == "ghost"
                            else (S1, S1, 0.8, 0.35))
    for gi in range(len(GEN_X) - 1):
        for k, o in enumerate(OFF):
            for pk in PARENTS[(gi, k)]:
                ax.plot([GEN_X[gi], GEN_X[gi + 1]],
                        [cy + OFF[pk], cy + o],
                        lw=lw, color=line, alpha=alpha,
                        ls=((0, (3, 3)) if mode == "ghost" else "-"), zorder=1)
    for gi, gx in enumerate(GEN_X):
        for k, o in enumerate(OFF):
            circ(ax, gx, cy + o, 0.62, fc=dot, ec="none", zorder=2)

    if mode == "ghost":                            # the sample you actually read
        for k in (1, 2):
            circ(ax, GEN_X[-1], cy + OFF[k], 0.62, fc=INK, ec="none", zorder=4)
            circ(ax, GEN_X[-1], cy + OFF[k], 1.25, fc="none", ec=INK, lw=1.2,
                 zorder=4)


def counts_only(ax, cy):
    """The census tier: a headcount today, and nothing else."""
    for gx in GEN_X[:4]:
        ax.text(gx, cy, "?", fontsize=18, color=GHOST, fontweight="bold",
                ha="center", va="center")
    r = 4.2
    circ(ax, GEN_X[-1], cy, r, fc=FAINT, ec=INK2, lw=1.3, zorder=1)
    golden = np.pi * (3 - np.sqrt(5))
    for i in range(9):
        rad = r * 0.60 * np.sqrt((i + 0.5) / 9)
        th  = i * golden
        circ(ax, GEN_X[-1] + rad * np.cos(th),
             cy + rad * np.sin(th) * ASP, 0.55, fc=INK2, ec="none", zorder=2)


def tick(ax, cx, cy, col):
    ax.plot([cx - 1.0, cx - 0.25, cx + 1.15],
            [cy - 0.3 * ASP, cy - 1.5 * ASP, cy + 1.6 * ASP],
            lw=2.6, color=col, solid_capstyle="round", zorder=4)


def cross(ax, cx, cy, col):
    for sx in (1, -1):
        ax.plot([cx - sx * 1.1, cx + sx * 1.1],
                [cy - 1.1 * ASP, cy + 1.1 * ASP],
                lw=2.6, color=col, solid_capstyle="round", zorder=4)


def dash(ax, cx, cy, col):
    ax.plot([cx - 1.2, cx + 1.2], [cy, cy], lw=2.6, color=col,
            solid_capstyle="round", zorder=4)


ROWS = [
    dict(tier="1", name="Census × ratio", note="the GBF indicator",
         draw=lambda ax, cy: counts_only(ax, cy),
         have="the past is unrecorded \u2014 a headcount today",
         how=r"$N_e = N_c \times 0.1$", how_sub="an assumed ratio",
         mark=dash, mcol=MUTED,
         verdict="Nothing genetic was measured",
         vsub="so there is nothing to check"),
    dict(tier="2", name="Genetic estimator", note="what field studies do",
         draw=lambda ax, cy: lattice(ax, cy, "ghost"),
         have="~10 genomes, one time point",
         how="invert a model", how_sub="LD  ·  temporal  ·  diversity",
         mark=cross, mcol=S2,
         verdict="No reference to check against",
         vsub="estimators disagree; nothing says which is right"),
    dict(tier="3", name="Simulation", note="what SLiM gives you",
         draw=lambda ax, cy: lattice(ax, cy, "full"),
         have="every individual, every generation",
         how="count coalescences", how_sub="read off the recorded genealogy",
         mark=tick, mcol=S3,
         verdict="The answer is known", vsub="so the estimator can be scored"),
]


def draw(stage, fname):
    fig, ax = plt.subplots(figsize=(W, H))
    ax.set_xlim(0, 100); ax.set_ylim(0, 100); ax.axis("off")

    for x, t, al in ((24.7, "What you have", "center"),
                     (54.0, "How $N_e$ is obtained", "center"),
                     (68.5, "Can you check it?", "left")):
        ax.text(x, 94.0, t, fontsize=14, fontweight="bold", color=INK,
                ha=al, va="center")
    ax.plot([1.5, 98.5], [90.0, 90.0], lw=1.2, color=GRID)

    for r, cy in zip(ROWS[:stage], BANDS[:stage]):
        circ(ax, 3.0, cy + 4.0, 1.8, fc=INK, ec="none", zorder=4)
        ax.text(3.0, cy + 4.0, r["tier"], fontsize=12.5, fontweight="bold",
                color=SURF, ha="center", va="center", zorder=5)
        ax.text(1.5, cy - 3.0, r["name"], fontsize=13, fontweight="bold",
                color=INK, ha="left", va="center")
        ax.text(1.5, cy - 8.0, r["note"], fontsize=11, color=MUTED,
                ha="left", va="center", style="italic")

        r["draw"](ax, cy)
        ax.text(24.7, cy - 13.5, r["have"], fontsize=12, color=INK2,
                ha="center", va="center")

        ax.add_patch(FancyArrowPatch((38.5, cy), (42.0, cy), mutation_scale=16,
                                     lw=1.8, color=MUTED, arrowstyle="-|>"))
        ax.add_patch(FancyBboxPatch((44.5, cy - 6.0), 19.0, 12.0,
                                    boxstyle="round,pad=0.6,rounding_size=1.6",
                                    fc=FAINT, ec=GRID, lw=1.3, zorder=1))
        ax.text(54.5, cy + 2.6, r["how"], fontsize=14.5, fontweight="bold",
                color=S1, ha="center", va="center", zorder=2)
        ax.text(54.5, cy - 3.2, r["how_sub"], fontsize=10.5, color=INK2,
                ha="center", va="center", zorder=2)

        r["mark"](ax, 70.5, cy + 1.0, r["mcol"])
        ax.text(74.0, cy + 2.8, r["verdict"], fontsize=13.5,
                fontweight="bold", color=r["mcol"], ha="left", va="center")
        ax.text(74.0, cy - 3.2, r["vsub"], fontsize=11, color=INK2,
                ha="left", va="center")

    fig.subplots_adjust(left=0.004, right=0.996, top=0.996, bottom=0.004)
    fig.savefig(os.path.join(OUT, fname), dpi=260, facecolor=SURF)
    plt.close(fig)
    print("wrote", fname)


for k in (1, 2, 3):
    draw(k, f"ne_tiers_build{k}.png")
