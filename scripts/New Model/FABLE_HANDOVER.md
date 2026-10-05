# Fable handover: continuous-space model v0.1

*Written 29 Sept 2026, after the build session with Claude (Opus). Read this first, then `CONTINUOUS_MODEL_BRIEF.md` (same folder) for the reasoning behind the design. Where the two disagree, this file wins. Section 2 lists every difference.*

## 1. Where things stand

The model runs end to end, and stages S0–S4 and S6 of the brief pass. What is left is listed in section 5.

| Stage | Status | Evidence (SLiM 5.2, test timings 2000/4000 unless stated) |
|---|---|---|
| **S0** maps | ✅ | `26_continuous_climate_maps.R` writes 57 maps per map set (169 × 96 grid points, 2 km spacing, 336 × 190 km). The check plot shows the Plateau warm band, the Alpine cold band and warm Ticino in the south-east. |
| **S1** orientation | ✅ | Built-in self-test at tick 1. SLiM's map value at each city equals R's to 0.0001 °C (Geneva 11.0620, Bern 11.0081, Zurich 11.3726, St. Gallen 9.8856). The model stops if it doesn't match. |
| **S2** density | ✅ with `SIGMA_COMP = 2` | Neutral, 300 ticks: mean N per population 1023–1045 (target 1000), 0 individuals outside discs. With `SIGMA_COMP = 1` it was 807–864, so it fails (see §4). |
| **S3** long-distance dispersal | ✅ | Realised emigration rates 0.0120 / 0.0144 / 0.0145 / 0.0123 against decay-matrix row sums 0.012 / 0.014 / 0.014 / 0.012. Destination splits match the row weights to within 0.01. |
| **S4** selection + phases | ✅ (qualitative) | 2 seeds; details in §3. |
| **S5** outputs | ⚠️ partial | All cull-module columns per population and total, plus `emig_pX`, `N_outside` and position snapshots. **Missing: ancestry fractions.** |
| **S6** disturbance | ✅ | Reduce, destroy-recolonisable and destroy-not-recolonisable all behave as specified (§3). |
| **S7** grid / SLURM | ❌ | Not started. |

## 2. Differences from the brief (decided during the build; Billy to confirm)

1. **Habitat discs are computed exactly, not stored as a raster.** A 5 km disc on a 2 km raster would be blocky. The disc test is `(x − cityX)² + (y − cityY)² ≤ PATCH_RADIUS²`.
2. **Default `MAP_SET = "smooth"`** (bilinear between ERA5 cell centres), not blocky `"cells"`.
   - Reason: Zurich sits about 200 m from an ERA5 cell boundary, so even the blocky map splits the Zurich disc between two cells (11.31 and 11.65 °C). There is no way to reproduce v1.2 exactly for every city.
   - The smooth map's city temperatures sit below v1.2's cell values: Geneva −0.05, Bern −0.53, Zurich −0.28, St. Gallen −0.51 °C.
   - `-d MAP_SET='cells'` switches back.
3. **Temperature-to-allele anchors** use v1.2's *rule*, applied to the map values at the city points:
   - coldest city historical mean → 2 copies (St. Gallen 9.886 °C);
   - warmest city in 2025 → 6 copies (Geneva 14.502 °C).

   With `cells`, the anchors equal v1.2's exactly (10.3914 and 14.5249).
4. **`SIGMA_COMP = 2 km`** (the competition kernel). This was needed to pass S2 (§4).
5. **"Reduce" is the density version:** the disc's K multiplier is set to 0.5 and half the population is killed. The area version (shrinking the disc) is open item 1 of the brief.
6. **The open-landscape switch is not implemented.** Only the patch landscape exists.

## 3. Measured results

### S4: null runs (seeds 11 and 12, decay matrix)

