#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPLICATES="${1:-${REPLICATES:-20}}"
PROJECT_ROOT="${PROJECT_ROOT:-/home/wwalli/msc_workspace/SLiM}"
OUTBASE="${OUTBASE:-/scratch/wwalli/TMP/4pop_ne}"
SLIM_BIN="${SLIM_BIN:-/home/wwalli/conda/envs/msc_env/bin/slim}"
MAX_CONCURRENT="${MAX_CONCURRENT:-12}"
TIME_LIMIT="${TIME_LIMIT:-0-12:00:00}"
MEMORY="${MEMORY:-4G}"

timestamp="$(date +%Y%m%d_%H%M%S)"
GRID="${GRID:-${OUTBASE}/manifests/parameter_grid_4pop_ne_${timestamp}.tsv}"

mkdir -p "${OUTBASE}/manifests" "${OUTBASE}/slurm"

bash "${SCRIPT_DIR}/make_4pop_ne_parameter_grid.sh" \
	"${REPLICATES}" "${GRID}"

run_count="$(awk 'END { print NR - 1 }' "${GRID}")"

echo "Submitting ${run_count} runs from ${GRID}"
echo "Maximum concurrent tasks: ${MAX_CONCURRENT}"

job_id="$(
	sbatch \
		--parsable \
		--job-name=grib_4pop_ne \
		--time="${TIME_LIMIT}" \
		--cpus-per-task=1 \
		--mem="${MEMORY}" \
		--array="1-${run_count}%${MAX_CONCURRENT}" \
		--output="${OUTBASE}/slurm/%A_%a.out" \
		--error="${OUTBASE}/slurm/%A_%a.err" \
		--export="ALL,PROJECT_ROOT=${PROJECT_ROOT},GRID=${GRID},SLIM_BIN=${SLIM_BIN},OUTBASE=${OUTBASE}" \
		"${SCRIPT_DIR}/run_4pop_ne_array.sh"
)"

echo "Submitted SLURM array job ${job_id}"
