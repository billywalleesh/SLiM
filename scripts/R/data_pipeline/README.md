# data pipeline (in run order)

These are copies of the original scripts in scripts/R, renamed so they sort in the order they are run.
The originals are still in scripts/R under their old numbers. Every script uses absolute paths, so it
does not matter which folder it sits in.

| script | was | what it does |
|---|---|---|
| 01_climate_matrix_8pop.R | 35_grib_climate_matrix_8pop_degrees_c_1940_2025.R | 8-city climate matrix (1940 to 2025) from the ERA5 GRIB file |
| 02_batch_matrix_creation.R | 33_batch_matrix_creation.R | random 1000-run matrix (K, cities, selection, migration slope, disturbance) |
| 03_migration_matrix_creation.R | 34_migration_matrix_creation.R | one migration matrix per run, from city distances and the run's slope |
| 04_climate_matrix_creation.R | 36_climate_matrix_creation.R | one climate matrix per run, for the run's cities |
| (cluster) | | run_repo_<date>/run_array_burnin50k.sh runs ramp_v1.3.1_burnin50k.slim once per row |
| 05_combine_results.R | 37.1_combine_burnin50k_results.R | logs -> run_results (one row per run: Ne indicators, extinct, any_pop_extinct, run settings) |
| 06_build_run_summary.R | 42_build_run_summary.R | run_results + logs -> run_summary (census N, Ne, % kept, % K occupied) |

## batches

| batch | run matrix seed | inputs | results |
|---|---|---|---|
| 1 | 14102026 | input/.../run_repo_14102026/14102026/ | results/ramp_v1.3.1_burnin50k/ |
| 2 | 20112026 | input/.../run_repo_20112026/ | results/ramp_v1.3.1_burnin50k_20112026/ |

Batch 1: selection 0.01 to 0.1, slope_min -0.001/50. Batch 2: selection 0.05 to 0.15, slope_min -0.001/25.
Same model (ramp_v1.3.1_burnin50k.slim) in both.

## notes

- 02, 03 and 04 setwd() into the run repo folder and write there. Check the setwd line points to the
  right batch before running, or they overwrite that batch's inputs.
- 03 writes every 0 as 0.0: SLiM's readCSV reads an all-zero column as integer and asMatrix() then fails
  (an isolated population gives an all-zero column; this crashed run 94 of batch 2 before the fix).
- 05 and 06 currently point to batch 1 (results/ramp_v1.3.1_burnin50k). Change log_folder,
  run_matrix_file and the output file names for batch 2.
- 05 still has the old batch 1 run matrix path (run_repo/14102026/). That folder is now
  run_repo_14102026/14102026/.
- extinct (from 05) means the whole metapopulation is gone: every population of the run has N = 0 at the end.
  Changed 25.11.2026. The old meaning (at least one population gone) is kept as any_pop_extinct.
