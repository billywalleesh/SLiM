#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPLICATES="${1:-${REPLICATES:-20}}"
PROJECT_ROOT="${PROJECT_ROOT:-/home/wwalli/msc_workspace/SLiM}"
OUTBASE="${OUTBASE:-/scratch/wwalli/TMP/ramp_v2}"
SLIM_BIN="${SLIM_BIN:-/home/wwalli/conda/envs/msc_env/bin/slim}"
MAX_CONCURRENT="${MAX_CONCURRENT:-12}"
TIME_LIMIT="${TIME_LIMIT:-0-12:00:00}"
MEMORY="${MEMORY:-4G}"
RECORD_TREES="${RECORD_TREES:-1}"
EXTRACT_NE="${EXTRACT_NE:-1}"
PYTHON_BIN="${PYTHON_BIN:-python}"
NEUTRAL_START="${NEUTRAL_START:-100000}"

timestamp="$(date +%Y%m%d_%H%M%S)"
GRID="${GRID:-${OUTBASE}/manifests/parameter_grid_ramp_v2_${timestamp}.tsv}"

mkdir -p "${OUTBASE}/manifests" "${OUTBASE}/slurm"

bash "${SCRIPT_DIR}/make_ramp_v2_parameter_grid.sh" \
	"${REPLICATES}" "${GRID}"

run_count="$(awk 'END { print NR - 1 }' "${GRID}")"

echo "Submitting ${run_count} runs from ${GRID}"
echo "Maximum concurrent tasks: ${MAX_CONCURRENT}"
echo "Tree-sequence recording: ${RECORD_TREES} (Ne extraction: ${EXTRACT_NE})"

if [[ "${RECORD_TREES}" == "1" && "${EXTRACT_NE}" == "1" ]]; then
	if ! "${PYTHON_BIN}" -c "import tskit" >/dev/null 2>&1; then
		echo "WARNING: '${PYTHON_BIN}' cannot import tskit." >&2
		echo "         Runs will still produce CSVs and .trees files, but" >&2
		echo "         Ne extraction will fail in every task." >&2
		echo "         Set PYTHON_BIN, or run ts_ne_batch.py later." >&2
	fi
fi

job_id="$(
	sbatch \
		--parsable \
		--job-name=grib_ramp_v2 \
		--time="${TIME_LIMIT}" \
		--cpus-per-task=1 \
		--mem="${MEMORY}" \
		--array="1-${run_count}%${MAX_CONCURRENT}" \
		--output="${OUTBASE}/slurm/%A_%a.out" \
		--error="${OUTBASE}/slurm/%A_%a.err" \
		--export="ALL,PROJECT_ROOT=${PROJECT_ROOT},GRID=${GRID},SLIM_BIN=${SLIM_BIN},OUTBASE=${OUTBASE},RECORD_TREES=${RECORD_TREES},EXTRACT_NE=${EXTRACT_NE},PYTHON_BIN=${PYTHON_BIN},NEUTRAL_START=${NEUTRAL_START}" \
		"${SCRIPT_DIR}/run_ramp_v2_array.sh"
)"

echo "Submitted SLURM array job ${job_id}"
