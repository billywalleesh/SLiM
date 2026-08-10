"""Compute true (coalescent) Ne per deme from a SLiM tree sequence.

Companion to scripts/SLiM/prototype_ts_ne/ramp_v1_treeseq_prototype.slim.

Why two estimators are reported
-------------------------------
The obvious estimator is branch-mode diversity: for a diploid population
E[T2] = 2*Ne, and tskit's branch-mode diversity is the mean total branch
length separating two samples, which is 2*E[T2]. So Ne = diversity / 4.

That is exact ONLY if the genealogy has fully coalesced. In this metapopulation
it has not: a few immigrant-descended lineages never find a common ancestor
inside the simulated period, so the deep parts of the tree are missing and the
branch estimate is biased LOW. The script reports the coalesced fraction so you
can see how much to distrust it.

The estimator to actually use is the pair coalescence rate within a time
window. For a diploid population the pair coalescence rate is 1/(2*Ne), so
Ne = 1 / (2 * rate). It only counts coalescences that really happened inside
the window, so uncoalesced lineages simply do not contribute instead of
silently truncating the answer. It also gives Ne as a function of time.

Usage
-----
    py scripts/py/ts_ne_prototype.py path/to/run.trees
    py scripts/py/ts_ne_prototype.py path/to/run.trees --window 200
"""

import argparse
import os

import numpy as np
import tskit

# Matches the deme order used throughout the SLiM models.
POPULATION_NAMES = ["Geneva", "Bern", "Zurich", "St_Gallen"]

# Genome layout in the prototype model: a selected block, then an UNLINKED
# neutral block. Comparing Ne between them shows the cost of linked selection.
SELECTED_BLOCK = (0, 100_000)
NEUTRAL_BLOCK = (100_000, 200_000)


def population_label(pop_id):
    if pop_id < len(POPULATION_NAMES):
        return POPULATION_NAMES[pop_id]
    return f"p{pop_id}"


def cohort_nodes(ts, time_ago, pop_id):
    """Sample nodes of individuals alive at `time_ago` in deme `pop_id`."""
    individuals = np.where(
        (ts.individuals_time == time_ago)
        & (ts.individuals_population == pop_id)
    )[0]
    if len(individuals) == 0:
        return individuals, np.array([], dtype=np.int32)
    nodes = np.concatenate([ts.individual(i).nodes for i in individuals])
    return individuals, nodes.astype(np.int32)


def coalesced_fraction(ts, nodes):
    """Span-weighted fraction of the genome whose tree has a single root."""
    sub = ts.simplify(samples=nodes, filter_populations=False)
    spans = np.array([tree.span for tree in sub.trees()])
    roots = np.array([tree.num_roots for tree in sub.trees()])
    return float(spans[roots == 1].sum() / spans.sum())


def branch_ne(ts, nodes):
    """Ne from branch-mode diversity, per genomic block. Biased low if the
    genealogy is not fully coalesced."""
    diversity = ts.diversity(
        sample_sets=[nodes],
        mode="branch",
        windows=[SELECTED_BLOCK[0], NEUTRAL_BLOCK[0], NEUTRAL_BLOCK[1]],
    )
    values = np.asarray(diversity).reshape(-1)
    return values[0] / 4.0, values[1] / 4.0


def pair_ne(ts, nodes, time_edges, per_block=False):
    """Ne = 1 / (2 * pair coalescence rate) within each time window."""
    kwargs = {"time_windows": time_edges, "sample_sets": [nodes]}
    if per_block:
        kwargs["windows"] = [
            SELECTED_BLOCK[0], NEUTRAL_BLOCK[0], NEUTRAL_BLOCK[1]
        ]
    rates = np.asarray(ts.pair_coalescence_rates(**kwargs))
    with np.errstate(divide="ignore", invalid="ignore"):
        ne = np.where(rates > 0, 1.0 / (2.0 * rates), np.inf)
    return ne


