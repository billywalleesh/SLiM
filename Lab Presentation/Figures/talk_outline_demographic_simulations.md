# Intro to Demographic Simulations — slide-by-slide storyline

**Billy Wallisch · Spatial Genomics Group, Dept. of Geography, UZH · 16 September 2026**
Target: 20–30 min · 25 slides · audience of ecologists / conservation people
Structure follows van Moorsel & Selmoni: *story*, not report — three problem → goal → method cycles, broad at the start, broad at the end. Every title is a full sentence carrying the take-home. Target ≤12 words of body text per slide.

---

## The one-sentence spine

> Conservation has committed to monitoring genetic diversity, but it monitors it with headcounts. I use forward-time simulation in SLiM to ask whether those headcounts still work when the climate is moving — and my first results say the genetic indicator can look healthy while the population is dying.

---

## ACT 1 — Why a headcount isn't enough (slides 2–8)

### 1. Title
**Intro to Demographic Simulations**
Billy Wallisch · 16 September 2026 · Spatial Genomics Group
*(UZH title layout, as in your template)*

### 2. Two populations. Same size. Different futures.
- **Visual:** two identical-looking photos of the same meadow/forest patch, side by side, each labelled "N = 500".
- **Say:** Ask the room to pick which one survives the next 50 years. They can't — and neither can a monitoring programme that only counts.
- *This is the hook. No text beyond the title and the two labels.*

### 3. What you can't see in a headcount is the raw material for adaptation.
- **Visual:** same two patches, now with a strip of coloured "genome" bars underneath — one patch varied, one patch nearly uniform.
- **Say:** Selection can only act on variation that already exists. Uniform population = nothing for climate to select on.

### 4. Small populations lose that variation, quietly and permanently.
- **Visual:** simple drift cartoon — allele frequencies wandering in a small vs large population over generations.
- **Say:** Drift, inbreeding, the ratchet. And it happens *before* numbers crash, which is the part that matters.

### 5. The world has already agreed this should be monitored.
- **Visual:** Kunming–Montreal GBF logo / Goal A + Target 4 text pulled out.
- **Say:** Genetic diversity of wild populations is now a headline global target. Countries have to report on it.
- *Cite the framework properly — this is the slide that makes an ecology audience sit up.*

### 6. But nobody can sequence every population, every year.
- **Visual:** cost/effort cartoon: a sequencing lab vs. a person with a clipboard.
- **Say:** So the agreed indicators are **demographic proxies** — the Ne > 500 rule of thumb and the proportion-of-populations-maintained indicator, both computed from census counts, not from DNA.

### 7. **Problem 1:** Those proxies were built for a stable world.
- **Visual:** a flat climate line, then the same line bending upward.
- **Say:** The relationship between how many individuals there are and how much diversity they hold was worked out for populations sitting at equilibrium. Climate change is exactly the situation where that assumption breaks.

### 8. **Goal 1:** Find out whether the proxy still holds when the climate moves.
- **Visual:** the question written large, nothing else.
- **Say:** State the thesis question plainly, once, in words a non-geneticist owns.

---

## ACT 2 — You can't run this experiment, so simulate it (slides 9–15)

### 9. **Problem 2:** There is no control Switzerland and no rewind button.
- **Visual:** a "field experiment" crossed out — 80 years, four cities, replicated.
- **Say:** To test a predictor you need to know the outcome. That means watching populations from 1940 to now, many times over. Nobody has that dataset.

### 10. **Method 2:** Build a population you *can* rewind.
- **Visual:** the loop — born → mate → migrate → die → repeat.
- **Say:** Forward-time, individual-based simulation. Every individual is an object with a genome. You press play and let 4,000 generations happen.

