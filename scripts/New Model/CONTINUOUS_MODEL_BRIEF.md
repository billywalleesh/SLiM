# Continuous-space model: design brief (for the Fable build)

*Agreed with Billy, 29 Sept 2026. Read this whole brief before opening any other file. Everything in it is decided unless it is listed under "Open items".*

## 1. Purpose

Build a continuous-space version of `grib_pop_index_local_adaptation_ramp_v1.2.slim`. It has four populations sitting on the real ERA5 Swiss temperature landscape at Geneva, Bern, Zurich and St. Gallen, and each adapts locally to its own 1940–1970 climate. The model then runs through the observed 1970–2025 record, and supports disturbance (halving or destroying a population) before climate change starts.

The thesis question is unchanged: does Ne at time *t* predict later population outcomes, and how do the GBF indicators (Ne 500 and populations maintained) behave under warming, habitat loss and population loss?

## 2. Files to use (and only these)

| File | Why |
|---|---|
| `SLiM/scripts/SLiM/grib_pop_index_local_adaptation_ramp_v1.2.slim` | The biology to preserve |
| `SLiM/scripts/SLiM/disturbance/grib_ramp_v1.2_disturbance.slim` | The disturbance logic and log columns to port. Tested, see §9 |
| `SLiM/scripts/New Model/Recipe 17.3` | `deviatePositions()` with reprising boundaries |
| `SLiM/scripts/New Model/Recipe 17.16` | nonWF density regulation through `localPopulationDensity()`, spatial mate choice |
| `SLiM/scripts/New Model/SLiM_Workshop_017X_Continuous_Space_II` | A spatial map scaling local K |
| `SLiM/scripts/New Model/Recipe 17.11` | A spatial map used as a phenotypic optimum |
| `SLiM/input/grib_pop_index_local_adaptation/population_locations/grib_population_locations_4pop_swiss_plateau.csv` | City coordinates (lon/lat) |
| `SLiM/data/raw/2m_temp_1940-2026.grib` + `SLiM/scripts/R/9_grib_climate_matrix_4pop_degrees_c_1940_2025.R` | The climate source and the existing extraction method |
| SLiM manual (project doc) | Look up only the sections needed: continuous space, spatial maps, `defineSpatialMap` orientation, `InteractionType`, `deviatePositions`, `localPopulationDensity`. Do not read it end to end. |

## 3. Decisions (locked)

### Organism

