# figure creation

Scripts that make figures from the cluster results. They only read the logs and summary files,
nothing in the results folders is changed. Every script uses absolute paths and writes its pictures
to figure_creation/output/<script number>_<name>_<batch>/.

| script | was | figure | batch |
|---|---|---|---|
| 01_census_N_year_by_year.R | 47_plot_census_N_year_by_year.R (batch 1) | census size of every run from Pre-Dist (tick 53999) and 1970 to 2025, mean over runs, runs below 500 in 2025 in black, dashed line at 500 | 2 (20112026) |
| 02_census_N_both_batches.R | 01 (minimal version) | census size for both batches in one picture, from Pre-Dist and from 1970 to 2025: mean over runs (line) and middle 50% of runs (band) per batch, dashed line at 500 | 1 (14102026) and 2 (20112026) |

## notes

- To make a figure for another batch, change log_folder, summary_file and output_dir at the top of the script.
- 01 and 02 check their numbers against the batch's run_summary file if it exists (made by data_pipeline/06_build_run_summary.R);
  without it the check is skipped and the figures are still made.
- Runs where every population died before 2025 stop early in the logs; their missing years count as 0.
