# v1.6 CSV Inputs

v1.6 changes the 25 populations from a one-dimensional chain into a 5 by 5 grid.

Population order in the CSV is row-by-row:

```text
p0   p1   p2   p3   p4
p5   p6   p7   p8   p9
p10  p11  p12  p13  p14
p15  p16  p17  p18  p19
p20  p21  p22  p23  p24
```

## Migration Matrix

`migration_matrix_v1.6.csv` is a 25 by 25 migration matrix.

- Rows are source populations.
- Columns are destination populations.
- Migration occurs only between north, south, east, and west neighbors.
- Diagonal/self migration is 0.0.
- Adjacent-neighbor migration probability is 0.0050.

This means:

- Corner populations have 2 migration neighbors.
- Edge populations have 3 migration neighbors.
- Interior populations have 4 migration neighbors.

## Climate Matrix

`climate_matrix_v1.6.csv` is a 2 by 25 climate matrix.

- Row 1 is `climate1`, a smooth baseline climate surface from 2.00 to 8.00.
- Row 2 is `climate2`, the same surface shifted warmer by 1.50 climate units.
- Columns follow the same p0 to p24 order shown above.

The SLiM script also calls `setMigrationRates()` once at setup so SLiMgui can draw the migration graph. Real migration in the nonWF model is still handled manually with `takeMigrants()` using the same CSV matrix.
