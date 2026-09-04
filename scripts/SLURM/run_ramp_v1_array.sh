#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/home/wwalli/msc_workspace/SLiM}"
MODEL="${MODEL:-${PROJECT_ROOT}/scripts/SLiM/parametized scripts/grib_pop_index_local_adaptation_ramp_parameterized.slim}"
GRID="${GRID:-${PROJECT_ROOT}/scripts/SLURM/parameter_grid_ramp_v1.tsv}"
SLIM_BIN="${SLIM_BIN:-/home/wwalli/conda/envs/msc_env/bin/slim}"
OUTBASE="${OUTBASE:-/scratch/wwalli/TMP/ramp_v1}"
TASK_ID="${SLURM_ARRAY_TASK_ID:-${TASK_ID:-}}"

# Tree-sequence recording for true coalescent Ne. Off by default: it costs
# roughly 40% more wall time and ~1 MB per run, and RECORD_TREES=0 produces
# results bit-identical to runs made before it existed.
RECORD_TREES="${RECORD_TREES:-0}"
# With RECORD_TREES=1, extract Ne in this same task while the .trees file is
# still on fast scratch, rather than in a serial pass over 240 files later.
EXTRACT_NE="${EXTRACT_NE:-1}"
PYTHON_BIN="${PYTHON_BIN:-python}"

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
TREES_DIR="${OUTBASE}/trees"
NE_DIR="${OUTBASE}/ne"
mkdir -p "${CSV_DIR}" "${LOG_DIR}"

console_log="${LOG_DIR}/${run_id}.log"
expected_output="${CSV_DIR}/${treatment_id}_rep_${replicate}_seed_${seed}.csv"
expected_trees="${TREES_DIR}/${treatment_id}_rep_${replicate}_seed_${seed}.trees"

echo "Starting ${run_id}"
echo "  task=${manifest_task_id}, seed=${seed}, replicate=${replicate}"
echo "  K=${K}, selection=${selection_strength}"
echo "  migration=${migration_treatment} (code ${migration_code})"
echo "  output=${expected_output}"
echo "  record_trees=${RECORD_TREES}"

if [[ "${RECORD_TREES}" == "1" ]]; then
	mkdir -p "${TREES_DIR}"
fi

"${SLIM_BIN}" \
	-s "${seed}" \
	-d "K=${K}" \
	-d "SELECTION_STRENGTH=${selection_strength}" \
	-d "MIGRATION_CODE=${migration_code}" \
	-d "REP=${replicate}" \
	-d "RECORD_TREES=${RECORD_TREES}" \
	-d "PROJECT_ROOT='${PROJECT_ROOT}'" \
	-d "RESULTS_DIR='${CSV_DIR}'" \
	-d "TREES_DIR='${TREES_DIR}'" \
	"${MODEL}" > "${console_log}" 2>&1

if [[ ! -s "${expected_output}" ]]; then
	echo "SLiM finished without producing the expected CSV: ${expected_output}" >&2
	echo "Inspect the log: ${console_log}" >&2
	exit 1
fi

if [[ "${RECORD_TREES}" == "1" ]]; then
	if [[ ! -s "${expected_trees}" ]]; then
		echo "Tree sequence missing: ${expected_trees}" >&2
		echo "Inspect the log: ${console_log}" >&2
		exit 1
	fi

	if [[ "${EXTRACT_NE}" == "1" ]]; then
		mkdir -p "${NE_DIR}"
		ne_csv="${NE_DIR}/${treatment_id}_rep_${replicate}_seed_${seed}_ne.csv"

		# Ne extraction is a separate concern from the simulation: if the
		# Python environment is missing tskit, keep the .trees file and the
		# run's CSV rather than failing the whole array task.
		if "${PYTHON_BIN}" \
			"${PROJECT_ROOT}/scripts/py/ts_ne_batch.py" \
			"${expected_trees}" --out "${ne_csv}" \
			>> "${console_log}" 2>&1
		then
			echo "  ne=${ne_csv}"
		else
			echo "Ne extraction failed for ${run_id}; .trees retained." >&2
			echo "Inspect the log: ${console_log}" >&2
		fi
	fi
fi

echo "Finished ${run_id}"
