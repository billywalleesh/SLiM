# v1.7 Small Test CSV Inputs

v1.7 provides two smaller landscapes for testing before running the 25-population version.

## 5-Population Test

Files:

- `migration_matrix_5pop_v1.7.csv`
- `climate_matrix_5pop_v1.7.csv`

Population layout:

```text
       p1
        |
p4 -- p0 -- p2
        |
       p3
```

This is a plus-shaped landscape. Population `p0` is the central population, and it exchanges migrants with the four surrounding populations. The outer populations only exchange migrants with `p0`.

The baseline climate has a north-to-south gradient:

- p1 is cool.
- p0, p2, and p4 are intermediate.
- p3 is warm.

## 10-Population Test

Files:

- `migration_matrix_10pop_v1.7.csv`
- `climate_matrix_10pop_v1.7.csv`

Population layout:

```text
p0  p1  p2  p3  p4
p5  p6  p7  p8  p9
```

This is a small 2 by 5 grid. Migration occurs only between north, south, east, and west neighbors.

The baseline climate is a diagonal gradient from cooler upper-left populations toward warmer lower-right populations.

## Notes

- Rows of each migration CSV are source populations.
- Columns of each migration CSV are destination populations.
- Migration probability between connected neighbors is `0.0050`.
- Row 1 of each climate CSV is `climate1`.
- Row 2 of each climate CSV is `climate2`, shifted warmer by `+1.50`.
