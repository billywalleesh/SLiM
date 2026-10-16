#!/bin/bash
#SBATCH --job-name=ramp_v1.3.1
#SBATCH --time=0-1:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2000
#SBATCH --output=logs/run_%a.out
#SBATCH --array=1-1000

# Runs the SLiM model once for every row of run_matrix_1000.csv.
# SLURM starts this script 1000 times; each copy gets its own number in
# SLURM_ARRAY_TASK_ID (1, 2, ... 1000), which is the run number.
#
# Before submitting (once, from inside the run_repo folder on the cluster):
#   mkdir -p logs
#   sbatch --array=1-3 run_array.sh     <- test 3 runs first
#   sbatch run_array.sh                 <- then all 1000

# ---- 1. Which run is this? ---------------------------------------------------
ID=${SLURM_ARRAY_TASK_ID}

# ---- 2. Where everything is (cluster paths) ------------------------------------
RUN_REPO=/home/wwalli/msc_workspace/SLiM/input/grib_pop_index_local_adaptation/run_repo
INPUT=$RUN_REPO/14102026                                  # run matrix + matrices
MODEL=$RUN_REPO/ramp_v1.3.1_cluster.slim                  # the SLiM model
SLIM=/home/wwalli/conda/envs/msc_env/bin/slim             # the SLiM program
OUTDIR=/scratch/wwalli/TMP/ramp_v1.3.1_cluster            # where the logs go

# ---- 3. A private working folder for this run --------------------------------
WORKDIR=/scratch/wwalli/TMP/work/${SLURM_ARRAY_JOB_ID}_${ID}
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
# -d     constants handed to the model: the run number and the two folders
$SLIM -s $((8000000 + ID)) \
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
