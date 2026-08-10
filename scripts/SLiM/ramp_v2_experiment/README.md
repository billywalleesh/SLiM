# ramp_v2: a tree-sequence-friendly genome

v2 exists for one reason: **v1's genome cannot support a reliable Ne estimate.**

Everything about the biology is unchanged from `ramp_v1` — same demography,
same climate series, same migration matrices, same selection, same phase
timings (ramp to tick 2000, historical hold to 4000, observed climate to
4055). Only the genome differs.

## Why v1's genome is the problem

v1 uses `r = 1e-8` over a 100 kb genome. That is `1e-3` crossovers per
meiosis: roughly one recombination event per thousand meioses. The whole
genome therefore behaves as a **single non-recombining locus**.

Measured on real runs:

| | v1 | v2 |
|---|---|---|
| distinct trees per run | **54** | **~11,900** |
| tree sequence size | 0.9 MB | 2.8 MB |
| run time (K=500) | 19 s | 45 s |

Ne read off 54 highly correlated genealogies is noisy, and every
diversity-based measure is dominated by linked selection rather than drift.

## What v2 changes

**1. Two blocks, unlinked.**

```
position:  0 ─────────── 99,999 │ 100,000 ─────────── 199,999
           [ SELECTED: m2 only ] │ [ NEUTRAL: no mutations ]
                            r = 0.5
```

The neutral block records genealogy free of linked selection. Comparing Ne
between the two blocks measures what selection costs.

**2. Recombination raised to `1e-6` per bp** (`RECOMBINATION_RATE`). A 100 kb
block at 1e-6 behaves like ~10 Mb at a realistic 1e-8.

**3. No neutral mutations are simulated.** The genealogy already carries the
neutral information, and mutations can be overlaid afterwards with msprime
(`scripts/py/ts_overlay.py`). The m2 supply is held **exactly equal to v1's**:
v1 drew mutations at `1e-7` and made 1% of them m2, giving `1e-9` per bp; v2
draws m2 directly at `1e-9` over a selected block of the same 100 kb.

### This is a new experiment, not a re-run

Freer recombination means less interference between selected sites, so v2
adapts somewhat more efficiently than v1. v2 results are **not** drop-in
replacements for v1 results. Compare v2 to v2.

## Nothing collides with v1

| | ramp_v1 | ramp_v2 |
|---|---|---|
| treatment ID prefix | `grib_ramp_v1_` | `grib_ramp_v2_` |
| seed base | 6000000 | 7000000 |
| scratch output | `/scratch/wwalli/TMP/ramp_v1` | `/scratch/wwalli/TMP/ramp_v2` |
| local results | `results/ramp_v1_experiment` | `results/ramp_v2_experiment` |

Note that **re-running either experiment overwrites its own previous output**.
Seeds are deterministic functions of the parameter grid, so the same treatment
and replicate always produce the same filename, and the model truncates on
write. Only the grid manifests are timestamped. To keep an earlier set, move it
aside or pass a different `OUTBASE` before resubmitting.

## Design

Identical to `ramp_v1`: 12 treatments, a complete factorial of

- carrying capacity: `500`, `2000`, `5000`
- climate-selection strength: `0.050`, `0.075`
- migration: `weak`, `strong`

Distance-decay migration (`MIGRATION_CODE=2`) remains selectable but is not
swept; add `2` to `migration_codes` in `make_ramp_v2_parameter_grid.sh` to
include it.

## Running it

Trial, one task at a time:

```bash
cd /home/wwalli/msc_workspace/SLiM
TASK_ID=1 bash scripts/SLURM/run_ramp_v2_array.sh
```

Full array (12 treatments x 20 replicates = 240 tasks):

```bash
cd /home/wwalli/msc_workspace/SLiM
bash scripts/SLURM/submit_ramp_v2_array.sh 20
```

Tree-sequence recording is **on by default** in v2. Each task writes:

```
/scratch/wwalli/TMP/ramp_v2/
    csv/     per-run tick-level results
    trees/   tree sequences        (~2.8 MB each, ~670 MB for 240 runs)
    ne/      per-run Ne table      (~2 KB each)
    logs/    console output
    slurm/   scheduler output
```

Ne is extracted inside each array task, so it parallelises with the array
rather than becoming a serial pass afterwards. Set `EXTRACT_NE=0` to skip it
and do the extraction later.

## Ne extraction

Per run, automatically. Or over a finished experiment:

```bash
python scripts/py/ts_ne_batch.py /scratch/wwalli/TMP/ramp_v2/trees \
    --out results/ramp_v2_experiment/ne_from_trees.csv \
    --neutral-start 100000
```

`--neutral-start 100000` is required for v2 — it tells the script to measure
Ne on the unlinked neutral block. Omit it for a single-block genome such as
v1's.

Output joins to the run CSVs on `treatment_id` / `replicate` / `seed`, with one
row per cohort x deme. Two cohorts are recorded: the **pre-climate predictor**
(tick 3999, permanently remembered) and the **final state** (tick 4055).

Columns worth knowing:

- `Ne_pair_window` — `1 / (2 x pair coalescence rate)` over the 100 generations
  before the cohort. **Use this one.** Robust to genealogies that have not
  fully coalesced, and responds quickly to recent change.
- `Ne_branch` — branch diversity / 4. Biased low when `fraction_coalesced` is
  well under 1, and inherently slow: it integrates over the whole past, so it
  keeps reporting a healthy Ne long after a population has crashed.
- `fraction_coalesced` — how much of the genome fully coalesced. Your warning
  light for `Ne_branch`.

See `scripts/py/ts_ne_prototype.py` for the annotated derivation of both.

## Expected precision

From four replicates of one v1 treatment, per-run Ne had a coefficient of
variation of about 15%. With 20 replicates that puts the standard error on a
treatment mean near 3-4%: fine for comparing treatments, not for interpreting
any individual run.

## An interpretation trap

Under **strong** migration, measured per-deme Ne came out at 2.3-2.8 times
local census N. That is not an error. With roughly 10 immigrants per deme per
generation, lineages traced backwards keep leaving the deme before they can
coalesce locally, so "per-deme Ne" is really reporting the metapopulation.

Per-deme Ne only means what it sounds like under **weak** migration. Say which
one you mean when writing this up.

## Python requirement

Ne extraction needs `tskit` (and `numpy`). Check the cluster environment
before submitting:

```bash
/home/wwalli/conda/envs/msc_env/bin/python -c "import tskit; print(tskit.__version__)"
```

If it is missing, `EXTRACT_NE=0` still collects every `.trees` file for later
processing. A failed extraction never fails the array task or deletes a tree
sequence.
