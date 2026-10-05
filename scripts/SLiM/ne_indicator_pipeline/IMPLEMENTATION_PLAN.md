# Ne-indicator pipeline — step-by-step implementation plan

Builds on **`grib_pop_index_local_adaptation_ramp_v1.2.slim`**. The biology stays exactly as it is: K = 1000, R = 1.01, selection 0.05, the temperature→allele scale, migration, fitness, and the Ne/varPheno estimators. Only the *plumbing* changes, so the model can:

1. share one burn-in across many scenarios (tree sequences + recapitation),
2. apply disturbances (reduce / destroy / pulse) from a table, and
3. compute the GBF indicators afterwards.

> **Status:** steps 2–6 were prototyped and run in a sandbox with SLiM 5.1, pyslim 1.1, msprime 1.4 and your 4-pop input files. Every "✅ verified" note and every measured number below comes from those runs.

---

## Folder layout

```
scripts/SLiM/ne_indicator_pipeline/
├── ne_lib.eidos            # shared functions, lifted from v1.2 (step 1)
├── 01_burnin.slim          # phases 1–2, saves .trees (step 2)
├── 02_recapitate.py        # completes neutral history, adds m1 (step 3)
├── 03_scenario.slim        # load → disturb → lag → climate (steps 4–5)
├── 04_make_scenarios.py    # writes disturbance maps + manifest (step 5)
├── 05_run_batch.sh         # adapted from run_reps.sh (step 7)
├── 06_indicators.py        # I1 / PM / proxy + outcome (step 6)
└── tests/                  # reference logs + test maps
```

**Ground rules**

- **One module per step.** Don't start the next step until the current test gate passes.
- **Parameters come in through `slim -d`**, with defaults in the script so SLiMgui still works. This is the same pattern as `run_reps.sh`:
  ```
  if (!exists("K")) defineConstant("K", 1000);
  ```
- **Timings for plumbing tests.** Use `-d TlocalAdaptation=2000 -d TclimateChange=4000`: demes stay healthy (~950) and a run takes about 30 s. Production uses v1.2's 4000/8000.
  - Don't go shorter than 2000/4000. At 200/400 the optimum moves faster than new m2 mutations arrive, and demes crash to ~100.

---

## Step 0 — Freeze a reference

Copy v1.2 into `tests/reference/` and run it with **3 seeds** at 2000/4000. Keep the logs. Every later step is compared against them.

**Gate:** you have 3 reference logs. Note N and mean phenotype per deme at the last burn-in tick and at 2025.

---

## Step 1 — Extract a shared library (`ne_lib.eidos`)

Move every v1.2 function into `ne_lib.eidos` unchanged. Add four small wrappers around v1.2 code blocks that are already there:

| Function | What it wraps / changes |
|---|---|
| `migrateAll()` | v1.2's migration block; now **returns immigrant counts per deme** |
| `applyClimateFitness(alleleOptima)` | v1.2's climate-fitness block |
| `regulateDensity(Kvec)` | v1.2's density block, now with a **per-deme K vector**. `K = 0` sets fitnessScaling to 0, so the deme becomes a sink |
| `setupModel(neutralInForward)` | reads the inputs, defines the constants, sets up the genetics |

Load it inside `initialize()`:

```
source(PIPE_DIR + "ne_lib.eidos");   // ✅ verified: functions defined this way work
```

**Gate:** rewrite v1.2 to call the library (neutral m1 on, no disturbance) and run it with the step-0 seeds. The logs should be **identical**, because you only moved code. If they differ, you've changed the order of random draws somewhere.

---

## Step 2 — Burn-in module (`01_burnin.slim`)

This is v1.2's ticks 1 → `TclimateChange − 1` with three changes:

```
initializeTreeSeq();
setupModel(F);   // g1 = m2 only, rate 1e-7 * 0.01; neutral m1 is added later by msprime
...
(TclimateChange - 1) late() { sim.treeSeqOutput(OUT_TREES); sim.simulationFinished(); }
```

- Expected warning: *"a neutral mutation type was defined and used"*. SLiM sees m2 as neutral because its s = 0 (its effect comes through the phenotype). It's harmless.
- Leaving out m1 changes nothing biologically, because neutral mutations don't affect the genealogy. msprime adds them statistically identically in step 3.

