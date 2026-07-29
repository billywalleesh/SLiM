#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPLICATES="${1:-${REPLICATES:-2}}"
OUTBASE="${OUTBASE:-/scratch/wwalli/TMP/4pop_ne_trial}"
GRID="${GRID:-${OUTBASE}/manifests/parameter_grid_4pop_ne_trial.tsv}"

bash "${SCRIPT_DIR}/make_4pop_ne_parameter_grid.sh" \
	"${REPLICATES}" "${GRID}"

run_count="$(awk 'END { print NR - 1 }' "${GRID}")"

echo "Running ${run_count} simulations sequentially."

for task_id in $(seq 1 "${run_count}"); do
	TASK_ID="${task_id}" \
	GRID="${GRID}" \
	OUTBASE="${OUTBASE}" \
	bash "${SCRIPT_DIR}/run_4pop_ne_array.sh"
done

echo "Completed all ${run_count} trial runs."
