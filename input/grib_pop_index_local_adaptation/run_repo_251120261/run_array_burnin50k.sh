#!/bin/bash
#SBATCH --job-name=burnin50k_251120261
#SBATCH --time=0-1:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=1000
#SBATCH --output=logs_251120261/run_%a.out
#SBATCH --array=1-1000

# Batch 3 (run matrix seed 251120261): selection strength 0.17-0.23, slope_min -0.001/25.
# Range chosen from a 100-run pilot (seed 25112026, selection 0.10-0.25, run_repo_25112026):
# about 20% whole-metapopulation extinction at 0.17-0.23, and runs above 0.24 died in the burn-in.
# extinct now means the whole metapopulation is gone (every population at N = 0).
# Same model as batch 1 (ramp_v1.3.1_burnin50k.slim), only the run matrix is new.
#
# Runs the 50,000-generation burn-in model once for every row of run_matrix_1000.csv.
# SLURM starts this script once per run; each copy gets its own number in
# SLURM_ARRAY_TASK_ID, which is the run number.
#
# Before submitting (once, from inside the run_repo_251120261 folder on the cluster):
#   mkdir -p logs_251120261
#   sbatch --array=1-3 run_array_burnin50k.sh       <- check 3 runs start fine
#   sbatch run_array_burnin50k.sh                   <- all 1000 runs (array=1-1000 above)

# ---- 1. Which run is this? ---------------------------------------------------
ID=${SLURM_ARRAY_TASK_ID}

# ---- 2. Where everything is (cluster paths) ------------------------------------
RUN_REPO=/home/wwalli/msc_workspace/SLiM/input/grib_pop_index_local_adaptation/run_repo_251120261
INPUT=$RUN_REPO                                           # run matrix + matrices (no dated subfolder, same as batch 2)
MODEL=$RUN_REPO/ramp_v1.3.1_burnin50k.slim                # the SLiM model
SLIM=/home/wwalli/conda/envs/msc_env/bin/slim             # the SLiM program
OUTDIR=/scratch/wwalli/TMP/ramp_v1.3.1_burnin50k_251120261 # where the logs go (new folder: batch 1 and 2 logs have the same file names)

# ---- 3. A private working folder for this run --------------------------------
WORKDIR=/scratch/wwalli/TMP/work_burnin50k_251120261/${SLURM_ARRAY_JOB_ID}_${ID}
mkdir -p $WORKDIR/migration_matrices $WORKDIR/climate_matrices $WORKDIR/climate_years
mkdir -p $OUTDIR

# ---- 4. Copy only this run's input files into it -----------------------------
cp $INPUT/run_matrix_1000.csv                                $WORKDIR/
cp $INPUT/migration_matrices/run_$ID.csv                     $WORKDIR/migration_matrices/
cp $INPUT/climate_matrices/run_$ID.csv                       $WORKDIR/climate_matrices/
cp $INPUT/climate_years/grib_climate_years_8pop_1940_2025.csv $WORKDIR/climate_years/

# The files were written on Windows (lines end in \r\n); SLiM on Linux needs \n
sed -i 's/\r$//' $WORKDIR/*.csv $WORKDIR/*/*.csv

# ---- 5. Run SLiM ----------------------------------------------------------------
# -s     the random seed, different for every run and the same if you re-run it
#        (batch 1 used 9000000 + ID, batch 2 uses 20000000 + ID, the batch 3 pilot used 25000000 + ID, batch 3 uses 26000000 + ID so no seed is shared)
# -d     constants handed to the model: the run number and the two folders
$SLIM -s $((26000000 + ID)) \
      -d RUN=$ID \
      -d "INPUT_DIR='$WORKDIR/'" \
      -d "OUTPUT_DIR='$OUTDIR/'" \
      $MODEL

# ---- 6. Check the output exists, then clean up -------------------------------
if [ -f $OUTDIR/run_${ID}_log.csv ]; then
    echo "Run $ID finished: $OUTDIR/run_${ID}_log.csv"
else
    echo "Run $ID FAILED: no log file was written"
fi

rm -r $WORKDIR