**Gate:** N ≈ K in every deme, mean phenotype approaching the historical optima, and the file saved at tick `TclimateChange − 1`.
✅ Measured: 4000 ticks in **32 s**; demes at 958 / 823 / 983 / 944 at tick 3900.

---

## Step 3 — Recapitate (`02_recapitate.py`)

Requires `pip install msprime pyslim tskit` (or install them from conda-forge).

```python
rts = pyslim.recapitate(ts, ancestral_Ne=ANC_NE, recombination_rate=1e-8, random_seed=seed)
model = msprime.SLiMMutationModel(type=1, next_id=pyslim.next_slim_mutation_id(rts))  # type=1 -> m1
mts = msprime.sim_mutations(rts, rate=1e-7 * 0.99, model=model, keep=True, random_seed=seed)
mts.dump(dst)
```

- **`ANC_NE`:** start with `numPops × K` (4000). This is a decision to record (see the log below).
- **`TimeUnitsMismatchWarning`:** harmless here, because 1 tick = 1 generation (non-overlapping generations). Silence it with `python -W ignore`.

**Gate:** every tree has exactly 1 root; branch-based Ne (= mean pairwise branch length ÷ 4) is close to `ANC_NE`; SLiM can load the file.
✅ Measured: 1 root per tree; **Ne_het ≈ 3,420 at climate onset**, versus ~1,240 in v1.2 without recapitation. This fixes the "still rising" heterozygosity Ne.

---

## Step 4 — Scenario module, *null scenario first* (`03_scenario.slim`)

```
1 late() {
    sim.readFromPopulationFile(IN_TREES);        // ✅ tick AND cycle restored to TclimateChange - 1
    if (community.tick != TclimateChange - 1)
        stop("burn-in / scenario TclimateChange mismatch");   // ✅ guard works
    survivors = sim.subpopulations.individuals;  // ✅ pedigree IDs survive the round trip
    sim.setValue("previousPedigreeIDs", survivors.pedigreeID);
    sim.setValue("previousSubpopIDs", survivors.subpopulation.id);
    // create the LogFile here, after loading
}
Tdisturb:Tend early() { ... }   // Tdisturb = TclimateChange; climate starts at TclimateChange + LAG
```

- `setupModel(T)` switches neutral m1 back on, so v1.2's per-tick Ne_het logging works unchanged.
- `initializeTreeSeq()` isn't needed just to *load* a `.trees` file (✅ verified).

**Gate A (plumbing):**
- the first log row is `cycle = TclimateChange`, year 1970;
- Ne_inb is not NA in the first tick;
- with `-d LAG=20` there are 20 rows labelled `Lag`, then 1970–2025.

✅ All three pass.

**Gate B (biology):** run the null scenario (no disturbance file) against the step-0 reference over ≥ 5 seeds. N and mean-phenotype trajectories in the climate phase should overlap. Ne_het will be higher **by design** (equilibrium instead of the unfinished burn-in).

---

## Step 5 — Disturbances (`04_make_scenarios.py` → one CSV per scenario)

The disturbance map has one row per deme:

```
deme,K_mult,restore_offset
0,1.0,-1      # untouched
1,0.3,-1      # permanent reduction
2,0.0,-1      # permanent destruction (sink)
3,0.1,20      # pulse: K x 0.1, restored 20 ticks after the disturbance
```

Inside the scenario script, each tick: `Kvec = K * currentKmult()` → `regulateDensity(Kvec)`. Log `K_pX` and `immig_pX` (immigrant fraction) alongside the v1.2 columns.

**Gate:** run the 4-deme test map above. ✅ Measured:

| Deme | Treatment | N at +0 | +20 | +30 | 2024 |
|---|---|---|---|---|---|
| p0 | control | 932 | 703 | 594 | 102 |
| p1 | ×0.3 | 301 | 256 | 238 | 106 |
| p2 | destroyed | 0 | 0 | 0 | 0 |
| p3 | pulse ×0.1 → restored | 86 | 93 | 152 | 118 |

p0 ended at 102 here versus 367 in the null run from the same burn-in. That fits the lost-gene-flow knock-on effect, but it is **one seed**. Treat it as a hypothesis to test with replicates.

**Gotchas the test exposed:**

