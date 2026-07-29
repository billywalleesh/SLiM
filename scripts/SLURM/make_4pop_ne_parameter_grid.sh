#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPLICATES="${1:-${REPLICATES:-5}}"
GRID="${2:-${SCRIPT_DIR}/parameter_grid_4pop_ne.tsv}"

if ! [[ "${REPLICATES}" =~ ^[1-9][0-9]*$ ]]; then
	echo "Replicate count must be a positive integer." >&2
	exit 1
fi

if (( REPLICATES > 999 )); then
	echo "Replicate count must not exceed 999 with the current seed scheme." >&2
	exit 1
fi

mkdir -p "$(dirname "${GRID}")"

printf '%s\n' \
	$'task_id\trun_id\ttreatment_id\treplicate\tseed\tK\tselection_strength\tmigration_code\tmigration_treatment' \
	> "${GRID}"

task_id=0
carrying_capacities=(500 2000 5000)
selection_strengths=(0.05 0.075)
migration_codes=(0 1)

for k_index in "${!carrying_capacities[@]}"; do
	K="${carrying_capacities[${k_index}]}"
	
	for selection_index in "${!selection_strengths[@]}"; do
		selection_strength="${selection_strengths[${selection_index}]}"
		
		if [[ "${selection_strength}" == "0.05" ]]; then
			selection_label="sel050"
		else
			selection_label="sel075"
		fi
		
		for migration_code in "${migration_codes[@]}"; do
			if (( migration_code == 0 )); then
				migration_treatment="weak"
			else
				migration_treatment="strong"
			fi
			
			treatment_id="grib_4pop_ne_ramp_${migration_treatment}_${selection_label}_K${K}"
			
			for replicate in $(seq 1 "${REPLICATES}"); do
				task_id=$((task_id + 1))
				
				# This construction is deterministic and unique for all
				# combinations in the design, up to 999 replicates.
				seed=$((5000000 +
					(k_index + 1) * 100000 +
					(selection_index + 1) * 10000 +
					migration_code * 1000 +
					replicate))
				
				run_id="${treatment_id}_rep_${replicate}_seed_${seed}"
				
				printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
					"${task_id}" \
					"${run_id}" \
					"${treatment_id}" \
					"${replicate}" \
					"${seed}" \
					"${K}" \
					"${selection_strength}" \
					"${migration_code}" \
					"${migration_treatment}" \
					>> "${GRID}"
			done
		done
	done
done

echo "Wrote ${task_id} runs to ${GRID}"
