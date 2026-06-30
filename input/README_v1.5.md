# v1.5 CSV Inputs

These are synthetic test inputs for a 25-population landscape.

## Migration Matrix

`migration_matrix_v1.5.csv` is a 25 by 25 migration-rate matrix.

- Rows are source populations.
- Columns are destination populations.
- Row 1 and column 1 are p0, row 2 and column 2 are p1, and so on.
- The diagonal is 0.0 because individuals do not migrate into the population they already occupy.
- Rates decline with distance along the population chain.

Distance class used for v1.5:

| Distance between populations | Migration probability |
| --- | --- |
| 1 step | 0.0050 |
| 2 steps | 0.0025 |
| 3 steps | 0.0010 |
| 4 steps | 0.0004 |
| 5 steps | 0.0002 |
| 6 steps | 0.0001 |
| More than 6 steps | 0.0000 |

This is a simple stepping-stone/dispersal-kernel model. Interior populations have a total possible migration probability of about 0.0184 per generation, before accounting for the model's rule that an individual can only migrate once in a generation.

For lower-dispersal taxa, multiply the nonzero values downward. For higher-dispersal taxa, multiply them upward or extend the nonzero tail beyond 6 population steps.

## Climate Matrix

`climate_matrix_v1.5.csv` has 2 rows and 25 columns.

- Row 1 is `climate1`: a stable baseline climate gradient from 2.00 to 8.00.
- Row 2 is `climate2`: the same gradient shifted warmer by 1.50 climate units.
- Columns are populations p0 through p24.

This is not real climate data. It is a clean synthetic gradient for testing whether the model can read 25-population climate inputs correctly. Later, real Copernicus-derived values could replace this file while keeping the same shape: rows as climate periods, columns as populations.