### 11. Most population genetics runs time backwards. We need it to run forwards.
- **Visual:** two arrows — coalescent (backwards, from today's samples to a common ancestor) vs forward-time (1940 → 2025).
- **Say:** Backwards methods are fast and elegant but assume you already know the demography and mostly can't handle selection. Selection driven by a changing environment is the whole point here, so: forwards.

### 12. SLiM is the tool that does this.
- **Visual:** SLiM logo + GUI screenshot mid-run.
- **Say:** Forward-time, individual-based, genetically explicit. Written by Ben Haller & Philipp Messer. Scripted in a small language called Eidos. It's free and it runs on a laptop.
- *Citation footer: Haller & Messer, SLiM.*

### 13. A SLiM model is four questions, asked every generation.
- **Visual:** four stacked boxes, built up with animation:
  1. what genome does this individual carry?
  2. what phenotype does that genome give it?
  3. how well does that phenotype fit *this year's* environment?
  4. does it survive and reproduce?
- **Say:** This is the whole conceptual machine. Everything else is bookkeeping.

### 14. And it reads like the biology it describes.
- **Visual:** ~6 lines of your actual Eidos — the fitness line is the money shot:
  `fitness = 1 - SELECTION_STRENGTH * lag^2`
- **Say:** One line, one sentence of biology: the further you are from the local optimum, the fewer offspring you leave. Don't walk through the syntax.

### 15. SLiM also hands you the family tree of every individual, for free.
- **Visual:** a small tree sequence — a handful of genealogies along a chromosome.
- **Say:** Tree recording. Instead of sequencing simulated individuals, you get the exact genealogy and read diversity and effective size straight off it. This is what makes the question answerable at all.
- *Optional aside if the room is with you: in my v1 genome the whole 100 kb behaved as one locus — 54 distinct trees per run. Rebuilding it as two unlinked blocks gave ~11,900. Same biology, usable measurement.*

---

## ACT 3 — What I'm doing with it (slides 16–24)

### 16. Section break: **My project**
- **Visual:** photo of the Swiss Plateau. Chapter-title layout from the template.

### 17. **Problem 3:** The Swiss Plateau has warmed, and the indicator has never been tested against a real climate record.
- **Visual:** the 1940–2025 ERA5 mean-temperature series for your four locations, one panel, four lines.
- **Say:** This is the actual forcing my simulations run on — not a scenario, the observed record.

### 18. **Goal 3:** Does effective size *before* the warming predict who is still there in 2025?
- **Visual:** timeline arrow — a measurement point at 1970, a question mark at 2025.
- **Say:** That is the whole thesis in one sentence. If Ne measured before the disturbance predicts the outcome, the indicator earns its keep. If it doesn't, we have a problem worth reporting.

### 19. **Method 3:** Four demes across the Plateau — Geneva, Bern, Zurich, St. Gallen.
- **Visual:** map of Switzerland, four dots, arrows for migration between them.
- **Say:** Each deme has its own climate series and its own local optimum. Individuals move between them at a rate I control.

### 20. Individuals carry a temperature optimum, and mismatch costs them.
- **Visual:** a bell curve sliding right, with a population lagging behind it.
- **Say:** A polygenic trait: number of adaptive allele copies maps onto degrees Celsius. 10.4 °C = 2 copies, 14.0 °C = 6 copies. The population chases a moving optimum; the gap is the "lag", and lag squared is what kills you.

### 21. Twelve treatments, twenty replicates, 240 runs on the cluster.
- **Visual:** the factorial cube — carrying capacity (500 / 2 000 / 5 000) × selection strength (0.05 / 0.075) × migration (weak / strong).
- **Say:** One parameterised model, a deterministic parameter grid, a SLURM array. Say the word "replication" out loud — this audience cares about it.

### 22. Each run is 4,055 generations: settle, adapt, then live through the record.
- **Visual:** horizontal timeline — ramp (ticks 1–2000) → historical hold (2000–4000) → observed climate 1970–2025 (4000–4055).
- **Say:** The long burn-in exists so that whatever I measure in 1970 is a real evolved state, not a leftover of my starting conditions.

### 23. **First result:** connect the demes, and "local" effective size stops being local.
- **Visual:** bar/scatter — measured per-deme Ne against local census N, weak vs strong migration.
- **Say:** Under strong migration, per-deme Ne came out **2.3–2.8× the local census size**. Not a bug: with ~10 immigrants per deme per generation, lineages leave before they can coalesce locally, so "per-deme Ne" is quietly reporting the whole metapopulation.
- **So what:** a well-connected but locally tiny population can pass the genetic indicator on connectivity alone.

### 24. **And the sharper one:** the genetic signal lags the collapse.
- **Visual:** two lines over the same crash — census N falling to 15, diversity-based Ne still reading ~324.
- **Say:** Diversity-based measures integrate over the whole past, so they keep reporting a healthy population long after it has crashed. That is a property of the measure, not an error in my code — and it is precisely the failure mode a monitoring indicator cannot afford.
- *This is your best slide. Land it, then pause.*

---

## Closing (slide 25)

### 25. An indicator that reassures you late is worse than no indicator.
- **Visual:** back to slide 2's two meadows.
- **Say:** Where this goes next: the full 240-run analysis, and a direct comparison of the census-based and genealogy-based indicators against the actual 2025 outcome. Then: thank you, contact, questions.
- *Contact layout from the template.*

---

## Things to decide before I build

1. **Slide 5 (GBF).** I'd like to name Goal A / Target 4 and the two indicators explicitly. Confirm the exact framing you want to use — this is the claim an ecologist in the room is most likely to push on.
2. **Figures.** `results/4pop_ne_experiment/analysis/` is empty, so slides 17, 23 and 24 currently have no plot. Either you point me at existing figures, or I write the R/Python to generate them from `results/reps/all_runs.csv` and `ramp_v2_experiment/ne_hardcoded_v2.csv`.
3. **Slide 24's numbers.** The Ne ≈ 324 vs N = 15 figure comes from your `ramp_v2` README. Confirm it's from a run you're happy to show, and which treatment it was.
4. **Trim point.** If the talk lands closer to 20 min, slides 4, 11 and 22 are the ones to cut — none of them carry a unique take-home.
