"""Batch coalescent-Ne extraction from many SLiM tree sequences.

Production counterpart to ts_ne_prototype.py. That script is the annotated
teaching version and prints a human-readable table for ONE run; this one
processes a whole directory and emits a single tidy CSV that joins to the
existing per-run result CSVs on treatment_id / replicate / seed.

Two ways to use it:

  1. Per SLURM task, immediately after SLiM, while the .trees file is still
     on fast scratch:
         py scripts/py/ts_ne_batch.py run.trees --out run_ne.csv

  2. As one aggregation pass over a finished experiment:
         py scripts/py/ts_ne_batch.py /scratch/wwalli/TMP/ramp_v1/trees \
             --out results/ramp_v1_experiment/ne_from_trees.csv

Ne definitions are explained at length in ts_ne_prototype.py. In short:
  Ne_pair   = 1 / (2 * pair coalescence rate) inside a time window.
              Robust to genealogies that have not fully coalesced. Use this.
  Ne_branch = branch-mode diversity / 4. Biased LOW when the genealogy has
              not coalesced, and slow to respond to recent change.
"""

import argparse
import csv
import glob
import os
import re
import sys
import traceback

import numpy as np
import tskit

POPULATION_NAMES = ["Geneva", "Bern", "Zurich", "St_Gallen"]

# grib_ramp_v1_strong_sel050_K500_rep_1_seed_6112001.trees
RUN_PATTERN = re.compile(
    r"^(?P<treatment_id>.+)_rep_(?P<replicate>\d+)_seed_(?P<seed>\d+)$"
)
TREATMENT_PATTERN = re.compile(
    r"_(?P<migration>weak|strong|decay)_sel(?P<selection>[0-9.]+)_K(?P<K>\d+)$"
)

OUTPUT_COLUMNS = [
    "run_id", "treatment_id", "replicate", "seed",
    "K", "selection_label", "migration_treatment",
    "cohort", "cohort_tick", "time_ago",
    "pop_id", "location", "census_N",
    "Ne_pair_window", "Ne_branch", "fraction_coalesced",
    "num_trees", "window_generations",
]


def parse_run_metadata(path):
    """Recover treatment/replicate/seed from the filename, so the Ne table
    joins to the existing result CSVs without extra bookkeeping."""
    stem = os.path.splitext(os.path.basename(path))[0]
    meta = {
        "run_id": stem, "treatment_id": "", "replicate": "",
        "seed": "", "K": "", "selection_label": "",
        "migration_treatment": "",
    }
    run_match = RUN_PATTERN.match(stem)
    if run_match:
        meta["treatment_id"] = run_match.group("treatment_id")
        meta["replicate"] = run_match.group("replicate")
        meta["seed"] = run_match.group("seed")
        treatment_match = TREATMENT_PATTERN.search(meta["treatment_id"])
        if treatment_match:
            meta["migration_treatment"] = treatment_match.group("migration")
            meta["selection_label"] = "sel" + treatment_match.group(
                "selection")
            meta["K"] = treatment_match.group("K")
    return meta


def population_label(pop_id):
    if pop_id < len(POPULATION_NAMES):
        return POPULATION_NAMES[pop_id]
    return f"p{pop_id}"