1. **A destroyed deme shows `immig = 1.0`.** Migrants arrive, then die (the sink working). Treat it as NA in the analysis.
2. **Ne_inb at tick *t* describes the *parents* (t−1).** So the indicator responds one tick *after* a disturbance. For a destroyed deme, the first-tick Ne_inb blows up (5,862), because mean fecundity is ≈ 0 and the Waples formula divides by nearly nothing. **Never use the estimator for destroyed demes;** set Ne = 0 in step 6.
3. **Pulse recovery is slow under climate stress,** and the 1.5 regrowth cap in the density regulation limits it too. Use LAG if you want recovery to happen *before* the climate phase.

**Generator options for `04_make_scenarios.py`:**

- fraction of demes affected — draw it from U(0,1) per run for a continuous gradient;
- type (reduce / destroy / pulse);
- severity (K_mult);
- spatial pattern (random / warmest-first / coldest-first, ranked by historical temperature);
- LAG.

Write a `manifest.csv` with one row per scenario ID.

---

## Step 6 — Indicators and outcome (`06_indicators.py`)

These rules follow the CCG / GEO BON indicator guidelines:

```python
Ne = np.where(N == 0, 0.0, Ne)                  # lost after baseline -> stays in denominator as Ne = 0
I1_ne500 = np.mean(Ne > 500, axis=1)            # headline A.4, over ALL baseline demes
PM       = np.mean(N > 0,   axis=1)             # populations maintained
I1_proxy = np.mean(N * 0.1 > 500, axis=1)       # Nc x 0.1 rule (no genetic data)
decline  = 1 - N_total[t + x] / N_total[t]      # outcome
```

**Gate:** unit tests on the 10-deme worked example (✅ pass):

| Case | I1 | PM |
|---|---|---|
| baseline: 8 of 10 above 500 | 0.8 | 1.0 |
| destroy a deme above 500 | 0.7 | 0.9 |
| destroy a deme already below 500 | 0.8 (unchanged) | 0.9 |

> ⚠️ **The proxy version is always 0 at K = 1000**, since 0.1 × 1000 = 100 < 500. It only varies if baseline K spans more than 5,000, which is a reason to include a heterogeneous-K landscape.

---

## Step 7 — Batch runner (`05_run_batch.sh`, adapted from `run_reps.sh`)

Loop order: **landscape → burn-in replicate b = 1…B → recapitate → scenario × seed s = 1…S**

- Put both seeds (burn-in, scenario) in the file name *and* as columns in every output CSV.
- Use B = 5–10 independent burn-ins per landscape. Branch every scenario from each one, and treat burn-in as a block / random effect in the analysis. That avoids pseudoreplication.
- Keep your existing pattern: one CSV per run, then combine them at the end.

**Gate:**
- the number of output files equals B × scenarios × S;
- re-running any single run with its seeds reproduces its file exactly.

---

## Step 8 — Scale up (later)

1. Switch to the 10-pop inputs, then to tens or hundreds of demes.
2. Build the migration kernel from `population_locations` coordinates, **with a distance cutoff**, so that destroying demes actually fragments the network.
3. At hundreds of demes, drop live m1 from the scenario runs too:
   - remember individuals at sampling ticks with `treeSeqRememberIndividuals()`, as your prototype already does;
   - compute heterozygosity Ne afterwards as tskit branch diversity ÷ 4 (no mutations needed);
   - add mutations only for the LD-Ne estimator.

---

## Measured timings (sandbox, 4 demes, K = 1000)

| Stage | Time |
|---|---|
| burn-in, 4000 ticks, m2 only | 32 s |
| recapitate + mutations | a few seconds |
| scenario run, 55–75 ticks with per-tick Ne logging | ~0.5 s |
| *for comparison:* v1.2 full 4055-tick run in the earlier test (m1 live, logging every tick) | ~4–5 min |

---

## Open decisions (record your choice)

- [ ] `ANC_NE` for recapitation (default `numPops × K`)
- [ ] migrants into destroyed demes: **sink** (current) or redirected
- [ ] which Ne feeds I1: Ne_inb, Ne_het, or LD-Ne (to be added), and at which tick relative to the disturbance
- [ ] outcome window *x* and the reference tick *t*
- [ ] low-migration landscapes: confirm FST has plateaued before the burn-in is saved
