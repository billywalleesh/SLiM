#!/usr/bin/env bash
# Which runs of the disturbance experiment are finished, and which are missing?
#
#   bash scripts/SLURM/check_disturbance_runs.sh           # all job_ids in run_grid.csv
#   bash scripts/SLURM/check_disturbance_runs.sh 1 76      # only job_ids 1-76
#
# Writes the missing job_ids to ${OUTBASE}/manifests/missing.txt. Resubmit
# them with:
#   JOB_LIST_FILE=${OUTBASE}/manifests/missing.txt bash scripts/SLURM/submit_disturbance_array.sh
# (check squeue first: runs still queued or running also count as missing)
set -euo pipefail

WORKSPACE="${WORKSPACE:-/home/wwalli/msc_workspace}"
GRID="${GRID:-${WORKSPACE}/SLiM/input/grib_pop_index_local_adaptation/disturbance_experiment/run_grid.csv}"
OUTBASE="${OUTBASE:-/scratch/wwalli/TMP/disturbance}"

max_job="$(awk -F, 'END { print $1 }' "${GRID}")"
FIRST="${1:-1}"
LAST="${2:-${max_job}}"

mkdir -p "${OUTBASE}/manifests"
missing_file="${OUTBASE}/manifests/missing.txt"

# job numbers of the finished runs (file names start with jobNNNN_)
done_file="$(mktemp)"
if [[ -d "${OUTBASE}/csv" ]]; then
	find "${OUTBASE}/csv" -name 'job*_log.csv' -printf '%f\n' |
		sed -E 's/^job0*([0-9]+)_.*/\1/' | sort -n -u > "${done_file}"
fi

seq "${FIRST}" "${LAST}" |
	awk -v done_file="${done_file}" '
		BEGIN { while ((getline id < done_file) > 0) finished[id] }
		!($1 in finished)' > "${missing_file}"
rm -f "${done_file}"

n_expected=$(( LAST - FIRST + 1 ))
n_missing="$(wc -l < "${missing_file}")"
echo "Finished: $(( n_expected - n_missing )) of ${n_expected}"
echo "Missing:  ${n_missing} (listed in ${missing_file})"

n_failed=0
if [[ -d "${OUTBASE}/failed" ]]; then
	n_failed="$(find "${OUTBASE}/failed" -name '*_console.txt' | wc -l)"
fi
if [[ "${n_failed}" -gt 0 ]]; then
	echo "Failed runs with saved console output: ${n_failed} (in ${OUTBASE}/failed/)"
fi

# rough storage use
if [[ -d "${OUTBASE}/csv" ]]; then
	echo "Output size: $(du -sh "${OUTBASE}/csv" | cut -f1)"
fi
