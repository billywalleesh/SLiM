#!/bin/bash
set -euo pipefail

MODEL="${MODEL:-/home/wwalli/msc_workspace/SLiM/scripts/SLiM/nonWF_climate_disruption_model_v2.1}"
GRID="${GRID:-/home/wwalli/msc_workspace/SLiM/scripts/SLURM/parameter_grid_v2_1.tsv}"
SLIM="${SLIM:-/home/wwalli/conda/envs/msc_env/bin/slim}"
OUTBASE="${OUTBASE:-/scratch/wwalli/TMP/slim_v2_1}"

TASK_ID="${SLURM_ARRAY_TASK_ID:-1}"

line="$(awk -v task_id="${TASK_ID}" 'NR == task_id + 1 { print; exit }' "${GRID}")"

if [[ -z "${line}" ]]; then
	echo "No parameter-grid row found for task ${TASK_ID}" >&2
	exit 1
fi

IFS=$'\t' read -r RUN_ID REP SEED TARGET_NE NUM_POPS MIGRATION_RATE FITNESS_WIDTH SHIFT_SIZE TBURN_SHARED TBURN_GRADIENT TPOST_SHIFT LOG_INTERVAL MU RECOMBINATION_RATE <<< "${line}"

CSV_DIR="${OUTBASE}/csv"
LOG_DIR="${OUTBASE}/logs"
mkdir -p "${CSV_DIR}" "${LOG_DIR}"

OUTFILE="${CSV_DIR}/${RUN_ID}.csv"
CONSOLE_LOG="${LOG_DIR}/${RUN_ID}.out"

echo "Running ${RUN_ID}"
echo "  seed=${SEED}"
echo "  target_Ne=${TARGET_NE}, num_pops=${NUM_POPS}, migration_rate=${MIGRATION_RATE}"
echo "  shift_size=${SHIFT_SIZE}, fitness_width=${FITNESS_WIDTH}"
echo "  output=${OUTFILE}"

"${SLIM}" \
	-s "${SEED}" \
	-d "RUN_ID='${RUN_ID}'" \
	-d "SEED=${SEED}" \
	-d "OUTFILE='${OUTFILE}'" \
	-d "Ne=${TARGET_NE}" \
	-d "N=${NUM_POPS}" \
	-d "m=${MIGRATION_RATE}" \
	-d "fitness_width=${FITNESS_WIDTH}" \
	-d "shift_size=${SHIFT_SIZE}" \
	-d "Tburn_shared=${TBURN_SHARED}" \
	-d "Tburn_gradient=${TBURN_GRADIENT}" \
	-d "Tpost_shift=${TPOST_SHIFT}" \
	-d "LOG_INTERVAL=${LOG_INTERVAL}" \
	-d "MU=${MU}" \
	-d "R=${RECOMBINATION_RATE}" \
	"${MODEL}" > "${CONSOLE_LOG}" 2>&1

echo "Finished ${RUN_ID}"
