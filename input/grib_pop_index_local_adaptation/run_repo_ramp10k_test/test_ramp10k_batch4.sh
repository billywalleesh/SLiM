#!/bin/bash
#SBATCH --job-name=ramp10k_test_b4
#SBATCH --time=0-1:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=1000
#SBATCH --output=logs_ramp10k_test/batch4_run_%a.out
#SBATCH --array=289,375,943

# Test of the 10,000-tick ramp (ramp_v1.3.1_burnin50k_ramp10k.slim) on batch 4.
# Reruns the 3 batch 4 runs that died in the 4000-tick ramp (289, 375, 943).
# Same run settings and the same seeds as batch 4 (27000000 + ID), only the ramp is longer.
# The batch 4 inputs are only read, nothing in run_repo_251120262 is changed.
#
# Before submitting (once, from inside the run_repo_ramp10k_test folder on the cluster):
#   mkdir -p logs_ramp10k_test
#   sbatch test_ramp10k_batch4.sh
#
# A run that gets through the ramp now ends with "Run <ID> finished" after the Tick 60055 | 2025 line,
# or with "All populations extinct at tick" 60000 or later. A tick below 60000 means it still died before 1970.

# ---- 1. Which run is this? ---------------------------------------------------
ID=${SLURM_ARRAY_TASK_ID}

# ---- 2. Where everything is (cluster paths) ------------------------------------
TEST_REPO=/home/wwalli/msc_workspace/SLiM/input/grib_pop_index_local_adaptation/run_repo_ramp10k_test
INPUT=/home/wwalli/msc_workspace/SLiM/input/grib_pop_index_local_adaptation/run_repo_251120262 # batch 4 inputs (only read)
MODEL=$TEST_REPO/ramp_v1.3.1_burnin50k_ramp10k.slim         # the model with the 10,000-tick ramp
SLIM=/home/wwalli/conda/envs/msc_env/bin/slim               # the SLiM program
OUTDIR=/scratch/wwalli/TMP/ramp10k_test_batch4               # where the logs go

# ---- 3. A private working folder for this run --------------------------------
WORKDIR=/scratch/wwalli/TMP/work_ramp10k_test_batch4/${SLURM_ARRAY_JOB_ID}_${ID}
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
# the same seed as in batch 4 (27000000 + ID)
$SLIM -s $((27000000 + ID)) \
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