- **Hold phase:** N per population 970–995. Ne_inb ≈ N (966–991). The harmonic mean of Ne_temporal is 982–1104 per population and 3869 / 3969 in total, the same as the cull module.
- **Adaptation at the end of the hold** (phenotype vs optimum, copies):

  | | Geneva | Bern | Zurich | St. Gallen |
  |---|---|---|---|---|
  | Phenotype | 2.77 | 2.80 | 2.81 | 2.38 |
  | Optimum | 3.02 | 2.97 | 3.28 | 2.00 |

  The warm populations lag their optima and St. Gallen overshoots. That is the gene-flow drag along the cline already diagnosed in v1.2.
- **Ne_het at the end of the hold:** about 1600–1680 per population, above N, as in v1.2 (under Nm ≈ 12 it measures the metapopulation).
- **2025:**
  - N per population (p0–p3): seed 11: 388 / 595 / 558 / 774; seed 12: 306 / 347 / 300 / 697.
  - Mean fitness: Geneva 0.73–0.75 (the lowest), the rest 0.84–0.88.
  - Phenotype against the 2025 optimum: Geneva 3.8 vs 6.0, St. Gallen 3.0 vs 4.4.
  - St. Gallen ends largest in both seeds, as in v1.2.
- **Comparison with v1.2 (seed 11, same timings):** v1.2 ended at 490 / 328 / 325 / 573. The continuous model's populations fare somewhat better in 2025. Plausible reasons: the smooth-map optima are lower for Bern and St. Gallen, and local mating. This is untested, and based on only 2 seeds.

### S6: disturbance runs (seed 11, target Bern, lag 100, disturbance at tick 3900)

- **Reduce:** 1107 → 553, K multiplier 0.5. N then holds at 500–570.
- **Destroy, recolonisable:** 1107 → 0. Immigrants refound it: 13 at +0, 209 at +10, 640 at +40, 893 at +60.
- **Destroy, not recolonisable:** 1107 → 0, K multiplier 0. Bern stays at N = 0; immigrants land in the sink and die. Ne_inb_p1 is NA (no blow-up), and the other populations are unaffected over 60 ticks (Geneva 914–1049, Zurich 898–948).

### Runtime (one core, 4 populations × ~1000)

- About 7 min for a 4055-tick test run.
- Production (8055 ticks): expect about 14 min.
- Neutral, 300 ticks: 19 s.

## 4. Things Fable should know

- **Density regulation depends on the competition kernel (crowding).** Offspring start at a parent's position and mate locally, so individuals cluster and feel a local density above the disc average. Neutral equilibrium N per population:

  | Setting | Mean N per population |
  |---|---|
  | `SIGMA_COMP = 0.5` | 650–700 |
  | `SIGMA_COMP = 1.0` | 810–860 |
  | `SIGMA_COMP = 2.0` | 1025–1045 |
  | `SIGMA_LOCAL = 2` (with `SIGMA_COMP = 1`) | 765–800 |

  Any change to the σ values needs S2 re-checked. The alternative, if Billy prefers exact comparability with v1.2, is disc-wide regulation `min(Kpop / Npop, 1.5)`, which removes local competition.
- **R = 1.01 means a population can grow at most about 1% per generation by itself.** Recovery after destruction is almost entirely immigration, and a reduced population cannot regrow above its new K anyway. This is inherited from v1.2 and matters for interpreting the recolonisation scenarios.
- **Geneva is 7 km from the map's west edge.** The disc (5 km) fits, but keep `PATCH_RADIUS ≤ 7` or enlarge the map box in the R script.
- **Line endings:** CSVs written by R on Windows have Windows line endings. On the Linux cluster, strip `\r` first, or `readCSV()` fails (the brief lists this pitfall).
- **Temporal Ne:** noisy per 10-generation window, so use the harmonic mean over windows. It includes linked selection, because the v1.2 genome is one linked block.
- **Population membership:** individuals carry their population index in `tag` (−1 = in no disc) and their phenotype in `tagF`. Inbreeding Ne groups parents by `previousPopIDs`.

## 5. Tasks for Fable (in order; one at a time; report numbers)

