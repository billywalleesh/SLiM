# SLiM/Scripts

## Overview

This folder contains scripts for my  MSc thesis on using **SLiM simulations** to study genetic diversity and extinction risk under climate change.

---

## Structure
* `scripts/` – simulation and analysus

---

## Reproducibility

The main script originated from /scripts/SLiM/pop_index_local_adaptation
  - this script creates 2 populations within different optimums (2 and 6 climates)
This script evolved into further versions through the use of real climate data to model climate disturbance. 

Now the versions attempt to quantify these optima of 2 and 6 in order for yearly mean degrees celcius 
to correspond to each optimum in a continuous manner. 

These versions output essentially the same things, and all calcutlations have remained intact:
  -Fitness
  -Reproduction
  -Migration 
  -etc.
However, I am now starting to output Ne. This has caused many different versions to take shape. V1 is oututting Ne according to 
the SLiM manual, and using .trees files. V2 is also according to the manual, but uses an unlinked nuetral genome as well.

---


## Status

Work in progress
