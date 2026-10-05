#!/usr/bin/env bash
# Worker for ONE run of the disturbance experiment (one SLURM array task).
#
# Array task i runs the job_id on line i of JOB_LIST (a plain list of
# job_ids, written by submit_disturbance_array.sh). Everything else -
# scenario, K, migration, selection, replicate, seed - is read by the SLiM
# script itself from run_grid.csv (-d JOB_ID).
#
# The run is written to a private temporary folder and only moved into
#   ${OUTBASE}/csv/K<K>_<migration>_sel<selection>/rep<NN>/
# when SLiM finishes without an error. So a file in csv/ is always a
# complete run, and resubmitting a job never leaves half-written files.
# The console output is kept only for failed runs (in ${OUTBASE}/failed/).
set -euo pipefail

WORKSPACE="${WORKSPACE:-/home/wwalli/msc_workspace}"
MODEL="${MODEL:-${WORKSPACE}/SLiM/scripts/SLiM/disturbance/grib_ramp_v1.2_disturbance.slim}"
GRID="${GRID:-${WORKSPACE}/SLiM/input/grib_pop_index_local_adaptation/disturbance_experiment/run_grid.csv}"
SLIM_BIN="${SLIM_BIN:-/home/wwalli/conda/envs/msc_env/bin/slim}"
OUTBASE="${OUTBASE:-/scratch/wwalli/TMP/disturbance}"
EXTRA_SLIM_ARGS="${EXTRA_SLIM_ARGS:-}"   # only for testing, e.g. shorter phases

TASK_ID="${SLURM_ARRAY_TASK_ID:-${TASK_ID:-}}"
LIST_OFFSET="${LIST_OFFSET:-0}"

if [[ -z "${TASK_ID}" || -z "${JOB_LIST:-}" ]]; then
	echo "Set SLURM_ARRAY_TASK_ID (or TASK_ID) and JOB_LIST." >&2
	exit 1
fi
for f in "${SLIM_BIN}" "${MODEL}" "${GRID}" "${JOB_LIST}"; do
	if [[ ! -e "${f}" ]]; then
		echo "Not found: ${f}" >&2
		exit 1
	fi
done

# line (offset + task) of the job list holds this task's job_id
line_number=$(( LIST_OFFSET + TASK_ID ))
JOB_ID="$(sed -n "${line_number}p" "${JOB_LIST}" | tr -d '[:space:]')"
if [[ -z "${JOB_ID}" ]]; then
	echo "No job_id on line ${line_number} of ${JOB_LIST}." >&2
	exit 1
fi

# this job's row of the grid:
# job_id,scenario_id,K,migration,migration_file,selection,rep,seed
row="$(awk -F, -v id="${JOB_ID}" 'NR > 1 && $1 == id { print; exit }' "${GRID}" | tr -d '\r')"
if [[ -z "${row}" ]]; then
	echo "job_id ${JOB_ID} not found in ${GRID}." >&2
	exit 1
fi
IFS=, read -r job_id scenario_id K migration migration_file selection rep seed <<< "${row}"

job_tag="$(printf 'job%04d' "${JOB_ID}")"
final_dir="${OUTBASE}/csv/K${K}_${migration}_sel${selection}/rep$(printf '%02d' "${rep}")"

# already done (e.g. when a whole range is resubmitted)
if compgen -G "${final_dir}/${job_tag}_*_log.csv" > /dev/null; then
	echo "${job_tag} already complete, skipping."
	exit 0
fi

tmp_dir="${OUTBASE}/tmp/${job_tag}"
rm -rf "${tmp_dir}"
mkdir -p "${tmp_dir}" "${final_dir}"
console_log="${tmp_dir}/console.txt"

echo "${job_tag}: scenario ${scenario_id}, K=${K}, migration=${migration}, selection=${selection}, rep=${rep}, seed=${seed}"
start=$(date +%s)

# PROJECT_ROOT is the workspace (the model adds /SLiM/input/... itself)
# shellcheck disable=SC2086
if "${SLIM_BIN}" \
	-d "JOB_ID=${JOB_ID}" \
	-d "PROJECT_ROOT='${WORKSPACE}'" \
	-d "RUN_GRID_FILE='${GRID}'" \
	-d "RESULTS_DIR='${tmp_dir}/'" \
	${EXTRA_SLIM_ARGS} \
	"${MODEL}" > "${console_log}" 2>&1
then
	log_file="$(compgen -G "${tmp_dir}/${job_tag}_*_log.csv" | head -n 1 || true)"
	if [[ -n "${log_file}" && -s "${log_file}" ]]; then
		mv "${log_file}" "${final_dir}/"
		rm -rf "${tmp_dir}"
		rm -f "${OUTBASE}/failed/${job_tag}_console.txt"   # an earlier failed attempt
		echo "${job_tag} finished in $(( $(date +%s) - start )) s -> ${final_dir}"
		exit 0
	fi
	echo "${job_tag}: SLiM finished but wrote no log." >&2
else
	echo "${job_tag}: SLiM stopped with an error." >&2
fi

# failed: keep the console output for inspection
mkdir -p "${OUTBASE}/failed"
mv "${console_log}" "${OUTBASE}/failed/${job_tag}_console.txt"
rm -rf "${tmp_dir}"
tail -n 20 "${OUTBASE}/failed/${job_tag}_console.txt" >&2
exit 1
