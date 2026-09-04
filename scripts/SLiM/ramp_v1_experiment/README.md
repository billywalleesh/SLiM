# Parameterized ramp v1 experiment

This is the parameterized form of the original
`grib_pop_index_local_adaptation_ramp_v1` model, wired into the same structured
run workflow used by the four-deme Ne experiment: one parameterized SLiM source
file, a deterministic parameter grid, and a SLURM array runner.

The biology is unchanged from v1. Only the treatment values, the output format,
and the run infrastructure are new.

## Demes

Population order is fixed across every climate file, migration file, script, and
output:

1. `p0`: Geneva
2. `p1`: Bern
3. `p2`: Zurich
4. `p3`: St. Gallen

## Temperature-to-allele scale

Unlike the four-deme Ne experiment, which freezes its calibration anchors, this
model derives the scale from the loaded climate data, exactly as v1 did:

- the coldest 1940-1970 baseline mean corresponds to 2 `m2` copies;
- the warmest temperature of the final observed year corresponds to 6 `m2` copies.

With the current 1940-2025 four-deme climate file this resolves to
10.3914 C = 2 copies (St. Gallen baseline) and 14.5249 C = 6 copies
(Geneva in 2025). Every population therefore starts near the bottom of the scale
and must track its own final optimum.

## Simulation phases

- ticks 1-1999: ramp toward each deme's 1940-1970 mean;
- ticks 2000-3999: adaptation at each historical mean;
- tick 4000: observed climate begins with 1970;
- ticks 4000-4055: observed annual climate for 1970-2025;
- tick 4055: simulation ends.

The year 1970 occurs in both the historical baseline and the observed record.

## Experimental design

The 12 treatments form a complete factorial design:

- carrying capacity from tick 1: `500`, `2000`, `5000`;
- climate-selection strength: `0.050`, `0.075`;
- migration treatment: `weak`, `strong`.

The `weak` and `strong` matrices are the flat, equal-destination matrices shared
with the four-deme Ne experiment, with fixed row totals of `0.0001` and `0.020`.

The distance-decay matrix that v1 originally used is still selectable as
`MIGRATION_CODE=2`, but it is deliberately not part of this design. To sweep it,
add `2` to `migration_codes` in `make_ramp_v1_parameter_grid.sh`. Because decay
is distance-weighted its row totals differ between demes (0.012 to 0.014), so
the model enforces only the per-row probability bound rather than a single fixed
total; the mean row total is recorded in each output row as
`mean_total_migration_rate`.

## Parameterized model

```text
scripts/SLiM/grib_pop_index_local_adaptation_ramp_parameterized.slim
```

Command-line treatment parameters:

- `K`: carrying capacity from tick 1;
- `SELECTION_STRENGTH`: coefficient in
  `fitness = 1 - selection_strength * lag^2`;
- `MIGRATION_CODE`: `0` for weak, `1` for strong, `2` for distance decay;
- `REP`: replicate identifier;
- `PROJECT_ROOT`: location of the `SLiM` project;
- `RESULTS_DIR`: directory receiving the run CSV.

`MIGRATION_CODE` selects the migration label and matrix together, preventing
incompatible combinations. The model derives its treatment ID and writes:

```text
<treatment_id>_rep_<replicate>_seed_<seed>.csv
```

Running with no `-d` arguments reproduces the original v1 configuration
(`K=500`, selection `0.05`, distance-decay migration) on the Windows development
machine. The results directory is created if it does not already exist. The
shell runners supply the Linux project and output paths on the cluster.

A single local run:

```bash
slim -s 6112001 -d K=500 -d SELECTION_STRENGTH=0.05 -d MIGRATION_CODE=2 -d REP=1 \
  scripts/SLiM/grib_pop_index_local_adaptation_ramp_parameterized.slim
```

## Output

One tidy CSV per run, one row per reported tick per deme. Rows are written every
100 ticks during the ramp and historical phases, then every tick from tick 4000
onward. Columns cover the treatment identifiers plus `N`, `temperature`,
`allele_optimum`, `mean_phenotype`, `phenotype_sd`, `phenotype_lag`,
`mean_climate_fitness`, `migrants_received`, and `extinct`.

This experiment does not record effective population size; use the four-deme Ne
experiment for `Ne` predictors.

## SLURM array

Submit 10 replicates per treatment with:

```bash
cd /home/wwalli/msc_workspace/SLiM
bash scripts/SLURM/submit_ramp_v1_array.sh 10
```

This submits `12 x 10 = 120` array tasks. Each task runs one independent SLiM
process. Seeds are deterministic and globally unique across treatments and
replicates, and use a `6000000` base that keeps them disjoint from the four-deme
Ne experiment's `5000000` seeds. The exact manifest is retained under:

```text
/scratch/wwalli/TMP/ramp_v1/manifests/
```

Useful submission overrides:

```bash
MAX_CONCURRENT=6 TIME_LIMIT=1-00:00:00 MEMORY=8G \
  bash scripts/SLURM/submit_ramp_v1_array.sh 10
```

Each run writes a unique CSV under `/scratch/wwalli/TMP/ramp_v1/csv/`, with
console logs in `logs/` and SLURM scheduler logs in `slurm/`.

To build a grid without submitting it, or to run one task directly:

```bash
bash scripts/SLURM/make_ramp_v1_parameter_grid.sh 5
TASK_ID=1 bash scripts/SLURM/run_ramp_v1_array.sh
```

## Rebuilding environmental inputs

Run these when the climate locations or migration construction change:

```powershell
Rscript scripts/R/9_grib_climate_matrix_4pop_degrees_c_1940_2025.R
Rscript scripts/R/10_grib_migration_matrix_4pop_distance_treatments.R
```
