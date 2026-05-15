#!/bin/bash
#SBATCH --job-name=run_reps
#SBATCH --time=0-03:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --output=console.out
#SBATCH --error=console.err

cd /home/wwalli/msc_workspace/SLiM/scripts/SLURM

bash run_reps.sh