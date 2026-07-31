# Four-deme effective-population-size experiment

This experiment tests whether effective population size immediately before
observed climate change predicts population size or extinction in 2025.

## Demes

Population order is fixed across every climate file, migration file, script,
and output:

1. `p0`: Geneva
2. `p1`: Bern
3. `p2`: Zurich
4. `p3`: St. Gallen

## Experimental design

The 12 treatments form a complete factorial design:

- carrying capacity from tick 1: `500`, `2000`, `5000`;
- total emigration probability per source deme: weak `0.0001`, strong `0.020`;
- climate-selection strength: `0.050`, `0.075`.

Migration is deliberately not distance-weighted in this simplified
experiment. Conditional on migrating, an individual has an equal probability
of entering each of the other three demes. Every matrix row has the same fixed
total, so adding destinations does not increase total emigration. The strong
treatment has 200 times the per-generation migration probability of the weak
treatment.

The shared temperature-to-allele calibration is held constant:

- 10.3914 degrees C corresponds to an optimum of 2 `m2` copies;
- 13.9782 degrees C corresponds to an optimum of 6 `m2` copies.

## Simulation phases

- ticks 1-1999: V2.3-style ramp toward each deme's 1940-1970 mean;
- ticks 2000-3999: adaptation at each historical mean;
- tick 4000: observed climate begins with 1970;
- ticks 4000-4055: observed annual climate for 1970-2025;
- tick 4055: simulation ends; there is no post-2025 hold.

The year 1970 occurs in both the historical baseline and observed record,
matching the established model.

## Effective-size outputs

`Ne_fecundity_preMigration` is calculated before offspring migrate and before
viability selection. It estimates the effective number of the previous
generation's locally breeding adults based on variance in offspring number.
It is a fecundity effective size, not a complete post-selection genetic
effective size.

The breeder cohorts from ticks 3900-3999 are summarized with:

- `Ne_fecundity_preClimate100_arithmetic`;
- `Ne_fecundity_preClimate100_harmonic`.

The harmonic mean is the preferred multigeneration summary. Mean realized
census size over the same 100 ticks is reported as `mean_N_preClimate100`.

`Ne_heterozygosity_proxy` is calculated from neutral `m1` diversity:

```text
Ne_pi = neutral_pi / (4 * 0.99e-7)
```

This is deliberately labeled a proxy. Migration, linkage to selected `m2`
mutations, and lack of full mutation-drift equilibrium mean it should not be
treated as an unbiased absolute estimate of effective size. The raw neutral
heterozygosity is also retained for PM/GBF comparisons.

## Parameterized model

The working implementation is now one SLiM source file:

```text
grib_4pop_ne_ramp_parameterized.slim
```

Its command-line treatment parameters are:

- `K`: carrying capacity from tick 1;
- `SELECTION_STRENGTH`: coefficient in
  `fitness = 1 - selection_strength * lag^2`;
- `MIGRATION_CODE`: `0` for weak or `1` for strong migration;
- `REP`: replicate identifier;
- `PROJECT_ROOT`: location of the `SLiM` project;
- `RESULTS_DIR`: directory receiving the run CSV.

`MIGRATION_CODE` selects the migration label, total rate, and matrix together,
preventing incompatible combinations. The model derives its treatment ID and
writes:

```text
<treatment_id>_rep_<replicate>_seed_<seed>.csv
```

Defaults allow the model to run directly on the Windows development machine.
The shell runners supply the Linux project and output paths on the cluster.

The 12 standalone `.slim` treatment files and their treatment manifest are
retained as the validated pre-parameterization archive. They are not used by
the new runners. The former R template-expansion workflow in script 11 is
therefore retired.

## Rebuilding environmental inputs

Run these scripts when the climate locations or migration construction change:

```powershell
Rscript scripts/R/9_grib_climate_matrix_4pop_degrees_c_1940_2025.R
Rscript scripts/R/10_grib_migration_matrix_4pop_distance_treatments.R
```

## Trial runs

From the Linux cluster, two sequential replicates for every treatment can be
run with:

```bash
cd /home/wwalli/msc_workspace/SLiM
bash scripts/SLURM/run_4pop_ne_trials.sh 2
```

This makes `12 x 2 = 24` runs. Trial results default to:

```text
/scratch/wwalli/TMP/4pop_ne_trial/
```

The trial runner first creates a TSV run manifest, then executes each manifest
row sequentially through the same worker used by SLURM.

## SLURM array

Submit 20 replicates per treatment with:

```bash
cd /home/wwalli/msc_workspace/SLiM
bash scripts/SLURM/submit_4pop_ne_array.sh 20
```

This submits `12 x 20 = 240` array tasks. Each task runs one independent SLiM
process. Seeds are deterministic and globally unique across treatments and
replicates. The exact manifest is retained under:

```text
/scratch/wwalli/TMP/4pop_ne/manifests/
```

Useful submission overrides include:

```bash
MAX_CONCURRENT=6 TIME_LIMIT=1-00:00:00 MEMORY=8G \
  bash scripts/SLURM/submit_4pop_ne_array.sh 20
```

Each run writes a unique CSV using its treatment ID and random seed under:

```text
/scratch/wwalli/TMP/4pop_ne/csv/
```

Console logs and SLURM scheduler logs are separated from the biological CSVs.

## Analysis

To analyze the scratch CSVs directly on Linux:

```bash
cd /home/wwalli/msc_workspace/SLiM
FOURPOP_NE_RESULTS_DIR=/scratch/wwalli/TMP/4pop_ne/csv \
  Rscript scripts/R/12_analyze_4pop_ne_outputs.R
```

Alternatively, copy completed CSVs to
`SLiM/results/4pop_ne_experiment/` on the development machine and run:

```powershell
Rscript scripts/R/12_analyze_4pop_ne_outputs.R
```

`FOURPOP_NE_RESULTS_DIR` changes the input directory.
`FOURPOP_NE_ANALYSIS_DIR` can independently redirect the analysis products.

This combines tick-level results and creates one summary row per
treatment x replicate x seed x deme. Legacy pilot outputs without a replicate
column remain readable and receive a missing replicate identifier.
