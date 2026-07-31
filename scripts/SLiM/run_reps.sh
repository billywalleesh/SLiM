#!/usr/bin/env bash
set -euo pipefail

# Local Windows/MSYS2 paths.
PROJECT_ROOT_WIN="C:/Users/WilliamWallisch/msc_workspace/SLiM"
PROJECT_ROOT_MSYS="/c/Users/WilliamWallisch/msc_workspace/SLiM"
SLIM="C:/msys64/mingw64/bin/slim.exe"
MODEL="${PROJECT_ROOT_WIN}/scripts/SLiM/grib_4pop_ne_ramp_parameterized.slim"
REPLICATES="${1:-10}"

# SLiM receives the Windows path; Bash uses the MSYS2 path.
OUTDIR_WIN="${PROJECT_ROOT_WIN}/results/reps"
OUTDIR_MSYS="${PROJECT_ROOT_MSYS}/results/reps"
RUNS_DIR_WIN="${OUTDIR_WIN}/runs"
RUNS_DIR_MSYS="${OUTDIR_MSYS}/runs"
LOGDIR_MSYS="${OUTDIR_MSYS}/logs"
COMBINED_FILE_MSYS="${OUTDIR_MSYS}/all_reps.csv"

# Safety check: this script may recursively delete only this exact folder.
EXPECTED_OUTDIR="/c/Users/WilliamWallisch/msc_workspace/SLiM/results/reps"
if [[ "${OUTDIR_MSYS}" != "${EXPECTED_OUTDIR}" ]]; then
	echo "Refusing to clean unexpected output directory: ${OUTDIR_MSYS}" >&2
	exit 1
fi

if [[ ! -x "${SLIM}" ]]; then
	echo "SLiM executable not found: ${SLIM}" >&2
	exit 1
fi

if [[ ! -f "${MODEL}" ]]; then
	echo "Parameterized model not found: ${MODEL}" >&2
	exit 1
fi

if ! [[ "${REPLICATES}" =~ ^[1-9][0-9]*$ ]]; then
	echo "Replicate count must be a positive integer: ${REPLICATES}" >&2
	exit 1
fi

echo "Cleaning previous trial results: ${OUTDIR_WIN}"
rm -rf -- "${OUTDIR_MSYS}"
mkdir -p "${RUNS_DIR_MSYS}" "${LOGDIR_MSYS}"

run_number=0
total_runs=$((12 * REPLICATES))

for K in 500 2000 5000; do
	for SELECTION_STRENGTH in 0.05 0.075; do
		if [[ "${SELECTION_STRENGTH}" == "0.05" ]]; then
			SELECTION_LABEL="sel050"
		else
			SELECTION_LABEL="sel075"
		fi
		
		for MIGRATION_CODE in 0 1; do
			if (( MIGRATION_CODE == 0 )); then
				MIGRATION_LABEL="weak"
			else
				MIGRATION_LABEL="strong"
			fi
			
			TREATMENT_ID="grib_4pop_ne_ramp_${MIGRATION_LABEL}_${SELECTION_LABEL}_K${K}"
			
			for REP in $(seq 1 "${REPLICATES}"); do
				run_number=$((run_number + 1))
				SEED=$((8000000 + run_number))
				RUN_ID="${TREATMENT_ID}_rep_${REP}_seed_${SEED}"
				LOG_FILE="${LOGDIR_MSYS}/${RUN_ID}.log"
				OUTPUT_FILE="${RUNS_DIR_MSYS}/${RUN_ID}.csv"
				
				echo
				echo "[${run_number}/${total_runs}] ${TREATMENT_ID}, replicate ${REP}"
				echo "  K=${K}"
				echo "  selection=${SELECTION_STRENGTH}"
				echo "  migration=${MIGRATION_LABEL} (code ${MIGRATION_CODE})"
				echo "  seed=${SEED}"
				
				"${SLIM}" \
					-s "${SEED}" \
					-d "K=${K}" \
					-d "SELECTION_STRENGTH=${SELECTION_STRENGTH}" \
					-d "MIGRATION_CODE=${MIGRATION_CODE}" \
					-d "REP=${REP}" \
					-d "PROJECT_ROOT='${PROJECT_ROOT_WIN}'" \
					-d "RESULTS_DIR='${RUNS_DIR_WIN}'" \
					"${MODEL}" > "${LOG_FILE}" 2>&1
				
				if [[ ! -s "${OUTPUT_FILE}" ]]; then
					echo "Expected output was not created: ${OUTPUT_FILE}" >&2
					echo "Inspect the log: ${LOG_FILE}" >&2
					exit 1
				fi
				
				echo "  finished"
			done
		done
	done
done

# Combine the recoverable per-run files into one analysis table. Keep the
# individual files so a failed or unusual replicate can still be inspected.
first_file=true
for run_file in "${RUNS_DIR_MSYS}"/*.csv; do
	if ${first_file}; then
		cat "${run_file}" > "${COMBINED_FILE_MSYS}"
		first_file=false
	else
		tail -n +2 "${run_file}" >> "${COMBINED_FILE_MSYS}"
	fi
done

echo
echo "Completed all ${run_number} runs."
echo "Combined CSV: ${OUTDIR_WIN}/all_reps.csv"
echo "Individual run CSVs: ${RUNS_DIR_WIN}"
echo "Console logs: ${OUTDIR_WIN}/logs"
