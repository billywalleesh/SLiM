# Disturbance experiment (cull module, v1.2)

Model: `scripts/SLiM/disturbance/grib_ramp_v1.2_disturbance.slim`

## Design

- 76 disturbance scenarios (`disturbance_scenarios.csv`): control; every set of
  populations (15) x 5 severities (halve, severe, bottleneck, destroy with and
  without recolonisation, minus "destroy all 4"); 2 west-east gradients.
  Each scenario gives every population `survive` (fraction of individuals left)
  and `habitat` (fraction of K left).
- x K 500 / 1000 / 5000 x migration weak / strong x selection 0.025 / 0.05
  x 10 replicates = **9,120 runs** (`run_grid.csv`, one row per run).
- All 76 scenarios of one setting and replicate share a seed, so they are
  identical up to the disturbance (matched controls).
- Disturbance 1 generation before climate change (tick 7999).

Both CSVs are in `input/grib_pop_index_local_adaptation/disturbance_experiment/`
and are made by `scripts/R/29_disturbance_experiment_design.R` (change K levels,
selection, replicates there and rerun it).

## Running on the cluster

```bash
cd /home/wwalli/msc_workspace/SLiM
git pull

# 1. pilot: all 76 scenarios of one setting (K 500), ~2 min each
bash scripts/SLURM/submit_disturbance_array.sh 1 76
bash scripts/SLURM/check_disturbance_runs.sh 1 76

# 2. everything (jobs that are already done are skipped)
bash scripts/SLURM/submit_disturbance_array.sh

# 3. progress / what is missing
squeue -u $USER
bash scripts/SLURM/check_disturbance_runs.sh

# 4. resubmit what is missing (once nothing is queued or running)
JOB_LIST_FILE=/scratch/wwalli/TMP/disturbance/manifests/missing.txt \
  bash scripts/SLURM/submit_disturbance_array.sh
```

Settings (environment variables): `MAX_CONCURRENT` (default 100), `TIME_LIMIT`
(4 h), `MEMORY` (4G), `CHUNK` (1000 tasks per array; must not exceed
`scontrol show config | grep MaxArraySize`), `OUTBASE`, `SLIM_BIN`.

## Output

```
/scratch/wwalli/TMP/disturbance/
  csv/K1000_strong_sel0.05/rep03/job1234_v1.2dist_S017_..._log.csv   complete runs only
  failed/job1234_console.txt      SLiM output of runs that stopped with an error
  manifests/                      job lists, missing.txt
  slurm/                          SLURM .out/.err files
```

A file in `csv/` is always a finished run: each run writes to `tmp/` first and
is moved only when SLiM ends without an error. Scratch is not permanent storage,
so copy `csv/` somewhere safe when the experiment is done.

## Run time (measured locally)

K 500 ~1.5 min, K 1000 ~3 min, K 5000 ~45 min per run; ~2,500 CPU-hours in
total, 90 % of it the K 5000 runs (job_ids 6081-9120).
