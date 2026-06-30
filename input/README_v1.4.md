# v1.4 CSV Inputs

`migration_matrix_v1.4.csv` is the migration-rate matrix.

- Rows are source populations.
- Columns are destination populations.
- Row 1 and column 1 are p0, row 2 and column 2 are p1, and so on.
- The diagonal should usually be 0.0 because a population does not migrate into itself.
- For 25 populations, this file should be 25 rows by 25 columns.

`climate_matrix_v1.4.csv` is the climate-optimum matrix.

- Rows are climate stages.
- Columns are populations.
- Row 1 is `climate1`, used from generation 2000 to 3999.
- Row 2 is `climate2`, used from generation 4000 to 6000.
- For 25 populations, this file should have 25 columns.

The SLiM script checks that the migration matrix is square and that the climate matrix has one column per population.