1. **Review first (cheap, high value).** Read `grib_continuous_v0.1.slim` against v1.2 and the SLiM manual. Look for anything that changes the biology unintentionally, especially:
   - the order of events within a tick;
   - whether founders dispersing at tick 1 matters;
   - the `drawByStrength` mate choice when a parent has no neighbours (no offspring);
   - edge correction in `localPopulationDensity` at disc edges.

   Report findings before changing anything.
2. **Ancestry fractions (S5).** Four floats per individual (the proportion descended from each founding population), set to the mean of the two parents at birth, logged as the per-population mean. Measure the runtime cost. If `setValue` per individual is too slow, consider storing them in a matrix indexed by pedigree ID, or derive them from the tree sequence afterwards.
3. **Optional `-d RECORD_TREES=1`** tree-sequence output, following `ramp_v1`'s pattern (no RNG draws, so runs stay bit-identical when it's off).
4. **Replicates.** 5 seeds each of the null run and the three disturbances at production timings, compared with the cull module (v1.2) on the same seeds: N in 2025, time to recolonise, and Ne at the disturbance and at climate onset.
5. **S7:** parameter grid and SLURM scripts in the existing pattern:
   - `make_*_parameter_grid.sh`, array worker, submit script;
   - seed base 8000000;
   - treatment IDs prefixed `cont_v0.1_`;
   - grid over DISTURBANCE_TYPE × RECOLONIZE × DISTURBANCE_LAG (1, 100, 500, 2000) × TARGET_POP × MIGRATION_FILE.
6. **Later, only if Billy asks:** the open landscape, reduce-as-area, and more populations.

**Efficiency rules:**
- Plumbing tests use 2000/4000 timings with `END_TICK` to stop early.
- Neutral density checks: `-d SELECTION_ON=0 -d END_TICK=300`.
- Don't read the whole manual or all of v1.2's history.

## 6. Files

| File | What |
|---|---|
| `SLiM/scripts/R/26_continuous_climate_maps.R` | S0: GRIB → maps, city coordinates, metadata, check plot |
| `SLiM/input/continuous_swiss/` | Its outputs (maps_smooth/, maps_cells/, map_metadata.csv, population_locations_lv95.csv, check_maps.png) |
| `SLiM/scripts/SLiM/continuous/grib_continuous_v0.1.slim` | The model |
| `SLiM/scripts/SLiM/disturbance/grib_ramp_v1.2_disturbance.slim` | Cull module (non-spatial v1.2 + disturbance), for comparisons |
| `SLiM/scripts/New Model/CONTINUOUS_MODEL_BRIEF.md` | Design brief |

**Run** (Windows, from the workspace; the defaults point at `C:/Users/WilliamWallisch/msc_workspace`):

```
slim -s 11 SLiM/scripts/SLiM/continuous/grib_continuous_v0.1.slim
slim -s 11 -d TlocalAdaptation=2000 -d TclimateChange=4000 -d DISTURBANCE_TYPE=2 -d RECOLONIZE=0 -d TARGET_POP=1 -d DISTURBANCE_LAG=100 SLiM/scripts/SLiM/continuous/grib_continuous_v0.1.slim
```

**Outputs** go to `SLiM/results/continuous_v0.1/`:
- `<label>_log.csv`: **long format**, one row per population per tick plus a row with `pop = total` (the cycle repeats 5 times). Columns: cycle, phase, year, pop, location, N, K, emigrants, Ne_het, Ne_inb, Ne_temporal, Ne_proxy, meanFitness, meanPheno, optimum, varPheno.
  - `K` is each population's current carrying capacity, so a reduced or destroyed population shows 500 or 0 from the disturbance tick on.
  - In the total row, K is the sum over populations, optimum is the mean of the populations' optima, and the Ne columns are the metapopulation estimates. Individuals outside every disc = total N minus the four populations.
  - The cull module writes the same layout, without `emigrants`.
- `<label>_positions.csv`: x, y, population, phenotype and optimum at tick 1, every 500 ticks, and every tick after climate change starts. This is about 4,000 rows per snapshot; set `-d SNAPSHOT_EVERY=0` to turn it off.