def main():
    parser = argparse.ArgumentParser(
        description="Coalescent Ne per deme from a SLiM tree sequence."
    )
    parser.add_argument("trees", help="path to the .trees file")
    parser.add_argument(
        "--window",
        type=float,
        default=100.0,
        help="generations before each cohort used for its headline Ne "
             "(default: 100)",
    )
    parser.add_argument(
        "--out-prefix",
        default=None,
        help="write summary and trajectory CSVs with this prefix "
             "(default: alongside the .trees file)",
    )
    args = parser.parse_args()

    ts = tskit.load(args.trees)
    final_tick = ts.metadata["SLiM"]["tick"]
    # Founders were created fresh at tick 1, so nothing can coalesce beyond
    # this. Any window reaching past it is meaningless.
    oldest_meaningful = final_tick - 1

    cohort_times = np.unique(ts.individuals_time)[::-1]

    print(f"file:        {os.path.basename(args.trees)}")
    print(f"final tick:  {final_tick}")
    print(f"trees:       {ts.num_trees}, "
          f"sequence length: {int(ts.sequence_length)}")
    print(f"cohorts (ticks ago): {[float(t) for t in cohort_times]}")
    print()

    summary_rows = []
    trajectory_rows = []

    for time_ago in cohort_times:
        cohort_tick = int(final_tick - time_ago)
        print(f"=== cohort at tick {cohort_tick} "
              f"({time_ago:.0f} generations ago) ===")
        print(f"{'deme':<11}{'N':>6}{'Ne_pair':>10}{'Ne_sel':>9}"
              f"{'Ne_neut':>9}{'Ne_branch':>11}{'coal':>8}")

        for pop_id in range(ts.num_populations):
            individuals, nodes = cohort_nodes(ts, time_ago, pop_id)
            census_n = len(individuals)
            if census_n < 2:
                print(f"{population_label(pop_id):<11}{census_n:>6}"
                      f"{'--':>10}{'--':>9}{'--':>9}{'--':>11}{'--':>8}")
                continue

            # Headline Ne: one window of `--window` generations immediately
            # preceding this cohort.
            edges = np.array([time_ago, time_ago + args.window, np.inf])
            headline = pair_ne(ts, nodes, edges)[0]
            per_block = pair_ne(ts, nodes, edges, per_block=True)
            ne_selected = np.asarray(per_block)[0, 0]
            ne_neutral = np.asarray(per_block)[1, 0]

            branch_selected, branch_neutral = branch_ne(ts, nodes)
            coalesced = coalesced_fraction(ts, nodes)

            print(f"{population_label(pop_id):<11}{census_n:>6}"
                  f"{headline:>10.1f}{ne_selected:>9.1f}{ne_neutral:>9.1f}"
                  f"{branch_neutral:>11.1f}{coalesced:>7.0%}")

            summary_rows.append({
                "cohort_tick": cohort_tick,
                "time_ago": float(time_ago),
                "pop_id": pop_id,
                "location": population_label(pop_id),
                "census_N": census_n,
                "Ne_pair_window": float(headline),
                "Ne_pair_selected_block": float(ne_selected),
                "Ne_pair_neutral_block": float(ne_neutral),
                "Ne_branch_selected_block": float(branch_selected),
                "Ne_branch_neutral_block": float(branch_neutral),
                "fraction_coalesced": coalesced,
                "window_generations": args.window,
            })

            # Coarse Ne(t) trajectory going back from this cohort.
            steps = [0, 50, 100, 200, 400, 800, 1600]
            traj_edges = np.array(
                [time_ago + s for s in steps] + [np.inf]
            )
            traj = pair_ne(ts, nodes, traj_edges)
            for i in range(len(steps)):
                start, end = traj_edges[i], traj_edges[i + 1]
                trajectory_rows.append({
                    "cohort_tick": cohort_tick,
                    "pop_id": pop_id,
                    "location": population_label(pop_id),
                    "window_start_ago": float(start),
                    "window_end_ago": float(end),
                    "Ne": float(traj[i]),
                    # Founders at tick 1 are unrelated, so any window
                    # reaching past them mixes real coalescence with
                    # lineages that simply ran out of simulation.
                    "beyond_simulation_start":
                        bool(end > oldest_meaningful),
                })
        print()

    print("Ne_pair    = 1/(2*pair coalescence rate) over the "
          f"{args.window:.0f} generations before the cohort  <-- use this")
    print("Ne_sel/neut= same, split by selected vs unlinked neutral block")
    print("Ne_branch  = branch-diversity/4 on the neutral block; "
          "biased LOW unless coal is near 100%")
    print("coal       = fraction of the genome whose tree fully coalesced")

    prefix = args.out_prefix or os.path.splitext(args.trees)[0]
    write_csv(f"{prefix}_ne_summary.csv", summary_rows)
    write_csv(f"{prefix}_ne_trajectory.csv", trajectory_rows)
    print()
    print(f"wrote {prefix}_ne_summary.csv")
    print(f"wrote {prefix}_ne_trajectory.csv")


def write_csv(path, rows):
    if not rows:
        return
    columns = list(rows[0].keys())
    with open(path, "w", encoding="utf-8", newline="") as handle:
        handle.write(",".join(columns) + "\n")
        for row in rows:
            handle.write(
                ",".join(str(row[column]) for column in columns) + "\n"
            )


if __name__ == "__main__":
    main()
