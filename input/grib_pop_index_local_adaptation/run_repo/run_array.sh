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
# Useful commands for running:
#   mkdir -p logs
# test 3 runs
#   sbatch --array=1-3 run_array.sh
# all 1000
#   sbatch run_array.sh

# ---- 1. Current Run --------------------------------------------------------
ID=${SLURM_ARRAY_TASK_ID}

# ---- 2.Directories ----------------------------------------------------------
RUN_REPO=/home/wwalli/msc_workspace/SLiM/input/grib_pop_index_local_adaptation/run_repo
 #run matrix + matrices
INPUT=$RUN_REPO/14102026
#the SLiM model
MODEL=$RUN_REPO/ramp_v1.3.1_cluster.slim
#the SLiM program
SLIM=/home/wwalli/conda/envs/msc_env/bin/slim
#log file output
OUTDIR=/scratch/wwalli/TMP/ramp_v1.3.1_cluster            

# ---- 3.Workspace--------------------------------------------------------------
WORKDIR=/scratch/wwalli/TMP/work/${SLURM_ARRAY_JOB_ID}_${ID}
mkdir -p $WORKDIR/migration_matrices $WORKDIR/climate_matrices $WORKDIR/climate_years
mkdir -p $OUTDIR

# ---- 4.Seperate run outputs------------------------------------------------------
$WORKDIR/
cp $INPUT/run_matrix_1000.csv

$WORKDIR/migration_matrices/
cp $INPUT/migration_matrices/run_$ID.csv

$WORKDIR/climate_matrices/
cp $INPUT/climate_matrices/run_$ID.csv

$WORKDIR/climate_years/
cp $INPUT/climate_years/grib_climate_years_8pop_1940_2025.csv

# The files were written on Windows (lines end in \r\n); SLiM on Linux needs \n
sed -i 's/\r$//' $WORKDIR/*.csv $WORKDIR/*/*.csv

# ---- 5. Run SLiM ----------------------------------------------------------------
#the random seed, different for every run and the same if you re-run it
# -s
#constants handed to the model: the run number and the two folders
# -d
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
