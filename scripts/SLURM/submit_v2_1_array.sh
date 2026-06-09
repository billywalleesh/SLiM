#!/bin/bash
#SBATCH --job-name=slim_v2_1
#SBATCH --time=0-12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --array=1-32
#SBATCH --output=slim_v2_1_%A_%a.out
#SBATCH --error=slim_v2_1_%A_%a.err

set -euo pipefail

# Activate conda
source ~/.bashrc
conda activate msc_env

# Move to project directory
cd /home/wwalli/msc_workspace/SLiM

# One array task reads one row from parameter_grid_v2_1.tsv
bash scripts/SLURM/run_v2_1_array.sh
