# SLiM

## Overview

This repository contains work for my MSc thesis on using **SLiM simulations** to study genetic diversity and extinction risk under climate change.

Genetic diversity is critical for ecosystem resilience. While DNA sequencing is the gold standard for measuring it, practical limitations (cost, labor, and time delays) make it difficult for large-scale monitoring.

This project explores **demographic indicators** (e.g., population size) as proxies for genetic diversity. Using simulation-based approaches, I evaluate how well these indicators predict genetic erosion and extinction risk.

---

## Project Goals

* Simulate populations under climate-change scenarios using SLiM
* Track genetic diversity and extinction over time
* Evaluate demographic indicators as proxies for genetic health
* Develop practical guidelines for real-world monitoring

---

## Structure

* `data/` – input and processed data
* `scripts/` – simulation and analysis code
* `notebooks/` – exploratory analysis
* `results/` – outputs (plots, logs, simulations)
* `workshop/` – SLiM training material and exercises

---

## Reproducibility

To reproduce key results:

1. Run simulation scripts:

   ```bash
   python scripts/run_simulation.py
   ```

2. Analyze outputs:

   ```bash
   Rscript scripts/analysis.R
   ```

*(Update these commands as your workflow develops)
---

## Tools & Skills

* SLiM (population genetics simulation)
* R (statistical analysis)
* Python (data handling & workflows)
* Spatial analysis
* High-performance computing (HPC)

---

## Status

Work in progress
