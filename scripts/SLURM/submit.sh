#!/bin/bash
#SBATCH --job-name=run_reps
#SBATCH --time=0-03:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --output=console.out
#SBATCH --error=console.err

# Activate conda
conda activate msc_env

# Move to working directory
cd /home/wwalli/msc_workspace/SLiM/scripts/SLURM

# Run script
bash run_reps.sh