def analyse_tree_sequence(path, window, neutral_start):
    """Yield one row per (cohort x deme) for a single .trees file."""
    ts = tskit.load(path)
    meta = parse_run_metadata(path)
    final_tick = ts.metadata["SLiM"]["tick"]

    # If the model wrote an unlinked neutral block, measure Ne there; a
    # genome without one is measured whole. tskit requires genome windows to
    # be a full partition [0, ..., L], so the block is selected by index
    # rather than by passing a bare interval.
    if (neutral_start is not None
            and 0 < neutral_start < ts.sequence_length):
        genome_windows = [
            0.0, float(neutral_start), float(ts.sequence_length)]
        block = 1
    else:
        genome_windows = [0.0, float(ts.sequence_length)]
        block = 0

    individuals_time = ts.individuals_time
    individuals_population = ts.individuals_population
    cohort_times = np.unique(individuals_time)[::-1]

    for cohort_index, time_ago in enumerate(cohort_times):
        # Cohort 0 is the most recent (the end of the run); the oldest
        # remembered cohort is the pre-climate predictor.
        cohort_name = "final" if time_ago == 0 else f"remembered_{cohort_index}"

        for pop_id in range(ts.num_populations):
            selected = np.where(
                (individuals_time == time_ago)
                & (individuals_population == pop_id)
            )[0]
            census_n = len(selected)

            row = dict(meta)
            row.update({
                "cohort": cohort_name,
                "cohort_tick": int(final_tick - time_ago),
                "time_ago": float(time_ago),
                "pop_id": pop_id,
                "location": population_label(pop_id),
                "census_N": census_n,
                "num_trees": ts.num_trees,
                "window_generations": window,
                "Ne_pair_window": "",
                "Ne_branch": "",
                "fraction_coalesced": "",
            })

            # A deme that has gone extinct, or is down to a single
            # individual, has no pair of lineages to coalesce.
            if census_n >= 2:
                nodes = np.concatenate(
                    [ts.individual(i).nodes for i in selected]
                ).astype(np.int32)

                edges = np.array([time_ago, time_ago + window, np.inf])
                # shape: (genome windows, time windows)
                rates = np.asarray(ts.pair_coalescence_rates(
                    time_windows=edges,
                    sample_sets=[nodes],
                    windows=genome_windows,
                ))
                rate = rates[block, 0]
                row["Ne_pair_window"] = (
                    float(1.0 / (2.0 * rate)) if rate > 0 else ""
                )

                # shape: (genome windows, sample sets)
                diversity = np.asarray(ts.diversity(
                    sample_sets=[nodes], mode="branch",
                    windows=genome_windows,
                ))
                row["Ne_branch"] = float(diversity[block, 0] / 4.0)

                simplified = ts.simplify(
                    samples=nodes, filter_populations=False)
                spans = np.array([t.span for t in simplified.trees()])
                roots = np.array([t.num_roots for t in simplified.trees()])
                row["fraction_coalesced"] = float(
                    spans[roots == 1].sum() / spans.sum())

            yield row


def collect_paths(targets):
    paths = []
    for target in targets:
        if os.path.isdir(target):
            paths.extend(sorted(glob.glob(os.path.join(target, "*.trees"))))
        else:
            expanded = sorted(glob.glob(target))
            paths.extend(expanded if expanded else [target])
    return paths


def main():
    parser = argparse.ArgumentParser(
        description="Coalescent Ne from many SLiM tree sequences."
    )
    parser.add_argument(
        "targets", nargs="+",
        help="directories, globs, or .trees files",
    )
    parser.add_argument(
        "--out", required=True, help="output CSV path")
    parser.add_argument(
        "--window", type=float, default=100.0,
        help="generations before each cohort used for Ne (default: 100)")
    parser.add_argument(
        "--neutral-start", type=float, default=None,
        help="start coordinate of an unlinked neutral block; omit for a "
             "single-block genome such as the production model")
    args = parser.parse_args()

    paths = collect_paths(args.targets)
    if not paths:
        sys.exit(f"No .trees files matched: {args.targets}")

    output_directory = os.path.dirname(os.path.abspath(args.out))
    if output_directory:
        os.makedirs(output_directory, exist_ok=True)

    processed = 0
    failed = []
    with open(args.out, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=OUTPUT_COLUMNS)
        writer.writeheader()

        for path in paths:
            try:
                for row in analyse_tree_sequence(
                    path, args.window, args.neutral_start
                ):
                    writer.writerow(row)
                processed += 1
            except Exception:
                # One corrupt or truncated file must not abandon the batch.
                failed.append(path)
                print(f"FAILED {path}", file=sys.stderr)
                traceback.print_exc(file=sys.stderr)

    print(f"processed {processed}/{len(paths)} tree sequences -> {args.out}")
    if failed:
        print(f"{len(failed)} failed:", file=sys.stderr)
        for path in failed:
            print(f"  {path}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