- An abstract annual species.
- Non-overlapping generations, as in v1.2: adults are killed each tick, so 1 tick = 1 generation = 1 climate year during the observed phase.
- Not beech. A tree-like life history (Hoban's suggestion) is a separate, later model.

### Landscape

- **Source:** the ERA5 2 m temperature GRIB, 0.25° cells (about 20 × 28 km).
- **Projection:** reproject to Swiss LV95 (EPSG:2056) in **km**, so all distances and σ values are in km.
- **Extent:** the raster rectangle, lon 6.0–10.5, lat 46.0–47.75.
- **Maps:**
  - one historical-mean map (1940–1970 mean) for phases 1–2;
  - one map per year for 1970–2025, used in phase 3.

  All are built **before** the Fable session by an R/terra script (stage S0) and written as SLiM-ready CSV matrices plus a metadata file (extent, cell size, orientation).
- **Interpolation:** use SLiM's `interpolate=T`.
- **The Alps:** no mask is needed. With `SELECTION_STRENGTH = 0.05`, cells colder than about 4 °C give fitness 0 for any phenotype, so the Alps are a natural barrier (verify in S4).

### Populations are areas (the patch landscape)

- One SLiM subpopulation on the whole map.
- A **habitat map** sets local carrying capacity: habitable inside four discs centred on the cities, K = 0 elsewhere.
- Population membership (p0–p3) = which disc an individual is in, recomputed every tick. Adults die each generation, so no one is ever "moved" between populations.
- **Disc radius:** justified by scale separation, not by a particular species:
  - small against one climate cell, so each population experiences one local climate as in v1.2;
  - small against the distances between cities (Geneva–Bern ≈ 130 km).

  Proposed default: **R = 5 km**. Local density is then set so that density × disc area = K = 1000 per population. Varying population size = varying density, or R per disc.
- **Open-landscape switch:** a second habitat map (habitable everywhere) with the same code. For later comparison. Note that Geneva, Bern and Zurich have nearly the same climate (11.1 / 11.5 / 11.7 °C), so in the open landscape they are expected to merge.

### Ancestry

- Each individual carries four ancestry fractions (the proportion descended from each founding population), set to the mean of its two parents at birth.
- The log records per-population mean ancestry.
- The tree sequence can recover true ancestry later if needed.

### Dispersal: two-part kernel, mirroring the v1.2 migration matrix

- **Local part:** every offspring is displaced by `deviatePositions(..., "reprising", INF, "n", SIGMA_LOCAL)` inside its disc. SIGMA_LOCAL is on the order of 0.5–1 km, so there is local structure but the disc stays well mixed over a few generations.
- **Long-distance part:** each offspring becomes a long-distance migrant with probability equal to its source population's **row sum** in the migration matrix.
  - Its destination population is drawn with the row's weights.
  - It lands at a uniform random point inside the destination disc.
  - This reproduces the v1.2 weak / strong / decay treatments exactly, and `MIGRATION_FILE` stays a `-d` parameter.
- **Boundary type:** reprising.

### Density regulation and mating

- **Density:** `fitnessScaling = K_local / localPopulationDensity`, where K_local = density × habitat map value (recipe 17.16 / workshop 17X). Keep v1.2's 1.5 regrowth cap if needed for comparability.
- **Mating:** a mate is drawn from nearest neighbours within a mate radius, which is a small multiple of SIGMA_LOCAL (recipe 17.16). This replaces v1.2's random mating within a deme.

### Selection (v1.2)

- Phenotype = m2 copy count.
- Optimum = `temperatureToAlleleOptimum(temperature map at the individual's position)`.
- Fitness = 1 − s·(phenotype − optimum)², floored at 0.
- **Temperature-to-allele anchors:** keep v1.2's values, computed from the city series (coldest historical mean 10.39 °C → 2 copies; warmest 2025 temperature → 6 copies). Store them as constants so the scale is identical to v1.2 and independent of map interpolation.

### Timeline (v1.2)

1. **Phase 1 (ticks 1–3999):** optimum ramps up to the historical map optimum.
2. **Phase 2 (ticks 4000–7999):** hold at the historical optimum.
3. **Phase 3 (ticks 8000–8055):** annual maps for 1970–2025.

Test runs use `-d TlocalAdaptation=2000 -d TclimateChange=4000`.

### Disturbance (ported from the cull module, same parameters)

- `DISTURBANCE_TYPE`: 0 none, 1 reduce, 2 destroy.
- `TARGET_POP`, `DISTURBANCE_LAG`, `DISTURBANCE_K_MULT` (default 0.5), `RECOLONIZE`.
- **Lag treatments:** 1, 100, 500 and 2000 generations before climate change:
  - 1: demographic effect only;
  - 100: ≈ Ne/10;
  - 500: ≈ Ne/2 (Mualim et al. 2026 mid-term);
  - 2000: near re-equilibrium of the reduced population.
- **Destroy, `RECOLONIZE = 0`:** that disc's habitat value is set to 0 permanently. The population is not maintained.
- **Destroy, `RECOLONIZE = 1`:** kill everyone but keep the habitat. If recolonised, the population **counts as maintained**; its Ne only affects the Ne 500 indicator once it is above 500.

### Outputs

A CSV row every tick, the same columns as the cull module, per population and total:

- tick, phase, year;
- N, K;
- Ne_het, Ne_inb, Ne_temporal;
- Ne_proxy (0.1 × N, the field rule, logged for validation against simulated Ne);
- mean climate fitness, mean phenotype, optimum, varPheno.

In addition:

- per-population mean ancestry fractions;
- the count of individuals outside all discs (should be ≈ 0 in the patch landscape);
- position snapshots (x, y, population, phenotype) every 500 ticks and every tick in phase 3, for maps;
- optional tree-sequence output (`-d RECORD_TREES=1`).

## 4. Build stages and pass criteria

Do one stage at a time. Don't start the next until the current one passes. Report the measured numbers for each stage.

| Stage | Build | Passes when |
|---|---|---|
| **S0** *(done before Fable)* | R/terra script: GRIB → LV95 km maps (historical mean + 56 annual), habitat maps (discs, open), metadata | A plot shows the same pattern as Billy's map. Map values at the cities are close to the baseline CSV: Geneva 11.11, Bern 11.54, Zurich 11.65, St. Gallen 10.39 °C (differences come only from interpolation versus cell lookup) |
| **S1** | Landscape + neutral local dispersal, no selection, no density | Reading the map in SLiM at the four city coordinates returns the S0 values. This is **the orientation test**: a flipped or transposed matrix fails it. No individual is ever out of bounds |
| **S2** | + density regulation from the habitat map | Equilibrium N per disc = 1000 ± 10%; ≈ 0 individuals outside discs |
| **S3** | + long-distance dispersal from `MIGRATION_FILE` | Realised emigration fraction per population and destination split match the matrix row sums and weights within sampling error (decay, weak, strong) |
| **S4** | + selection and the three phases | Per-population mean phenotype tracks the historical optimum by the end of phase 2, and trajectories in phase 3 are qualitatively like v1.2 (null run, ≥ 3 seeds, 2000/4000 timings) |
| **S5** | + full log, ancestry, snapshots, optional trees | All columns present. Ne_inb ≈ N under Poisson reproduction; harmonic mean of Ne_temporal over the hold ≈ N per population (the cull module gives ≈ 1000 at N ≈ 940) |
| **S6** | + disturbance | The four cull-module test scenarios (§9) behave the same way: the target population is halved or emptied at the right tick, K changes, a sink stays at 0, and recolonisation happens within ~40 generations |
| **S7** | Parameterise everything via `-d` and add a SLURM grid in the existing pattern (`make_*_parameter_grid.sh`, array worker, submit script) | A re-run with the same seed reproduces its file exactly |

## 5. Known pitfalls (already hit in this project)

- **Line endings:** input CSVs have Windows line endings. On Linux, `readCSV()` then reads the last column as strings and `asMatrix()` fails. Strip `\r` for cluster runs.
- **`createDirectory()` is not recursive:** make sure `SLiM/results/` exists.
- **Matrix orientation:** `defineSpatialMap()` matrix orientation relative to x/y is the classic bug. S1 exists to catch it. Check the manual's description rather than assuming.
- **Ne_inb for a destroyed population:** it blows up in the tick after destruction (mean fecundity ≈ 0). Use Ne = 0 for destroyed populations in the indicators.
- **Temporal Ne is noisy per 10-generation window:** use the harmonic mean over windows. The v1.2 genome is one tightly linked 100 kb block (r = 1e-8), so temporal Ne includes linked selection and there are few independent loci. The v2 genome (separate unlinked neutral block, r = 1e-6) is an option. It changes adaptation speed, so it is a new experiment, not a re-run.
- **Gene-flow drag:** gene flow along the temperature cline pre-adapts the cold population (p3). Expect it to reappear here.
- **Ne_het under v1.2 migration:** a halved population's Ne_het does not drop within 500 generations under the decay matrix (§9), because it is really measuring the metapopulation. The same will hold in continuous space unless migration is weak.

## 6. Efficiency rules for the session

- Plumbing tests use 2000/4000 timings; production uses 4000/8000.
- Consult the manual by section. Don't paste large chunks back.
- Write each stage's code as a diff to the previous stage and run it before explaining it.
- After every stage, report the numbers, and nothing else unless something failed.

## 7. Open items (Billy decides; defaults in brackets)

1. **Reduce as area or density:** does "reduce" shrink the disc (radius × 1/√2, closer to Mualim's habitat loss) or lower its density? *[area]*
2. **Climate metric:** absolute temperature or a 30-year anomaly (Hoban's suggestion)? *[absolute, as in v1.2]*
3. **Density and dispersal values:** a literature-based value for a real Swiss Plateau annual (plant or insect)? *[scale-separation defaults above]*
4. **Which genome:** v1.2 (comparable to existing runs) or v2 (better for Ne)? *[v1.2 first]*

## 8. Later extensions (not in this build)

- Open landscape
- Tens to hundreds of populations
- Projected climate scenarios
- A tree-like life history
- Recapitated burn-in with shared burn-ins, as in `ne_indicator_pipeline/IMPLEMENTATION_PLAN.md`

## 9. Cull module: results from its test runs

**Script:** `SLiM/scripts/SLiM/disturbance/grib_ramp_v1.2_disturbance.slim` (SLiM 5.2; 2000/4000 timings; seed 11; decay matrix; target p1 Bern).

**Null run:** the N and Ne_het columns are **identical tick for tick** to the original v1.2 with the same seed, so the biology is unchanged. Over the hold phase:

- harmonic-mean Ne_temporal ≈ 1030 (p0) and ≈ 3850 (total);
- Ne_inb ≈ N ≈ 940.

**Disturbance runs:**

| Scenario | At disturbance | N in 2025 (p0–p3) |
|---|---|---|
| None | none | 490 / 328 / 325 / 573 |
| Reduce ×0.5, lag 1 | p1 1022 → 511, K 500 | 164 / 203 / 352 / 444 |
| Reduce ×0.5, lag 500 | p1 917 → 458, K 500 | 269 / 252 / 297 / 545 |
| Destroy, no recolonisation, lag 100 | p1 926 → 0, K 0 (sink) | 184 / 0 / 141 / 347 |
| Destroy, recolonisable, lag 100 | p1 926 → 0, K 1000 | 243 / 331 / 405 / 476 |

- **Recolonisation:** from immigrants, p1 was back at N ≈ 480 within 35 generations.
- **These are single runs:** every difference in this table is a hypothesis until it is replicated.
