#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/home/wwalli/msc_workspace/SLiM}"
MODEL="${MODEL:-${PROJECT_ROOT}/scripts/SLiM/4pop_ne_experiment/grib_4pop_ne_ramp_parameterized.slim}"
GRID="${GRID:-${PROJECT_ROOT}/scripts/SLURM/parameter_grid_4pop_ne.tsv}"
SLIM_BIN="${SLIM_BIN:-/home/wwalli/conda/envs/msc_env/bin/slim}"
OUTBASE="${OUTBASE:-/scratch/wwalli/TMP/4pop_ne}"
TASK_ID="${SLURM_ARRAY_TASK_ID:-${TASK_ID:-}}"

if [[ -z "${TASK_ID}" ]]; then
	echo "Set SLURM_ARRAY_TASK_ID or TASK_ID to a manifest task number." >&2
	exit 1
fi

if ! [[ "${TASK_ID}" =~ ^[1-9][0-9]*$ ]]; then
	echo "Task ID must be a positive integer: ${TASK_ID}" >&2
	exit 1
fi

if [[ ! -x "${SLIM_BIN}" ]]; then
	echo "SLiM executable not found or not executable: ${SLIM_BIN}" >&2
	exit 1
fi

if [[ ! -f "${MODEL}" ]]; then
	echo "Parameterized SLiM model not found: ${MODEL}" >&2
	exit 1
fi

if [[ ! -f "${GRID}" ]]; then
	echo "Parameter grid not found: ${GRID}" >&2
	exit 1
fi

line="$(awk -v task_id="${TASK_ID}" \
	'NR > 1 && $1 == task_id { print; exit }' "${GRID}")"

if [[ -z "${line}" ]]; then
	echo "No parameter-grid row found for task ${TASK_ID}." >&2
	exit 1
fi

IFS=$'\t' read -r \
	manifest_task_id \
	run_id \
	treatment_id \
	replicate \
	seed \
	K \
	selection_strength \
	migration_code \
	migration_treatment \
	<<< "${line}"

CSV_DIR="${OUTBASE}/csv"
LOG_DIR="${OUTBASE}/logs"
mkdir -p "${CSV_DIR}" "${LOG_DIR}"

console_log="${LOG_DIR}/${run_id}.log"
expected_output="${CSV_DIR}/${treatment_id}_rep_${replicate}_seed_${seed}.csv"

echo "Starting ${run_id}"
echo "  task=${manifest_task_id}, seed=${seed}, replicate=${replicate}"
echo "  K=${K}, selection=${selection_strength}"
echo "  migration=${migration_treatment} (code ${migration_code})"
echo "  output=${expected_output}"

"${SLIM_BIN}" \
	-s "${seed}" \
	-d "K=${K}" \
	-d "SELECTION_STRENGTH=${selection_strength}" \
	-d "MIGRATION_CODE=${migration_code}" \
	-d "REP=${replicate}" \
	-d "PROJECT_ROOT='${PROJECT_ROOT}'" \
	-d "RESULTS_DIR='${CSV_DIR}'" \
	"${MODEL}" > "${console_log}" 2>&1

if [[ ! -s "${expected_output}" ]]; then
	echo "SLiM finished without producing the expected CSV: ${expected_output}" >&2
	echo "Inspect the log: ${console_log}" >&2
	exit 1
fi

echo "Finished ${run_id}"
