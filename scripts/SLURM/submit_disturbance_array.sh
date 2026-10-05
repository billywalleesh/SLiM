#!/usr/bin/env bash
# Submit runs of the disturbance experiment as SLURM array jobs.
#
#   bash scripts/SLURM/submit_disturbance_array.sh               # all jobs in run_grid.csv
#   bash scripts/SLURM/submit_disturbance_array.sh 1 76          # job_ids 1-76 only (pilot)
#   JOB_LIST_FILE=missing.txt bash scripts/SLURM/submit_disturbance_array.sh
#                                                                # job_ids listed in a file
#
# Overrides (environment): WORKSPACE, OUTBASE, SLIM_BIN, MAX_CONCURRENT,
# TIME_LIMIT, MEMORY, CHUNK.
#
# SLURM limits the size of one array (MaxArraySize; check with
#   scontrol show config | grep MaxArraySize ),
# so the job list is split into arrays of CHUNK tasks. Each array starts
# when the previous one has finished, so at most MAX_CONCURRENT runs are
# going at any time. Jobs that are already complete are skipped by the
# worker, so resubmitting a range is safe.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${WORKSPACE:-/home/wwalli/msc_workspace}"
GRID="${GRID:-${WORKSPACE}/SLiM/input/grib_pop_index_local_adaptation/disturbance_experiment/run_grid.csv}"
OUTBASE="${OUTBASE:-/scratch/wwalli/TMP/disturbance}"
SLIM_BIN="${SLIM_BIN:-/home/wwalli/conda/envs/msc_env/bin/slim}"
MAX_CONCURRENT="${MAX_CONCURRENT:-100}"
TIME_LIMIT="${TIME_LIMIT:-0-04:00:00}"   # K = 5000 runs take ~1 h
MEMORY="${MEMORY:-4G}"
CHUNK="${CHUNK:-1000}"

mkdir -p "${OUTBASE}/manifests" "${OUTBASE}/slurm"
timestamp="$(date +%Y%m%d_%H%M%S)"
JOB_LIST="${OUTBASE}/manifests/joblist_${timestamp}.txt"

# the list of job_ids to run
if [[ -n "${JOB_LIST_FILE:-}" ]]; then
	grep -E '^[0-9]+' "${JOB_LIST_FILE}" | tr -d '\r' > "${JOB_LIST}"
else
	max_job="$(awk -F, 'END { print $1 }' "${GRID}")"
	FIRST="${1:-1}"
	LAST="${2:-${max_job}}"
	seq "${FIRST}" "${LAST}" > "${JOB_LIST}"
fi

n_jobs="$(wc -l < "${JOB_LIST}")"
if [[ "${n_jobs}" -eq 0 ]]; then
	echo "Nothing to submit."
	exit 0
fi
echo "Submitting ${n_jobs} runs (list: ${JOB_LIST})"
echo "At most ${MAX_CONCURRENT} at once, ${CHUNK} per array, time limit ${TIME_LIMIT}"

previous=""
offset=0
while [[ "${offset}" -lt "${n_jobs}" ]]; do
	size=$(( n_jobs - offset ))
	if [[ "${size}" -gt "${CHUNK}" ]]; then size="${CHUNK}"; fi

	dependency=()
	if [[ -n "${previous}" ]]; then dependency=(--dependency="afterany:${previous}"); fi

	previous="$(
		sbatch \
			--parsable \
			--job-name=disturbance \
			--time="${TIME_LIMIT}" \
			--cpus-per-task=1 \
			--mem="${MEMORY}" \
			--array="1-${size}%${MAX_CONCURRENT}" \
			"${dependency[@]}" \
			--output="${OUTBASE}/slurm/%A_%a.out" \
			--error="${OUTBASE}/slurm/%A_%a.err" \
			--export="ALL,WORKSPACE=${WORKSPACE},GRID=${GRID},OUTBASE=${OUTBASE},SLIM_BIN=${SLIM_BIN},JOB_LIST=${JOB_LIST},LIST_OFFSET=${offset}" \
			"${SCRIPT_DIR}/run_disturbance_array.sh"
	)"
	echo "  array ${previous}: list lines $(( offset + 1 ))-$(( offset + size ))"
	offset=$(( offset + size ))
done

echo "Check progress with:  squeue -u \$USER"
echo "Check completeness with:  bash ${SCRIPT_DIR}/check_disturbance_runs.sh"
